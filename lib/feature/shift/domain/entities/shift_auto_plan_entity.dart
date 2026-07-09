enum ShiftAutoPlannerMode { rotation, coverage }

class ShiftAutoPlanTemplateEntity {
  const ShiftAutoPlanTemplateEntity({
    required this.profileId,
    required this.requiredMemberCount,
    this.simultaneousMemberCount,
  });

  final String profileId;
  final int requiredMemberCount;
  final int? simultaneousMemberCount;
}

class ShiftAutoPlanRequestEntity {
  const ShiftAutoPlanRequestEntity({
    required this.teamId,
    required this.from,
    required this.to,
    required this.plannerMode,
    required this.replaceExistingAssignments,
    required this.templates,
  });

  final String teamId;
  final DateTime from;
  final DateTime to;
  final ShiftAutoPlannerMode plannerMode;
  final bool replaceExistingAssignments;
  final List<ShiftAutoPlanTemplateEntity> templates;
}

class ShiftAutoPlanResultEntity {
  const ShiftAutoPlanResultEntity({
    required this.createdAssignmentsCount,
    required this.preservedAssignmentsCount,
    required this.uncoveredSlotsCount,
    required this.warnings,
  });

  final int createdAssignmentsCount;
  final int preservedAssignmentsCount;
  final int uncoveredSlotsCount;
  final List<String> warnings;
}
