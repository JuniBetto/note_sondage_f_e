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
}
