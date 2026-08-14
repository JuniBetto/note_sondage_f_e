class ShiftOpenIntent {
  const ShiftOpenIntent({
    this.assignmentId,
    this.shiftDate,
    this.teamId,
    this.preferredUserIds = const [],
    this.autoReplaceFromWorkflow = false,
    this.targetUserId,
    this.isPublic,
    this.profileName,
    this.startTime,
    this.endTime,
    this.openDayEntriesWhenAssignmentMissing = false,
    this.openDialogWhenAssignmentMissing = false,
  });

  final String? assignmentId;
  final DateTime? shiftDate;
  final String? teamId;
  final List<String> preferredUserIds;
  final bool autoReplaceFromWorkflow;
  final String? targetUserId;
  final bool? isPublic;
  final String? profileName;
  final String? startTime;
  final String? endTime;
  final bool openDayEntriesWhenAssignmentMissing;
  final bool openDialogWhenAssignmentMissing;
}

class ShiftOpenIntentController {
  ShiftOpenIntent? _pendingIntent;

  ShiftOpenIntent? get pendingIntent => _pendingIntent;

  bool get hasPendingIntent => _pendingIntent != null;

  void queue({
    String? assignmentId,
    String? shiftDate,
    String? teamId,
    List<String>? preferredUserIds,
    bool autoReplaceFromWorkflow = false,
    String? targetUserId,
    String? isPublic,
    String? profileName,
    String? startTime,
    String? endTime,
    bool openDayEntriesWhenAssignmentMissing = false,
    bool openDialogWhenAssignmentMissing = false,
  }) {
    final normalizedAssignmentId = assignmentId?.trim();
    final normalizedShiftDate = shiftDate?.trim();
    final normalizedTeamId = teamId?.trim();
    final normalizedPreferredUserIds = (preferredUserIds ?? const <String>[])
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toSet()
        .toList(growable: false);
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
      shiftDate: normalizedShiftDate != null && normalizedShiftDate.isNotEmpty
          ? DateTime.tryParse(normalizedShiftDate)
          : null,
      teamId: normalizedTeamId != null && normalizedTeamId.isNotEmpty
          ? normalizedTeamId
          : null,
      preferredUserIds: normalizedPreferredUserIds,
      autoReplaceFromWorkflow: autoReplaceFromWorkflow,
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
      startTime: normalizedStartTime != null && normalizedStartTime.isNotEmpty
          ? normalizedStartTime
          : null,
      endTime: normalizedEndTime != null && normalizedEndTime.isNotEmpty
          ? normalizedEndTime
          : null,
      openDayEntriesWhenAssignmentMissing: openDayEntriesWhenAssignmentMissing,
      openDialogWhenAssignmentMissing: openDialogWhenAssignmentMissing,
    );
  }

  void clear() {
    _pendingIntent = null;
  }
}
