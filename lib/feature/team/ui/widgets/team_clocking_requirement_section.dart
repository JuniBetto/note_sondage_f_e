import 'package:flutter/material.dart';
import 'package:note_sondage/feature/team/domain/entities/team_member_clocking_alarm_override_entity.dart';
import 'package:note_sondage/feature/team/domain/entities/team_member_entity.dart';
import 'package:note_sondage/languages/l10n/app_localizations.dart';
import 'package:note_sondage/theme/extensions/color_scheme/color_scheme.dart';
import 'package:note_sondage/ui/widgets/app_toggle_switch.dart';

enum _AlarmField { reminder, missing, open }

extension on _AlarmField {
  String? read(TeamMemberClockingAlarmOverrideEntity override) =>
      switch (this) {
        _AlarmField.reminder => override.reminderTime,
        _AlarmField.missing => override.missingAlertTime,
        _AlarmField.open => override.openAlertTime,
      };

  TeamMemberClockingAlarmOverrideEntity write(
    TeamMemberClockingAlarmOverrideEntity override,
    String? value,
  ) => switch (this) {
    _AlarmField.reminder => TeamMemberClockingAlarmOverrideEntity(
      reminderTime: value,
      missingAlertTime: override.missingAlertTime,
      openAlertTime: override.openAlertTime,
    ),
    _AlarmField.missing => TeamMemberClockingAlarmOverrideEntity(
      reminderTime: override.reminderTime,
      missingAlertTime: value,
      openAlertTime: override.openAlertTime,
    ),
    _AlarmField.open => TeamMemberClockingAlarmOverrideEntity(
      reminderTime: override.reminderTime,
      missingAlertTime: override.missingAlertTime,
      openAlertTime: value,
    ),
  };
}

class TeamClockingRequirementSection extends StatelessWidget {
  const TeamClockingRequirementSection({
    super.key,
    required this.clockingRequired,
    required this.onClockingRequiredChanged,
    required this.requiredStartDate,
    required this.onRequiredStartDateChanged,
    required this.requiredEndDate,
    required this.onRequiredEndDateChanged,
    required this.reminderTime,
    required this.onReminderTimeChanged,
    required this.missingAlertTime,
    required this.onMissingAlertTimeChanged,
    required this.openAlertTime,
    required this.onOpenAlertTimeChanged,
    this.readOnly = false,
    this.teamId,
    this.members = const <TeamMemberEntity>[],
    this.onOverrideChanged,
  });

  final bool clockingRequired;
  final ValueChanged<bool> onClockingRequiredChanged;
  final String requiredStartDate;
  final ValueChanged<String> onRequiredStartDateChanged;
  final String? requiredEndDate;
  final ValueChanged<String?> onRequiredEndDateChanged;
  final String reminderTime;
  final ValueChanged<String> onReminderTimeChanged;
  final String missingAlertTime;
  final ValueChanged<String> onMissingAlertTimeChanged;
  final String openAlertTime;
  final ValueChanged<String> onOpenAlertTimeChanged;
  final bool readOnly;

  /// When set (together with [onOverrideChanged]), each time row shows a
  /// "+" letting the caller add a per-member override — only meaningful when
  /// editing an existing team (a real [teamId] and real [members] to pick
  /// from). Left null while creating a team, where neither exists yet.
  final String? teamId;
  final List<TeamMemberEntity> members;
  final Future<void> Function(
    TeamMemberEntity member,
    TeamMemberClockingAlarmOverrideEntity override,
  )?
  onOverrideChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final loc = AppLocalizations.of(context)!;

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
                      loc.teamClockingRequirementTitle,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      loc.teamClockingRequirementDescription,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.descriptionColor,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              AppToggleSwitch(
                value: clockingRequired,
                onChanged: readOnly ? null : onClockingRequiredChanged,
              ),
            ],
          ),
          const SizedBox(height: 12),
          _InfoLine(
            icon: Icons.notifications_active_outlined,
            text: loc.teamClockingRequirementDefaultInfo,
          ),
          const SizedBox(height: 16),
          AbsorbPointer(
            absorbing: readOnly || !clockingRequired,
            child: Opacity(
              opacity: clockingRequired ? 1 : 0.55,
              child: Column(
                children: [
                  _DateTile(
                    title: loc.teamClockingRequirementStartDateTitle,
                    subtitle: loc.teamClockingRequirementStartDateSubtitle,
                    value:
                        _formatDateForDisplay(context, requiredStartDate) ??
                        requiredStartDate,
                    enabled: !readOnly && clockingRequired,
                    onTap: () => _pickDate(context, requiredStartDate, (value) {
                      if (value != null) {
                        onRequiredStartDateChanged(value);
                      }
                    }),
                  ),
                  const SizedBox(height: 10),
                  _DateTile(
                    title: loc.teamClockingRequirementEndDateTitle,
                    subtitle: loc.teamClockingRequirementEndDateSubtitle,
                    value:
                        _formatDateForDisplay(context, requiredEndDate) ??
                        loc.teamClockingRequirementNoEndDate,
                    enabled: !readOnly && clockingRequired,
                    onTap: () => _pickDate(
                      context,
                      requiredEndDate,
                      onRequiredEndDateChanged,
                      _parseDate(requiredStartDate),
                    ),
                  ),
                  if ((requiredEndDate?.trim().isNotEmpty ?? false) &&
                      !readOnly &&
                      clockingRequired)
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: () => onRequiredEndDateChanged(null),
                        icon: const Icon(Icons.close_rounded, size: 18),
                        label: Text(loc.teamClockingRequirementClearEndDate),
                      ),
                    ),
                  if (requiredEndDate?.trim().isNotEmpty ?? false)
                    const SizedBox(height: 10),
                  _buildTimeTileWithOverrides(
                    context,
                    field: _AlarmField.reminder,
                    title: loc.teamClockingRequirementUserReminderTitle,
                    subtitle: loc.teamClockingRequirementUserReminderSubtitle,
                    defaultValue: reminderTime,
                    enabled: !readOnly && clockingRequired,
                    onTapDefault: () =>
                        _pickTime(context, reminderTime, onReminderTimeChanged),
                  ),
                  const SizedBox(height: 10),
                  _buildTimeTileWithOverrides(
                    context,
                    field: _AlarmField.missing,
                    title: loc.teamClockingRequirementMissingCheckTitle,
                    subtitle: loc.teamClockingRequirementMissingCheckSubtitle,
                    defaultValue: missingAlertTime,
                    enabled: !readOnly && clockingRequired,
                    onTapDefault: () => _pickTime(
                      context,
                      missingAlertTime,
                      onMissingAlertTimeChanged,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _buildTimeTileWithOverrides(
                    context,
                    field: _AlarmField.open,
                    title: loc.teamClockingRequirementOpenCheckTitle,
                    subtitle: loc.teamClockingRequirementOpenCheckSubtitle,
                    defaultValue: openAlertTime,
                    enabled: !readOnly && clockingRequired,
                    onTapDefault: () => _pickTime(
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

  Future<void> _pickDate(
    BuildContext context,
    String? currentValue,
    ValueChanged<String?> onChanged, [
    DateTime? minDate,
  ]) async {
    final now = DateTime.now();
    final firstDate = minDate ?? DateTime(now.year - 2);
    final initial = _parseDate(currentValue ?? '') ?? firstDate;
    final selected = await showDatePicker(
      context: context,
      initialDate: initial.isBefore(firstDate) ? firstDate : initial,
      firstDate: firstDate,
      lastDate: DateTime(now.year + 5),
    );
    if (selected == null) {
      return;
    }
    onChanged(_formatDateForApi(selected));
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
      builder: (pickerContext, child) {
        final mediaQuery = MediaQuery.of(
          pickerContext,
        ).copyWith(alwaysUse24HourFormat: false);

        return Localizations.override(
          context: pickerContext,
          locale: const Locale('en'),
          child: MediaQuery(data: mediaQuery, child: child!),
        );
      },
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

  DateTime? _parseDate(String value) {
    if (value.trim().isEmpty) {
      return null;
    }
    return DateTime.tryParse(value);
  }

  String _formatDateForApi(DateTime value) {
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '${value.year}-$month-$day';
  }

  String? _formatDateForDisplay(BuildContext context, String? value) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }
    final parsed = _parseDate(value);
    if (parsed == null) {
      return value;
    }
    return MaterialLocalizations.of(context).formatMediumDate(parsed);
  }

  String _memberDisplayName(TeamMemberEntity member) {
    final name = member.initialName?.trim();
    return (name != null && name.isNotEmpty) ? name : member.userEmail;
  }

  /// The default time tile, plus (only when [teamId]/[onOverrideChanged] are
  /// set) a "+" to add a per-member override for this specific check, and a
  /// compact row per member that already has one.
  Widget _buildTimeTileWithOverrides(
    BuildContext context, {
    required _AlarmField field,
    required String title,
    required String subtitle,
    required String defaultValue,
    required bool enabled,
    required VoidCallback onTapDefault,
  }) {
    final loc = AppLocalizations.of(context)!;
    final canManageOverrides = teamId != null && onOverrideChanged != null;
    final overriddenMembers = canManageOverrides
        ? members
              .where(
                (member) =>
                    field.read(
                      member.clockingAlarmOverride ??
                          const TeamMemberClockingAlarmOverrideEntity(),
                    ) !=
                    null,
              )
              .toList()
        : const <TeamMemberEntity>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: _TimeTile(
                title: title,
                subtitle: subtitle,
                value: defaultValue,
                enabled: enabled,
                onTap: onTapDefault,
              ),
            ),
            if (canManageOverrides && enabled) ...[
              const SizedBox(width: 8),
              IconButton(
                tooltip: loc.teamClockingRequirementAddOverrideTooltip,
                onPressed: () =>
                    _addOverride(context, field, overriddenMembers),
                icon: const Icon(Icons.add_circle_outline),
              ),
            ],
          ],
        ),
        if (overriddenMembers.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final member in overriddenMembers)
                _MemberOverrideTile(
                  memberName: _memberDisplayName(member),
                  value:
                      field.read(
                        member.clockingAlarmOverride ??
                            const TeamMemberClockingAlarmOverrideEntity(),
                      ) ??
                      defaultValue,
                  enabled: enabled,
                  onTap: () => _editOverride(context, field, member),
                  onRemove: () => _setOverrideValue(field, member, null),
                ),
            ],
          ),
        ],
      ],
    );
  }

  Future<void> _addOverride(
    BuildContext context,
    _AlarmField field,
    List<TeamMemberEntity> alreadyOverridden,
  ) async {
    final overriddenIds = alreadyOverridden.map((member) => member.id).toSet();
    final candidates = members
        .where((member) => !overriddenIds.contains(member.id))
        .toList();
    if (candidates.isEmpty) {
      return;
    }
    final member = await _pickMember(context, candidates);
    if (member == null || !context.mounted) {
      return;
    }
    await _pickTime(context, reminderTime, (time) async {
      await _setOverrideValue(field, member, time);
    });
  }

  Future<void> _editOverride(
    BuildContext context,
    _AlarmField field,
    TeamMemberEntity member,
  ) async {
    final currentOverride =
        member.clockingAlarmOverride ??
        const TeamMemberClockingAlarmOverrideEntity();
    final currentValue = field.read(currentOverride) ?? reminderTime;
    await _pickTime(context, currentValue, (time) async {
      await _setOverrideValue(field, member, time);
    });
  }

  Future<void> _setOverrideValue(
    _AlarmField field,
    TeamMemberEntity member,
    String? value,
  ) async {
    final currentOverride =
        member.clockingAlarmOverride ??
        const TeamMemberClockingAlarmOverrideEntity();
    final updated = field.write(currentOverride, value);
    await onOverrideChanged?.call(member, updated);
  }

  Future<TeamMemberEntity?> _pickMember(
    BuildContext context,
    List<TeamMemberEntity> candidates,
  ) {
    final loc = AppLocalizations.of(context)!;
    return showDialog<TeamMemberEntity>(
      context: context,
      builder: (dialogContext) => SimpleDialog(
        title: Text(loc.teamClockingRequirementChooseMember),
        children: candidates
            .map(
              (member) => SimpleDialogOption(
                onPressed: () => Navigator.of(dialogContext).pop(member),
                child: Text(_memberDisplayName(member)),
              ),
            )
            .toList(),
      ),
    );
  }
}

/// Riga "testo a sinistra, valore a destra" delle tile di impostazione.
///
/// Se a destra il valore (es. "Aucune date de fin") occupa cosi' tanto che al
/// testo resterebbe una colonna stretta, quest'ultimo andava a capo quasi
/// lettera per lettera — succede con schermi stretti o con font di sistema
/// grandi. In quel caso il valore passa sotto il testo, che torna a usare
/// tutta la larghezza della tile.
class _AdaptiveTileRow extends StatelessWidget {
  const _AdaptiveTileRow({
    required this.info,
    required this.trailing,
    required this.trailingWidth,
  });

  static const double _minInfoWidth = 150;
  static const double _gap = 12;

  /// Titolo e sottotitolo.
  final Widget info;

  /// Riquadro con il valore e l'icona.
  final Widget trailing;

  /// Larghezza che [trailing] occupa quando sta tutto su una riga.
  final double trailingWidth;

  /// Misura il riquadro del valore: testo + spazio + icona + padding interno.
  static double measureTrailing(
    BuildContext context, {
    required String value,
    required TextStyle? style,
    double iconSize = 18,
  }) {
    final painter = TextPainter(
      text: TextSpan(text: value, style: style),
      textDirection: TextDirection.ltr,
      textScaler: MediaQuery.textScalerOf(context),
      maxLines: 1,
    )..layout();
    return painter.width + 8 + iconSize + 24;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final sideBySide =
            constraints.maxWidth - trailingWidth - _gap >= _minInfoWidth;
        if (sideBySide) {
          return Row(
            children: [
              Expanded(child: info),
              const SizedBox(width: _gap),
              trailing,
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            info,
            const SizedBox(height: 10),
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: constraints.maxWidth),
              child: trailing,
            ),
          ],
        );
      },
    );
  }
}

/// Riquadro con il valore di una tile (data o orario) e la sua icona.
///
/// Se lo spazio non basta e il valore viene accorciato con "…", compare un
/// "!" che al tap mostra il testo completo. Se il valore sta per intero il
/// "!" non c'e'.
class _TileValueBox extends StatelessWidget {
  const _TileValueBox({
    required this.title,
    required this.value,
    required this.background,
    required this.radius,
    required this.textStyle,
    required this.icon,
    required this.iconColor,
  });

  static const double _horizontalPadding = 12;
  static const double _iconSize = 18;
  static const double _gap = 8;

  final String title;
  final String value;
  final Color? background;
  final double radius;
  final TextStyle? textStyle;
  final IconData icon;
  final Color? iconColor;

  bool _isTruncated(BuildContext context, double maxWidth) {
    if (!maxWidth.isFinite) {
      return false;
    }
    final painter = TextPainter(
      text: TextSpan(text: value, style: textStyle),
      textDirection: TextDirection.ltr,
      textScaler: MediaQuery.textScalerOf(context),
      maxLines: 1,
    )..layout();
    final available = maxWidth - (_horizontalPadding * 2) - _gap - _iconSize;
    return painter.width > available;
  }

  Future<void> _showFullValue(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: SelectableText(value),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(loc.close),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return LayoutBuilder(
      builder: (context, constraints) {
        final truncated = _isTruncated(context, constraints.maxWidth);
        return Container(
          padding: const EdgeInsets.symmetric(
            horizontal: _horizontalPadding,
            vertical: 8,
          ),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(radius),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (truncated) ...[
                // Il tap sul "!" non deve aprire il selettore della tile.
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => _showFullValue(context),
                  child: Tooltip(
                    message: value,
                    child: Padding(
                      padding: const EdgeInsets.all(2),
                      child: Icon(
                        Icons.error_outline_rounded,
                        size: _iconSize,
                        color: colorScheme.error,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
              ],
              Flexible(
                child: Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textStyle,
                ),
              ),
              const SizedBox(width: _gap),
              Icon(icon, size: _iconSize, color: iconColor),
            ],
          ),
        );
      },
    );
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
          child: _AdaptiveTileRow(
            info: Column(
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
            trailingWidth: _AdaptiveTileRow.measureTrailing(
              context,
              value: value,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            trailing: _TileValueBox(
              title: title,
              value: value,
              background: colorScheme.bgNavbarSurface,
              radius: 12,
              textStyle: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
              icon: Icons.schedule_rounded,
              iconColor: enabled
                  ? colorScheme.primary
                  : colorScheme.descriptionColor,
            ),
          ),
        ),
      ),
    );
  }
}

class _DateTile extends StatelessWidget {
  const _DateTile({
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
    return _SettingTile(
      title: title,
      subtitle: subtitle,
      value: value,
      enabled: enabled,
      onTap: onTap,
      icon: Icons.event_outlined,
    );
  }
}

class _SettingTile extends StatelessWidget {
  const _SettingTile({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.enabled,
    required this.onTap,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final String value;
  final bool enabled;
  final VoidCallback onTap;
  final IconData icon;

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
          child: _AdaptiveTileRow(
            info: Column(
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
            trailingWidth: _AdaptiveTileRow.measureTrailing(
              context,
              value: value,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            trailing: _TileValueBox(
              title: title,
              value: value,
              background: colorScheme.homeSecondary?.withValues(alpha: 0.7),
              radius: 14,
              textStyle: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
              icon: icon,
              iconColor: colorScheme.descriptionColor,
            ),
          ),
        ),
      ),
    );
  }
}

/// Compact per-member override row shown under a default [_TimeTile], for
/// the "+" flow in [TeamClockingRequirementSection].
class _MemberOverrideTile extends StatelessWidget {
  const _MemberOverrideTile({
    required this.memberName,
    required this.value,
    required this.enabled,
    required this.onTap,
    required this.onRemove,
  });

  final String memberName;
  final String value;
  final bool enabled;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: colorScheme.surface.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.withValues(alpha: 0.12)),
          ),
          // No Expanded here on purpose: the tile sizes to its own content
          // (member name + time) so several fit on the same line — see the
          // Wrap in _buildTimeTileWithOverrides. Only the name gets a max
          // width, so a long full name still wraps to its own line instead
          // of stretching the whole row.
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.person_outline,
                size: 14,
                color: colorScheme.descriptionColor,
              ),
              const SizedBox(width: 6),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 140),
                child: Text(
                  memberName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                value,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: colorScheme.primary,
                ),
              ),
              if (enabled) ...[
                const SizedBox(width: 2),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: Icon(
                    Icons.close_rounded,
                    size: 16,
                    color: colorScheme.descriptionColor,
                  ),
                  onPressed: onRemove,
                ),
              ],
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
