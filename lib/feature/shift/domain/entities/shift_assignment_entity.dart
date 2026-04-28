import 'package:flutter/material.dart';
import 'shift_profile_entity.dart';

/// Mirrors the backend ShiftAssignment entity.
class ShiftAssignmentEntity {
  const ShiftAssignmentEntity({
    required this.id,
    required this.userId,
    required this.shiftDate,
    this.profileId,
    this.profileName,
    this.profileColor,
    required this.startTime,
    required this.endTime,
    required this.overnight,
    this.note,
    required this.alarmOffsets,
    this.profile,
  });

  final String id;
  final String userId;
  final DateTime shiftDate;
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
    TimeOfDay? startTime,
    TimeOfDay? endTime,
    bool? overnight,
    String? note,
    List<int>? alarmOffsets,
    ShiftProfileEntity? profile,
  }) {
    return ShiftAssignmentEntity(
      id: id,
      userId: userId,
      shiftDate: shiftDate,
      profileId: profileId,
      profileName: profileName,
      profileColor: profileColor,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      overnight: overnight ?? this.overnight,
      note: note ?? this.note,
      alarmOffsets: alarmOffsets ?? this.alarmOffsets,
      profile: profile ?? this.profile,
    );
  }
}
