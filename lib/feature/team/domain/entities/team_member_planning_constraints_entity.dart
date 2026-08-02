class TeamMemberPlanningConstraintsEntity {
  const TeamMemberPlanningConstraintsEntity({
    this.workerType,
    this.availableWeekdays = const <String>[],
    this.preferredShiftTypes = const <String>[],
    this.blockedShiftTypes = const <String>[],
    this.unavailableDateRanges = const <String>[],
    this.minDailyHours,
    this.maxDailyHours,
    this.maxWeeklyHours,
    this.maxMonthlyHours,
    this.overtimeAllowed,
    this.avoidConsecutiveShifts,
    this.requiresCoworkerPresence,
    this.minRestHoursBetweenShifts,
    this.maxConsecutiveNightShifts,
    this.maxConsecutiveWeekendShifts,
    this.notes,
  });

  final String? workerType;
  final List<String> availableWeekdays;
  final List<String> preferredShiftTypes;
  final List<String> blockedShiftTypes;
  final List<String> unavailableDateRanges;
  final int? minDailyHours;
  final int? maxDailyHours;
  final int? maxWeeklyHours;
  final int? maxMonthlyHours;
  final bool? overtimeAllowed;
  final bool? avoidConsecutiveShifts;
  final bool? requiresCoworkerPresence;
  final int? minRestHoursBetweenShifts;
  final int? maxConsecutiveNightShifts;
  final int? maxConsecutiveWeekendShifts;
  final String? notes;

  TeamMemberPlanningConstraintsEntity copyWith({
    String? workerType,
    List<String>? availableWeekdays,
    List<String>? preferredShiftTypes,
    List<String>? blockedShiftTypes,
    List<String>? unavailableDateRanges,
    int? minDailyHours,
    int? maxDailyHours,
    int? maxWeeklyHours,
    int? maxMonthlyHours,
    bool? overtimeAllowed,
    bool? avoidConsecutiveShifts,
    bool? requiresCoworkerPresence,
    int? minRestHoursBetweenShifts,
    int? maxConsecutiveNightShifts,
    int? maxConsecutiveWeekendShifts,
    String? notes,
  }) {
    return TeamMemberPlanningConstraintsEntity(
      workerType: workerType ?? this.workerType,
      availableWeekdays: availableWeekdays ?? this.availableWeekdays,
      preferredShiftTypes: preferredShiftTypes ?? this.preferredShiftTypes,
      blockedShiftTypes: blockedShiftTypes ?? this.blockedShiftTypes,
      unavailableDateRanges:
          unavailableDateRanges ?? this.unavailableDateRanges,
      minDailyHours: minDailyHours ?? this.minDailyHours,
      maxDailyHours: maxDailyHours ?? this.maxDailyHours,
      maxWeeklyHours: maxWeeklyHours ?? this.maxWeeklyHours,
      maxMonthlyHours: maxMonthlyHours ?? this.maxMonthlyHours,
      overtimeAllowed: overtimeAllowed ?? this.overtimeAllowed,
      avoidConsecutiveShifts:
          avoidConsecutiveShifts ?? this.avoidConsecutiveShifts,
      requiresCoworkerPresence:
          requiresCoworkerPresence ?? this.requiresCoworkerPresence,
      minRestHoursBetweenShifts:
          minRestHoursBetweenShifts ?? this.minRestHoursBetweenShifts,
      maxConsecutiveNightShifts:
          maxConsecutiveNightShifts ?? this.maxConsecutiveNightShifts,
      maxConsecutiveWeekendShifts:
          maxConsecutiveWeekendShifts ?? this.maxConsecutiveWeekendShifts,
      notes: notes ?? this.notes,
    );
  }
}
