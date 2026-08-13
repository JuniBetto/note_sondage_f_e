import 'shift_assignment_entity.dart';

enum ShiftAutoPlannerMode { rotation, coverage }

enum ShiftAutoPlanPreviewAction { create, preserve, delete }

enum ShiftAutoPlanIssueSeverity { warning, blocking }

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
    required this.previewItemId,
    this.sourceAssignmentId,
    required this.action,
    required this.assignment,
  });

  final String previewItemId;
  final String? sourceAssignmentId;
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
    required this.issues,
    required this.days,
  });

  final String snapshotToken;
  final bool fullyFeasible;
  final int createdAssignmentsCountPreview;
  final int preservedAssignmentsCount;
  final int deletedAssignmentsCountPreview;
  final int uncoveredSlotsCount;
  final List<String> warnings;
  final List<ShiftAutoPlanIssueEntity> issues;
  final List<ShiftAutoPlanPreviewDayEntity> days;
}

class ShiftAutoPlanIssueEntity {
  const ShiftAutoPlanIssueEntity({
    required this.code,
    required this.severity,
    required this.message,
    this.userId,
    this.shiftDate,
    this.teamId,
    this.profileId,
    this.profileName,
  });

  final String code;
  final ShiftAutoPlanIssueSeverity severity;
  final String message;
  final String? userId;
  final DateTime? shiftDate;
  final String? teamId;
  final String? profileId;
  final String? profileName;
}

class ShiftAutoPlanDraftAssignmentEntity {
  const ShiftAutoPlanDraftAssignmentEntity({
    required this.previewItemId,
    this.sourceAssignmentId,
    required this.assignment,
  });

  final String previewItemId;
  final String? sourceAssignmentId;
  final ShiftAssignmentEntity assignment;

  ShiftAutoPlanDraftAssignmentEntity copyWith({
    String? previewItemId,
    String? sourceAssignmentId,
    ShiftAssignmentEntity? assignment,
  }) {
    return ShiftAutoPlanDraftAssignmentEntity(
      previewItemId: previewItemId ?? this.previewItemId,
      sourceAssignmentId: sourceAssignmentId ?? this.sourceAssignmentId,
      assignment: assignment ?? this.assignment,
    );
  }
}
