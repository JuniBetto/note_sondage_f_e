import 'dart:async';
import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:note_sondage/core/config/runtime_config.dart';
import 'package:note_sondage/core/dependency_injection/dependency_injection.dart';
import 'package:note_sondage/core/network/setup_dio.dart';
import 'package:note_sondage/feature/auth/domain/entities/user_device_entity.dart';
import 'package:note_sondage/feature/notification/navigation/notification_navigation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:note_sondage/feature/auth/infrastructure/data/backend_auth_data_source.dart';
import 'package:note_sondage/feature/notification/inbox/notification_center_cubit.dart';
import 'package:note_sondage/feature/notification/inbox/notification_center_item.dart';
import 'package:note_sondage/feature/notification/local/local_notification_service.dart';
import 'package:note_sondage/feature/notification/preferences/notification_preferences_cubit.dart';
import 'package:note_sondage/feature/notification/push/push_diagnostics_snapshot.dart';
import 'package:note_sondage/feature/notification/realtime/realtime_notification_model.dart';
import 'package:note_sondage/firebase_options.dart';

const String _backgroundTeamInviteCategoryId = 'team_invite_actions';

/// Gestisce i messaggi FCM quando l'app è in background o terminata.
///
/// REGOLE OBBLIGATORIE:
/// - Deve essere una funzione top-level (non un metodo di classe).
/// - Deve avere `@pragma('vm:entry-point')` altrimenti il tree-shaker
///   di Dart la rimuove in release mode e le notifiche background spariscono.
/// - NON può usare `getIt` (il DI non è inizializzato in questo isolate).
/// - Deve inizializzare Firebase e flutter_local_notifications
///   autonomamente prima di usarli.
///
/// QUANDO VIENE CHIAMATO:
/// - Messaggi data-only (nessun blocco `notification` nel payload FCM).
///   I messaggi con blocco `notification` vengono mostrati direttamente
///   dall'OS senza passare per questo handler.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // 1. Firebase deve essere inizializzato anche in questo isolate separato.
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // 2. Legge title/body dal payload data o dal blocco notification (fallback).
  final data = message.data;
  final title = data['title']?.toString().isNotEmpty == true
      ? data['title']!
      : message.notification?.title ?? 'Notifica';
  final body = data['body']?.toString().isNotEmpty == true
      ? data['body']!
      : message.notification?.body ?? '';
  final metadata = {
    for (final entry in data.entries)
      if (entry.value.isNotEmpty &&
          !_reservedKeys.contains(entry.key.toString()))
        entry.key.toString(): entry.value.toString(),
  };
  final notificationItem = NotificationCenterItem(
    notificationId:
        data['notificationId']?.toString() ??
        message.messageId ??
        'push-${DateTime.now().millisecondsSinceEpoch}',
    eventType: data['eventType']?.toString() ?? 'PUSH_NOTIFICATION',
    sourceService: data['sourceService']?.toString() ?? 'push',
    title: title,
    body: body,
    occurredAt:
        DateTime.tryParse(data['occurredAt']?.toString() ?? '') ??
        DateTime.now(),
    metadata: metadata,
  );
  if (notificationItem.eventType.trim().toUpperCase().startsWith('SHIFT_')) {
    debugPrint(
      '[PushBackground] eventType=${notificationItem.eventType} '
      'title="${notificationItem.title}" '
      'body="${notificationItem.body}" '
      'messageId=${message.messageId} '
      'dataKeys=${message.data.keys.toList()}',
    );
  }
  final canRespondToInvite =
      notificationItem.eventType == 'TEAM_MEMBER_INVITED' &&
      notificationItem.invitationId != null &&
      (notificationItem.metadata['invitedUserId']?.trim().isNotEmpty ?? false);
  final payload = jsonEncode(notificationItem.toJson());

  // Nessun testo = niente da mostrare (es. silent sync messages).
  if (title.isEmpty && body.isEmpty) return;

  // 3. Inizializza flutter_local_notifications standalone.
  final plugin = FlutterLocalNotificationsPlugin();
  const androidSettings = AndroidInitializationSettings('ic_stat_notify');
  const darwinSettings = DarwinInitializationSettings();
  await plugin.initialize(
    const InitializationSettings(android: androidSettings, iOS: darwinSettings),
    onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
  );

  // 4. Assicura che il canale Android esista.
  const channel = AndroidNotificationChannel(
    'team_updates',
    'Team updates',
    description: 'Realtime updates about teams and invitations',
    importance: Importance.max,
  );
  await plugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >()
      ?.createNotificationChannel(channel);

  // 5. Mostra la notifica.
  final notificationDetails = NotificationDetails(
    android: AndroidNotificationDetails(
      'team_updates',
      'Team updates',
      channelDescription: 'Realtime updates about teams and invitations',
      importance: Importance.max,
      priority: Priority.high,
      icon: 'ic_stat_notify',
      actions: canRespondToInvite
          ? const <AndroidNotificationAction>[
              AndroidNotificationAction(
                'accept_team_invite',
                'Accetta',
                showsUserInterface: true,
                cancelNotification: true,
              ),
              AndroidNotificationAction(
                'reject_team_invite',
                'Rifiuta',
                showsUserInterface: true,
                cancelNotification: true,
              ),
            ]
          : null,
    ),
    iOS: DarwinNotificationDetails(
      categoryIdentifier: canRespondToInvite
          ? _backgroundTeamInviteCategoryId
          : null,
      threadIdentifier: notificationItem.metadata['teamId'],
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    ),
  );

  await plugin.show(
    notificationItem.notificationId.hashCode,
    title,
    body,
    notificationDetails,
    payload: payload,
  );
  if (notificationItem.eventType.trim().toUpperCase().startsWith('SHIFT_')) {
    debugPrint(
      '[PushBackground] local notification shown for ${notificationItem.eventType}',
    );
  }
}

class PushNotificationService {
  PushNotificationService({
    BackendAuthDataSource? backendAuth,
    LocalNotificationService? localNotifications,
  }) : _backendAuth = backendAuth ?? BackendAuthDataSource(),
       _localNotifications = localNotifications ?? LocalNotificationService();

  static const _deviceFingerprintKey = 'push_device_fingerprint';
  static const _lastRegisteredPushTokenKey = 'last_registered_push_token';
  static const _lastRegisteredPushUserIdKey = 'last_registered_push_user_id';
  static const _lastRegisteredPushAtKey = 'last_registered_push_at';
  static const Duration _pushRegistrationRefreshInterval = Duration(hours: 6);
  static const Duration _apnsTokenWaitStep = Duration(milliseconds: 400);
  static const int _apnsTokenWaitAttempts = 12;
  static const Duration _iosRegistrationRetryDelay = Duration(seconds: 6);
  static const int _maxIosRegistrationRetryAttempts = 8;

  final BackendAuthDataSource _backendAuth;
  final LocalNotificationService _localNotifications;
  final StreamController<RealtimeNotification> _controller =
      StreamController<RealtimeNotification>.broadcast();
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  StreamSubscription<String>? _tokenRefreshSubscription;
  Timer? _iosRegistrationRetryTimer;
  int _iosRegistrationRetryAttempts = 0;
  bool _initialized = false;
  bool _available = true;
  String? _lastRegistrationErrorMessage;

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
      await _messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

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
      final permissionSettings = await _messaging.getNotificationSettings();
      if (!_allowsRemoteNotifications(permissionSettings.authorizationStatus)) {
        debugPrint(
          '[PushNotificationService] device registration skipped because notifications are not authorized.',
        );
        return;
      }

      final apnsReady = await _waitForPlatformPushToken();
      if (defaultTargetPlatform == TargetPlatform.iOS && !apnsReady) {
        debugPrint(
          '[PushNotificationService] APNS token not ready yet; scheduling iOS registration retry.',
        );
        _scheduleIosRegistrationRetry();
        return;
      }

      final token = forceToken ?? await _messaging.getToken();
      if (token == null || token.isEmpty) {
        debugPrint(
          '[PushNotificationService] FCM token unavailable; scheduling iOS registration retry.',
        );
        _scheduleIosRegistrationRetry();
        return;
      }
      if (!await _shouldRegisterToken(firebaseUser.uid, token)) {
        _clearIosRegistrationRetry();
        return;
      }

      final fingerprint = await _getOrCreateDeviceFingerprint();
      await _backendAuth.registerCurrentDevice(
        deviceFingerprint: fingerprint,
        deviceName: defaultTargetPlatform.name,
        platform: defaultTargetPlatform.name,
        clientApp: 'flutter_app',
        pushProvider: 'FIREBASE',
        pushToken: token,
      );
      await _markTokenRegistered(firebaseUser.uid, token);
      _clearIosRegistrationRetry();
      _lastRegistrationErrorMessage = null;
      debugPrint(
        '[PushNotificationService] device registration synced for ${firebaseUser.uid}.',
      );
    } on MissingPluginException catch (error) {
      _available = false;
      _lastRegistrationErrorMessage = error.toString();
      debugPrint(
        '[PushNotificationService] device registration skipped because plugin is unavailable: $error',
      );
    } on PlatformException catch (error) {
      _lastRegistrationErrorMessage = error.message ?? error.code;
      debugPrint(
        '[PushNotificationService] device registration skipped due to platform error: ${error.message ?? error.code}',
      );
    } catch (error) {
      _lastRegistrationErrorMessage = error.toString();
      debugPrint(
        '[PushNotificationService] device registration failed: $error',
      );
    }
  }

  Future<PushDiagnosticsSnapshot> collectDiagnostics() async {
    final prefs = await SharedPreferences.getInstance();
    NotificationSettings? permissionSettings;
    if (_available && _supportsPushPlatform) {
      try {
        permissionSettings = await _messaging.getNotificationSettings();
      } catch (_) {
        permissionSettings = null;
      }
    }
    final authorizationStatus =
        permissionSettings?.authorizationStatus.name ?? 'unsupported';
    final notificationsAuthorized =
        permissionSettings != null &&
        _allowsRemoteNotifications(permissionSettings.authorizationStatus);

    String? apnsToken;
    String? fcmToken;
    if (_available && _supportsPushPlatform) {
      try {
        apnsToken = defaultTargetPlatform == TargetPlatform.iOS
            ? await _messaging.getAPNSToken()
            : null;
      } catch (_) {
        apnsToken = null;
      }
      try {
        fcmToken = await _messaging.getToken();
      } catch (_) {
        fcmToken = null;
      }
    }

    var backendDevices = <UserDeviceEntity>[];
    String? backendFetchError;
    try {
      backendDevices = await _backendAuth.getCurrentDevices();
    } catch (error) {
      backendFetchError = error.toString();
    }

    return PushDiagnosticsSnapshot(
      supportsPushPlatform: _supportsPushPlatform,
      serviceAvailable: _available,
      platformLabel: defaultTargetPlatform.name,
      apiBaseUrl: DioClient.baseUrl,
      hasCustomApiBaseUrl: RuntimeConfig.hasCustomApiBaseUrl,
      authorizationStatus: authorizationStatus,
      notificationsAuthorized: notificationsAuthorized,
      userId: FirebaseAuth.instance.currentUser?.uid,
      apnsToken: apnsToken,
      fcmToken: fcmToken,
      deviceFingerprint: prefs.getString(_deviceFingerprintKey),
      cachedRegisteredUserId: prefs.getString(_lastRegisteredPushUserIdKey),
      cachedRegisteredToken: prefs.getString(_lastRegisteredPushTokenKey),
      cachedRegisteredAt: DateTime.tryParse(
        prefs.getString(_lastRegisteredPushAtKey) ?? '',
      ),
      backendDevices: backendDevices,
      lastRegistrationError: _lastRegistrationErrorMessage,
      backendFetchError: backendFetchError,
    );
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    final notification = _emitNotification(message);
    if (_shouldSuppressForegroundNotification(notification)) {
      return;
    }
    final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (currentUserId.isNotEmpty) {
      await _localNotifications.showRealtimeNotification(
        NotificationCenterItem.fromRealtime(notification),
        currentUserId: currentUserId,
      );
    }
  }

  void _handleMessage(RemoteMessage message) {
    final notification = _emitNotification(message);
    final item = NotificationCenterItem.fromRealtime(notification);
    getIt<NotificationCenterCubit>().consumeNotification(item.notificationId);
    unawaited(NotificationNavigation.open(item));
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
      body: data['body']?.toString() ?? message.notification?.body ?? '',
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
    _controller.add(notification);
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

  Future<bool> _waitForPlatformPushToken() async {
    if (defaultTargetPlatform != TargetPlatform.iOS) {
      return true;
    }

    for (var attempt = 0; attempt < _apnsTokenWaitAttempts; attempt++) {
      final apnsToken = await _messaging.getAPNSToken();
      if (apnsToken != null && apnsToken.isNotEmpty) {
        return true;
      }
      await Future<void>.delayed(_apnsTokenWaitStep);
    }
    debugPrint(
      '[PushNotificationService] APNS token still unavailable after waiting; continuing with current FCM state.',
    );
    return false;
  }

  void _scheduleIosRegistrationRetry() {
    if (defaultTargetPlatform != TargetPlatform.iOS) {
      return;
    }
    final firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser == null || firebaseUser.uid.isEmpty) {
      return;
    }
    if (_iosRegistrationRetryAttempts >= _maxIosRegistrationRetryAttempts) {
      debugPrint(
        '[PushNotificationService] iOS push registration retry limit reached.',
      );
      return;
    }
    if (_iosRegistrationRetryTimer?.isActive ?? false) {
      return;
    }

    _iosRegistrationRetryAttempts += 1;
    _iosRegistrationRetryTimer = Timer(_iosRegistrationRetryDelay, () {
      _iosRegistrationRetryTimer = null;
      if (!_available || !_supportsPushPlatform) {
        return;
      }
      if (FirebaseAuth.instance.currentUser == null) {
        return;
      }
      unawaited(syncDeviceRegistration());
    });
  }

  void _clearIosRegistrationRetry() {
    _iosRegistrationRetryTimer?.cancel();
    _iosRegistrationRetryTimer = null;
    _iosRegistrationRetryAttempts = 0;
  }

  bool _allowsRemoteNotifications(AuthorizationStatus status) {
    return status == AuthorizationStatus.authorized ||
        status == AuthorizationStatus.provisional;
  }

  Future<bool> _shouldRegisterToken(String userId, String token) async {
    final prefs = await SharedPreferences.getInstance();
    final cachedUserId = prefs.getString(_lastRegisteredPushUserIdKey);
    final cachedToken = prefs.getString(_lastRegisteredPushTokenKey);
    final cachedAtRaw = prefs.getString(_lastRegisteredPushAtKey);
    final cachedAt = cachedAtRaw == null
        ? null
        : DateTime.tryParse(cachedAtRaw);
    final isCacheFresh =
        cachedAt != null &&
        DateTime.now().difference(cachedAt) < _pushRegistrationRefreshInterval;

    return cachedUserId != userId || cachedToken != token || !isCacheFresh;
  }

  Future<void> _markTokenRegistered(String userId, String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastRegisteredPushUserIdKey, userId);
    await prefs.setString(_lastRegisteredPushTokenKey, token);
    await prefs.setString(
      _lastRegisteredPushAtKey,
      DateTime.now().toIso8601String(),
    );
  }

  Future<void> dispose() async {
    _clearIosRegistrationRetry();
    await _tokenRefreshSubscription?.cancel();
    await _controller.close();
  }

  bool _shouldSuppressForegroundNotification(
    RealtimeNotification notification,
  ) {
    final eventType = notification.eventType.trim().toUpperCase();
    final isChatNotification =
        eventType.contains('CHAT') ||
        (notification.metadata['conversationId']?.trim().isNotEmpty ?? false);
    if (isChatNotification &&
        !getIt<NotificationPreferencesCubit>()
            .state
            .effectivePreferences
            .chatMessagesEnabled) {
      return true;
    }
    if (!isChatNotification) {
      return false;
    }

    // Foreground chat notifications should update the in-app home/notification
    // surfaces only. System banners are reserved for background/terminated.
    return true;
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
