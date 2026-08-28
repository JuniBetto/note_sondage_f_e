import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:note_sondage/core/config/runtime_config.dart';
import 'package:note_sondage/core/network/setup_dio.dart';
import 'package:note_sondage/feature/notification/realtime/realtime_notification_model.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';

class RealtimeNotificationService {
  static const List<Duration> _webReconnectDelays = <Duration>[
    Duration(seconds: 5),
    Duration(seconds: 10),
    Duration(seconds: 20),
    Duration(seconds: 30),
    Duration(seconds: 60),
  ];

  final StreamController<RealtimeNotification> _controller =
      StreamController<RealtimeNotification>.broadcast();

  StompClient? _client;
  Timer? _webReconnectTimer;
  String? _connectedUserId;
  List<String> _candidateWsUrls = const <String>[];
  int _currentWsUrlIndex = 0;
  int _webReconnectAttempts = 0;
  bool _connectedForCurrentSession = false;
  bool _switchingWsUrl = false;

  Stream<RealtimeNotification> get stream => _controller.stream;

  /// Feeds a locally-constructed notification into the same stream used for
  /// server-pushed events, so the current device reacts to its own action
  /// exactly like the real recipient would (the backend only pushes
  /// decision notifications to the requester, never back to the actor who
  /// approved/rejected). Callers must mark `metadata['realtimeOnly']` as
  /// `'true'` so it isn't persisted into the notification inbox.
  void emitLocal(RealtimeNotification notification) {
    _controller.add(notification);
  }

  bool get isConnected => _client?.connected ?? false;

  void connect(String userId) {
    if (userId.isEmpty) return;
    if (_connectedUserId == userId && isConnected) return;

    disconnect();
    _connectedUserId = userId;

    final apiUri = Uri.parse(DioClient.baseUrl);
    if (!kIsWeb && Platform.isIOS && apiUri.host == '10.0.2.2') {
      debugPrint(
        '[RealtimeNotificationService] API_BASE_URL is using 10.0.2.2 on iOS. '
        'This host works for the Android emulator, not for iOS.',
      );
    }
    _candidateWsUrls = _resolveWebSocketUrls(apiUri, userId);
    _currentWsUrlIndex = 0;
    _connectedForCurrentSession = false;
    _clearWebReconnectSchedule(resetAttempts: true);

    debugPrint(
      '[RealtimeNotificationService] Candidate websocket URLs: '
      '${_candidateWsUrls.join(' | ')}',
    );

    _activateCurrentClient(userId);
  }

  void _activateCurrentClient(String userId) {
    if (_candidateWsUrls.isEmpty ||
        _currentWsUrlIndex >= _candidateWsUrls.length) {
      debugPrint(
        '[RealtimeNotificationService] No websocket URL candidates available',
      );
      return;
    }

    final wsUrl = _candidateWsUrls[_currentWsUrlIndex];
    final webSocketHeaders = kIsWeb ? null : {'X-User-Id': userId};

    debugPrint('[RealtimeNotificationService] Connecting to $wsUrl');

    _client = StompClient(
      config: StompConfig(
        url: wsUrl,
        // HTTP headers used during WebSocket handshake (mobile/desktop).
        // note_sondage_notification requires X-User-Id to authenticate /ws.
        webSocketConnectHeaders: webSocketHeaders,
        // Keep STOMP CONNECT headers aligned with the same identity.
        stompConnectHeaders: {'X-User-Id': userId},
        reconnectDelay: kIsWeb ? Duration.zero : const Duration(seconds: 5),
        connectionTimeout: const Duration(seconds: 15),
        heartbeatOutgoing: const Duration(seconds: 10),
        heartbeatIncoming: const Duration(seconds: 10),
        onConnect: _onConnect,
        onDisconnect: (_) {
          _controller.add(
            RealtimeNotification(
              notificationId: 'system-disconnected',
              eventType: 'SYSTEM_DISCONNECTED',
              sourceService: 'client',
              title: 'Realtime disconnected',
              body: 'Realtime websocket disconnected',
              occurredAt: DateTime.now(),
              metadata: const {},
            ),
          );
        },
        onStompError: (frame) {
          debugPrint(
            '[RealtimeNotificationService] STOMP error: ${frame.body}',
          );
        },
        onWebSocketError: (error) {
          debugPrint(
            '[RealtimeNotificationService] WS error on $wsUrl: $error',
          );
          _handleConnectionFailure(userId, failedUrl: wsUrl, reason: '$error');
        },
        onWebSocketDone: () {
          debugPrint(
            '[RealtimeNotificationService] WS closed for user $_connectedUserId',
          );
          _handleConnectionFailure(
            userId,
            failedUrl: wsUrl,
            reason: 'socket closed',
          );
        },
      ),
    );

    try {
      _client?.activate();
    } catch (error) {
      debugPrint(
        '[RealtimeNotificationService] Failed to activate WS on $wsUrl: $error',
      );
    }
  }

  void _handleConnectionFailure(
    String userId, {
    required String failedUrl,
    required String reason,
  }) {
    if (_connectedUserId != userId) {
      return;
    }

    if (!_connectedForCurrentSession &&
        _tryFallbackUrl(userId, failedUrl: failedUrl, reason: reason)) {
      return;
    }

    _scheduleWebReconnect(userId, reason: reason);
  }

  bool _tryFallbackUrl(
    String userId, {
    required String failedUrl,
    required String reason,
  }) {
    if (_connectedForCurrentSession || _switchingWsUrl) {
      return false;
    }
    if (_candidateWsUrls.isEmpty ||
        _currentWsUrlIndex >= _candidateWsUrls.length ||
        _candidateWsUrls[_currentWsUrlIndex] != failedUrl) {
      return false;
    }
    if (_currentWsUrlIndex >= _candidateWsUrls.length - 1) {
      return false;
    }

    _switchingWsUrl = true;
    _currentWsUrlIndex += 1;
    final nextUrl = _candidateWsUrls[_currentWsUrlIndex];
    debugPrint(
      '[RealtimeNotificationService] Falling back to $nextUrl after $reason',
    );
    _client?.deactivate();
    _client = null;
    Future<void>.microtask(() {
      _switchingWsUrl = false;
      if (_connectedUserId == userId) {
        _activateCurrentClient(userId);
      }
    });
    return true;
  }

  void _scheduleWebReconnect(String userId, {required String reason}) {
    if (!kIsWeb || _connectedUserId != userId) {
      return;
    }
    if (_webReconnectTimer?.isActive ?? false) {
      return;
    }
    if (_webReconnectAttempts >= _webReconnectDelays.length) {
      debugPrint(
        '[RealtimeNotificationService] Web reconnect paused after '
        '$_webReconnectAttempts failed attempts. '
        'A new app lifecycle/auth reconnect will retry.',
      );
      return;
    }

    final delay = _webReconnectDelays[_webReconnectAttempts];
    _webReconnectAttempts += 1;
    debugPrint(
      '[RealtimeNotificationService] Scheduling web reconnect attempt '
      '$_webReconnectAttempts/${_webReconnectDelays.length} in '
      '${delay.inSeconds}s after $reason',
    );

    _webReconnectTimer = Timer(delay, () {
      _webReconnectTimer = null;
      if (_connectedUserId != userId || isConnected) {
        return;
      }

      // Before the first successful connection, retry the full candidate list
      // from the preferred URL instead of hammering only the last fallback.
      if (!_connectedForCurrentSession) {
        _currentWsUrlIndex = 0;
      }
      _activateCurrentClient(userId);
    });
  }

  void _clearWebReconnectSchedule({bool resetAttempts = false}) {
    _webReconnectTimer?.cancel();
    _webReconnectTimer = null;
    if (resetAttempts) {
      _webReconnectAttempts = 0;
    }
  }

  List<String> _resolveWebSocketUrls(Uri apiUri, String userId) {
    final wsScheme = apiUri.scheme == 'https' ? 'wss' : 'ws';

    if (RuntimeConfig.hasCustomNotificationWsUrl) {
      final directUri = Uri.parse(RuntimeConfig.resolvedNotificationWsUrl);
      return <String>[
        directUri
            .replace(
              scheme: directUri.scheme.isEmpty ? wsScheme : directUri.scheme,
              path: '/ws',
              queryParameters: {'userId': userId},
            )
            .toString(),
      ];
    }

    if (!RuntimeConfig.hasCustomApiBaseUrl) {
      return <String>[
        apiUri
            .replace(
              scheme: wsScheme,
              port: 8085,
              path: '/ws',
              queryParameters: {'userId': userId},
            )
            .toString(),
      ];
    }

    final configuredPort = apiUri.hasPort
        ? apiUri.port
        : (apiUri.scheme == 'https' ? 443 : 80);

    final sameOriginUrl = apiUri
        .replace(
          scheme: wsScheme,
          port: configuredPort,
          path: '/ws',
          queryParameters: {'userId': userId},
        )
        .toString();
    final directNotificationUrl = apiUri
        .replace(
          scheme: wsScheme,
          port: 8085,
          path: '/ws',
          queryParameters: {'userId': userId},
        )
        .toString();

    final urls = <String>[];
    final preferDirect =
        _shouldUseDirectNotificationPort(apiUri.host) && configuredPort != 8085;

    if (preferDirect) {
      urls.add(directNotificationUrl);
      if (sameOriginUrl != directNotificationUrl) {
        urls.add(sameOriginUrl);
      }
    } else {
      urls.add(sameOriginUrl);
      if (directNotificationUrl != sameOriginUrl) {
        urls.add(directNotificationUrl);
      }
    }

    return urls;
  }

  bool _shouldUseDirectNotificationPort(String host) {
    final normalizedHost = host.trim().toLowerCase();
    if (normalizedHost.isEmpty) {
      return false;
    }

    return normalizedHost == 'localhost' ||
        normalizedHost == '127.0.0.1' ||
        normalizedHost == '::1' ||
        normalizedHost == '10.0.2.2';
  }

  void _onConnect(StompFrame frame) {
    _connectedForCurrentSession = true;
    _clearWebReconnectSchedule(resetAttempts: true);
    debugPrint(
      '[RealtimeNotificationService] Connected for user $_connectedUserId',
    );
    _controller.add(
      RealtimeNotification(
        notificationId: 'system-connected',
        eventType: 'SYSTEM_CONNECTED',
        sourceService: 'client',
        title: 'Realtime connected',
        body: 'Realtime websocket connected',
        occurredAt: DateTime.now(),
        metadata: const {},
      ),
    );

    _client?.subscribe(
      destination: '/user/queue/notifications',
      callback: (message) {
        final body = message.body;
        if (body == null || body.isEmpty) return;
        try {
          final decoded = jsonDecode(body) as Map<String, dynamic>;
          _controller.add(RealtimeNotification.fromJson(decoded));
        } catch (e) {
          debugPrint('[RealtimeNotificationService] parse error: $e');
        }
      },
    );
  }

  void disconnect() {
    _clearWebReconnectSchedule(resetAttempts: true);
    _client?.deactivate();
    _client = null;
    _connectedUserId = null;
    _candidateWsUrls = const <String>[];
    _currentWsUrlIndex = 0;
    _connectedForCurrentSession = false;
    _switchingWsUrl = false;
  }

  Future<void> dispose() async {
    disconnect();
    await _controller.close();
  }
}
