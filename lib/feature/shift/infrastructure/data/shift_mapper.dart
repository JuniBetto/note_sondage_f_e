import 'package:flutter/material.dart';
import 'package:note_sondage/feature/shift/domain/entities/shift_profile_entity.dart';
import 'package:note_sondage/feature/shift/domain/entities/shift_assignment_entity.dart';

class ShiftMapper {
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
      teamId: json['teamId'] as String?,
      profileId: json['profileId'] as String?,
      profileName: json['profileName'] as String?,
      profileColor: json['profileColor'] as String?,
      startTime: _parseTime(json['startTime'] as String),
      endTime: _parseTime(json['endTime'] as String),
      overnight: (json['overnight'] as bool?) ?? false,
      note: json['note'] as String?,
      alarmOffsets: offsets,
      isPublic: (json['isPublic'] as bool?) ?? false,
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
    String? targetFirebaseUid,
  }) {
    String? _fmt(TimeOfDay? t) => t == null
        ? null
        : '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}:00';

    return {
      'shiftDate': shiftDate.toIso8601String().split('T').first,
      if (profileId != null) 'profileId': profileId,
      if (startTime != null) 'startTime': _fmt(startTime),
      if (endTime != null) 'endTime': _fmt(endTime),
      if (overnight != null) 'overnight': overnight,
      if (note != null) 'note': note,
      if (alarmOffsets != null) 'alarmOffsets': alarmOffsets,
      if (teamId != null) 'teamId': teamId,
      'isPublic': isPublic,
      if (targetFirebaseUid != null) 'targetFirebaseUid': targetFirebaseUid,
    };
  }
}
