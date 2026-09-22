import 'package:note_sondage/feature/event/domain/entities/event_reminder_anchor.dart';

class EventUpdateRequestEntity {
  const EventUpdateRequestEntity({
    this.title,
    this.description,
    this.startsAt,
    this.endsAt,
    this.clearEndsAt = false,
    this.allDay,
    this.location,
    this.participantUserIds,
    this.participantDisplayNames,
    this.reminderOffsets,
    this.reminderAnchor,
  });

  final String? title;
  final String? description;
  final DateTime? startsAt;
  final DateTime? endsAt;
  final bool clearEndsAt;
  final bool? allDay;
  final String? location;
  final List<String>? participantUserIds;
  final List<String>? participantDisplayNames;

  /// `null` = don't touch the existing reminder; a list (even empty)
  /// replaces the current offsets.
  final List<int>? reminderOffsets;
  final EventReminderAnchor? reminderAnchor;
}
