import 'package:flutter/material.dart';
import 'package:note_sondage/feature/shift/domain/entities/shift_assignment_entity.dart';
import 'package:note_sondage/theme/extensions/color_scheme/color_scheme.dart';

/// Interactive monthly calendar that shows shift assignments.
///
/// Usage:
/// ```dart
/// ShiftCalendarWidget(
///   assignments: assignments,
///   focusedMonth: _focusedMonth,
///   onMonthChanged: (d) => setState(() => _focusedMonth = d),
///   onDayTap: (date, dayAssignments) { /* open assign dialog */ },
/// )
/// ```
class ShiftCalendarWidget extends StatelessWidget {
  const ShiftCalendarWidget({
    super.key,
    required this.assignments,
    required this.focusedMonth,
    required this.onMonthChanged,
    required this.onDayTap,
  });

  final List<ShiftAssignmentEntity> assignments;
  final DateTime focusedMonth;
  final ValueChanged<DateTime> onMonthChanged;

  /// Called with the tapped date and all visible assignments for that day.
  final void Function(DateTime date, List<ShiftAssignmentEntity> assignments)
  onDayTap;

  static const List<String> _months = [
    'Gennaio',
    'Febbraio',
    'Marzo',
    'Aprile',
    'Maggio',
    'Giugno',
    'Luglio',
    'Agosto',
    'Settembre',
    'Ottobre',
    'Novembre',
    'Dicembre',
  ];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final firstDay = DateTime(focusedMonth.year, focusedMonth.month, 1);
    final daysInMonth = DateTime(
      focusedMonth.year,
      focusedMonth.month + 1,
      0,
    ).day;

    // Map date → assignments for O(1) lookup
    final assignMap = <String, List<ShiftAssignmentEntity>>{};
    for (final a in assignments) {
      final key = '${a.shiftDate.year}-${a.shiftDate.month}-${a.shiftDate.day}';
      assignMap.putIfAbsent(key, () => []).add(a);
    }

    final weekdayOffset = (firstDay.weekday - 1) % 7; // Mon = 0
    final totalCells = weekdayOffset + daysInMonth;
    final rows = (totalCells / 7).ceil();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Month navigation header ───────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: () => onMonthChanged(
                  DateTime(focusedMonth.year, focusedMonth.month - 1),
                ),
              ),
              Expanded(
                child: Wrap(
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _HeaderPickerButton(
                      label: _monthName(focusedMonth),
                      onTap: () async {
                        final selectedMonth = await _pickMonth(context);
                        if (selectedMonth == null) {
                          return;
                        }
                        onMonthChanged(
                          DateTime(focusedMonth.year, selectedMonth, 1),
                        );
                      },
                    ),
                    _HeaderPickerButton(
                      label: '${focusedMonth.year}',
                      onTap: () async {
                        final selectedYear = await _pickYear(context);
                        if (selectedYear == null) {
                          return;
                        }
                        onMonthChanged(
                          DateTime(selectedYear, focusedMonth.month, 1),
                        );
                      },
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: () => onMonthChanged(
                  DateTime(focusedMonth.year, focusedMonth.month + 1),
                ),
              ),
            ],
          ),
        ),

        // ── Day-of-week labels ────────────────────────────────────────────
        Row(
          children: _weekdayLabels(context).map((label) {
            return Expanded(
              child: Center(
                child: Text(
                  label,
                  style: textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colorScheme.descriptionColor,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 4),

        // ── Calendar grid ─────────────────────────────────────────────────
        for (int row = 0; row < rows; row++)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              children: List.generate(7, (col) {
                final cellIndex = row * 7 + col;
                final dayNumber = cellIndex - weekdayOffset + 1;

                if (dayNumber < 1 || dayNumber > daysInMonth) {
                  return const Expanded(child: SizedBox());
                }

                final date = DateTime(
                  focusedMonth.year,
                  focusedMonth.month,
                  dayNumber,
                );
                final key = '${date.year}-${date.month}-${date.day}';
                final dayAssignments = assignMap[key] ?? const [];
                final isToday = _isToday(date);

                return Expanded(
                  child: _DayCell(
                    day: dayNumber,
                    isToday: isToday,
                    assignments: dayAssignments,
                    onTap: () => onDayTap(date, dayAssignments),
                  ),
                );
              }),
            ),
          ),
      ],
    );
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  String _monthName(DateTime date) {
    return _months[date.month - 1];
  }

  List<String> _weekdayLabels(BuildContext context) => [
    'Lun',
    'Mar',
    'Mer',
    'Gio',
    'Ven',
    'Sab',
    'Dom',
  ];

  Future<int?> _pickMonth(BuildContext context) async {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return showDialog<int>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Seleziona mese'),
          content: SizedBox(
            width: 360,
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: List.generate(_months.length, (index) {
                final month = index + 1;
                final isSelected = month == focusedMonth.month;
                return ChoiceChip(
                  label: Text(_months[index]),
                  selected: isSelected,
                  onSelected: (_) => Navigator.of(dialogContext).pop(month),
                  selectedColor: (colorScheme.selectItem ?? colorScheme.primary)
                      .withValues(alpha: 0.14),
                  side: BorderSide(
                    color: isSelected
                        ? (colorScheme.selectItem ?? colorScheme.primary)
                        : colorScheme.outlineVariant,
                  ),
                  labelStyle: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: colorScheme.onSurface,
                  ),
                );
              }),
            ),
          ),
        );
      },
    );
  }

  Future<int?> _pickYear(BuildContext context) async {
    return showDialog<int>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Seleziona anno'),
          content: SizedBox(
            width: 320,
            height: 320,
            child: YearPicker(
              firstDate: DateTime(2000),
              lastDate: DateTime(2100),
              selectedDate: focusedMonth,
              currentDate: DateTime.now(),
              onChanged: (selectedDate) {
                Navigator.of(dialogContext).pop(selectedDate.year);
              },
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _HeaderPickerButton extends StatelessWidget {
  const _HeaderPickerButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final accent = colorScheme.selectItem ?? colorScheme.primary;

    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: accent.withValues(alpha: 0.16)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(width: 6),
            Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: accent),
          ],
        ),
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.isToday,
    required this.assignments,
    required this.onTap,
  });

  final int day;
  final bool isToday;
  final List<ShiftAssignmentEntity> assignments;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final appPrimary = colorScheme.primaryColor ?? colorScheme.primary;
    final assignment = assignments.isNotEmpty ? assignments.first : null;
    final shiftColor = assignment?.displayColor;
    final publicCount = assignments.where((item) => item.isPublic).length;
    final hasMore = assignments.length > 2;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: shiftColor != null
              ? shiftColor.withValues(alpha: 0.15)
              : colorScheme.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isToday
                ? Theme.of(context).colorScheme.primary
                : shiftColor != null
                ? shiftColor.withValues(alpha: 0.4)
                : colorScheme.outlineVariant.withValues(alpha: 0.3),
            width: isToday ? 2 : 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Day number + visibility icon on same row
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$day',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: isToday ? FontWeight.w800 : FontWeight.w500,
                      color: isToday
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  if (assignments.isNotEmpty) ...[
                    const SizedBox(width: 1),
                    Tooltip(
                      message: publicCount > 0
                          ? '$publicCount turno/i pubblico/i visibili al team'
                          : 'Turni privati',
                      child: Icon(
                        publicCount > 0 ? Icons.public : Icons.lock_outline,
                        size: 8,
                        color: publicCount > 0
                            ? appPrimary
                            : colorScheme.outline.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ],
              ),
              if (assignments.isNotEmpty) ...[
                const SizedBox(height: 2),
                ...assignments.take(2).map((item) {
                  final label = item.userName?.trim().isNotEmpty == true
                      ? '${_abbreviate(item.profileName ?? '?')} ${_initials(item.userName!)}'
                      : _abbreviate(item.profileName ?? '?');
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 2,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: item.displayColor.withValues(alpha: 0.84),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        label,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  );
                }),
                if (hasMore)
                  Text(
                    '+${assignments.length - 2} altri',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontSize: 8,
                      color: colorScheme.descriptionColor,
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _abbreviate(String name) {
    if (name.length <= 4) return name.toUpperCase();
    return name.substring(0, 3).toUpperCase();
  }

  String _initials(String raw) {
    final parts = raw.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
    final initials = parts.take(2).map((part) => part[0].toUpperCase()).join();
    return initials.isEmpty ? '?' : initials;
  }
}
