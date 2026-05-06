import 'package:dio/dio.dart';
import 'package:note_sondage/core/network/setup_dio.dart';
import 'package:note_sondage/feature/shift/domain/entities/shift_assignment_entity.dart';
import 'package:note_sondage/feature/shift/domain/entities/shift_profile_entity.dart';
import 'package:note_sondage/feature/shift/infrastructure/data/shift_mapper.dart';
import 'package:flutter/material.dart';

class ShiftRemoteDataSource {
  final Dio _dio;

  ShiftRemoteDataSource({Dio? dio}) : _dio = dio ?? DioClient().dio;

  // ── Profiles ──────────────────────────────────────────────────────────────

  Future<List<ShiftProfileEntity>> getProfiles() async {
    final response = await _dio.get('/api/aggregate/shift/profiles');
    final data = response.data as List<dynamic>? ?? const [];
    return data
        .map((e) => ShiftMapper.profileFromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<ShiftProfileEntity> createProfile({
    required String name,
    required TimeOfDay startTime,
    required TimeOfDay endTime,
    required bool overnight,
    required List<int> alarmOffsets,
    String? color,
    bool isPublic = false,
  }) async {
    final response = await _dio.post(
      '/api/aggregate/shift/profiles',
      data: ShiftMapper.profileToJson(
        name: name,
        startTime: startTime,
        endTime: endTime,
        overnight: overnight,
        alarmOffsets: alarmOffsets,
        color: color,
        isPublic: isPublic,
      ),
    );
    return ShiftMapper.profileFromJson(
      Map<String, dynamic>.from(response.data),
    );
  }

  Future<ShiftProfileEntity> updateProfile(
    String profileId, {
    required String name,
    required TimeOfDay startTime,
    required TimeOfDay endTime,
    required bool overnight,
    required List<int> alarmOffsets,
    String? color,
    bool isPublic = false,
  }) async {
    final response = await _dio.put(
      '/api/aggregate/shift/profiles/$profileId',
      data: ShiftMapper.profileToJson(
        name: name,
        startTime: startTime,
        endTime: endTime,
        overnight: overnight,
        alarmOffsets: alarmOffsets,
        color: color,
        isPublic: isPublic,
      ),
    );
    return ShiftMapper.profileFromJson(
      Map<String, dynamic>.from(response.data),
    );
  }

  Future<void> deleteProfile(String profileId) async {
    await _dio.delete('/api/aggregate/shift/profiles/$profileId');
  }

  // ── Assignments ───────────────────────────────────────────────────────────

  Future<List<ShiftAssignmentEntity>> getAssignments({
    required DateTime from,
    required DateTime to,
  }) async {
    final response = await _dio.get(
      '/api/aggregate/shift/assignments',
      queryParameters: {
        'from': from.toIso8601String().split('T').first,
        'to': to.toIso8601String().split('T').first,
      },
    );
    final data = response.data as List<dynamic>? ?? const [];
    return data
        .map(
          (e) => ShiftMapper.assignmentFromJson(Map<String, dynamic>.from(e)),
        )
        .toList();
  }

  Future<ShiftAssignmentEntity> assign({
    required DateTime shiftDate,
    String? profileId,
    TimeOfDay? startTime,
    TimeOfDay? endTime,
    bool? overnight,
    String? note,
    List<int>? alarmOffsets,
    bool isPublic = false,
    String? teamId,
    String? targetUserId,
  }) async {
    final response = await _dio.post(
      '/api/aggregate/shift/assignments',
      data: ShiftMapper.assignmentToJson(
        shiftDate: shiftDate,
        profileId: profileId,
        startTime: startTime,
        endTime: endTime,
        overnight: overnight,
        note: note,
        alarmOffsets: alarmOffsets,
        isPublic: isPublic,
        teamId: teamId,
        targetFirebaseUid: targetUserId,
      ),
    );
    return ShiftMapper.assignmentFromJson(
      Map<String, dynamic>.from(response.data),
    );
  }

  Future<ShiftAssignmentEntity> updateAssignment(
    String assignmentId, {
    String? profileId,
    TimeOfDay? startTime,
    TimeOfDay? endTime,
    bool? overnight,
    String? note,
    List<int>? alarmOffsets,
    bool isPublic = false,
    String? teamId,
    String? targetUserId,
  }) async {
    final response = await _dio.put(
      '/api/aggregate/shift/assignments/$assignmentId',
      data: ShiftMapper.assignmentToJson(
        shiftDate: DateTime.now(), // ignored by backend on update
        profileId: profileId,
        startTime: startTime,
        endTime: endTime,
        overnight: overnight,
        note: note,
        alarmOffsets: alarmOffsets,
        isPublic: isPublic,
        teamId: teamId,
        targetFirebaseUid: targetUserId,
      ),
    );
    return ShiftMapper.assignmentFromJson(
      Map<String, dynamic>.from(response.data),
    );
  }

  Future<void> deleteAssignment(String assignmentId) async {
    await _dio.delete('/api/aggregate/shift/assignments/$assignmentId');
  }
}
