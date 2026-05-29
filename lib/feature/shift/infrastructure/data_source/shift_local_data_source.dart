import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:note_sondage/feature/shift/domain/entities/shift_assignment_entity.dart';
import 'package:note_sondage/feature/shift/domain/entities/shift_profile_entity.dart';

class ShiftLocalDataSource {
  static const String _profilesBoxPrefix = 'shift_profiles_box';
  static const String _assignmentsBoxPrefix = 'shift_assignments_box';
  static const String _profilesKey = 'profiles';
  static const String _assignmentsKey = 'assignments';

  String _suffix() {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null || userId.isEmpty) {
      return 'anonymous';
    }
    return userId;
  }

  String get _profilesBoxName => '${_profilesBoxPrefix}_${_suffix()}';
  String get _assignmentsBoxName => '${_assignmentsBoxPrefix}_${_suffix()}';

  Future<Box<String>> _openProfilesBox() async {
    if (Hive.isBoxOpen(_profilesBoxName)) {
      return Hive.box<String>(_profilesBoxName);
    }
    return Hive.openBox<String>(_profilesBoxName);
  }

  Future<Box<String>> _openAssignmentsBox() async {
    if (Hive.isBoxOpen(_assignmentsBoxName)) {
      return Hive.box<String>(_assignmentsBoxName);
    }
    return Hive.openBox<String>(_assignmentsBoxName);
  }

  Future<void> saveProfiles(List<ShiftProfileEntity> profiles) async {
    final box = await _openProfilesBox();
    final payload = profiles
        .map(
          (profile) => <String, dynamic>{
            'id': profile.id,
            'userId': profile.userId,
            'name': profile.name,
            'color': profile.color,
            'startTime': _formatTime(profile.startTime),
            'endTime': _formatTime(profile.endTime),
            'overnight': profile.overnight,
            'isSystem': profile.isSystem,
            'alarmOffsets': profile.alarmOffsets,
            'isPublic': profile.isPublic,
          },
        )
        .toList();
    await box.put(_profilesKey, jsonEncode(payload));
  }

  Future<List<ShiftProfileEntity>> getProfiles() async {
    final box = await _openProfilesBox();
    final raw = box.get(_profilesKey);
    if (raw == null || raw.isEmpty) {
      return const <ShiftProfileEntity>[];
    }
    final decoded = jsonDecode(raw);
    if (decoded is! List) {
      return const <ShiftProfileEntity>[];
    }
    return decoded.whereType<Map>().map((item) {
      final map = item.map((key, value) => MapEntry(key.toString(), value));
      return ShiftProfileEntity(
        id: map['id'] as String,
        userId: map['userId'] as String?,
        name: map['name'] as String,
        color: map['color'] as String?,
        startTime: _parseTime(map['startTime'] as String),
        endTime: _parseTime(map['endTime'] as String),
        overnight: (map['overnight'] as bool?) ?? false,
        isSystem: (map['isSystem'] as bool?) ?? false,
        alarmOffsets: (map['alarmOffsets'] as List<dynamic>? ?? const [])
            .map((e) => (e as num).toInt())
            .toList(),
        isPublic: (map['isPublic'] as bool?) ?? false,
      );
    }).toList();
  }

  Future<void> saveAssignments(List<ShiftAssignmentEntity> assignments) async {
    final box = await _openAssignmentsBox();
    final payload = assignments
        .map(
          (assignment) => <String, dynamic>{
            'id': assignment.id,
            'userId': assignment.userId,
            'userName': assignment.userName,
            'shiftDate': assignment.shiftDate.toIso8601String(),
            'teamId': assignment.teamId,
            'teamShiftGroupId': assignment.teamShiftGroupId,
            'profileId': assignment.profileId,
            'profileName': assignment.profileName,
            'profileColor': assignment.profileColor,
            'startTime': _formatTime(assignment.startTime),
            'endTime': _formatTime(assignment.endTime),
            'overnight': assignment.overnight,
            'note': assignment.note,
            'alarmOffsets': assignment.alarmOffsets,
            'isPublic': assignment.isPublic,
          },
        )
        .toList();
    await box.put(_assignmentsKey, jsonEncode(payload));
  }

  Future<List<ShiftAssignmentEntity>> getAssignments({
    DateTime? from,
    DateTime? to,
  }) async {
    final box = await _openAssignmentsBox();
    final raw = box.get(_assignmentsKey);
    if (raw == null || raw.isEmpty) {
      return const <ShiftAssignmentEntity>[];
    }
    final decoded = jsonDecode(raw);
    if (decoded is! List) {
      return const <ShiftAssignmentEntity>[];
    }
    final assignments = decoded.whereType<Map>().map((item) {
      final map = item.map((key, value) => MapEntry(key.toString(), value));
      return ShiftAssignmentEntity(
        id: map['id'] as String,
        userId: map['userId'] as String,
        userName: map['userName'] as String?,
        shiftDate: DateTime.parse(map['shiftDate'] as String),
        teamId: map['teamId'] as String?,
        teamShiftGroupId: map['teamShiftGroupId'] as String?,
        profileId: map['profileId'] as String?,
        profileName: map['profileName'] as String?,
        profileColor: map['profileColor'] as String?,
        startTime: _parseTime(map['startTime'] as String),
        endTime: _parseTime(map['endTime'] as String),
        overnight: (map['overnight'] as bool?) ?? false,
        note: map['note'] as String?,
        alarmOffsets: (map['alarmOffsets'] as List<dynamic>? ?? const [])
            .map((e) => (e as num).toInt())
            .toList(),
        isPublic: (map['isPublic'] as bool?) ?? false,
      );
    }).toList();

    if (from == null && to == null) {
      return assignments;
    }

    return assignments.where((assignment) {
      final day = DateTime(
        assignment.shiftDate.year,
        assignment.shiftDate.month,
        assignment.shiftDate.day,
      );
      if (from != null) {
        final start = DateTime(from.year, from.month, from.day);
        if (day.isBefore(start)) {
          return false;
        }
      }
      if (to != null) {
        final end = DateTime(to.year, to.month, to.day);
        if (day.isAfter(end)) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  String _formatTime(TimeOfDay time) =>
      '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:00';

  TimeOfDay _parseTime(String raw) {
    final parts = raw.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }
}
