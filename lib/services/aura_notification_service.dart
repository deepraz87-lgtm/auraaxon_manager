import 'dart:async';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../firebase_options.dart';
import '../features/aura_agents/notification_helper.dart';

// High Importance Notification Channel for Android
const AndroidNotificationChannel highImportanceChannel = AndroidNotificationChannel(
  'auraaxon_alerts_high_importance',
  'AuraAxon High Priority Alerts',
  description: 'Real-time alerts for agent registrations, leads, and operational events.',
  importance: Importance.max,
  playSound: true,
  enableVibration: true,
  showBadge: true,
);

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  } catch (_) {}

  final notification = message.notification;
  if (notification != null) {
    await flutterLocalNotificationsPlugin.show(
      id: message.hashCode,
      title: notification.title ?? 'AuraAxon Alert',
      body: notification.body ?? '',
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          highImportanceChannel.id,
          highImportanceChannel.name,
          channelDescription: highImportanceChannel.description,
          importance: Importance.max,
          priority: Priority.high,
          visibility: NotificationVisibility.public,
          playSound: true,
          enableVibration: true,
          icon: '@mipmap/ic_launcher',
          styleInformation: BigTextStyleInformation(notification.body ?? ''),
        ),
      ),
    );
  }
}

@pragma('vm:entry-point')
void onBackgroundServiceStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();

  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  } catch (e) {
    debugPrint('Background service Firebase init note: $e');
  }

  final FlutterLocalNotificationsPlugin localPlugin = FlutterLocalNotificationsPlugin();
  const AndroidInitializationSettings androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
  await localPlugin.initialize(settings: const InitializationSettings(android: androidInit));

  final prefs = await SharedPreferences.getInstance();
  int lastNotifTime = prefs.getInt('last_processed_notif_time') ?? DateTime.now().millisecondsSinceEpoch - 60000;

  // Listen to manager_notifications in real-time
  FirebaseFirestore.instance
      .collection('manager_notifications')
      .where('read', isEqualTo: false)
      .snapshots()
      .listen((snapshot) async {
    for (final change in snapshot.docChanges) {
      if (change.type == DocumentChangeType.added) {
        final data = change.doc.data();
        if (data == null) continue;

        final notifId = change.doc.id;
        final processedKey = 'notif_seen_$notifId';
        if (prefs.getBool(processedKey) == true) continue;

        final Timestamp? timestamp = data['createdAt'] as Timestamp?;
        final timeMillis = timestamp?.millisecondsSinceEpoch ?? DateTime.now().millisecondsSinceEpoch;

        if (timeMillis < lastNotifTime) continue;

        final title = (data['title'] ?? 'AuraAxon Alert').toString();
        final body = (data['message'] ?? 'New notification received in AuraAxon Manager.').toString();

        await localPlugin.show(
          id: notifId.hashCode,
          title: title,
          body: body,
          notificationDetails: NotificationDetails(
            android: AndroidNotificationDetails(
              highImportanceChannel.id,
              highImportanceChannel.name,
              channelDescription: highImportanceChannel.description,
              importance: Importance.max,
              priority: Priority.high,
              visibility: NotificationVisibility.public,
              playSound: true,
              enableVibration: true,
              icon: '@mipmap/ic_launcher',
              styleInformation: BigTextStyleInformation(body),
            ),
          ),
        );

        await prefs.setBool(processedKey, true);
        await prefs.setInt('last_processed_notif_time', timeMillis);
      }
    }
  }, onError: (err) {
    debugPrint('Background service Firestore listen error: $err');
  });
}

class AuraNotificationService {
  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    if (kIsWeb) {
      _initWebNotifications();
    } else {
      await _initMobileNotifications();
    }
  }

  static Future<void> _initMobileNotifications() async {
    // 1. Android notification channel & local notifications setup
    const AndroidInitializationSettings androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initSettings = InitializationSettings(android: androidInit);
    await flutterLocalNotificationsPlugin.initialize(settings: initSettings);

    final androidPlatformPlugin = flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlatformPlugin != null) {
      await androidPlatformPlugin.createNotificationChannel(highImportanceChannel);
      await androidPlatformPlugin.requestNotificationsPermission();
    }

    // 2. Firebase Cloud Messaging setup
    try {
      FirebaseMessaging messaging = FirebaseMessaging.instance;
      await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        final notif = message.notification;
        if (notif != null) {
          flutterLocalNotificationsPlugin.show(
            id: message.hashCode,
            title: notif.title ?? 'AuraAxon Alert',
            body: notif.body ?? '',
            notificationDetails: NotificationDetails(
              android: AndroidNotificationDetails(
                highImportanceChannel.id,
                highImportanceChannel.name,
                channelDescription: highImportanceChannel.description,
                importance: Importance.max,
                priority: Priority.high,
                visibility: NotificationVisibility.public,
                playSound: true,
                enableVibration: true,
                icon: '@mipmap/ic_launcher',
                styleInformation: BigTextStyleInformation(notif.body ?? ''),
              ),
            ),
          );
        }
      });

      // Subscribe to managers topic
      await messaging.subscribeToTopic('auraaxon_managers');
    } catch (e) {
      debugPrint('FCM Mobile init note: $e');
    }

    // 3. Start Background Service
    try {
      final service = FlutterBackgroundService();
      await service.configure(
        androidConfiguration: AndroidConfiguration(
          onStart: onBackgroundServiceStart,
          autoStart: true,
          isForegroundMode: false,
          autoStartOnBoot: true,
        ),
        iosConfiguration: IosConfiguration(
          autoStart: false,
          onForeground: onBackgroundServiceStart,
        ),
      );
      await service.startService();
    } catch (e) {
      debugPrint('Background service config note: $e');
    }
  }

  static void _initWebNotifications() {
    NotificationHelper.requestPermission();

    FirebaseFirestore.instance
        .collection('manager_notifications')
        .where('read', isEqualTo: false)
        .snapshots()
        .listen((snapshot) {
      for (final change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          final data = change.doc.data();
          if (data == null) continue;

          final title = (data['title'] ?? 'AuraAxon Alert').toString();
          final body = (data['message'] ?? 'New notification received.').toString();

          NotificationHelper.showSystemNotification(
            title: title,
            body: body,
          );
          NotificationHelper.playChime();
        }
      }
    });
  }
}
