import 'package:note_sondage/feature/shift/domain/entities/shift_assignment_entity.dart';

DateTime _normalizeDate(DateTime value) =>
    DateTime(value.year, value.month, value.day);

Iterable<DateTime> visibleDatesForAssignment(
  ShiftAssignmentEntity assignment,
) sync* {
  final shiftDate = _normalizeDate(assignment.shiftDate);
  yield shiftDate;
  if (assignment.overnight) {
    yield shiftDate.add(const Duration(days: 1));
  }
}

bool isAssignmentVisibleOnDate(
  ShiftAssignmentEntity assignment,
  DateTime date,
) {
  final normalizedDate = _normalizeDate(date);
  return visibleDatesForAssignment(
    assignment,
  ).any((candidateDate) => candidateDate == normalizedDate);
}
