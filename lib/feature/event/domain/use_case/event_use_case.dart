import 'package:note_sondage/feature/event/domain/entities/event_create_request_entity.dart';
import 'package:note_sondage/feature/event/domain/entities/event_entity.dart';
import 'package:note_sondage/feature/event/domain/entities/event_update_request_entity.dart';
import 'package:note_sondage/feature/event/domain/repositories/event_repository.dart';

class EventUseCase {
  EventUseCase(this._repository);

  final EventRepository _repository;

  /// Passing `null` returns the caller's own events across every team
  /// (created by them or where they're a participant) — mirrors Shift's
  /// "no team filter" convention rather than a dedicated "/mine" endpoint.
  Future<List<EventEntity>> getEventsByTeam(String? teamId) {
    return _repository.getEventsByTeam(teamId);
  }

  Future<List<EventEntity>> getArchivedEventsByTeam(String? teamId) {
    return _repository.getArchivedEventsByTeam(teamId);
  }

  Future<EventEntity> getEventById(String eventId) {
    return _repository.getEventById(eventId);
  }

  Future<EventEntity> createEvent(EventCreateRequestEntity request) {
    return _repository.createEvent(request);
  }

  Future<EventEntity> updateEvent(
    String eventId,
    EventUpdateRequestEntity request,
  ) {
    return _repository.updateEvent(eventId, request);
  }

  Future<EventEntity> archiveEvent(String eventId) {
    return _repository.archiveEvent(eventId);
  }

  Future<EventEntity> unarchiveEvent(String eventId) {
    return _repository.unarchiveEvent(eventId);
  }

  Future<void> deleteEventPermanently(String eventId) {
    return _repository.deleteEventPermanently(eventId);
  }
}
