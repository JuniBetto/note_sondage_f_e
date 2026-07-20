import 'package:flutter/material.dart';
import 'package:note_sondage/feature/shift/domain/entities/shift_auto_plan_entity.dart';
import 'package:note_sondage/feature/shift/domain/entities/shift_profile_entity.dart';
import 'package:note_sondage/feature/shift/domain/entities/shift_assignment_entity.dart';
import 'package:note_sondage/feature/shift/domain/entities/shift_assignment_create_request_entity.dart';

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
}
