import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:note_sondage/core/config/runtime_config.dart';
import 'package:note_sondage/core/network/setup_dio.dart';
import 'package:note_sondage/feature/notification/realtime/realtime_notification_model.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';

class RealtimeNotificationService {
  final StreamController<RealtimeNotification> _controller =
      StreamController<RealtimeNotification>.broadcast();

  StompClient? _client;
  String? _connectedUserId;

  Stream<RealtimeNotification> get stream => _controller.stream;

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
    final wsUrl = _resolveWebSocketUrl(apiUri, userId);
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
        reconnectDelay: const Duration(seconds: 5),
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
        },
        onWebSocketDone: () {
          debugPrint(
            '[RealtimeNotificationService] WS closed for user $_connectedUserId',
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

  String _resolveWebSocketUrl(Uri apiUri, String userId) {
    final wsScheme = apiUri.scheme == 'https' ? 'wss' : 'ws';

    if (RuntimeConfig.hasCustomNotificationWsUrl) {
      final directUri = Uri.parse(RuntimeConfig.resolvedNotificationWsUrl);
      return directUri
          .replace(
            scheme: directUri.scheme.isEmpty ? wsScheme : directUri.scheme,
            path: '/ws',
            queryParameters: {'userId': userId},
          )
          .toString();
    }

    if (!RuntimeConfig.hasCustomApiBaseUrl) {
      return apiUri
          .replace(
            scheme: wsScheme,
            port: 8085,
            path: '/ws',
            queryParameters: {'userId': userId},
          )
          .toString();
    }

    final configuredPort = apiUri.hasPort
        ? apiUri.port
        : (apiUri.scheme == 'https' ? 443 : 80);
    final targetPort =
        _isPrivateOrLanHost(apiUri.host) && configuredPort == 8080
        ? 8085
        : configuredPort;

    return apiUri
        .replace(
          scheme: wsScheme,
          port: targetPort,
          path: '/ws',
          queryParameters: {'userId': userId},
        )
        .toString();
  }

  bool _isPrivateOrLanHost(String host) {
    final normalizedHost = host.trim().toLowerCase();
    if (normalizedHost.isEmpty) {
      return false;
    }

    if (normalizedHost == 'localhost' ||
        normalizedHost == '127.0.0.1' ||
        normalizedHost == '::1') {
      return true;
    }

    if (normalizedHost.endsWith('.lan') || normalizedHost.endsWith('.local')) {
      return true;
    }

    if (normalizedHost.startsWith('10.') ||
        normalizedHost.startsWith('192.168.')) {
      return true;
    }

    final octets = normalizedHost.split('.');
    if (octets.length != 4) {
      return false;
    }

    final firstOctet = int.tryParse(octets[0]);
    final secondOctet = int.tryParse(octets[1]);
    if (firstOctet == null || secondOctet == null) {
      return false;
    }

    return firstOctet == 172 && secondOctet >= 16 && secondOctet <= 31;
  }

  void _onConnect(StompFrame frame) {
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
    _client?.deactivate();
    _client = null;
    _connectedUserId = null;
  }

  Future<void> dispose() async {
    disconnect();
    await _controller.close();
  }
}
