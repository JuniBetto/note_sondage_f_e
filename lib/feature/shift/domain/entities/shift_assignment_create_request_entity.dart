import 'package:flutter/material.dart';

class ShiftAssignmentCreateRequestEntity {
  const ShiftAssignmentCreateRequestEntity({
    required this.shiftDate,
    this.profileId,
    this.startTime,
    this.endTime,
    this.overnight,
    this.note,
    this.alarmOffsets,
    this.isPublic = false,
    this.teamId,
    this.teamShiftGroupId,
    this.targetUserId,
    this.targetUserName,
    this.contextType,
    this.contextId,
    this.sourceType,
    this.sourceId,
    this.sourceMessageId,
  });

  final DateTime shiftDate;
  final String? profileId;
  final TimeOfDay? startTime;
  final TimeOfDay? endTime;
  final bool? overnight;
  final String? note;
  final List<int>? alarmOffsets;
  final bool isPublic;
  final String? teamId;
  final String? teamShiftGroupId;
  final String? targetUserId;
  final String? targetUserName;
  final String? contextType;
  final String? contextId;
  final String? sourceType;
  final String? sourceId;
  final String? sourceMessageId;
}
