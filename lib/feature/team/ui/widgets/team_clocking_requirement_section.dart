import 'package:flutter/material.dart';
import 'package:note_sondage/theme/extensions/color_scheme/color_scheme.dart';

class TeamClockingRequirementSection extends StatelessWidget {
  const TeamClockingRequirementSection({
    super.key,
    required this.clockingRequired,
    required this.onClockingRequiredChanged,
    required this.reminderTime,
    required this.onReminderTimeChanged,
    required this.missingAlertTime,
    required this.onMissingAlertTimeChanged,
    required this.openAlertTime,
    required this.onOpenAlertTimeChanged,
    this.readOnly = false,
  });

  final bool clockingRequired;
  final ValueChanged<bool> onClockingRequiredChanged;
  final String reminderTime;
  final ValueChanged<String> onReminderTimeChanged;
  final String missingAlertTime;
  final ValueChanged<String> onMissingAlertTimeChanged;
  final String openAlertTime;
  final ValueChanged<String> onOpenAlertTimeChanged;
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isItalian = Localizations.localeOf(context).languageCode == 'it';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.homeSecondary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.borderColor!.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isItalian
                          ? 'Timbratura obbligatoria'
                          : 'Required clocking',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isItalian
                          ? 'Se attiva, tutti i membri del team devono registrare una timbratura, ferie o permesso.'
                          : 'If enabled, every team member must register a clocking, vacation, or permission entry.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.descriptionColor,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Switch.adaptive(
                value: clockingRequired,
                onChanged: readOnly ? null : onClockingRequiredChanged,
              ),
            ],
          ),
          const SizedBox(height: 12),
          _InfoLine(
            icon: Icons.notifications_active_outlined,
            text: isItalian
                ? 'Default: No. Quando attiva, il sistema manda un promemoria all\'utente e avvisa l\'owner se manca o resta aperta una timbratura.'
                : 'Default: No. When enabled, the system reminds the user and alerts the owner when a clocking is missing or still open.',
          ),
          const SizedBox(height: 16),
          AbsorbPointer(
            absorbing: readOnly || !clockingRequired,
            child: Opacity(
              opacity: clockingRequired ? 1 : 0.55,
              child: Column(
                children: [
                  _TimeTile(
                    title: isItalian ? 'Promemoria utente' : 'User reminder',
                    subtitle: isItalian
                        ? 'Orario in cui ricordare al membro di timbrare.'
                        : 'Time used to remind the member to clock in.',
                    value: reminderTime,
                    enabled: !readOnly && clockingRequired,
                    onTap: () =>
                        _pickTime(context, reminderTime, onReminderTimeChanged),
                  ),
                  const SizedBox(height: 10),
                  _TimeTile(
                    title: isItalian
                        ? 'Controllo timbratura mancante'
                        : 'Missing clocking check',
                    subtitle: isItalian
                        ? 'Dopo questo orario l\'owner riceve un avviso se manca una registrazione.'
                        : 'After this time the owner is alerted when a required entry is still missing.',
                    value: missingAlertTime,
                    enabled: !readOnly && clockingRequired,
                    onTap: () => _pickTime(
                      context,
                      missingAlertTime,
                      onMissingAlertTimeChanged,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _TimeTile(
                    title: isItalian
                        ? 'Controllo timbratura aperta'
                        : 'Open clocking check',
                    subtitle: isItalian
                        ? 'Dopo questo orario l\'owner viene avvisato se una timbratura non e stata chiusa.'
                        : 'After this time the owner is alerted when a clocking is still open.',
                    value: openAlertTime,
                    enabled: !readOnly && clockingRequired,
                    onTap: () => _pickTime(
                      context,
                      openAlertTime,
                      onOpenAlertTimeChanged,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickTime(
    BuildContext context,
    String currentValue,
    ValueChanged<String> onChanged,
  ) async {
    final initial = _parseTime(currentValue);
    final selected = await showTimePicker(
      context: context,
      initialTime: initial,
    );
    if (selected == null) {
      return;
    }
    onChanged(_formatTime(selected));
  }

  TimeOfDay _parseTime(String value) {
    final parts = value.split(':');
    final hour = parts.isNotEmpty ? int.tryParse(parts[0]) ?? 9 : 9;
    final minute = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;
    return TimeOfDay(hour: hour, minute: minute);
  }

  String _formatTime(TimeOfDay value) {
    final hh = value.hour.toString().padLeft(2, '0');
    final mm = value.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }
}

class _TimeTile extends StatelessWidget {
  const _TimeTile({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.enabled,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final String value;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.descriptionColor,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.bgNavbarSurface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      value,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.schedule_rounded,
                      size: 18,
                      color: enabled
                          ? colorScheme.primary
                          : colorScheme.descriptionColor,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: theme.colorScheme.descriptionColor),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.descriptionColor,
            ),
          ),
        ),
      ],
    );
  }
}
