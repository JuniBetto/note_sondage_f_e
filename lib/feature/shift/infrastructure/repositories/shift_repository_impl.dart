import 'package:flutter/material.dart';
import 'package:note_sondage/feature/shift/domain/entities/shift_assignment_entity.dart';
import 'package:note_sondage/feature/shift/domain/entities/shift_profile_entity.dart';
import 'package:note_sondage/feature/shift/domain/repositories/shift_repository.dart';
import 'package:note_sondage/feature/shift/infrastructure/data_source/shift_remote_data_source.dart';

class ShiftRepositoryImpl implements ShiftRepository {
  final ShiftRemoteDataSource _remote;

  ShiftRepositoryImpl(this._remote);

  @override
  Future<List<ShiftProfileEntity>> getProfiles() => _remote.getProfiles();

  @override
  Future<ShiftProfileEntity> createProfile({
    required String name,
    required TimeOfDay startTime,
    required TimeOfDay endTime,
    required bool overnight,
    required List<int> alarmOffsets,
    String? color,
    bool isPublic = false,
  }) => _remote.createProfile(
    name: name,
    startTime: startTime,
    endTime: endTime,
    overnight: overnight,
    alarmOffsets: alarmOffsets,
    color: color,
    isPublic: isPublic,
  );

  @override
  Future<ShiftProfileEntity> updateProfile(
    String profileId, {
    required String name,
    required TimeOfDay startTime,
    required TimeOfDay endTime,
    required bool overnight,
    required List<int> alarmOffsets,
    String? color,
    bool isPublic = false,
  }) => _remote.updateProfile(
    profileId,
    name: name,
    startTime: startTime,
    endTime: endTime,
    overnight: overnight,
    alarmOffsets: alarmOffsets,
    color: color,
    isPublic: isPublic,
  );

  @override
  Future<void> deleteProfile(String profileId) =>
      _remote.deleteProfile(profileId);

  @override
  Future<List<ShiftAssignmentEntity>> getAssignments({
    required DateTime from,
    required DateTime to,
  }) => _remote.getAssignments(from: from, to: to);

  @override
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
  }) => _remote.assign(
    shiftDate: shiftDate,
    profileId: profileId,
    startTime: startTime,
    endTime: endTime,
    overnight: overnight,
    note: note,
    alarmOffsets: alarmOffsets,
    isPublic: isPublic,
    teamId: teamId,
    targetUserId: targetUserId,
  );

  @override
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
  }) => _remote.updateAssignment(
    assignmentId,
    profileId: profileId,
    startTime: startTime,
    endTime: endTime,
    overnight: overnight,
    note: note,
    alarmOffsets: alarmOffsets,
    isPublic: isPublic,
    teamId: teamId,
  );

  @override
  Future<void> deleteAssignment(String assignmentId) =>
      _remote.deleteAssignment(assignmentId);
}
