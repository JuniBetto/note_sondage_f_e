import 'package:flutter/material.dart';
import 'package:note_sondage/feature/shift/domain/entities/shift_assignment_entity.dart';
import 'package:note_sondage/feature/shift/ui/widgets/shift_calendar_widget.dart';

class ShiftAutoPlanPreviewCalendarCard extends StatelessWidget {
  const ShiftAutoPlanPreviewCalendarCard({
    super.key,
    required this.compact,
    required this.assignments,
    required this.focusedMonth,
    required this.onMonthChanged,
    required this.onDayTap,
    required this.emptyMessage,
  });

  final bool compact;
  final List<ShiftAssignmentEntity> assignments;
  final DateTime focusedMonth;
  final ValueChanged<DateTime> onMonthChanged;
  final void Function(DateTime date) onDayTap;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: theme.dividerColor.withValues(alpha: 0.18)),
      ),
      child: Padding(
        padding: EdgeInsets.all(compact ? 10 : 16),
        child: assignments.isEmpty
            ? Padding(
                padding: EdgeInsets.all(compact ? 6 : 4),
                child: Text(emptyMessage, style: theme.textTheme.bodyMedium),
              )
            : ShiftCalendarWidget(
                assignments: assignments,
                focusedMonth: focusedMonth,
                onMonthChanged: onMonthChanged,
                onDayTap: (date, _) => onDayTap(date),
              ),
      ),
    );
  }
}
