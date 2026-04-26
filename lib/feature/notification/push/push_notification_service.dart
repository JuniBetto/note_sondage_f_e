import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:note_sondage/feature/auth/infrastructure/data/backend_auth_data_source.dart';
import 'package:note_sondage/feature/notification/inbox/notification_center_item.dart';
import 'package:note_sondage/feature/notification/local/local_notification_service.dart';
import 'package:note_sondage/feature/notification/realtime/realtime_notification_model.dart';

Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {}

class PushNotificationService {
  PushNotificationService({
    BackendAuthDataSource? backendAuth,
    LocalNotificationService? localNotifications,
  }) : _backendAuth = backendAuth ?? BackendAuthDataSource(),
       _localNotifications = localNotifications ?? LocalNotificationService();

  static const _deviceFingerprintKey = 'push_device_fingerprint';

  final BackendAuthDataSource _backendAuth;
  final LocalNotificationService _localNotifications;
  final StreamController<RealtimeNotification> _controller =
      StreamController<RealtimeNotification>.broadcast();
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  StreamSubscription<String>? _tokenRefreshSubscription;
  bool _initialized = false;
  bool _available = true;

  Stream<RealtimeNotification> get stream => _controller.stream;

  Future<void> init() async {
    if (_initialized) {
      _initialized = true;
      return;
    }

    _initialized = true;
    if (!_supportsPushPlatform) {
      _available = false;
      return;
    }

    try {
      await _messaging.requestPermission();

      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
      FirebaseMessaging.onMessageOpenedApp.listen(_handleMessage);

      final initialMessage = await _messaging.getInitialMessage();
      if (initialMessage != null) {
        _handleMessage(initialMessage);
      }

      _tokenRefreshSubscription = _messaging.onTokenRefresh.listen((token) {
        if (token.isEmpty) return;
        unawaited(syncDeviceRegistration(forceToken: token));
      });
    } on MissingPluginException catch (error) {
      _available = false;
      debugPrint(
        '[PushNotificationService] firebase_messaging not available on this build: $error',
      );
    } on PlatformException catch (error) {
      _available = false;
      debugPrint(
        '[PushNotificationService] push init skipped due to platform error: ${error.message ?? error.code}',
      );
    } catch (error) {
      _available = false;
      debugPrint('[PushNotificationService] push init failed: $error');
    }
  }

  Future<void> syncDeviceRegistration({String? forceToken}) async {
    if (!_available || !_supportsPushPlatform) return;

    final firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser == null) return;

    try {
      final token = forceToken ?? await _messaging.getToken();
      if (token == null || token.isEmpty) return;

      final fingerprint = await _getOrCreateDeviceFingerprint();
      await _backendAuth.registerCurrentDevice(
        deviceFingerprint: fingerprint,
        deviceName: defaultTargetPlatform.name,
        platform: defaultTargetPlatform.name,
        clientApp: 'flutter_app',
        pushProvider: 'FIREBASE',
        pushToken: token,
      );
    } on MissingPluginException catch (error) {
      _available = false;
      debugPrint(
        '[PushNotificationService] device registration skipped because plugin is unavailable: $error',
      );
    } on PlatformException catch (error) {
      debugPrint(
        '[PushNotificationService] device registration skipped due to platform error: ${error.message ?? error.code}',
      );
    } catch (error) {
      debugPrint('[PushNotificationService] device registration failed: $error');
    }
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    final notification = _emitNotification(message);
    final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (currentUserId.isNotEmpty) {
      await _localNotifications.showRealtimeNotification(
        NotificationCenterItem.fromRealtime(notification),
        currentUserId: currentUserId,
      );
    }
  }

  void _handleMessage(RemoteMessage message) {
    _emitNotification(message);
  }

  RealtimeNotification _emitNotification(RemoteMessage message) {
    final data = message.data;
    final notification = RealtimeNotification(
      notificationId:
          data['notificationId']?.toString() ??
          message.messageId ??
          'push-${DateTime.now().millisecondsSinceEpoch}',
      eventType: data['eventType']?.toString() ?? 'PUSH_NOTIFICATION',
      sourceService: data['sourceService']?.toString() ?? 'push',
      title:
          data['title']?.toString() ??
          message.notification?.title ??
          'Notification',
      body:
          data['body']?.toString() ??
          message.notification?.body ??
          '',
      occurredAt:
          DateTime.tryParse(data['occurredAt']?.toString() ?? '') ??
          DateTime.now(),
      metadata: {
        for (final entry in data.entries)
          if (entry.value.isNotEmpty &&
              !_reservedKeys.contains(entry.key.toString()))
            entry.key.toString(): entry.value.toString(),
      },
    );
    _controller.add(
      notification,
    );
    return notification;
  }

  Future<String> _getOrCreateDeviceFingerprint() async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getString(_deviceFingerprintKey);
    if (existing != null && existing.isNotEmpty) {
      return existing;
    }

    final fingerprint =
        '${defaultTargetPlatform.name}-${DateTime.now().microsecondsSinceEpoch}';
    await prefs.setString(_deviceFingerprintKey, fingerprint);
    return fingerprint;
  }

  Future<void> dispose() async {
    await _tokenRefreshSubscription?.cancel();
    await _controller.close();
  }

  bool get _supportsPushPlatform =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);
}

const Set<String> _reservedKeys = {
  'notificationId',
  'eventType',
  'sourceService',
  'title',
  'body',
  'occurredAt',
};
