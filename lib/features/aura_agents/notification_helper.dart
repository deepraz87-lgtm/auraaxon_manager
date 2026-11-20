import 'dart:async';
import 'notification_helper_stub.dart'
    if (dart.library.js) 'notification_helper_web.dart';

class NotificationHelper {
  static bool get isSupported => WebNotificationHelper.isSupported;
  static String get permissionStatus => WebNotificationHelper.permissionStatus;
  static bool get isGranted => WebNotificationHelper.isGranted;
  static bool get isDenied => WebNotificationHelper.isDenied;

  static Future<String> requestPermission() => WebNotificationHelper.requestPermission();

  static void showSystemNotification({
    required String title,
    required String body,
    String? icon,
  }) {
    WebNotificationHelper.showSystemNotification(
      title: title,
      body: body,
      icon: icon,
    );
  }

  static void playChime() {
    WebNotificationHelper.playChime();
  }
}
