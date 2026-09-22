import 'package:note_sondage/feature/event/domain/entities/event_reminder_anchor.dart';
import 'package:note_sondage/feature/event/domain/entities/event_workflow_metadata_entity.dart';

class EventCreateRequestEntity {
  const EventCreateRequestEntity({
    required this.title,
    required this.startsAt,
    required this.createdByUserId,
    this.teamId,
    this.description,
    this.endsAt,
    this.allDay = false,
    this.location,
    this.participantUserIds = const <String>[],
    this.participantDisplayNames = const <String>[],
    this.createdByDisplayName,
    this.workflowMetadata,
    this.reminderOffsets = const <int>[],
    this.reminderAnchor = EventReminderAnchor.startsAt,
  });

  /// `null` creates a personal event — not attached to any team, visible
  /// only to the creator and its participants.
  final String? teamId;
  final String title;
  final String? description;
  final DateTime startsAt;
  final DateTime? endsAt;
  final bool allDay;
  final String? location;
  final List<String> participantUserIds;
  final List<String> participantDisplayNames;
  final String createdByUserId;
  final String? createdByDisplayName;
  final EventWorkflowMetadataEntity? workflowMetadata;
  final List<int> reminderOffsets;
  final EventReminderAnchor reminderAnchor;
}
