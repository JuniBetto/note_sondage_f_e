import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:note_sondage/feature/notification/inbox/notification_center_item.dart';
import 'package:note_sondage/feature/notification/local/notification_action_intent.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

const String _teamInviteCategoryId = 'team_invite_actions';
const String _shiftAlarmChannelId = 'shift_alarms';
const String _shiftAlarmChannelName = 'Shift Alarms';
const String _shiftAlarmChannelDesc = 'Reminders before your scheduled shifts';
const String _shiftAlarmClockChannelId = 'shift_alarms_clock';
const String _shiftAlarmClockChannelName = 'Sveglie Turno';
const String _shiftAlarmClockChannelDesc =
    'Sveglie con schermo intero per i tuoi turni';
const String _pendingNotificationActionsKey = 'pending_notification_actions';
const String _shiftNotificationsEnabledKey = 'shift_notifications_enabled';
const String _scheduledShiftAlarmIdsKey = 'scheduled_shift_alarm_ids';
const String _shiftAlarmTypeKey = 'shift_alarm_type';

/// Esito della richiesta di permessi per la modalità **Sveglia** su Android.
class AlarmPermissionStatus {
  const AlarmPermissionStatus({
    required this.exactAlarm,
    required this.fullScreenIntent,
  });

  /// Se l'app può schedulare allarmi esatti (`SCHEDULE_EXACT_ALARM`).
  final bool exactAlarm;

  /// Se l'app può mostrare notifiche a schermo intero (`USE_FULL_SCREEN_INTENT`).
  final bool fullScreenIntent;

  /// `true` se entrambi i permessi sono concessi.
  bool get allGranted => exactAlarm && fullScreenIntent;
}

/// Tipo di notifica di allarme turno scelta dall'utente.
enum ShiftAlarmType {
  /// Notifica standard (comportamento di default).
  notification,

  /// Sveglia vera: schermo intero, vibrazione persistente, non si chiude da sola.
  alarm,
}

@pragma('vm:entry-point')
Future<void> notificationTapBackground(
  NotificationResponse notificationResponse,
) async {
  await _persistBackgroundNotificationResponse(notificationResponse);
}

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

    // ── Timezone init ────────────────────────────────────────────────────────
    try {
      tz_data.initializeTimeZones();
      final localTz = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(localTz));
    } catch (_) {
      // fallback: UTC
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
        InitializationSettings(android: androidSettings, iOS: darwinSettings),
        onDidReceiveNotificationResponse: _onNotificationResponse,
        onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
      );

      await _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.requestNotificationsPermission();

      await _plugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >()
          ?.requestPermissions(alert: true, badge: true, sound: true);

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

      const shiftAlarmChannel = AndroidNotificationChannel(
        _shiftAlarmChannelId,
        _shiftAlarmChannelName,
        description: _shiftAlarmChannelDesc,
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
      );

      await _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(shiftAlarmChannel);

      const shiftAlarmClockChannel = AndroidNotificationChannel(
        _shiftAlarmClockChannelId,
        _shiftAlarmClockChannelName,
        description: _shiftAlarmClockChannelDesc,
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
      );

      await _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(shiftAlarmClockChannel);

      final launchDetails = await _plugin.getNotificationAppLaunchDetails();
      if (launchDetails?.didNotificationLaunchApp == true &&
          launchDetails?.notificationResponse != null) {
        await _persistBackgroundNotificationResponse(
          launchDetails!.notificationResponse!,
        );
      }

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
      NotificationDetails(android: androidDetails, iOS: darwinDetails),
      payload: payload,
    );
  }

  Future<void> dispose() async {
    await _actionController.close();
  }

  Future<List<NotificationActionIntent>> drainPendingActionIntents() async {
    final prefs = await SharedPreferences.getInstance();
    final rawItems = prefs.getStringList(_pendingNotificationActionsKey) ?? [];
    if (rawItems.isEmpty) {
      return const [];
    }

    await prefs.remove(_pendingNotificationActionsKey);

    final intents = <NotificationActionIntent>[];
    for (final raw in rawItems) {
      try {
        final decoded = jsonDecode(raw) as Map<String, dynamic>;
        final rawMetadata = decoded['metadata'];
        final metadata = <String, String>{};
        if (rawMetadata is Map) {
          for (final entry in rawMetadata.entries) {
            if (entry.key != null && entry.value != null) {
              metadata[entry.key.toString()] = entry.value.toString();
            }
          }
        }
        intents.add(
          NotificationActionIntent(
            notificationId: decoded['notificationId']?.toString() ?? '',
            actionId: decoded['actionId']?.toString() ?? '',
            metadata: metadata,
          ),
        );
      } catch (error) {
        debugPrint(
          '[LocalNotificationService] Failed to restore queued action: $error',
        );
      }
    }

    return intents;
  }

  // ── Shift Alarm ─────────────────────────────────────────────────────────

  /// Mostra immediatamente una notifica di allarme turno (path realtime/push).
  Future<void> showShiftAlarmNotification({
    required String shiftId,
    required String profileName,
    required String shiftDate,
    required int minutesBefore,
  }) async {
    if (!_initialized || !_available || !_supportsLocalNotifications) return;
    if (!await areShiftNotificationsEnabled()) return;

    final alarmType = await getShiftAlarmType();
    final isAlarm = alarmType == ShiftAlarmType.alarm;

    final title = '⏰ Turno tra $minutesBefore min';
    final body = profileName.isNotEmpty
        ? 'Shift "$profileName" — $shiftDate'
        : 'Il tuo turno inizia tra $minutesBefore minuti';

    final androidDetails = AndroidNotificationDetails(
      isAlarm ? _shiftAlarmClockChannelId : _shiftAlarmChannelId,
      isAlarm ? _shiftAlarmClockChannelName : _shiftAlarmChannelName,
      channelDescription: isAlarm
          ? _shiftAlarmClockChannelDesc
          : _shiftAlarmChannelDesc,
      importance: Importance.max,
      priority: Priority.max,
      playSound: true,
      enableVibration: true,
      category: AndroidNotificationCategory.alarm,
      fullScreenIntent: isAlarm,
      // ongoing: true causa soppressione silenziosa su Android 14+ senza foreground service
      ongoing: false,
      autoCancel: true,
      visibility: NotificationVisibility.public,
    );

    final darwinDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      interruptionLevel: InterruptionLevel.timeSensitive,
    );

    await _plugin.show(
      'shift_alarm_$shiftId'.hashCode,
      title,
      body,
      NotificationDetails(android: androidDetails, iOS: darwinDetails),
    );
  }

  /// Schedula le notifiche locali per un turno in base agli [alarmOffsets].
  /// Cancella eventuali allarmi precedenti per lo stesso [shiftId].
  Future<void> scheduleShiftAlarms({
    required String shiftId,
    required String profileName,
    required DateTime shiftStart,
    required List<int> alarmOffsets,
  }) async {
    if (!_initialized || !_available || !_supportsLocalNotifications) return;
    if (!await areShiftNotificationsEnabled()) return;
    if (alarmOffsets.isEmpty) return;

    final alarmType = await getShiftAlarmType();
    final isAlarm = alarmType == ShiftAlarmType.alarm;

    // Cancella prima i vecchi allarmi per questo turno
    await cancelShiftAlarms(shiftId: shiftId, alarmOffsets: alarmOffsets);

    final now = tz.TZDateTime.now(tz.local);

    for (final offsetMinutes in alarmOffsets) {
      // offsetMinutes è negativo (es. -30 = 30 min prima)
      final alarmTime = tz.TZDateTime.from(
        shiftStart.add(Duration(minutes: offsetMinutes)),
        tz.local,
      );

      // Non schedulare se l'orario è già passato
      if (alarmTime.isBefore(now)) continue;

      final minutesBefore = offsetMinutes.abs();
      final notifId = '${shiftId}_$offsetMinutes'.hashCode;
      final title = '⏰ Turno tra $minutesBefore min';
      final body = profileName.isNotEmpty
          ? 'Shift "$profileName" inizia alle ${_formatTime(shiftStart)}'
          : 'Il tuo turno inizia tra $minutesBefore minuti';

      final androidDetails = AndroidNotificationDetails(
        isAlarm ? _shiftAlarmClockChannelId : _shiftAlarmChannelId,
        isAlarm ? _shiftAlarmClockChannelName : _shiftAlarmChannelName,
        channelDescription: isAlarm
            ? _shiftAlarmClockChannelDesc
            : _shiftAlarmChannelDesc,
        importance: Importance.max,
        priority: Priority.max,
        playSound: true,
        enableVibration: true,
        category: AndroidNotificationCategory.alarm,
        fullScreenIntent: isAlarm,
        // ongoing: true causa soppressione silenziosa su Android 14+ senza foreground service
        ongoing: false,
        autoCancel: true,
        visibility: NotificationVisibility.public,
      );

      final darwinDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        interruptionLevel: InterruptionLevel.timeSensitive,
      );

      try {
        await _plugin.zonedSchedule(
          notifId,
          title,
          body,
          alarmTime,
          NotificationDetails(android: androidDetails, iOS: darwinDetails),
          androidScheduleMode: isAlarm
              ? AndroidScheduleMode.alarmClock
              : AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          payload: jsonEncode({
            'notificationId': notifId.toString(),
            'eventType': 'SHIFT_ALARM',
            'sourceService': 'shift',
            'title': title,
            'body': body,
            'occurredAt': alarmTime.toIso8601String(),
            'metadata': {
              'assignmentId': shiftId,
              'shiftDate': shiftStart.toIso8601String(),
              'profileName': profileName,
            },
          }),
        );
        await _rememberScheduledShiftAlarmId(notifId);
        debugPrint('[ShiftAlarm] Scheduled alarm $notifId at $alarmTime');
      } catch (e) {
        debugPrint('[ShiftAlarm] Failed to schedule $notifId: $e');
      }
    }
  }

  /// Cancella tutti gli allarmi schedulati per un turno.
  Future<void> cancelShiftAlarms({
    required String shiftId,
    required List<int> alarmOffsets,
  }) async {
    if (!_initialized || !_available || !_supportsLocalNotifications) return;
    for (final offset in alarmOffsets) {
      final notifId = '${shiftId}_$offset'.hashCode;
      await _plugin.cancel(notifId);
      await _forgetScheduledShiftAlarmId(notifId);
    }
  }

  Future<void> setShiftNotificationsEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_shiftNotificationsEnabledKey, enabled);
    if (!enabled) {
      final scheduledIds =
          prefs
              .getStringList(_scheduledShiftAlarmIdsKey)
              ?.map(int.tryParse)
              .whereType<int>()
              .toList() ??
          const <int>[];
      for (final notifId in scheduledIds) {
        await _plugin.cancel(notifId);
      }
      await prefs.remove(_scheduledShiftAlarmIdsKey);
    }
  }

  Future<bool> areShiftNotificationsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_shiftNotificationsEnabledKey) ?? true;
  }

  Future<void> setShiftAlarmType(ShiftAlarmType type) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_shiftAlarmTypeKey, type.name);
  }

  Future<ShiftAlarmType> getShiftAlarmType() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_shiftAlarmTypeKey);
    // Default: alarm (sveglia), non semplice notifica
    if (raw == ShiftAlarmType.notification.name) return ShiftAlarmType.notification;
    return ShiftAlarmType.alarm;
  }

  /// Richiede i permessi necessari per la modalità **Sveglia** su Android.
  ///
  /// Restituisce un [AlarmPermissionStatus] con l'esito dei singoli check:
  /// - [exactAlarm]: se l'app può schedulare allarmi esatti
  ///   (`SCHEDULE_EXACT_ALARM` / `USE_EXACT_ALARM`).
  ///   Per `alarmClock` non è strettamente richiesto, ma consigliato per
  ///   la modalità notifica con `exactAllowWhileIdle`.
  /// - [fullScreenIntent]: se l'app può aprire lo schermo intero (Android 14+).
  ///   Senza questo permesso `fullScreenIntent: true` viene ignorato silenziosamente.
  ///
  /// Entrambi i metodi aprono la pagina Impostazioni di sistema corretta se
  /// il permesso non è ancora concesso.
  Future<AlarmPermissionStatus> requestAlarmModePermissions() async {
    if (!_initialized || !_available || !_supportsLocalNotifications) {
      return const AlarmPermissionStatus(
        exactAlarm: true,
        fullScreenIntent: true,
      );
    }

    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    if (android == null) {
      return const AlarmPermissionStatus(
        exactAlarm: true,
        fullScreenIntent: true,
      );
    }

    // ── Exact alarm (Android 12+ / API 31+) ──────────────────────────────────
    // setAlarmClock() non richiede questo permesso, ma requestExactAlarmsPermission
    // non causa errori su versioni precedenti e prepara l'app per la modalità
    // exactAllowWhileIdle usata per le notifiche normali.
    bool exactAlarmGranted = true;
    try {
      final granted = await android.requestExactAlarmsPermission();
      exactAlarmGranted = granted ?? true;
    } catch (_) {
      // API non disponibile su questa versione Android → consideriamo OK
    }

    // ── Full screen intent (Android 14+ / API 34+) ───────────────────────────
    // Senza questo permesso la notifica sveglia non mostra lo schermo intero.
    // requestFullScreenIntentPermission() è no-op su Android < 14 e restituisce
    // true se il permesso è già concesso o non richiesto.
    bool fullScreenGranted = true;
    try {
      final granted = await android.requestFullScreenIntentPermission();
      fullScreenGranted = granted ?? true;
    } catch (_) {
      // API non disponibile su versioni precedenti Android 14 → consideriamo OK
    }

    return AlarmPermissionStatus(
      exactAlarm: exactAlarmGranted,
      fullScreenIntent: fullScreenGranted,
    );
  }

  Future<void> _rememberScheduledShiftAlarmId(int notifId) async {
    final prefs = await SharedPreferences.getInstance();
    final ids = List<String>.from(
      prefs.getStringList(_scheduledShiftAlarmIdsKey) ?? const <String>[],
    );
    final raw = notifId.toString();
    if (!ids.contains(raw)) {
      ids.add(raw);
      await prefs.setStringList(_scheduledShiftAlarmIdsKey, ids);
    }
  }

  Future<void> _forgetScheduledShiftAlarmId(int notifId) async {
    final prefs = await SharedPreferences.getInstance();
    final ids = List<String>.from(
      prefs.getStringList(_scheduledShiftAlarmIdsKey) ?? const <String>[],
    );
    ids.remove(notifId.toString());
    await prefs.setStringList(_scheduledShiftAlarmIdsKey, ids);
  }

  String _formatTime(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

  bool get _supportsLocalNotifications =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  void _onNotificationResponse(NotificationResponse response) {
    final intent = _notificationActionIntentFromResponse(response);
    if (intent == null) {
      return;
    }
    _actionController.add(intent);
  }
}

NotificationActionIntent? _notificationActionIntentFromResponse(
  NotificationResponse response,
) {
  final payload = response.payload;
  if (payload == null || payload.isEmpty) {
    return null;
  }

  try {
    final decoded = jsonDecode(payload) as Map<String, dynamic>;
    final item = NotificationCenterItem.fromJson(decoded);
    return NotificationActionIntent(
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
    );
  } catch (error) {
    debugPrint('[LocalNotificationService] Failed to parse payload: $error');
    return null;
  }
}

Future<void> _persistBackgroundNotificationResponse(
  NotificationResponse response,
) async {
  final intent = _notificationActionIntentFromResponse(response);
  if (intent == null) {
    return;
  }

  final prefs = await SharedPreferences.getInstance();
  final rawItems = List<String>.from(
    prefs.getStringList(_pendingNotificationActionsKey) ?? const <String>[],
  );
  final encoded = jsonEncode({
    'notificationId': intent.notificationId,
    'actionId': intent.actionId,
    'metadata': intent.metadata,
  });

  if (rawItems.contains(encoded)) {
    return;
  }

  rawItems.add(encoded);
  if (rawItems.length > 30) {
    rawItems.removeRange(0, rawItems.length - 30);
  }
  await prefs.setStringList(_pendingNotificationActionsKey, rawItems);
}
