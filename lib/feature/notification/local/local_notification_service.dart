import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:note_sondage/feature/notification/inbox/notification_center_item.dart';
import 'package:note_sondage/feature/notification/local/notification_action_intent.dart';

const String _teamInviteCategoryId = 'team_invite_actions';

@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse notificationResponse) {}

class LocalNotificationService {
  LocalNotificationService();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  final StreamController<NotificationActionIntent> _actionController =
      StreamController<NotificationActionIntent>.broadcast();

  bool _initialized = false;
  bool _available = true;

  Stream<NotificationActionIntent> get actions => _actionController.stream;

  Future<void> init() async {
    if (_initialized) {
      _initialized = true;
      return;
    }

    if (!_supportsLocalNotifications) {
      _initialized = true;
      _available = false;
      return;
    }

    const androidSettings = AndroidInitializationSettings('ic_launcher');
    final darwinSettings = DarwinInitializationSettings(
      notificationCategories: [
        DarwinNotificationCategory(
          _teamInviteCategoryId,
          actions: [
            DarwinNotificationAction.plain(
              'accept_team_invite',
              'Accetta',
              options: {DarwinNotificationActionOption.foreground},
            ),
            DarwinNotificationAction.plain(
              'reject_team_invite',
              'Rifiuta',
              options: {DarwinNotificationActionOption.foreground},
            ),
          ],
        ),
      ],
    );

    try {
      await _plugin.initialize(
        InitializationSettings(
          android: androidSettings,
          iOS: darwinSettings,
        ),
        onDidReceiveNotificationResponse: _onNotificationResponse,
        onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
      );

      const androidChannel = AndroidNotificationChannel(
        'team_updates',
        'Team updates',
        description: 'Realtime updates about teams and invitations',
        importance: Importance.max,
      );

      await _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(androidChannel);

      _initialized = true;
    } on MissingPluginException catch (error) {
      _initialized = true;
      _available = false;
      debugPrint(
        '[LocalNotificationService] flutter_local_notifications not available on this build: $error',
      );
    } on PlatformException catch (error) {
      _initialized = true;
      _available = false;
      debugPrint(
        '[LocalNotificationService] local notifications unavailable: ${error.message ?? error.code}',
      );
    } catch (error) {
      _initialized = true;
      _available = false;
      debugPrint('[LocalNotificationService] init failed: $error');
    }
  }

  Future<void> showRealtimeNotification(
    NotificationCenterItem item, {
    required String currentUserId,
  }) async {
    if (!_initialized || !_available || !_supportsLocalNotifications) return;

    final canRespond = item.supportsInviteDecisionFor(currentUserId);
    final payload = jsonEncode(item.toJson());

    final androidDetails = AndroidNotificationDetails(
      'team_updates',
      'Team updates',
      channelDescription: 'Realtime updates about teams and invitations',
      importance: Importance.max,
      priority: Priority.high,
      actions: canRespond
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
    );

    final darwinDetails = DarwinNotificationDetails(
      categoryIdentifier: canRespond ? _teamInviteCategoryId : null,
      threadIdentifier: item.metadata['teamId'],
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    await _plugin.show(
      item.notificationId.hashCode,
      item.title,
      item.body,
      NotificationDetails(
        android: androidDetails,
        iOS: darwinDetails,
      ),
      payload: payload,
    );
  }

  Future<void> dispose() async {
    await _actionController.close();
  }

  bool get _supportsLocalNotifications =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  void _onNotificationResponse(NotificationResponse response) {
    final payload = response.payload;
    if (payload == null || payload.isEmpty) {
      return;
    }

    try {
      final decoded = jsonDecode(payload) as Map<String, dynamic>;
      final item = NotificationCenterItem.fromJson(decoded);
      _actionController.add(
        NotificationActionIntent(
          notificationId: item.notificationId,
          actionId: response.actionId ?? '',
          metadata: {
            ...item.metadata,
            'eventType': item.eventType,
            'sourceService': item.sourceService,
            'title': item.title,
            'body': item.body,
            'occurredAt': item.occurredAt.toIso8601String(),
          },
        ),
      );
    } catch (error) {
      debugPrint('[LocalNotificationService] Failed to parse payload: $error');
    }
  }
}
