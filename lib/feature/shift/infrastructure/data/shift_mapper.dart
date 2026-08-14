import 'package:flutter/material.dart';
import 'package:note_sondage/feature/shift/domain/entities/shift_auto_plan_entity.dart';
import 'package:note_sondage/feature/shift/domain/entities/shift_profile_entity.dart';
import 'package:note_sondage/feature/shift/domain/entities/shift_assignment_entity.dart';
import 'package:note_sondage/feature/shift/domain/entities/shift_assignment_create_request_entity.dart';
import 'package:note_sondage/feature/shift/domain/entities/shift_replacement_candidate_entity.dart';

class ShiftMapper {
  static String? _nullableString(dynamic value) {
    final normalized = (value as String?)?.trim();
    if (normalized == null || normalized.isEmpty) {
      return null;
    }
    return normalized;
  }

  static TimeOfDay _parseTime(String raw) {
    // Format: "HH:mm:ss" or "HH:mm"
    final parts = raw.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  static TimeOfDay parseTime(String raw) => _parseTime(raw);

  static ShiftProfileEntity profileFromJson(Map<String, dynamic> json) {
    final offsets = (json['alarmOffsets'] as List<dynamic>? ?? [])
        .map((e) => (e as num).toInt())
        .toList();
    return ShiftProfileEntity(
      id: json['id'] as String,
      userId: json['userId'] as String?,
      name: json['name'] as String,
      color: json['color'] as String?,
      startTime: _parseTime(json['startTime'] as String),
      endTime: _parseTime(json['endTime'] as String),
      overnight: (json['overnight'] as bool?) ?? false,
      isSystem: (json['isSystem'] as bool?) ?? false,
      alarmOffsets: offsets,
      isPublic: (json['isPublic'] as bool?) ?? false,
    );
  }

  static ShiftAssignmentEntity assignmentFromJson(Map<String, dynamic> json) {
    final offsets = (json['alarmOffsets'] as List<dynamic>? ?? [])
        .map((e) => (e as num).toInt())
        .toList();
    return ShiftAssignmentEntity(
      id: json['id'] as String,
      userId: json['userId'] as String,
      userName: json['userName'] as String?,
      shiftDate: DateTime.parse(json['shiftDate'] as String),
      teamId: _nullableString(json['teamId']),
      teamShiftGroupId: _nullableString(json['teamShiftGroupId']),
      profileId: _nullableString(json['profileId']),
      profileName: json['profileName'] as String?,
      profileColor: json['profileColor'] as String?,
      startTime: _parseTime(json['startTime'] as String),
      endTime: _parseTime(json['endTime'] as String),
      overnight: (json['overnight'] as bool?) ?? false,
      note: json['note'] as String?,
      alarmOffsets: offsets,
      isPublic: (json['isPublic'] as bool?) ?? false,
      memberEditUnlocked: (json['memberEditUnlocked'] as bool?) ?? false,
      memberChangeRequestPending:
          (json['memberChangeRequestPending'] as bool?) ?? false,
    );
  }

  static Map<String, dynamic> profileToJson({
    required String name,
    required TimeOfDay startTime,
    required TimeOfDay endTime,
    required bool overnight,
    required List<int> alarmOffsets,
    String? color,
    bool isPublic = false,
  }) {
    return {
      'name': name,
      'color': color,
      'startTime':
          '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}:00',
      'endTime':
          '${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}:00',
      'overnight': overnight,
      'alarmOffsets': alarmOffsets,
      'isPublic': isPublic,
    };
  }

  static Map<String, dynamic> assignmentToJson({
    required DateTime shiftDate,
    String? profileId,
    TimeOfDay? startTime,
    TimeOfDay? endTime,
    bool? overnight,
    String? note,
    List<int>? alarmOffsets,
    bool isPublic = false,
    String? teamId,
    String? teamShiftGroupId,
    String? targetFirebaseUid,
  }) {
    String? formatTime(TimeOfDay? t) => t == null
        ? null
        : '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}:00';

    return {
      'shiftDate': shiftDate.toIso8601String().split('T').first,
      if (profileId != null) 'profileId': profileId,
      if (startTime != null) 'startTime': formatTime(startTime),
      if (endTime != null) 'endTime': formatTime(endTime),
      if (overnight != null) 'overnight': overnight,
      if (note != null) 'note': note,
      if (alarmOffsets != null) 'alarmOffsets': alarmOffsets,
      if (teamId != null) 'teamId': teamId,
      if (teamShiftGroupId != null) 'teamShiftGroupId': teamShiftGroupId,
      'isPublic': isPublic,
      if (targetFirebaseUid != null) 'targetFirebaseUid': targetFirebaseUid,
    };
  }

  static Map<String, dynamic> assignmentCreateRequestToJson(
    ShiftAssignmentCreateRequestEntity request,
  ) {
    return assignmentToJson(
      shiftDate: request.shiftDate,
      profileId: request.profileId,
      startTime: request.startTime,
      endTime: request.endTime,
      overnight: request.overnight,
      note: request.note,
      alarmOffsets: request.alarmOffsets,
      isPublic: request.isPublic,
      teamId: request.teamId,
      teamShiftGroupId: request.teamShiftGroupId,
      targetFirebaseUid: request.targetUserId,
    );
  }

  static Map<String, dynamic> autoPlanRequestToJson(
    ShiftAutoPlanRequestEntity request,
  ) {
    return {
      'teamId': request.teamId,
      'from': request.from.toIso8601String().split('T').first,
      'to': request.to.toIso8601String().split('T').first,
      'plannerMode': switch (request.plannerMode) {
        ShiftAutoPlannerMode.coverage => 'COVERAGE',
        ShiftAutoPlannerMode.rotation => 'ROTATION',
      },
      'replaceExistingAssignments': request.replaceExistingAssignments,
      'templates': request.templates
          .map(
            (template) => {
              'profileId': template.profileId,
              'requiredMemberCount': template.requiredMemberCount,
              if (template.simultaneousMemberCount != null)
                'simultaneousMemberCount': template.simultaneousMemberCount,
            },
          )
          .toList(),
    };
  }

  static ShiftAutoPlanResultEntity autoPlanResultFromJson(
    Map<String, dynamic> json,
  ) {
    return ShiftAutoPlanResultEntity(
      createdAssignmentsCount:
          (json['createdAssignmentsCount'] as num?)?.toInt() ?? 0,
      preservedAssignmentsCount:
          (json['preservedAssignmentsCount'] as num?)?.toInt() ?? 0,
      uncoveredSlotsCount: (json['uncoveredSlotsCount'] as num?)?.toInt() ?? 0,
      warnings: (json['warnings'] as List<dynamic>? ?? const [])
          .map((item) => item.toString())
          .toList(),
    );
  }

  static ShiftAutoPlanPreviewEntity autoPlanPreviewFromJson(
    Map<String, dynamic> json,
  ) {
    return ShiftAutoPlanPreviewEntity(
      snapshotToken: (json['snapshotToken'] as String?) ?? '',
      fullyFeasible: (json['fullyFeasible'] as bool?) ?? false,
      createdAssignmentsCountPreview:
          (json['createdAssignmentsCountPreview'] as num?)?.toInt() ?? 0,
      preservedAssignmentsCount:
          (json['preservedAssignmentsCount'] as num?)?.toInt() ?? 0,
      deletedAssignmentsCountPreview:
          (json['deletedAssignmentsCountPreview'] as num?)?.toInt() ?? 0,
      uncoveredSlotsCount: (json['uncoveredSlotsCount'] as num?)?.toInt() ?? 0,
      warnings: (json['warnings'] as List<dynamic>? ?? const [])
          .map((item) => item.toString())
          .toList(),
      issues: (json['issues'] as List<dynamic>? ?? const [])
          .map(
            (item) =>
                autoPlanIssueFromJson(Map<String, dynamic>.from(item as Map)),
          )
          .toList(),
      days: (json['days'] as List<dynamic>? ?? const [])
          .map(
            (item) => autoPlanPreviewDayFromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList(),
    );
  }

  static ShiftAutoPlanPreviewDayEntity autoPlanPreviewDayFromJson(
    Map<String, dynamic> json,
  ) {
    return ShiftAutoPlanPreviewDayEntity(
      date: DateTime.parse(json['date'] as String),
      items: (json['items'] as List<dynamic>? ?? const [])
          .map(
            (item) => autoPlanPreviewAssignmentFromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList(),
    );
  }

  static ShiftAutoPlanPreviewAssignmentEntity autoPlanPreviewAssignmentFromJson(
    Map<String, dynamic> json,
  ) {
    final rawAction = (json['action'] as String?)?.trim().toUpperCase();
    final action = switch (rawAction) {
      'DELETE' => ShiftAutoPlanPreviewAction.delete,
      'PRESERVE' => ShiftAutoPlanPreviewAction.preserve,
      _ => ShiftAutoPlanPreviewAction.create,
    };
    return ShiftAutoPlanPreviewAssignmentEntity(
      previewItemId: (json['previewItemId'] as String?) ?? '',
      sourceAssignmentId: _nullableString(json['sourceAssignmentId']),
      action: action,
      assignment: assignmentFromJson(
        Map<String, dynamic>.from(json['assignment'] as Map),
      ),
    );
  }

  static ShiftAutoPlanIssueEntity autoPlanIssueFromJson(
    Map<String, dynamic> json,
  ) {
    final rawSeverity = (json['severity'] as String?)?.trim().toUpperCase();
    final severity = switch (rawSeverity) {
      'BLOCKING' => ShiftAutoPlanIssueSeverity.blocking,
      _ => ShiftAutoPlanIssueSeverity.warning,
    };
    final shiftDateRaw = _nullableString(json['shiftDate']);
    return ShiftAutoPlanIssueEntity(
      code: (json['code'] as String?) ?? '',
      severity: severity,
      message: (json['message'] as String?) ?? '',
      userId: _nullableString(json['userId']),
      shiftDate: shiftDateRaw == null ? null : DateTime.parse(shiftDateRaw),
      teamId: _nullableString(json['teamId']),
      profileId: _nullableString(json['profileId']),
      profileName: _nullableString(json['profileName']),
    );
  }

  static ShiftReplacementCandidatesEntity replacementCandidatesFromJson(
    Map<String, dynamic> json,
  ) {
    return ShiftReplacementCandidatesEntity(
      assignmentId: (json['assignmentId'] as String?) ?? '',
      teamId: _nullableString(json['teamId']),
      teamName: _nullableString(json['teamName']),
      sourceUserId: _nullableString(json['sourceUserFirebaseUid']),
      sourceUserDisplayName: _nullableString(json['sourceUserDisplayName']),
      shiftDate: DateTime.parse(json['shiftDate'] as String),
      startTime: _parseTime(json['startTime'] as String),
      endTime: _parseTime(json['endTime'] as String),
      overnight: (json['overnight'] as bool?) ?? false,
      hasCompatibleCandidates:
          (json['hasCompatibleCandidates'] as bool?) ?? false,
      candidates: (json['candidates'] as List<dynamic>? ?? const [])
          .map(
            (item) => replacementCandidateFromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList(),
    );
  }

  static ShiftReplacementCandidateEntity replacementCandidateFromJson(
    Map<String, dynamic> json,
  ) {
    return ShiftReplacementCandidateEntity(
      userId: (json['firebaseUid'] as String?) ?? '',
      email: _nullableString(json['email']),
      fullName: _nullableString(json['fullName']),
      avatarUrl: _nullableString(json['avatarUrl']),
      role: _nullableString(json['role']),
      compatible: (json['compatible'] as bool?) ?? false,
      incompatibilities:
          (json['incompatibilities'] as List<dynamic>? ?? const [])
              .map(
                (item) => replacementCandidateIssueFromJson(
                  Map<String, dynamic>.from(item as Map),
                ),
              )
              .toList(),
    );
  }

  static ShiftReplacementCandidateIssueEntity replacementCandidateIssueFromJson(
    Map<String, dynamic> json,
  ) {
    return ShiftReplacementCandidateIssueEntity(
      code: (json['code'] as String?) ?? '',
      message: (json['message'] as String?) ?? '',
    );
  }

  static Map<String, dynamic> autoPlanPreviewDraftAssignmentToJson(
    ShiftAutoPlanDraftAssignmentEntity assignment,
  ) {
    String formatTime(TimeOfDay t) =>
        '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}:00';
    return {
      'previewItemId': assignment.previewItemId,
      if (assignment.sourceAssignmentId != null)
        'sourceAssignmentId': assignment.sourceAssignmentId,
      'userId': assignment.assignment.userId,
      'shiftDate': assignment.assignment.shiftDate
          .toIso8601String()
          .split('T')
          .first,
      if (assignment.assignment.profileId != null)
        'profileId': assignment.assignment.profileId,
      if (assignment.assignment.profileName != null)
        'profileName': assignment.assignment.profileName,
      if (assignment.assignment.profileColor != null)
        'profileColor': assignment.assignment.profileColor,
      'startTime': formatTime(assignment.assignment.startTime),
      'endTime': formatTime(assignment.assignment.endTime),
      'overnight': assignment.assignment.overnight,
      if (assignment.assignment.note != null)
        'note': assignment.assignment.note,
      'alarmOffsets': assignment.assignment.alarmOffsets,
      if (assignment.assignment.teamShiftGroupId != null)
        'teamShiftGroupId': assignment.assignment.teamShiftGroupId,
      'memberEditUnlocked': assignment.assignment.memberEditUnlocked,
      'memberChangeRequestPending':
          assignment.assignment.memberChangeRequestPending,
    };
  }
}
