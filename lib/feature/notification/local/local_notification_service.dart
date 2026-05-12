import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

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
const String _shiftReminderChannelId = 'shift_reminders_standard_v1';
const String _shiftReminderChannelName = 'Shift Reminders';
const String _shiftReminderChannelDesc =
    'Standard notifications for shift reminders';
const String _shiftAlarmVibrateChannelId = 'shift_alarms_vibrate_v3';
const String _shiftAlarmVibrateChannelName = 'Shift Alarms Vibrate';
const String _shiftAlarmVibrateChannelDesc = 'Shift alarms with vibration only';
const String _shiftAlarmRingtoneChannelId = 'shift_alarms_ringtone_v3';
const String _shiftAlarmRingtoneChannelName = 'Shift Alarms Ringtone';
const String _shiftAlarmRingtoneChannelDesc = 'Shift alarms with ringtone only';
const String _shiftAlarmRingtoneRawSound = 'shift_alarm_ringtone';
const String _pendingNotificationActionsKey = 'pending_notification_actions';
const String _shiftNotificationsEnabledKey = 'shift_notifications_enabled';
const String _scheduledShiftAlarmIdsKey = 'scheduled_shift_alarm_ids';
const String _shiftAlarmTypeKey = 'shift_alarm_type';
const String _shiftAlarmFeedbackKey = 'shift_alarm_feedback';
const String _shiftAlarmDurationSecondsKey = 'shift_alarm_duration_seconds';
const Duration _immediateShiftAlarmFallbackDelay = Duration(seconds: 5);
const int _defaultShiftAlarmDurationSeconds = 5;
const int _maxShiftAlarmDurationSeconds = 30;
const int _maxShiftAlarmDurationSecondsIos = 29;

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

enum ShiftAlarmFeedback { vibrate, ringtone }

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
  bool get supportsVibrateOnlyShiftAlarmFeedback => !_isIos;
  int get maxShiftAlarmDurationSeconds =>
      _isIos ? _maxShiftAlarmDurationSecondsIos : _maxShiftAlarmDurationSeconds;

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

    const androidSettings = AndroidInitializationSettings('ic_stat_notify');
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

      const shiftReminderChannel = AndroidNotificationChannel(
        _shiftReminderChannelId,
        _shiftReminderChannelName,
        description: _shiftReminderChannelDesc,
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
      );

      await _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(shiftReminderChannel);

      await _ensureShiftAlarmFeedbackChannel(
        feedback: ShiftAlarmFeedback.vibrate,
        durationSeconds: 5,
      );
      await _ensureShiftAlarmFeedbackChannel(
        feedback: ShiftAlarmFeedback.ringtone,
        durationSeconds: 5,
      );

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
      icon: 'ic_stat_notify',
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

  Future<void> showDebugNotificationNow() async {
    if (!_initialized || !_available || !_supportsLocalNotifications) return;

    final androidDetails = AndroidNotificationDetails(
      'team_updates',
      'Team updates',
      channelDescription: 'Realtime updates about teams and invitations',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      icon: 'ic_stat_notify',
    );

    const darwinDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    await _plugin.show(
      'debug_notification_now'.hashCode,
      'Debug notification',
      'If you can read this, local notifications are working.',
      NotificationDetails(android: androidDetails, iOS: darwinDetails),
    );
  }

  Future<void> scheduleDebugShiftAlarm({
    Duration delay = const Duration(seconds: 10),
  }) async {
    if (!_initialized || !_available || !_supportsLocalNotifications) return;

    final now = tz.TZDateTime.now(tz.local);
    final alarmTime = now.add(delay);
    const durationSeconds = 10;
    final channel = _resolveShiftAlarmChannel(
      ShiftAlarmFeedback.ringtone,
      durationSeconds,
    );
    await _ensureShiftAlarmFeedbackChannel(
      feedback: ShiftAlarmFeedback.ringtone,
      durationSeconds: durationSeconds,
    );
    final androidDetails = AndroidNotificationDetails(
      channel.id,
      channel.name,
      channelDescription: channel.description,
      importance: Importance.max,
      priority: Priority.max,
      playSound: true,
      enableVibration: false,
      audioAttributesUsage: AudioAttributesUsage.alarm,
      category: AndroidNotificationCategory.alarm,
      icon: 'ic_stat_notify',
      timeoutAfter: durationSeconds * 1000,
    );
    final darwinDetails = _buildDarwinShiftNotificationDetails(
      alarmType: ShiftAlarmType.alarm,
      feedback: ShiftAlarmFeedback.ringtone,
      durationSeconds: durationSeconds,
    );
    final notifId = _shiftFallbackNotificationId('debug-shift-alarm-manual');
    await _plugin.cancel(notifId);
    await _plugin.zonedSchedule(
      notifId,
      '⏰ Debug shift alarm',
      'This is a local alarm test scheduled in a few seconds.',
      alarmTime,
      NotificationDetails(android: androidDetails, iOS: darwinDetails),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<String> scheduleDebugShiftUsingCurrentMode({
    Duration delay = const Duration(seconds: 10),
  }) async {
    if (!_initialized || !_available || !_supportsLocalNotifications) {
      return 'Local notifications unavailable on this build.';
    }

    final alarmType = await getShiftAlarmType();
    final alarmFeedback = await getShiftAlarmFeedback();
    final durationSeconds = await getShiftAlarmDurationSeconds();
    final permissionStatus = await requestAlarmModePermissions();
    final shiftId = 'debug-shift-current-mode';
    await cancelShiftAlarms(shiftId: shiftId, alarmOffsets: const <int>[0]);
    await scheduleShiftAlarms(
      shiftId: shiftId,
      profileName: 'Debug current shift mode',
      shiftStart: DateTime.now().add(delay),
      alarmOffsets: const <int>[0],
    );
    final pending = await pendingNotificationRequests();
    final summary =
        'mode=${alarmType.name}, feedback=${alarmFeedback.name}, duration=${durationSeconds}s, exactAlarm=${permissionStatus.exactAlarm}, fullScreenIntent=${permissionStatus.fullScreenIntent}, pending=${pending.length}, tz=${tz.local.name}';
    debugPrint('[ShiftAlarmDebug] $summary');
    return summary;
  }

  Future<String> getAlarmModeDebugStatus() async {
    if (!_initialized || !_available || !_supportsLocalNotifications) {
      return 'Local notifications unavailable on this build.';
    }
    final alarmType = await getShiftAlarmType();
    final alarmFeedback = await getShiftAlarmFeedback();
    final durationSeconds = await getShiftAlarmDurationSeconds();
    final permissionStatus = await requestAlarmModePermissions();
    final pending = await pendingNotificationRequests();
    final summary =
        'mode=${alarmType.name}, feedback=${alarmFeedback.name}, duration=${durationSeconds}s, exactAlarm=${permissionStatus.exactAlarm}, fullScreenIntent=${permissionStatus.fullScreenIntent}, pending=${pending.length}, tz=${tz.local.name}';
    debugPrint('[ShiftAlarmDebug] $summary');
    return summary;
  }

  Future<int> scheduleDebugShiftThroughAppFlow() async {
    if (!_initialized || !_available || !_supportsLocalNotifications) return 0;

    final shiftId = 'debug-shift-pipeline';
    await cancelShiftAlarms(shiftId: shiftId, alarmOffsets: const <int>[0]);
    await scheduleShiftAlarms(
      shiftId: shiftId,
      profileName: 'Debug pipeline shift',
      shiftStart: DateTime.now().add(const Duration(seconds: 20)),
      alarmOffsets: const <int>[0],
    );
    final pending = await pendingNotificationRequests();
    return pending.length;
  }

  Future<List<PendingNotificationRequest>> pendingNotificationRequests() async {
    if (!_initialized || !_available || !_supportsLocalNotifications) {
      return const <PendingNotificationRequest>[];
    }
    return _plugin.pendingNotificationRequests();
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
    final alarmFeedback = await getShiftAlarmFeedback();
    final durationSeconds = await getShiftAlarmDurationSeconds();
    final config = _resolveShiftNotificationConfig(
      alarmType: alarmType,
      feedback: alarmFeedback,
      durationSeconds: durationSeconds,
    );
    await _ensureShiftNotificationChannel(
      alarmType: alarmType,
      feedback: alarmFeedback,
      durationSeconds: durationSeconds,
    );

    final title = '⏰ Turno tra $minutesBefore min';
    final body = profileName.isNotEmpty
        ? 'Shift "$profileName" — $shiftDate'
        : 'Il tuo turno inizia tra $minutesBefore minuti';

    final androidDetails = AndroidNotificationDetails(
      config.channel.id,
      config.channel.name,
      channelDescription: config.channel.description,
      importance: Importance.max,
      priority: Priority.max,
      playSound: config.playSound,
      sound: config.sound,
      enableVibration: config.enableVibration,
      vibrationPattern: config.enableVibration
          ? _buildAlarmVibrationPattern(durationSeconds)
          : null,
      audioAttributesUsage: AudioAttributesUsage.alarm,
      category: AndroidNotificationCategory.alarm,
      fullScreenIntent: config.fullScreenIntent,
      timeoutAfter: alarmType == ShiftAlarmType.alarm
          ? durationSeconds * 1000
          : null,
      icon: 'ic_stat_notify',
      // ongoing: true causa soppressione silenziosa su Android 14+ senza foreground service
      ongoing: false,
      autoCancel: true,
      visibility: NotificationVisibility.public,
    );

    final darwinDetails = _buildDarwinShiftNotificationDetails(
      alarmType: alarmType,
      feedback: alarmFeedback,
      durationSeconds: durationSeconds,
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
    if (!await areShiftNotificationsEnabled()) {
      debugPrint(
        '[ShiftAlarm] Skipped $shiftId: shift notifications disabled.',
      );
      return;
    }
    if (alarmOffsets.isEmpty) {
      debugPrint('[ShiftAlarm] Skipped $shiftId: no alarm offsets.');
      return;
    }

    final alarmType = await getShiftAlarmType();
    final alarmFeedback = await getShiftAlarmFeedback();
    final durationSeconds = await getShiftAlarmDurationSeconds();
    final config = _resolveShiftNotificationConfig(
      alarmType: alarmType,
      feedback: alarmFeedback,
      durationSeconds: durationSeconds,
    );
    await _ensureShiftNotificationChannel(
      alarmType: alarmType,
      feedback: alarmFeedback,
      durationSeconds: durationSeconds,
    );

    // Cancella prima i vecchi allarmi per questo turno
    await cancelShiftAlarms(shiftId: shiftId, alarmOffsets: alarmOffsets);

    final now = tz.TZDateTime.now(tz.local);
    debugPrint(
      '[ShiftAlarm] Evaluate $shiftId with shiftStart=$shiftStart, tzNow=$now, tzLocal=${tz.local.name}, offsets=$alarmOffsets',
    );
    var scheduledAtLeastOne = false;

    for (final offsetMinutes in alarmOffsets) {
      // offsetMinutes è negativo (es. -30 = 30 min prima)
      final alarmTime = tz.TZDateTime.from(
        shiftStart.add(Duration(minutes: offsetMinutes)),
        tz.local,
      );

      // Non schedulare se l'orario è già passato
      if (alarmTime.isBefore(now)) {
        debugPrint(
          '[ShiftAlarm] Skip offset $offsetMinutes for $shiftId: $alarmTime already passed.',
        );
        continue;
      }

      final minutesBefore = offsetMinutes.abs();
      final notifId = '${shiftId}_$offsetMinutes'.hashCode;
      final title = '⏰ Turno tra $minutesBefore min';
      final body = profileName.isNotEmpty
          ? 'Shift "$profileName" inizia alle ${_formatTime(shiftStart)}'
          : 'Il tuo turno inizia tra $minutesBefore minuti';

      final androidDetails = AndroidNotificationDetails(
        config.channel.id,
        config.channel.name,
        channelDescription: config.channel.description,
        importance: Importance.max,
        priority: Priority.max,
        playSound: config.playSound,
        sound: config.sound,
        enableVibration: config.enableVibration,
        vibrationPattern: config.enableVibration
            ? _buildAlarmVibrationPattern(durationSeconds)
            : null,
        audioAttributesUsage: AudioAttributesUsage.alarm,
        category: AndroidNotificationCategory.alarm,
        fullScreenIntent: config.fullScreenIntent,
        timeoutAfter: alarmType == ShiftAlarmType.alarm
            ? durationSeconds * 1000
            : null,
        icon: 'ic_stat_notify',
        // ongoing: true causa soppressione silenziosa su Android 14+ senza foreground service
        ongoing: false,
        autoCancel: true,
        visibility: NotificationVisibility.public,
      );

      final darwinDetails = _buildDarwinShiftNotificationDetails(
        alarmType: alarmType,
        feedback: alarmFeedback,
        durationSeconds: durationSeconds,
      );

      try {
        await _plugin.zonedSchedule(
          notifId,
          title,
          body,
          alarmTime,
          NotificationDetails(android: androidDetails, iOS: darwinDetails),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
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
        scheduledAtLeastOne = true;
        debugPrint('[ShiftAlarm] Scheduled alarm $notifId at $alarmTime');
      } catch (e) {
        debugPrint('[ShiftAlarm] Failed to schedule $notifId: $e');
      }
    }

    if (scheduledAtLeastOne) {
      return;
    }

    final shiftStartTz = tz.TZDateTime.from(shiftStart, tz.local);
    if (!shiftStartTz.isAfter(now)) {
      debugPrint(
        '[ShiftAlarm] No schedule for $shiftId: shift start already passed.',
      );
      return;
    }

    final fallbackId = _shiftFallbackNotificationId(shiftId);
    final fallbackTime = now.add(_immediateShiftAlarmFallbackDelay);
    final minutesBefore = shiftStartTz.difference(now).inMinutes.clamp(0, 9999);
    final title = minutesBefore <= 1
        ? '⏰ Turno imminente'
        : '⏰ Turno tra $minutesBefore min';
    final body = profileName.isNotEmpty
        ? 'Shift "$profileName" inizia alle ${_formatTime(shiftStart)}'
        : 'Il tuo turno inizia presto';

    final androidDetails = AndroidNotificationDetails(
      config.channel.id,
      config.channel.name,
      channelDescription: config.channel.description,
      importance: Importance.max,
      priority: Priority.max,
      playSound: config.playSound,
      sound: config.sound,
      enableVibration: config.enableVibration,
      vibrationPattern: config.enableVibration
          ? _buildAlarmVibrationPattern(durationSeconds)
          : null,
      audioAttributesUsage: AudioAttributesUsage.alarm,
      category: AndroidNotificationCategory.alarm,
      fullScreenIntent: config.fullScreenIntent,
      timeoutAfter: alarmType == ShiftAlarmType.alarm
          ? durationSeconds * 1000
          : null,
      icon: 'ic_stat_notify',
      ongoing: false,
      autoCancel: true,
      visibility: NotificationVisibility.public,
    );

    final darwinDetails = _buildDarwinShiftNotificationDetails(
      alarmType: alarmType,
      feedback: alarmFeedback,
      durationSeconds: durationSeconds,
    );

    try {
      await _plugin.zonedSchedule(
        fallbackId,
        title,
        body,
        fallbackTime,
        NotificationDetails(android: androidDetails, iOS: darwinDetails),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: jsonEncode({
          'notificationId': fallbackId.toString(),
          'eventType': 'SHIFT_ALARM',
          'sourceService': 'shift',
          'title': title,
          'body': body,
          'occurredAt': fallbackTime.toIso8601String(),
          'metadata': {
            'assignmentId': shiftId,
            'shiftDate': shiftStart.toIso8601String(),
            'profileName': profileName,
            'fallback': 'true',
          },
        }),
      );
      await _rememberScheduledShiftAlarmId(fallbackId);
      debugPrint(
        '[ShiftAlarm] Scheduled immediate fallback $fallbackId at $fallbackTime',
      );
    } catch (e) {
      debugPrint('[ShiftAlarm] Failed to schedule immediate fallback: $e');
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
    final fallbackId = _shiftFallbackNotificationId(shiftId);
    await _plugin.cancel(fallbackId);
    await _forgetScheduledShiftAlarmId(fallbackId);
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
    if (raw == ShiftAlarmType.notification.name)
      return ShiftAlarmType.notification;
    return ShiftAlarmType.alarm;
  }

  Future<void> setShiftAlarmFeedback(ShiftAlarmFeedback feedback) async {
    final prefs = await SharedPreferences.getInstance();
    final normalized = _normalizedShiftAlarmFeedback(feedback);
    await prefs.setString(_shiftAlarmFeedbackKey, normalized.name);
  }

  Future<ShiftAlarmFeedback> getShiftAlarmFeedback() async {
    if (_isIos) {
      return ShiftAlarmFeedback.ringtone;
    }
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_shiftAlarmFeedbackKey);
    if (raw == ShiftAlarmFeedback.ringtone.name) {
      return ShiftAlarmFeedback.ringtone;
    }
    return ShiftAlarmFeedback.vibrate;
  }

  Future<void> setShiftAlarmDurationSeconds(int seconds) async {
    final prefs = await SharedPreferences.getInstance();
    final normalized = _normalizeShiftAlarmDurationSeconds(seconds);
    await prefs.setInt(_shiftAlarmDurationSecondsKey, normalized);
  }

  Future<int> getShiftAlarmDurationSeconds() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getInt(_shiftAlarmDurationSecondsKey);
    return _normalizeShiftAlarmDurationSeconds(
      raw ?? _defaultShiftAlarmDurationSeconds,
    );
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

    // ── Notification permission (Android 13+) ───────────────────────────────
    // Se l'utente ha negato POST_NOTIFICATIONS, l'allarme viene schedulato ma
    // non mostra nulla. Lo richiediamo di nuovo quando l'utente abilita/salva
    // una sveglia per ridurre i casi "non succede niente".
    try {
      await android.requestNotificationsPermission();
    } catch (_) {
      // API non disponibile su questa versione Android.
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

  int _shiftFallbackNotificationId(String shiftId) =>
      '${shiftId}_fallback'.hashCode;

  Int64List _buildAlarmVibrationPattern(int durationSeconds) {
    final durationMs =
        _normalizeShiftAlarmDurationSeconds(durationSeconds) * 1000;
    final pattern = <int>[0];
    var elapsed = 0;
    while (elapsed < durationMs) {
      final onMs = (durationMs - elapsed) >= 700 ? 700 : durationMs - elapsed;
      pattern.add(onMs);
      elapsed += onMs;
      if (elapsed >= durationMs) {
        break;
      }
      const offMs = 300;
      pattern.add(offMs);
      elapsed += offMs;
    }
    return Int64List.fromList(pattern);
  }

  _ShiftAlarmChannelConfig _resolveShiftAlarmChannel(
    ShiftAlarmFeedback feedback,
    int durationSeconds,
  ) {
    final normalized = _normalizeShiftAlarmDurationSeconds(durationSeconds);
    if (feedback == ShiftAlarmFeedback.ringtone) {
      return _ShiftAlarmChannelConfig(
        id: '${_shiftAlarmRingtoneChannelId}_$normalized',
        name: _shiftAlarmRingtoneChannelName,
        description: '$_shiftAlarmRingtoneChannelDesc ($normalized s)',
      );
    }
    return _ShiftAlarmChannelConfig(
      id: '${_shiftAlarmVibrateChannelId}_$normalized',
      name: _shiftAlarmVibrateChannelName,
      description: '$_shiftAlarmVibrateChannelDesc ($normalized s)',
    );
  }

  _ShiftNotificationConfig _resolveShiftNotificationConfig({
    required ShiftAlarmType alarmType,
    required ShiftAlarmFeedback feedback,
    required int durationSeconds,
  }) {
    final normalizedFeedback = _normalizedShiftAlarmFeedback(feedback);
    if (alarmType == ShiftAlarmType.notification) {
      return const _ShiftNotificationConfig(
        channel: _ShiftAlarmChannelConfig(
          id: _shiftReminderChannelId,
          name: _shiftReminderChannelName,
          description: _shiftReminderChannelDesc,
        ),
        playSound: true,
        sound: null,
        enableVibration: true,
        fullScreenIntent: false,
      );
    }

    final channel = _resolveShiftAlarmChannel(
      normalizedFeedback,
      durationSeconds,
    );
    return _ShiftNotificationConfig(
      channel: channel,
      playSound: normalizedFeedback == ShiftAlarmFeedback.ringtone,
      sound: normalizedFeedback == ShiftAlarmFeedback.ringtone
          ? const RawResourceAndroidNotificationSound(
              _shiftAlarmRingtoneRawSound,
            )
          : null,
      enableVibration: normalizedFeedback == ShiftAlarmFeedback.vibrate,
      fullScreenIntent: false,
    );
  }

  Future<void> _ensureShiftNotificationChannel({
    required ShiftAlarmType alarmType,
    required ShiftAlarmFeedback feedback,
    required int durationSeconds,
  }) async {
    if (alarmType == ShiftAlarmType.notification) {
      return;
    }
    await _ensureShiftAlarmFeedbackChannel(
      feedback: feedback,
      durationSeconds: durationSeconds,
    );
  }

  Future<void> _ensureShiftAlarmFeedbackChannel({
    required ShiftAlarmFeedback feedback,
    required int durationSeconds,
  }) async {
    final normalizedFeedback = _normalizedShiftAlarmFeedback(feedback);
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android == null) {
      return;
    }

    final channel = _resolveShiftAlarmChannel(
      normalizedFeedback,
      durationSeconds,
    );
    final normalized = _normalizeShiftAlarmDurationSeconds(durationSeconds);

    final androidChannel = AndroidNotificationChannel(
      channel.id,
      channel.name,
      description: channel.description,
      importance: Importance.max,
      playSound: normalizedFeedback == ShiftAlarmFeedback.ringtone,
      enableVibration: normalizedFeedback == ShiftAlarmFeedback.vibrate,
      vibrationPattern: normalizedFeedback == ShiftAlarmFeedback.vibrate
          ? _buildAlarmVibrationPattern(normalized)
          : null,
      sound: normalizedFeedback == ShiftAlarmFeedback.ringtone
          ? const RawResourceAndroidNotificationSound(
              _shiftAlarmRingtoneRawSound,
            )
          : null,
      audioAttributesUsage: AudioAttributesUsage.alarm,
    );

    await android.createNotificationChannel(androidChannel);
  }

  bool get _supportsLocalNotifications =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  bool get _isIos => defaultTargetPlatform == TargetPlatform.iOS;

  int _normalizeShiftAlarmDurationSeconds(int seconds) {
    return seconds.clamp(1, maxShiftAlarmDurationSeconds).toInt();
  }

  ShiftAlarmFeedback _normalizedShiftAlarmFeedback(
    ShiftAlarmFeedback feedback,
  ) {
    if (_isIos) {
      return ShiftAlarmFeedback.ringtone;
    }
    return feedback;
  }

  DarwinNotificationDetails _buildDarwinShiftNotificationDetails({
    required ShiftAlarmType alarmType,
    required ShiftAlarmFeedback feedback,
    required int durationSeconds,
  }) {
    final normalizedFeedback = _normalizedShiftAlarmFeedback(feedback);
    final isAlarm = alarmType == ShiftAlarmType.alarm;
    final customSound =
        isAlarm && normalizedFeedback == ShiftAlarmFeedback.ringtone && _isIos
        ? _resolveIosShiftAlarmSoundFilename(durationSeconds)
        : null;

    return DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      sound: customSound,
      interruptionLevel: InterruptionLevel.timeSensitive,
    );
  }

  String _resolveIosShiftAlarmSoundFilename(int durationSeconds) {
    final normalized = _normalizeShiftAlarmDurationSeconds(durationSeconds);
    return 'shift_alarm_ringtone_$normalized.wav';
  }

  void _onNotificationResponse(NotificationResponse response) {
    final intent = _notificationActionIntentFromResponse(response);
    if (intent == null) {
      return;
    }
    _actionController.add(intent);
  }
}

class _ShiftAlarmChannelConfig {
  const _ShiftAlarmChannelConfig({
    required this.id,
    required this.name,
    required this.description,
  });

  final String id;
  final String name;
  final String description;
}

class _ShiftNotificationConfig {
  const _ShiftNotificationConfig({
    required this.channel,
    required this.playSound,
    required this.sound,
    required this.enableVibration,
    required this.fullScreenIntent,
  });

  final _ShiftAlarmChannelConfig channel;
  final bool playSound;
  final AndroidNotificationSound? sound;
  final bool enableVibration;
  final bool fullScreenIntent;
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
