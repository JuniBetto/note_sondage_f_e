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
///   onDayTap: (date, existing) { /* open assign dialog */ },
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

  /// Called with the tapped date and the existing assignment (or null).
  final void Function(DateTime date, ShiftAssignmentEntity? existing) onDayTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final firstDay = DateTime(focusedMonth.year, focusedMonth.month, 1);
    final daysInMonth =
        DateTime(focusedMonth.year, focusedMonth.month + 1, 0).day;

    // Map date → assignment for O(1) lookup
    final assignMap = <String, ShiftAssignmentEntity>{};
    for (final a in assignments) {
      final key =
          '${a.shiftDate.year}-${a.shiftDate.month}-${a.shiftDate.day}';
      assignMap[key] = a;
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
                child: Text(
                  _monthLabel(context, focusedMonth),
                  textAlign: TextAlign.center,
                  style: textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
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
                final assignment = assignMap[key];
                final isToday = _isToday(date);

                return Expanded(
                  child: _DayCell(
                    day: dayNumber,
                    isToday: isToday,
                    assignment: assignment,
                    onTap: () => onDayTap(date, assignment),
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

  String _monthLabel(BuildContext context, DateTime date) {
    const months = [
      'Gennaio', 'Febbraio', 'Marzo', 'Aprile',
      'Maggio', 'Giugno', 'Luglio', 'Agosto',
      'Settembre', 'Ottobre', 'Novembre', 'Dicembre',
    ];
    return '${months[date.month - 1]} ${date.year}';
  }

  List<String> _weekdayLabels(BuildContext context) =>
      ['Lun', 'Mar', 'Mer', 'Gio', 'Ven', 'Sab', 'Dom'];
}

// ─────────────────────────────────────────────────────────────────────────────

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.isToday,
    required this.assignment,
    required this.onTap,
  });

  final int day;
  final bool isToday;
  final ShiftAssignmentEntity? assignment;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final shiftColor = assignment?.displayColor;

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
              Text(
                '$day',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight:
                      isToday ? FontWeight.w800 : FontWeight.w500,
                  color: isToday
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.onSurface,
                ),
              ),
              if (assignment != null) ...[
                const SizedBox(height: 2),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 2,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: shiftColor!.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    _abbreviate(assignment!.profileName ?? '?'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                    overflow: TextOverflow.ellipsis,
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
}
