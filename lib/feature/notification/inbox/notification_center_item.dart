import 'package:equatable/equatable.dart';
import 'package:note_sondage/feature/notification/realtime/realtime_notification_model.dart';
import 'package:note_sondage/feature/notification/shared/workflow_context_metadata.dart';

class NotificationCenterItem extends Equatable {
  const NotificationCenterItem({
    required this.notificationId,
    required this.eventType,
    required this.sourceService,
    required this.title,
    required this.body,
    required this.occurredAt,
    required this.metadata,
  });

  final String notificationId;
  final String eventType;
  final String sourceService;
  final String title;
  final String body;
  final DateTime occurredAt;
  final Map<String, String> metadata;

  factory NotificationCenterItem.fromJson(Map<String, dynamic> json) {
    final rawMetadata = json['metadata'];
    final metadata = <String, String>{};
    if (rawMetadata is Map) {
      for (final entry in rawMetadata.entries) {
        if (entry.key != null && entry.value != null) {
          metadata[entry.key.toString()] = entry.value.toString();
        }
      }
    }

    return NotificationCenterItem(
      notificationId: json['notificationId']?.toString() ?? '',
      eventType: json['eventType']?.toString() ?? '',
      sourceService: json['sourceService']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      body: json['body']?.toString() ?? '',
      occurredAt:
          DateTime.tryParse(json['occurredAt']?.toString() ?? '') ??
          DateTime.now(),
      metadata: metadata,
    );
  }

  factory NotificationCenterItem.fromRealtime(
    RealtimeNotification notification,
  ) {
    return NotificationCenterItem(
      notificationId: notification.notificationId,
      eventType: notification.eventType,
      sourceService: notification.sourceService,
      title: notification.title,
      body: notification.body,
      occurredAt: notification.occurredAt,
      metadata: notification.metadata,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'notificationId': notificationId,
      'eventType': eventType,
      'sourceService': sourceService,
      'title': title,
      'body': body,
      'occurredAt': occurredAt.toIso8601String(),
      'metadata': metadata,
    };
  }

  NotificationCenterItem copyWith({
    String? notificationId,
    String? eventType,
    String? sourceService,
    String? title,
    String? body,
    DateTime? occurredAt,
    Map<String, String>? metadata,
  }) {
    return NotificationCenterItem(
      notificationId: notificationId ?? this.notificationId,
      eventType: eventType ?? this.eventType,
      sourceService: sourceService ?? this.sourceService,
      title: title ?? this.title,
      body: body ?? this.body,
      occurredAt: occurredAt ?? this.occurredAt,
      metadata: metadata ?? this.metadata,
    );
  }

  WorkflowContextMetadata get workflowContext =>
      WorkflowContextMetadata.fromMetadata(metadata);

  String? get contextType => workflowContext.contextType;

  String? get contextId => workflowContext.contextId;

  String? get sourceType => workflowContext.sourceType;

  String? get sourceId => workflowContext.sourceId;

  String? get sourceMessageId => workflowContext.sourceMessageId;

  String? get invitationId {
    final value = metadata['invitationId']?.trim();
    if (value == null || value.isEmpty) {
      return null;
    }
    return value;
  }

  String? get teamName {
    final value = metadata['teamName']?.trim();
    if (value == null || value.isEmpty) {
      return null;
    }
    return value;
  }

  String get bodyWithTeamContext {
    final resolvedBody = body.trim();
    final resolvedTeamName = teamName;
    if (resolvedTeamName == null) {
      return resolvedBody;
    }

    final normalizedBody = resolvedBody.toLowerCase();
    final normalizedTeamName = resolvedTeamName.toLowerCase();
    if (normalizedBody.contains(normalizedTeamName)) {
      return resolvedBody;
    }

    if (resolvedBody.isEmpty) {
      return 'Team: $resolvedTeamName';
    }
    return '$resolvedBody\nTeam: $resolvedTeamName';
  }

  String? get roleCode {
    final value = metadata['roleCode']?.trim();
    if (value == null || value.isEmpty) {
      return null;
    }
    return value;
  }

  String? get requestType {
    final value = metadata['requestType']?.trim();
    if (value == null || value.isEmpty) {
      return null;
    }
    return value;
  }

  String? get requesterUserId {
    final value = metadata['requesterUserId']?.trim();
    if (value == null || value.isEmpty) {
      return null;
    }
    return value;
  }

  String? get swapRequestId {
    final value = metadata['swapRequestId']?.trim();
    if (value == null || value.isEmpty) {
      return null;
    }
    return value;
  }

  String? get swapStage {
    final value = metadata['swapStage']?.trim();
    if (value == null || value.isEmpty) {
      return null;
    }
    return value;
  }

  String? get requestedDate {
    final value = metadata['requestedDate']?.trim();
    if (value == null || value.isEmpty) {
      return null;
    }
    return value;
  }

  String? get permissionStartTime {
    final value = metadata['permissionStartTime']?.trim();
    if (value == null || value.isEmpty) {
      return null;
    }
    return value;
  }

  String? get permissionEndTime {
    final value = metadata['permissionEndTime']?.trim();
    if (value == null || value.isEmpty) {
      return null;
    }
    return value;
  }

  String? get recordId {
    final value = metadata['recordId']?.trim();
    if (value == null || value.isEmpty) {
      return null;
    }
    return value;
  }

  int get impactedShiftCount {
    return int.tryParse(metadata['impactedShiftCount']?.trim() ?? '') ?? 0;
  }

  List<String> get impactedShiftSummaries {
    final raw = metadata['impactedShiftSummaries']?.trim();
    if (raw == null || raw.isEmpty) {
      return const <String>[];
    }
    return raw
        .split('||')
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toList(growable: false);
  }

  bool get hasImpactedShiftSummaries => impactedShiftSummaries.isNotEmpty;

  int get impactedTaskCount {
    return int.tryParse(metadata['impactedTaskCount']?.trim() ?? '') ?? 0;
  }

  List<String> get impactedTaskSummaries {
    final raw = metadata['impactedTaskSummaries']?.trim();
    if (raw == null || raw.isEmpty) {
      return const <String>[];
    }
    return raw
        .split('||')
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toList(growable: false);
  }

  bool get hasImpactedTaskSummaries => impactedTaskSummaries.isNotEmpty;

  int get impactedEventCount {
    return int.tryParse(metadata['impactedEventCount']?.trim() ?? '') ?? 0;
  }

  List<String> get impactedEventSummaries {
    final raw = metadata['impactedEventSummaries']?.trim();
    if (raw == null || raw.isEmpty) {
      return const <String>[];
    }
    return raw
        .split('||')
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toList(growable: false);
  }

  bool get hasImpactedEventSummaries => impactedEventSummaries.isNotEmpty;

  bool get isApprovedAbsenceDecision =>
      eventType == 'CLOCKING_VACATION_REQUEST_APPROVED' ||
      eventType == 'CLOCKING_PERMISSION_REQUEST_APPROVED' ||
      eventType == 'CLOCKING_SICK_REQUEST_APPROVED';

  bool get supportsImpactedShiftNavigation {
    if (!isApprovedAbsenceDecision) {
      return false;
    }
    return (metadata['teamId']?.trim().isNotEmpty ?? false) &&
        (requestedDate?.isNotEmpty ?? false) &&
        (requesterUserId?.isNotEmpty ?? false);
  }

  String? get actionRequestNote {
    final noteKeys = <String>['note', 'shiftNote'];
    for (final key in noteKeys) {
      final value = metadata[key]?.trim();
      if (value != null && value.isNotEmpty) {
        return value;
      }
    }
    return null;
  }

  bool get isPendingTeamInvitation => eventType == 'TEAM_MEMBER_INVITED';

  bool get isTerminalTeamInvitationEvent =>
      eventType == 'TEAM_INVITATION_CANCELLED' ||
      eventType == 'TEAM_INVITATION_REJECTED' ||
      (eventType == 'TEAM_MEMBER_JOINED' && invitationId != null);

  bool hidesTeamDetailFor(String currentUserId) {
    final invitedUserId = metadata['invitedUserId']?.trim() ?? '';
    if (currentUserId.isEmpty || invitedUserId.isEmpty) {
      return false;
    }
    if (invitedUserId != currentUserId) {
      return false;
    }
    return isPendingTeamInvitation || isTerminalTeamInvitationEvent;
  }

  bool supportsInviteDecisionFor(String currentUserId) {
    return eventType == 'TEAM_MEMBER_INVITED' &&
        invitationId != null &&
        (metadata['invitedUserId']?.trim() ?? '') == currentUserId;
  }

  bool get isPendingClockingManagerDecision =>
      eventType == 'CLOCKING_CLOCKING_REQUESTED' ||
      eventType == 'CLOCKING_DECOMMIT_REQUESTED' ||
      eventType == 'CLOCKING_VACATION_REQUESTED' ||
      eventType == 'CLOCKING_SICK_REQUESTED' ||
      eventType == 'CLOCKING_PERMISSION_REQUESTED' ||
      eventType == 'SHIFT_CHANGE_REQUESTED' ||
      eventType == 'SHIFT_SWAP_REQUESTED' ||
      eventType == 'SHIFT_SWAP_MANAGER_REVIEW_REQUESTED';

  bool get isReplacementOffer => requestType == 'shift_replacement';

  String? get replacementOfferId => metadata['offerId']?.trim();

  bool supportsReplacementOfferDecision() {
    return isReplacementOffer &&
        (replacementOfferId?.isNotEmpty ?? false);
  }

  bool supportsClockingDecision() {
    if (!isPendingClockingManagerDecision || requestType == null) {
      return false;
    }
    if (requestType == 'shift_swap') {
      return swapRequestId != null;
    }
    return requesterUserId != null &&
        ((requestType == 'shift_change' &&
                metadata['assignmentId']?.trim().isNotEmpty == true) ||
            (teamName != null && requestedDate != null));
  }

  bool supportsApprovedManualClockingFor({
    required String currentUserId,
    required String teamId,
    String? teamName,
    required DateTime date,
  }) {
    if (eventType != 'CLOCKING_CLOCKING_REQUEST_APPROVED') {
      return false;
    }
    if (recordId != null) {
      // Carries a recordId => this approval targets a specific already-open
      // record (unlock request), not a brand-new manual entry.
      return false;
    }
    if ((requesterUserId ?? '') != currentUserId) {
      return false;
    }
    final notificationTeamId = metadata['teamId']?.trim() ?? '';
    final notificationTeamName = metadata['teamName']?.trim() ?? '';
    final normalizedSelectedTeamName = teamName?.trim().toLowerCase() ?? '';

    if (notificationTeamId.isNotEmpty) {
      if (notificationTeamId.toLowerCase() != teamId.trim().toLowerCase()) {
        return false;
      }
    } else {
      if (notificationTeamName.isEmpty || normalizedSelectedTeamName.isEmpty) {
        return false;
      }
      if (notificationTeamName.toLowerCase() != normalizedSelectedTeamName) {
        return false;
      }
    }

    final requested = requestedDate;
    if (requested == null) {
      return false;
    }
    final parsed = DateTime.tryParse(requested);
    if (parsed == null) {
      return false;
    }
    return parsed.year == date.year &&
        parsed.month == date.month &&
        parsed.day == date.day;
  }

  /// Whether this is an approved "unlock" decision for the given open
  /// clocking record: a request-clocking approval that carries the
  /// [recordId] of an already-open record from a past day, letting the
  /// owner close that exact record themselves instead of filling in a new
  /// manual entry.
  bool supportsApprovedUnlockRecordFor({
    required String currentUserId,
    required String teamId,
    String? teamName,
    required DateTime date,
    required String recordId,
  }) {
    if (eventType != 'CLOCKING_CLOCKING_REQUEST_APPROVED') {
      return false;
    }
    if ((this.recordId ?? '') != recordId) {
      return false;
    }
    if ((requesterUserId ?? '') != currentUserId) {
      return false;
    }
    final notificationTeamId = metadata['teamId']?.trim() ?? '';
    final notificationTeamName = metadata['teamName']?.trim() ?? '';
    final normalizedSelectedTeamName = teamName?.trim().toLowerCase() ?? '';

    if (notificationTeamId.isNotEmpty) {
      if (notificationTeamId.toLowerCase() != teamId.trim().toLowerCase()) {
        return false;
      }
    } else {
      if (notificationTeamName.isEmpty || normalizedSelectedTeamName.isEmpty) {
        return false;
      }
      if (notificationTeamName.toLowerCase() != normalizedSelectedTeamName) {
        return false;
      }
    }

    final requested = requestedDate;
    if (requested == null) {
      return false;
    }
    final parsed = DateTime.tryParse(requested);
    if (parsed == null) {
      return false;
    }
    return parsed.year == date.year &&
        parsed.month == date.month &&
        parsed.day == date.day;
  }

  @override
  List<Object?> get props => [
    notificationId,
    eventType,
    sourceService,
    title,
    body,
    occurredAt,
    metadata,
    contextType,
    contextId,
    sourceType,
    sourceId,
    sourceMessageId,
  ];
}
