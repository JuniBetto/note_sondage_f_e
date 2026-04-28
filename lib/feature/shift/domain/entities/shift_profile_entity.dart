import 'package:flutter/material.dart';

/// Mirrors the backend ShiftProfile entity.
class ShiftProfileEntity {
  const ShiftProfileEntity({
    required this.id,
    this.userId,
    required this.name,
    this.color,
    required this.startTime,
    required this.endTime,
    required this.overnight,
    required this.isSystem,
    required this.alarmOffsets,
  });

  final String id;

  /// null → system profile
  final String? userId;
  final String name;

  /// Hex string like '#FFA726'
  final String? color;
  final TimeOfDay startTime;
  final TimeOfDay endTime;

  /// True if the shift ends the next calendar day
  final bool overnight;
  final bool isSystem;

  /// Minutes before startTime (negative values). E.g. [-30, -15]
  final List<int> alarmOffsets;

  ShiftProfileEntity copyWith({
    String? name,
    String? color,
    TimeOfDay? startTime,
    TimeOfDay? endTime,
    bool? overnight,
    List<int>? alarmOffsets,
  }) {
    return ShiftProfileEntity(
      id: id,
      userId: userId,
      name: name ?? this.name,
      color: color ?? this.color,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      overnight: overnight ?? this.overnight,
      isSystem: isSystem,
      alarmOffsets: alarmOffsets ?? this.alarmOffsets,
    );
  }

  Color get displayColor {
    if (color == null) return Colors.blueGrey;
    try {
      final hex = color!.replaceFirst('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (_) {
      return Colors.blueGrey;
    }
  }
}
