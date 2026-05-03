import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:note_sondage/feature/notification/preferences/notification_preferences_cubit.dart';
import 'package:note_sondage/feature/notification/preferences/notification_preferences_entity.dart';
import 'package:note_sondage/languages/l10n/app_localizations.dart';
import 'package:note_sondage/theme/extensions/color_scheme/color_scheme.dart';

class NotificationSettingsMobile extends StatefulWidget {
  const NotificationSettingsMobile({super.key});

  @override
  State<NotificationSettingsMobile> createState() =>
      _NotificationSettingsMobileState();
}

class _NotificationSettingsMobileState
    extends State<NotificationSettingsMobile> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<NotificationPreferencesCubit>().loadPreferences();
    });
  }

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;

    return BlocBuilder<NotificationPreferencesCubit, NotificationPreferencesState>(
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
