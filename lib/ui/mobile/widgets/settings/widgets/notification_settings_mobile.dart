import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:note_sondage/core/dependency_injection/dependency_injection.dart';
import 'package:note_sondage/feature/notification/local/local_notification_service.dart';
import 'package:note_sondage/feature/notification/preferences/notification_preferences_cubit.dart';
import 'package:note_sondage/feature/notification/preferences/notification_preferences_entity.dart';
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<NotificationPreferencesCubit>().loadPreferences();
      _loadShiftAlarmFeedback();
      _loadShiftAlarmDuration();
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
                          'Configure how you want to be notified',
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
              _buildSectionTitle(context, 'General'),
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
                      title: 'Email Notifications',
                      subtitle: 'Receive updates via email',
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
                      title: 'Push Notifications',
                      subtitle: 'Receive push notifications on your device',
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

              _buildSectionTitle(context, 'Shift alarm'),
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
                        'Alarm feedback',
                        style: textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        supportsVibrateOnlyShiftAlarmFeedback
                            ? 'Choose whether shift alarms should vibrate or play a ringtone. Default: vibrate.'
                            : 'On iPhone, shift alarms use a ringtone. Vibration-only mode is not available for local alarms.',
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.descriptionColor,
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (supportsVibrateOnlyShiftAlarmFeedback)
                        SegmentedButton<ShiftAlarmFeedback>(
                          segments: const [
                            ButtonSegment(
                              value: ShiftAlarmFeedback.vibrate,
                              icon: Icon(Icons.vibration, size: 16),
                              label: Text('Vibrate'),
                            ),
                            ButtonSegment(
                              value: ShiftAlarmFeedback.ringtone,
                              icon: Icon(Icons.music_note, size: 16),
                              label: Text('Ringtone'),
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
                                'Ringtone',
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
                        'Duration: ${_shiftAlarmDurationSeconds}s',
                        style: textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
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
              _buildSectionTitle(context, 'Activity'),
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
                      title: 'Survey Reminders',
                      subtitle: 'Get reminded about pending surveys',
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
                      title: 'Team Updates',
                      subtitle: 'Notifications about team changes',
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
                      title: 'Clocking Alerts',
                      subtitle: 'Reminders to clock in and out',
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
                      title: 'Shift Notifications',
                      subtitle: 'Assignments, updates and shift reminders',
                      value: preferences.shiftAlertsEnabled,
                      onChanged: (v) => _updatePreferences(
                        context,
                        preferences.copyWith(shiftAlertsEnabled: v),
                      ),
                      showDivider: false,
                    ),
                  ],
                ),
              ),

              if (kDebugMode) ...[
                const SizedBox(height: 20),
                _buildSectionTitle(context, 'Debug'),
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
                          'Run local notification self-tests on this device.',
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
                              child: const Text('Test notification now'),
                            ),
                            OutlinedButton(
                              onPressed: () => _runDebugShiftAlarm(context),
                              child: const Text('Test alarm in 10s'),
                            ),
                            OutlinedButton(
                              onPressed: () =>
                                  _runDebugCurrentShiftMode(context),
                              child: const Text('Test current mode'),
                            ),
                            OutlinedButton(
                              onPressed: () => _showAlarmModeStatus(context),
                              child: const Text('Alarm mode status'),
                            ),
                            OutlinedButton(
                              onPressed: () => _runDebugShiftPipeline(context),
                              child: const Text('Test shift path 20s'),
                            ),
                            OutlinedButton(
                              onPressed: () => _showPendingRequests(context),
                              child: const Text('Pending requests'),
                            ),
                            OutlinedButton(
                              onPressed: () => _inspectRealShiftPlans(context),
                              child: const Text('Inspect real shifts'),
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
