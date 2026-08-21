import '../entities/shift_profile_entity.dart';
import '../entities/shift_assignment_entity.dart';
import '../entities/shift_assignment_create_request_entity.dart';
import '../entities/shift_availability_sondage_draft_request_entity.dart';
import '../entities/shift_auto_plan_entity.dart';
import '../entities/shift_replacement_candidate_entity.dart';
import 'package:flutter/material.dart';
import 'package:note_sondage/feature/sondage/domain/entities/sondage_entity.dart';

abstract class ShiftRepository {
  Future<List<ShiftProfileEntity>> getProfiles();

  Future<ShiftProfileEntity> createProfile({
    required String name,
    required TimeOfDay startTime,
    required TimeOfDay endTime,
    required bool overnight,
    required List<int> alarmOffsets,
    String? color,
    bool isPublic = false,
  });

  Future<ShiftProfileEntity> updateProfile(
    String profileId, {
    required String name,
    required TimeOfDay startTime,
    required TimeOfDay endTime,
    required bool overnight,
    required List<int> alarmOffsets,
    String? color,
    bool isPublic = false,
  });

  Future<void> deleteProfile(String profileId);

  Future<List<ShiftAssignmentEntity>> getAssignments({
    required DateTime from,
    required DateTime to,
    List<String>? visibleTeamIds,
    List<String>? visibleUserIds,
  });

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
  });

  Future<List<ShiftAssignmentEntity>> assignBatch({
    required List<ShiftAssignmentCreateRequestEntity> requests,
  });

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
  });

  Future<void> deleteAssignment(String assignmentId);

  Future<void> requestAssignmentChange(
    String assignmentId, {
    String? profileId,
    TimeOfDay? startTime,
    TimeOfDay? endTime,
    bool? overnight,
    String? note,
    List<int>? alarmOffsets,
  });

  Future<void> requestAssignmentSwap(
    String assignmentId, {
    required String candidateUserId,
    String? note,
  });

  Future<ShiftReplacementCandidatesEntity> findReplacementCandidates(
    String assignmentId,
  );

  Future<void> offerReplacement(
    String assignmentId, {
    required String candidateFirebaseUid,
  });

  Future<SondageEntity> createAvailabilitySondageDraft(
    String assignmentId,
    ShiftAvailabilitySondageDraftRequestEntity request,
  );

  Future<ShiftAutoPlanResultEntity> autoPlan(
    ShiftAutoPlanRequestEntity request,
  );

  Future<ShiftAutoPlanPreviewEntity> previewAutoPlan(
    ShiftAutoPlanRequestEntity request,
  );

  Future<ShiftAutoPlanPreviewEntity> recalculateAutoPlanPreview(
    String snapshotToken,
    List<ShiftAutoPlanDraftAssignmentEntity> draftAssignments,
  );

  Future<ShiftAutoPlanResultEntity> confirmAutoPlan(String snapshotToken);
}
