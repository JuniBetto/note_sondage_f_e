import 'browser_notification_bridge.dart';

class _UnsupportedBrowserNotificationBridge
    implements BrowserNotificationBridge {
  @override
  bool get isSupported => false;

  @override
  Future<BrowserNotificationPermissionStatus> getPermissionStatus() async {
    return BrowserNotificationPermissionStatus.unsupported;
  }

  @override
  Future<BrowserNotificationPermissionStatus> requestPermission() async {
    return BrowserNotificationPermissionStatus.unsupported;
  }

  @override
  void showNotification({
    required String title,
    required String body,
    String? tag,
    Duration? autoCloseAfter,
  }) {}
}

BrowserNotificationBridge createBrowserNotificationBridgeImpl() =>
    _UnsupportedBrowserNotificationBridge();
