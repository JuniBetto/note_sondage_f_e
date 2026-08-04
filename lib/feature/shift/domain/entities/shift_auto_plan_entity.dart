import 'shift_assignment_entity.dart';

enum ShiftAutoPlannerMode { rotation, coverage }

enum ShiftAutoPlanPreviewAction { create, preserve, delete }

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

class ShiftAutoPlanPreviewAssignmentEntity {
  const ShiftAutoPlanPreviewAssignmentEntity({
    required this.action,
    required this.assignment,
  });

  final ShiftAutoPlanPreviewAction action;
  final ShiftAssignmentEntity assignment;
}

class ShiftAutoPlanPreviewDayEntity {
  const ShiftAutoPlanPreviewDayEntity({
    required this.date,
    required this.items,
  });

  final DateTime date;
  final List<ShiftAutoPlanPreviewAssignmentEntity> items;
}

class ShiftAutoPlanPreviewEntity {
  const ShiftAutoPlanPreviewEntity({
    required this.snapshotToken,
    required this.fullyFeasible,
    required this.createdAssignmentsCountPreview,
    required this.preservedAssignmentsCount,
    required this.deletedAssignmentsCountPreview,
    required this.uncoveredSlotsCount,
    required this.warnings,
    required this.days,
  });

  final String snapshotToken;
  final bool fullyFeasible;
  final int createdAssignmentsCountPreview;
  final int preservedAssignmentsCount;
  final int deletedAssignmentsCountPreview;
  final int uncoveredSlotsCount;
  final List<String> warnings;
  final List<ShiftAutoPlanPreviewDayEntity> days;
}
