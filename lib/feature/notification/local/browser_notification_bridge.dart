import 'browser_notification_bridge_stub.dart'
    if (dart.library.html) 'browser_notification_bridge_web.dart';

enum BrowserNotificationPermissionStatus {
  granted,
  denied,
  defaultValue,
  unsupported,
}

abstract class BrowserNotificationBridge {
  bool get isSupported;

  Future<BrowserNotificationPermissionStatus> getPermissionStatus();

  Future<BrowserNotificationPermissionStatus> requestPermission();

  void showNotification({
    required String title,
    required String body,
    String? tag,
    Duration? autoCloseAfter,
  });
}

BrowserNotificationBridge createBrowserNotificationBridge() =>
    createBrowserNotificationBridgeImpl();
