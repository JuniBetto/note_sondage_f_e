import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:note_sondage/core/dependency_injection/dependency_injection.dart';
import 'package:note_sondage/feature/notification/local/local_notification_service.dart';
import 'package:note_sondage/feature/notification/preferences/notification_preferences_cubit.dart';
import 'package:note_sondage/feature/notification/preferences/notification_preferences_entity.dart';
import 'package:note_sondage/feature/notification/push/push_diagnostics_snapshot.dart';
import 'package:note_sondage/feature/notification/push/push_notification_service.dart';
import 'package:note_sondage/feature/notification/push/widgets/push_diagnostics_panel.dart';
import 'package:note_sondage/feature/shift/domain/entities/shift_assignment_entity.dart';
import 'package:note_sondage/feature/shift/ui/bloc/shift_bloc.dart';
import 'package:note_sondage/languages/l10n/app_localizations.dart';
import 'package:note_sondage/theme/extensions/color_scheme/color_scheme.dart';
import 'package:note_sondage/ui/widgets/app_snackbar.dart';

class NotificationSettingsMobile extends StatefulWidget {
  const NotificationSettingsMobile({super.key});

  @override
  State<NotificationSettingsMobile> createState() =>
      _NotificationSettingsMobileState();
}

class _NotificationSettingsMobileState
    extends State<NotificationSettingsMobile> {
  ShiftAlarmFeedback _shiftAlarmFeedback =
      defaultTargetPlatform == TargetPlatform.iOS
      ? ShiftAlarmFeedback.ringtone
      : ShiftAlarmFeedback.vibrate;
  int _shiftAlarmDurationSeconds = 5;
  PushDiagnosticsSnapshot? _pushDiagnostics;
  bool _isLoadingPushDiagnostics = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<NotificationPreferencesCubit>().loadPreferences();
      _loadShiftAlarmFeedback();
      _loadShiftAlarmDuration();
      _loadPushDiagnostics();
    });
  }

  Future<void> _loadShiftAlarmFeedback() async {
    final feedback = await getIt<LocalNotificationService>()
        .getShiftAlarmFeedback();
    if (!mounted) return;
    setState(() {
      _shiftAlarmFeedback = feedback;
    });
  }

  Future<void> _loadShiftAlarmDuration() async {
    final duration = await getIt<LocalNotificationService>()
        .getShiftAlarmDurationSeconds();
    if (!mounted) return;
    setState(() {
      _shiftAlarmDurationSeconds = duration;
    });
  }

  Future<void> _loadPushDiagnostics({bool syncFirst = false}) async {
    setState(() {
      _isLoadingPushDiagnostics = true;
    });

    try {
      final pushService = getIt<PushNotificationService>();
      if (syncFirst) {
        await pushService.syncDeviceRegistration();
      }
      final snapshot = await pushService.collectDiagnostics();
      if (!mounted) return;
      setState(() {
        _pushDiagnostics = snapshot;
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoadingPushDiagnostics = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final localNotificationService = getIt<LocalNotificationService>();
    final supportsVibrateOnlyShiftAlarmFeedback =
        localNotificationService.supportsVibrateOnlyShiftAlarmFeedback;
    final maxShiftAlarmDurationSeconds =
        localNotificationService.maxShiftAlarmDurationSeconds;
    final localization = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;

    return BlocBuilder<
      NotificationPreferencesCubit,
      NotificationPreferencesState
    >(
      builder: (context, state) {
        final preferences = state.effectivePreferences;

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ──
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF9800).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.notifications_rounded,
                      color: Color(0xFFFF9800),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          localization.settingsNotification,
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          localization.notificationsSettingsIntro,
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.descriptionColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // ── General Section ──
              _buildSectionTitle(context, localization.notificationsGeneral),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: colorScheme.homeSecondary,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: colorScheme.borderColor!.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  children: [
                    _buildSwitchTile(
                      context,
                      icon: Icons.email_rounded,
                      iconColor: const Color(0xFF2196F3),
                      title: localization.emailNotifications,
                      subtitle: localization.receiveUpdatesByEmail,
                      value: preferences.emailEnabled,
                      onChanged: (v) => _updatePreferences(
                        context,
                        preferences.copyWith(emailEnabled: v),
                      ),
                      showDivider: true,
                    ),
                    _buildSwitchTile(
                      context,
                      icon: Icons.phone_iphone_rounded,
                      iconColor: const Color(0xFF4CAF50),
                      title: localization.pushNotifications,
                      subtitle:
                          localization.receivePushNotificationsOnYourDevice,
                      value: preferences.pushEnabled,
                      onChanged: (v) => _updatePreferences(
                        context,
                        preferences.copyWith(pushEnabled: v),
                      ),
                      showDivider: false,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              _buildSectionTitle(context, 'Device push status'),
              const SizedBox(height: 8),
              PushDiagnosticsPanel(
                snapshot: _pushDiagnostics,
                isLoading: _isLoadingPushDiagnostics,
                onRefresh: _loadPushDiagnostics,
                onSyncNow: () => _loadPushDiagnostics(syncFirst: true),
              ),

              const SizedBox(height: 20),

              _buildSectionTitle(context, localization.shiftReminders),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: colorScheme.homeSecondary,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: colorScheme.borderColor!.withValues(alpha: 0.3),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        localization.reminderMode,
                        style: textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        localization.notificationReminderModeDescription,
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.descriptionColor,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildInfoNote(
                        context,
                        icon: Icons.info_outline_rounded,
                        title: localization.howItWorks,
                        message: localization.notificationAndAlarmDifference,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        localization.alarmStyle,
                        style: textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        supportsVibrateOnlyShiftAlarmFeedback
                            ? localization.alarmStyleDescription
                            : localization.alarmStyleDescriptionIos,
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.descriptionColor,
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (supportsVibrateOnlyShiftAlarmFeedback)
                        SegmentedButton<ShiftAlarmFeedback>(
                          segments: [
                            ButtonSegment(
                              value: ShiftAlarmFeedback.vibrate,
                              icon: const Icon(Icons.vibration, size: 16),
                              label: Text(localization.vibrate),
                            ),
                            ButtonSegment(
                              value: ShiftAlarmFeedback.ringtone,
                              icon: const Icon(Icons.music_note, size: 16),
                              label: Text(localization.ringtone),
                            ),
                          ],
                          selected: {_shiftAlarmFeedback},
                          onSelectionChanged: (selection) async {
                            final feedback = selection.first;
                            await getIt<LocalNotificationService>()
                                .setShiftAlarmFeedback(feedback);
                            if (!mounted) return;
                            setState(() {
                              _shiftAlarmFeedback = feedback;
                            });
                          },
                        )
                      else
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: colorScheme.primary.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: colorScheme.primary.withValues(
                                alpha: 0.18,
                              ),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.music_note_rounded,
                                size: 18,
                                color: colorScheme.primary,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                localization.ringtone,
                                style: textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 16),
                      Text(
                        '${localization.alarmDuration}: ${_shiftAlarmDurationSeconds}s',
                        style: textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        localization.alarmDurationAppliesOnlyToAlarmMode,
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.descriptionColor,
                        ),
                      ),
                      Slider(
                        min: 1,
                        max: maxShiftAlarmDurationSeconds.toDouble(),
                        divisions: maxShiftAlarmDurationSeconds - 1,
                        value: _shiftAlarmDurationSeconds.toDouble(),
                        label: '${_shiftAlarmDurationSeconds}s',
                        onChanged: (value) async {
                          final seconds = value.round();
                          await getIt<LocalNotificationService>()
                              .setShiftAlarmDurationSeconds(seconds);
                          if (!mounted) return;
                          setState(() {
                            _shiftAlarmDurationSeconds = seconds;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // ── Activity Section ──
              _buildSectionTitle(context, localization.activity),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: colorScheme.homeSecondary,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: colorScheme.borderColor!.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  children: [
                    _buildSwitchTile(
                      context,
                      icon: Icons.assignment_rounded,
                      iconColor: const Color(0xFF9C27B0),
                      title: localization.surveyReminders,
                      subtitle: localization.getRemindedAboutPendingSurveys,
                      value: preferences.surveyRemindersEnabled,
                      onChanged: (v) => _updatePreferences(
                        context,
                        preferences.copyWith(surveyRemindersEnabled: v),
                      ),
                      showDivider: true,
                    ),
                    _buildSwitchTile(
                      context,
                      icon: Icons.groups_rounded,
                      iconColor: const Color(0xFF00BCD4),
                      title: localization.teamUpdates,
                      subtitle: localization.notificationsAboutTeamChanges,
                      value: preferences.teamUpdatesEnabled,
                      onChanged: (v) => _updatePreferences(
                        context,
                        preferences.copyWith(teamUpdatesEnabled: v),
                      ),
                      showDivider: true,
                    ),
                    _buildSwitchTile(
                      context,
                      icon: Icons.access_time_rounded,
                      iconColor: const Color(0xFFE91E63),
                      title: localization.clockingAlerts,
                      subtitle: localization.remindersToClockInAndOut,
                      value: preferences.clockingAlertsEnabled,
                      onChanged: (v) => _updatePreferences(
                        context,
                        preferences.copyWith(clockingAlertsEnabled: v),
                      ),
                      showDivider: true,
                    ),
                    _buildSwitchTile(
                      context,
                      icon: Icons.event_available_rounded,
                      iconColor: const Color(0xFF5C6BC0),
                      title: localization.shiftNotifications,
                      subtitle:
                          localization.assignmentsUpdatesAndShiftReminders,
                      value: preferences.shiftAlertsEnabled,
                      onChanged: (v) => _updatePreferences(
                        context,
                        preferences.copyWith(shiftAlertsEnabled: v),
                      ),
                      showDivider: true,
                    ),
                    _buildSwitchTile(
                      context,
                      icon: Icons.chat_bubble_rounded,
                      iconColor: const Color(0xFF2E7D32),
                      title: 'Chat notifications',
                      subtitle:
                          'Messages, direct chats, and unread chat alerts.',
                      value: preferences.chatMessagesEnabled,
                      onChanged: (v) => _updatePreferences(
                        context,
                        preferences.copyWith(chatMessagesEnabled: v),
                      ),
                      showDivider: false,
                    ),
                  ],
                ),
              ),

              if (kDebugMode) ...[
                const SizedBox(height: 20),
                _buildSectionTitle(context, localization.debugTools),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: colorScheme.homeSecondary,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: colorScheme.borderColor!.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          localization.debugToolsDeviceMessage,
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.descriptionColor,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            OutlinedButton(
                              onPressed: () =>
                                  _runDebugNotificationNow(context),
                              child: Text(localization.testNotificationNow),
                            ),
                            OutlinedButton(
                              onPressed: () => _runDebugShiftAlarm(context),
                              child: Text(localization.testAlarmIn10Seconds),
                            ),
                            OutlinedButton(
                              onPressed: () =>
                                  _runDebugCurrentShiftMode(context),
                              child: Text(localization.testCurrentMode),
                            ),
                            OutlinedButton(
                              onPressed: () => _showAlarmModeStatus(context),
                              child: Text(localization.alarmModeStatus),
                            ),
                            OutlinedButton(
                              onPressed: () => _runDebugShiftPipeline(context),
                              child: const Text('Test shift path 20s'),
                            ),
                            OutlinedButton(
                              onPressed: () => _showPendingRequests(context),
                              child: Text(localization.pendingRequests),
                            ),
                            OutlinedButton(
                              onPressed: () => _inspectRealShiftPlans(context),
                              child: Text(localization.inspectRealShifts),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  void _updatePreferences(
    BuildContext context,
    NotificationPreferencesEntity preferences,
  ) {
    context.read<NotificationPreferencesCubit>().updatePreferences(preferences);
  }

  Future<void> _runDebugNotificationNow(BuildContext context) async {
    await getIt<LocalNotificationService>().showDebugNotificationNow();
    if (!context.mounted) return;
    AppSnackBar.showSuccess(
      context,
      'A debug notification was sent immediately.',
      title: 'Debug notification',
    );
  }

  Future<void> _runDebugShiftAlarm(BuildContext context) async {
    await getIt<LocalNotificationService>().scheduleDebugShiftAlarm();
    if (!context.mounted) return;
    AppSnackBar.showSuccess(
      context,
      'A debug alarm was scheduled for 10 seconds from now.',
      title: 'Debug alarm scheduled',
    );
  }

  Future<void> _runDebugCurrentShiftMode(BuildContext context) async {
    final result = await getIt<LocalNotificationService>()
        .scheduleDebugShiftUsingCurrentMode();
    if (!context.mounted) return;
    AppSnackBar.showSuccess(
      context,
      'A shift reminder was scheduled with the currently selected mode. Lock the phone or send the app to background before it fires.\n$result',
      title: 'Current mode test',
    );
  }

  Future<void> _showAlarmModeStatus(BuildContext context) async {
    final result = await getIt<LocalNotificationService>()
        .getAlarmModeDebugStatus();
    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Alarm mode status'),
        content: SelectableText(result),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _showPendingRequests(BuildContext context) async {
    final pending = await getIt<LocalNotificationService>()
        .pendingNotificationRequests();
    if (!context.mounted) return;
    AppSnackBar.showWarning(
      context,
      'Pending local notifications: ${pending.length}',
      title: 'Scheduler state',
    );
  }

  Future<void> _runDebugShiftPipeline(BuildContext context) async {
    final pendingCount = await getIt<LocalNotificationService>()
        .scheduleDebugShiftThroughAppFlow();
    if (!context.mounted) return;
    AppSnackBar.showSuccess(
      context,
      'The real shift scheduling path queued notifications. Pending requests: $pendingCount',
      title: 'Shift pipeline test',
    );
  }

  Future<void> _inspectRealShiftPlans(BuildContext context) async {
    final state = getIt<ShiftBloc>().state;
    if (state is! ShiftAssignmentsLoaded) {
      AppSnackBar.showWarning(
        context,
        'The shift list is not loaded yet. Open the shift page first, then try again.',
        title: 'Shift inspector',
      );
      return;
    }

    final plans = state.assignments.map(_buildShiftPlanLine).toList();
    if (!context.mounted) return;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Real shift plans'),
        content: SizedBox(
          width: 420,
          child: plans.isEmpty
              ? const Text('No loaded shifts were found in memory.')
              : SingleChildScrollView(
                  child: SelectableText(
                    plans.join('\n\n'),
                    style: Theme.of(dialogContext).textTheme.bodySmall,
                  ),
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  String _buildShiftPlanLine(ShiftAssignmentEntity assignment) {
    final deviceNow = DateTime.now();
    final shiftStart = DateTime(
      assignment.shiftDate.year,
      assignment.shiftDate.month,
      assignment.shiftDate.day,
      assignment.startTime.hour,
      assignment.startTime.minute,
    );
    final lines = <String>[
      'Shift ${assignment.id}',
      'Device now: ${_fmtDateTime(deviceNow)} (${deviceNow.timeZoneName} ${deviceNow.timeZoneOffset})',
      'Start: ${_fmtDateTime(shiftStart)}',
      'Offsets: ${assignment.alarmOffsets.isEmpty ? 'none' : assignment.alarmOffsets.join(', ')}',
    ];

    if (assignment.alarmOffsets.isEmpty) {
      lines.add('Result: no alarms configured');
      return lines.join('\n');
    }

    var futureAlarmCount = 0;
    for (final offset in assignment.alarmOffsets) {
      final alarmAt = shiftStart.add(Duration(minutes: offset));
      final status = alarmAt.isBefore(deviceNow) ? 'past' : 'future';
      if (!alarmAt.isBefore(deviceNow)) {
        futureAlarmCount++;
      }
      lines.add('Alarm $offset min -> ${_fmtDateTime(alarmAt)} [$status]');
    }

    if (futureAlarmCount == 0 && shiftStart.isAfter(deviceNow)) {
      lines.add('Fallback: immediate reminder should be scheduled');
    } else if (shiftStart.isBefore(deviceNow)) {
      lines.add('Result: shift already started/passed');
    }

    return lines.join('\n');
  }

  String _fmtDateTime(DateTime value) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${value.year}-${two(value.month)}-${two(value.day)} ${two(value.hour)}:${two(value.minute)}:${two(value.second)}';
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title.toUpperCase(),
        style: theme.textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w600,
          letterSpacing: 1.2,
          color: theme.colorScheme.descriptionColor,
        ),
      ),
    );
  }

  Widget _buildInfoNote(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String message,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.primary.withValues(alpha: 0.14)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: colorScheme.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  message,
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.descriptionColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchTile(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required bool showDivider,
  }) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.descriptionColor,
                      ),
                    ),
                  ],
                ),
              ),
              Switch.adaptive(
                value: value,
                onChanged: onChanged,
                activeTrackColor: colorScheme.selectItem,
              ),
            ],
          ),
        ),
        if (showDivider)
          Padding(
            padding: const EdgeInsets.only(left: 70),
            child: Divider(
              height: 1,
              color: colorScheme.borderColor?.withValues(alpha: 0.3),
            ),
          ),
      ],
    );
  }
}
