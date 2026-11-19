import 'dart:async';
import 'package:flutter/foundation.dart';
// ignore: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:js' as js;

class NotificationHelper {
  static bool get isSupported {
    if (!kIsWeb) return false;
    try {
      return js.context.hasProperty('Notification');
    } catch (_) {
      return false;
    }
  }

  static String get permissionStatus {
    if (!kIsWeb) return 'unsupported';
    try {
      final notif = js.context['Notification'];
      if (notif != null) {
        return (notif['permission'] ?? 'default').toString();
      }
    } catch (e) {
      debugPrint('Permission status check notice: $e');
    }
    return 'default';
  }

  static bool get isGranted => permissionStatus == 'granted';
  static bool get isDenied => permissionStatus == 'denied';

  static Future<String> requestPermission() async {
    if (!kIsWeb) return 'unsupported';
    final completer = Completer<String>();

    try {
      // ignore: deprecated_member_use
      final callback = js.allowInterop((perm) {
        if (!completer.isCompleted) {
          completer.complete(perm?.toString() ?? permissionStatus);
        }
      });

      js.context.callMethod('requestAuraNotificationPermission', [callback]);

      // Safety timeout in case user ignores prompt or browser takes long
      Future.delayed(const Duration(seconds: 8), () {
        if (!completer.isCompleted) {
          completer.complete(permissionStatus);
        }
      });
    } catch (e) {
      debugPrint('Web notification permission request note: $e');
      if (!completer.isCompleted) {
        completer.complete(permissionStatus);
      }
    }

    return completer.future;
  }

  static void showSystemNotification({
    required String title,
    required String body,
    String? icon,
  }) {
    if (kIsWeb) {
      try {
        js.context.callMethod('showAuraSystemNotification', [
          title,
          body,
          icon ?? 'icons/Icon-192.png',
        ]);
      } catch (e) {
        debugPrint('Web system notification trigger note: $e');
      }
    }
  }

  static void playChime() {
    if (kIsWeb) {
      try {
        js.context.callMethod('playAuraChime');
      } catch (e) {
        debugPrint('Web play chime note: $e');
      }
    }
  }
}
