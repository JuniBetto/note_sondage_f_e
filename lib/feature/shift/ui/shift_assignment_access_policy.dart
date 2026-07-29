import 'package:note_sondage/feature/shift/domain/entities/shift_assignment_entity.dart';

class ShiftAssignmentAccessPolicy {
  const ShiftAssignmentAccessPolicy._();

  static String? normalizedTeamId(String? teamId) {
    final value = teamId?.trim();
    if (value == null || value.isEmpty) {
      return null;
    }
    return value;
  }

  static bool hasTeamScope(ShiftAssignmentEntity assignment) {
    return normalizedTeamId(assignment.teamId) != null;
  }

  static bool belongsToAvailableTeam(
    ShiftAssignmentEntity assignment, {
    required Iterable<String> availableTeamIds,
  }) {
    final assignmentTeamId = normalizedTeamId(assignment.teamId);
    if (assignmentTeamId == null) {
      return true;
    }

    final availableIds = availableTeamIds
        .map((teamId) => normalizedTeamId(teamId))
        .whereType<String>()
        .toSet();
    return availableIds.contains(assignmentTeamId);
  }

  static bool isVisibleWithAvailableTeams(
    ShiftAssignmentEntity assignment, {
    required Iterable<String> availableTeamIds,
  }) {
    return belongsToAvailableTeam(
      assignment,
      availableTeamIds: availableTeamIds,
    );
  }

  static bool isOwnedByCurrentUser(
    ShiftAssignmentEntity assignment, {
    required String currentUserId,
  }) {
    final normalizedCurrentUserId = currentUserId.trim();
    final normalizedAssignmentUserId = assignment.userId.trim();
    if (normalizedCurrentUserId.isEmpty || normalizedAssignmentUserId.isEmpty) {
      return false;
    }
    return normalizedCurrentUserId == normalizedAssignmentUserId;
  }

  static bool canManageAssignment(
    ShiftAssignmentEntity assignment, {
    required String currentUserId,
    required Iterable<String> manageableTeamIds,
  }) {
    if (!assignment.isPublic) {
      return isOwnedByCurrentUser(assignment, currentUserId: currentUserId);
    }

    final assignmentTeamId = normalizedTeamId(assignment.teamId);
    if (assignmentTeamId == null) {
      return isOwnedByCurrentUser(assignment, currentUserId: currentUserId);
    }

    final manageableIds = manageableTeamIds
        .map((teamId) => normalizedTeamId(teamId))
        .whereType<String>()
        .toSet();
    return manageableIds.contains(assignmentTeamId);
  }

  static bool canRequestAssignmentChange(
    ShiftAssignmentEntity assignment, {
    required String currentUserId,
    required bool canManageAssignment,
  }) {
    return assignment.isPublic &&
        hasTeamScope(assignment) &&
        isOwnedByCurrentUser(assignment, currentUserId: currentUserId) &&
        !assignment.memberEditUnlocked &&
        !canManageAssignment;
  }

  static bool canEditApprovedAssignment(
    ShiftAssignmentEntity assignment, {
    required String currentUserId,
    required bool canManageAssignment,
  }) {
    return assignment.isPublic &&
        hasTeamScope(assignment) &&
        isOwnedByCurrentUser(assignment, currentUserId: currentUserId) &&
        assignment.memberEditUnlocked &&
        !canManageAssignment;
  }
}
