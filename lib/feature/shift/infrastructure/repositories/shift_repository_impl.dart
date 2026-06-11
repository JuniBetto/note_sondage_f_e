import 'package:flutter/material.dart';
import 'package:note_sondage/feature/shift/domain/entities/shift_assignment_entity.dart';
import 'package:note_sondage/feature/shift/domain/entities/shift_profile_entity.dart';
import 'package:note_sondage/feature/shift/domain/repositories/shift_repository.dart';
import 'package:note_sondage/feature/shift/infrastructure/data_source/shift_local_data_source.dart';
import 'package:note_sondage/feature/shift/infrastructure/data_source/shift_remote_data_source.dart';

class ShiftRepositoryImpl implements ShiftRepository {
  final ShiftLocalDataSource _local;
  final ShiftRemoteDataSource _remote;

  ShiftRepositoryImpl(this._local, this._remote);

  @override
  Future<List<ShiftProfileEntity>> getProfiles() async {
    try {
      final profiles = await _remote.getProfiles();
      await _local.saveProfiles(profiles);
      return profiles;
    } catch (e) {
      final cached = await _local.getProfiles();
      if (cached.isNotEmpty) {
        return cached;
      }
      rethrow;
    }
  }

  @override
  Future<ShiftProfileEntity> createProfile({
    required String name,
    required TimeOfDay startTime,
    required TimeOfDay endTime,
    required bool overnight,
    required List<int> alarmOffsets,
    String? color,
    bool isPublic = false,
  }) async {
    final profile = await _remote.createProfile(
      name: name,
      startTime: startTime,
      endTime: endTime,
      overnight: overnight,
      alarmOffsets: alarmOffsets,
      color: color,
      isPublic: isPublic,
    );
    final cached = await _local.getProfiles();
    await _local.saveProfiles([
      ...cached.where((item) => item.id != profile.id),
      profile,
    ]);
    return profile;
  }

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
  }) async {
    final profile = await _remote.updateProfile(
      profileId,
      name: name,
      startTime: startTime,
      endTime: endTime,
      overnight: overnight,
      alarmOffsets: alarmOffsets,
      color: color,
      isPublic: isPublic,
    );
    final cached = await _local.getProfiles();
    await _local.saveProfiles(
      cached.map((item) => item.id == profile.id ? profile : item).toList(),
    );
    return profile;
  }

  @override
  Future<void> deleteProfile(String profileId) async {
    await _remote.deleteProfile(profileId);
    final cached = await _local.getProfiles();
    await _local.saveProfiles(
      cached.where((item) => item.id != profileId).toList(),
    );
  }

  @override
  Future<List<ShiftAssignmentEntity>> getAssignments({
    required DateTime from,
    required DateTime to,
    List<String>? visibleTeamIds,
    List<String>? visibleUserIds,
  }) async {
    try {
      final assignments = await _remote.getAssignments(
        from: from,
        to: to,
        visibleTeamIds: visibleTeamIds,
        visibleUserIds: visibleUserIds,
      );
      final cached = await _local.getAssignments();
      final requestedDays = <String>{
        for (
          var day = DateTime(from.year, from.month, from.day);
          !day.isAfter(DateTime(to.year, to.month, to.day));
          day = day.add(const Duration(days: 1))
        )
          '${day.year}-${day.month}-${day.day}',
      };
      final preservedOutsideRange = cached.where((assignment) {
        final key =
            '${assignment.shiftDate.year}-${assignment.shiftDate.month}-${assignment.shiftDate.day}';
        return !requestedDays.contains(key);
      }).toList();
      await _local.saveAssignments([...preservedOutsideRange, ...assignments]);
      return assignments;
    } catch (e) {
      final cached = await _local.getAssignments(from: from, to: to);
      if (cached.isNotEmpty) {
        return cached;
      }
      rethrow;
    }
  }

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
    String? teamShiftGroupId,
    String? targetUserId,
  }) async {
    final assignment = await _remote.assign(
      shiftDate: shiftDate,
      profileId: profileId,
      startTime: startTime,
      endTime: endTime,
      overnight: overnight,
      note: note,
      alarmOffsets: alarmOffsets,
      isPublic: isPublic,
      teamId: teamId,
      teamShiftGroupId: teamShiftGroupId,
      targetUserId: targetUserId,
    );
    final cached = await _local.getAssignments();
    await _local.saveAssignments([
      ...cached.where((item) => item.id != assignment.id),
      assignment,
    ]);
    return assignment;
  }

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
    String? teamShiftGroupId,
    String? targetUserId,
  }) async {
    final assignment = await _remote.updateAssignment(
      assignmentId,
      profileId: profileId,
      startTime: startTime,
      endTime: endTime,
      overnight: overnight,
      note: note,
      alarmOffsets: alarmOffsets,
      isPublic: isPublic,
      teamId: teamId,
      teamShiftGroupId: teamShiftGroupId,
      targetUserId: targetUserId,
    );
    final cached = await _local.getAssignments();
    await _local.saveAssignments(
      cached
          .map((item) => item.id == assignment.id ? assignment : item)
          .toList(),
    );
    return assignment;
  }

  @override
  Future<void> deleteAssignment(String assignmentId) async {
    await _remote.deleteAssignment(assignmentId);
    final cached = await _local.getAssignments();
    await _local.saveAssignments(
      cached.where((item) => item.id != assignmentId).toList(),
    );
  }

  @override
  Future<void> requestAssignmentChange(
    String assignmentId, {
    String? profileId,
    TimeOfDay? startTime,
    TimeOfDay? endTime,
    bool? overnight,
    String? note,
    List<int>? alarmOffsets,
  }) {
    return _remote.requestAssignmentChange(
      assignmentId,
      profileId: profileId,
      startTime: startTime,
      endTime: endTime,
      overnight: overnight,
      note: note,
      alarmOffsets: alarmOffsets,
    );
  }
}
