class ShiftOpenIntent {
  const ShiftOpenIntent({
    this.assignmentId,
    this.shiftDate,
    this.teamId,
    this.targetUserId,
    this.isPublic,
    this.profileName,
    this.startTime,
    this.endTime,
  });

  final String? assignmentId;
  final DateTime? shiftDate;
  final String? teamId;
  final String? targetUserId;
  final bool? isPublic;
  final String? profileName;
  final String? startTime;
  final String? endTime;
}

class ShiftOpenIntentController {
  ShiftOpenIntent? _pendingIntent;

  ShiftOpenIntent? get pendingIntent => _pendingIntent;

  bool get hasPendingIntent => _pendingIntent != null;

  void queue({
    String? assignmentId,
    String? shiftDate,
    String? teamId,
    String? targetUserId,
    String? isPublic,
    String? profileName,
    String? startTime,
    String? endTime,
  }) {
    final normalizedAssignmentId = assignmentId?.trim();
    final normalizedShiftDate = shiftDate?.trim();
    final normalizedTeamId = teamId?.trim();
    final normalizedTargetUserId = targetUserId?.trim();
    final normalizedIsPublic = isPublic?.trim().toLowerCase();
    final normalizedProfileName = profileName?.trim();
    final normalizedStartTime = startTime?.trim();
    final normalizedEndTime = endTime?.trim();
    _pendingIntent = ShiftOpenIntent(
      assignmentId:
          normalizedAssignmentId != null && normalizedAssignmentId.isNotEmpty
              ? normalizedAssignmentId
              : null,
      shiftDate:
          normalizedShiftDate != null && normalizedShiftDate.isNotEmpty
              ? DateTime.tryParse(normalizedShiftDate)
              : null,
      teamId:
          normalizedTeamId != null && normalizedTeamId.isNotEmpty
              ? normalizedTeamId
              : null,
      targetUserId:
          normalizedTargetUserId != null && normalizedTargetUserId.isNotEmpty
              ? normalizedTargetUserId
              : null,
      isPublic: switch (normalizedIsPublic) {
        'true' => true,
        'false' => false,
        _ => null,
      },
      profileName:
          normalizedProfileName != null && normalizedProfileName.isNotEmpty
              ? normalizedProfileName
              : null,
      startTime:
          normalizedStartTime != null && normalizedStartTime.isNotEmpty
              ? normalizedStartTime
              : null,
      endTime:
          normalizedEndTime != null && normalizedEndTime.isNotEmpty
              ? normalizedEndTime
              : null,
    );
  }

  void clear() {
    _pendingIntent = null;
  }
}
