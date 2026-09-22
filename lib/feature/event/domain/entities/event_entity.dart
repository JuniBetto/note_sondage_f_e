import 'package:note_sondage/feature/event/domain/entities/event_reminder_anchor.dart';
import 'package:note_sondage/feature/event/domain/entities/event_workflow_metadata_entity.dart';

class EventEntity {
  const EventEntity({
    required this.id,
    required this.title,
    required this.startsAt,
    required this.allDay,
    required this.createdByUserId,
    required this.createdAt,
    required this.updatedAt,
    this.teamId,
    this.description,
    this.endsAt,
    this.location,
    this.participantUserIds = const <String>[],
    this.participantDisplayNames = const <String>[],
    this.createdByDisplayName,
    this.workflowMetadata,
    this.archivedAt,
    this.reminderOffsets = const <int>[],
    this.reminderAnchor = EventReminderAnchor.startsAt,
  });

  final String id;

  /// `null` means this is a personal event — not attached to any team,
  /// visible only to [createdByUserId] and its participants.
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
  final DateTime? archivedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Minuti relativi (negativi = prima) a cui schedulare i promemoria
  /// dell'allarme, ancorati a [reminderAnchor]. Gia' scoped lato backend
  /// all'utente che ha effettuato la richiesta: il creatore vede il proprio,
  /// un partecipante vede il proprio (indipendente), chiunque altro vede una
  /// lista vuota.
  final List<int> reminderOffsets;

  /// Se i promemoria sono ancorati a [startsAt] o a [endsAt].
  final EventReminderAnchor reminderAnchor;

  /// Data/ora usata per calcolare i promemoria, in base a [reminderAnchor].
  DateTime? get reminderAnchorTime =>
      reminderAnchor == EventReminderAnchor.endsAt ? endsAt : startsAt;

  bool get isArchived => archivedAt != null;

  EventEntity copyWith({
    String? id,
    String? teamId,
    String? title,
    String? description,
    DateTime? startsAt,
    DateTime? endsAt,
    bool clearEndsAt = false,
    bool? allDay,
    String? location,
    List<String>? participantUserIds,
    List<String>? participantDisplayNames,
    String? createdByUserId,
    String? createdByDisplayName,
    EventWorkflowMetadataEntity? workflowMetadata,
    DateTime? archivedAt,
    bool clearArchivedAt = false,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<int>? reminderOffsets,
    EventReminderAnchor? reminderAnchor,
  }) {
    return EventEntity(
      id: id ?? this.id,
      teamId: teamId ?? this.teamId,
      title: title ?? this.title,
      description: description ?? this.description,
      startsAt: startsAt ?? this.startsAt,
      endsAt: clearEndsAt ? null : (endsAt ?? this.endsAt),
      allDay: allDay ?? this.allDay,
      location: location ?? this.location,
      participantUserIds: participantUserIds ?? this.participantUserIds,
      participantDisplayNames:
          participantDisplayNames ?? this.participantDisplayNames,
      createdByUserId: createdByUserId ?? this.createdByUserId,
      createdByDisplayName: createdByDisplayName ?? this.createdByDisplayName,
      workflowMetadata: workflowMetadata ?? this.workflowMetadata,
      archivedAt: clearArchivedAt ? null : (archivedAt ?? this.archivedAt),
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      reminderOffsets: reminderOffsets ?? this.reminderOffsets,
      reminderAnchor: reminderAnchor ?? this.reminderAnchor,
    );
  }
}
