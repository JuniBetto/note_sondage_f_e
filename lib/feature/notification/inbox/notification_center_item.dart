import 'package:equatable/equatable.dart';
import 'package:note_sondage/feature/notification/realtime/realtime_notification_model.dart';

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

  factory NotificationCenterItem.fromRealtime(RealtimeNotification notification) {
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
      eventType == 'CLOCKING_VACATION_REQUESTED' ||
      eventType == 'CLOCKING_PERMISSION_REQUESTED';

  bool supportsClockingDecision() {
    return isPendingClockingManagerDecision &&
        teamName != null &&
        requesterUserId != null &&
        requestedDate != null &&
        requestType != null;
  }

  bool supportsApprovedManualClockingFor({
    required String currentUserId,
    required String teamId,
    required DateTime date,
  }) {
    if (eventType != 'CLOCKING_CLOCKING_REQUEST_APPROVED') {
      return false;
    }
    if ((requesterUserId ?? '') != currentUserId) {
      return false;
    }
    if ((metadata['teamId']?.trim() ?? '') != teamId) {
      return false;
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
  ];
}
