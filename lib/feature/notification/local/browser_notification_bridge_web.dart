import 'dart:async';
import 'dart:js_interop';

import 'package:web/web.dart' as web;

import 'browser_notification_bridge.dart';

class _WebBrowserNotificationBridge implements BrowserNotificationBridge {
  @override
  bool get isSupported {
    try {
      web.Notification.permission;
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<BrowserNotificationPermissionStatus> getPermissionStatus() async {
    if (!isSupported) {
      return BrowserNotificationPermissionStatus.unsupported;
    }
    return _mapPermission(web.Notification.permission);
  }

  @override
  Future<BrowserNotificationPermissionStatus> requestPermission() async {
    if (!isSupported) {
      return BrowserNotificationPermissionStatus.unsupported;
    }
    final result = (await web.Notification.requestPermission().toDart).toDart;
    return _mapPermission(result);
  }

  @override
  void showNotification({
    required String title,
    required String body,
    String? tag,
    Duration? autoCloseAfter,
  }) {
    if (!isSupported || web.Notification.permission != 'granted') {
      return;
    }

    final options = tag == null
        ? web.NotificationOptions(body: body)
        : web.NotificationOptions(body: body, tag: tag);
    final notification = web.Notification(title, options);

    final effectiveAutoClose = autoCloseAfter;
    if (effectiveAutoClose != null) {
      Timer(effectiveAutoClose, () => notification.close());
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
