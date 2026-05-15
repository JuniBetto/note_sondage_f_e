import 'dart:async';
import 'dart:html' as html;

import 'browser_notification_bridge.dart';

class _WebBrowserNotificationBridge implements BrowserNotificationBridge {
  @override
  bool get isSupported => html.Notification.supported;

  @override
  Future<BrowserNotificationPermissionStatus> getPermissionStatus() async {
    if (!isSupported) {
      return BrowserNotificationPermissionStatus.unsupported;
    }
    return _mapPermission(html.Notification.permission);
  }

  @override
  Future<BrowserNotificationPermissionStatus> requestPermission() async {
    if (!isSupported) {
      return BrowserNotificationPermissionStatus.unsupported;
    }
    final result = await html.Notification.requestPermission();
    return _mapPermission(result);
  }

  @override
  void showNotification({
    required String title,
    required String body,
    String? tag,
    Duration? autoCloseAfter,
  }) {
    if (!isSupported || html.Notification.permission != 'granted') {
      return;
    }

    final notification = html.Notification(title, body: body, tag: tag);

    final effectiveAutoClose = autoCloseAfter;
    if (effectiveAutoClose != null) {
      Timer(effectiveAutoClose, notification.close);
    }
  }

  BrowserNotificationPermissionStatus _mapPermission(String? permission) {
    switch (permission) {
      case 'granted':
        return BrowserNotificationPermissionStatus.granted;
      case 'denied':
        return BrowserNotificationPermissionStatus.denied;
      default:
        return BrowserNotificationPermissionStatus.defaultValue;
    }
  }
}

BrowserNotificationBridge createBrowserNotificationBridgeImpl() =>
    _WebBrowserNotificationBridge();
