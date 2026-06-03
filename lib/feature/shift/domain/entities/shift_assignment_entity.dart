import 'package:flutter/material.dart';
import 'shift_profile_entity.dart';

/// Mirrors the backend ShiftAssignment entity.
class ShiftAssignmentEntity {
  const ShiftAssignmentEntity({
    required this.id,
    required this.userId,
    this.userName,
    required this.shiftDate,
    this.teamId,
    this.teamShiftGroupId,
    this.profileId,
    this.profileName,
    this.profileColor,
    required this.startTime,
    required this.endTime,
    required this.overnight,
    this.note,
    required this.alarmOffsets,
    this.profile,
    this.isPublic = false,
  });

  final String id;
  final String userId;
  final String? userName;
  final DateTime shiftDate;
  final String? teamId;
  final String? teamShiftGroupId;
  final String? profileId;
  final String? profileName;
  final String? profileColor;
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final bool overnight;
  final String? note;
  final List<int> alarmOffsets;

  /// Optional resolved profile (populated client-side for display)
  final ShiftProfileEntity? profile;

  /// True → visible to all team members; False → private (owner only).
  final bool isPublic;

  Color get displayColor {
    final hex = profileColor;
    if (hex == null) return Colors.blueGrey;
    try {
      return Color(int.parse('FF${hex.replaceFirst('#', '')}', radix: 16));
    } catch (_) {
      return Colors.blueGrey;
    }
  }

  ShiftAssignmentEntity copyWith({
    String? userName,
    TimeOfDay? startTime,
    TimeOfDay? endTime,
    bool? overnight,
    String? note,
    List<int>? alarmOffsets,
    ShiftProfileEntity? profile,
    bool? isPublic,
    String? teamId,
    String? teamShiftGroupId,
  }) {
    return ShiftAssignmentEntity(
      id: id,
      userId: userId,
      userName: userName ?? this.userName,
      shiftDate: shiftDate,
      teamId: teamId ?? this.teamId,
      teamShiftGroupId: teamShiftGroupId ?? this.teamShiftGroupId,
      profileId: profileId,
      profileName: profileName,
      profileColor: profileColor,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      overnight: overnight ?? this.overnight,
      note: note ?? this.note,
      alarmOffsets: alarmOffsets ?? this.alarmOffsets,
      profile: profile ?? this.profile,
      isPublic: isPublic ?? this.isPublic,
    );
  }
}
