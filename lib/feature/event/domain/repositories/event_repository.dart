import 'package:note_sondage/feature/event/domain/entities/event_create_request_entity.dart';
import 'package:note_sondage/feature/event/domain/entities/event_entity.dart';
import 'package:note_sondage/feature/event/domain/entities/event_update_request_entity.dart';

abstract class EventRepository {
  Future<List<EventEntity>> getEventsByTeam(String? teamId);

  Future<List<EventEntity>> getArchivedEventsByTeam(String? teamId);

  Future<EventEntity> getEventById(String eventId);

  Future<EventEntity> createEvent(EventCreateRequestEntity request);

  Future<EventEntity> updateEvent(
    String eventId,
    EventUpdateRequestEntity request,
  );

  Future<EventEntity> archiveEvent(String eventId);

  Future<EventEntity> unarchiveEvent(String eventId);

  Future<void> deleteEventPermanently(String eventId);
}
