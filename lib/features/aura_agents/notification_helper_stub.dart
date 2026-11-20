// Stub implementation for platforms other than Web (Android, iOS, Desktop)
class WebNotificationHelper {
  static bool get isSupported => false;
  static String get permissionStatus => 'unsupported';
  static bool get isGranted => false;
  static bool get isDenied => false;

  static Future<String> requestPermission() async {
    return 'unsupported';
  }

  static void showSystemNotification({
    required String title,
    required String body,
    String? icon,
  }) {
    // Handled natively by flutter_local_notifications on Android
  }

  static void playChime() {
    // No-op on mobile
  }
}
