import 'package:flutter/material.dart';
import 'package:note_sondage/languages/l10n/app_localizations.dart';
import 'package:note_sondage/theme/extensions/color_scheme/color_scheme.dart';

class SettingsNotificationWeb extends StatefulWidget {
  const SettingsNotificationWeb({super.key});

  @override
  State<SettingsNotificationWeb> createState() =>
      _SettingsNotificationWebState();
}

class _SettingsNotificationWebState extends State<SettingsNotificationWeb> {
  bool _emailNotifications = true;
  bool _pushNotifications = false;
  bool _surveyReminders = true;
  bool _teamUpdates = true;
  bool _clockingAlerts = false;

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;

    return Align(
      alignment: Alignment.topLeft,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          // Header
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFFF9800).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.notifications_rounded,
                  color: Color(0xFFFF9800),
                  size: 26,
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    localization.settingsNotification,
                    style: textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Configure how you want to be notified',
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.descriptionColor,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 32),

          // General Notifications
          _buildSectionTitle(context, 'General'),
          const SizedBox(height: 12),
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
                  value: _emailNotifications,
                  onChanged: (v) => setState(() => _emailNotifications = v),
                  showDivider: true,
                ),
                _buildSwitchTile(
                  context,
                  icon: Icons.phone_iphone_rounded,
                  iconColor: const Color(0xFF4CAF50),
                  title: 'Push Notifications',
                  subtitle: 'Receive push notifications on your device',
                  value: _pushNotifications,
                  onChanged: (v) => setState(() => _pushNotifications = v),
                  showDivider: false,
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Activity Notifications
          _buildSectionTitle(context, 'Activity'),
          const SizedBox(height: 12),
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
                  value: _surveyReminders,
                  onChanged: (v) => setState(() => _surveyReminders = v),
                  showDivider: true,
                ),
                _buildSwitchTile(
                  context,
                  icon: Icons.groups_rounded,
                  iconColor: const Color(0xFF00BCD4),
                  title: 'Team Updates',
                  subtitle: 'Notifications about team changes',
                  value: _teamUpdates,
                  onChanged: (v) => setState(() => _teamUpdates = v),
                  showDivider: true,
                ),
                _buildSwitchTile(
                  context,
                  icon: Icons.access_time_rounded,
                  iconColor: const Color(0xFFE91E63),
                  title: 'Clocking Alerts',
                  subtitle: 'Reminders to clock in and out',
                  value: _clockingAlerts,
                  onChanged: (v) => setState(() => _clockingAlerts = v),
                  showDivider: false,
                ),
              ],
            ),
          ),
        ],
      ),
      ),
    );
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
