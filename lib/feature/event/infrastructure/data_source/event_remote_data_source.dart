import 'package:dio/dio.dart';
import 'package:note_sondage/core/network/setup_dio.dart';
import 'package:note_sondage/feature/event/domain/entities/event_create_request_entity.dart';
import 'package:note_sondage/feature/event/domain/entities/event_entity.dart';
import 'package:note_sondage/feature/event/domain/entities/event_reminder_anchor.dart';
import 'package:note_sondage/feature/event/domain/entities/event_update_request_entity.dart';
import 'package:note_sondage/feature/event/infrastructure/data/event_mapper.dart';

class EventRemoteDataSource {
  EventRemoteDataSource({Dio? dio}) : _dio = dio ?? DioClient().dio;

  final Dio _dio;

  Future<List<EventEntity>> getEventsByTeam(String? teamId) async {
    final response = await _dio.get(
      '/api/events',
      queryParameters: {if (teamId != null) 'teamId': teamId},
    );
    final data = response.data as List<dynamic>? ?? const <dynamic>[];
    return data
        .whereType<Map<String, dynamic>>()
        .map(EventMapper.fromJson)
        .toList(growable: false);
  }

  Future<List<EventEntity>> getArchivedEventsByTeam(String? teamId) async {
    final response = await _dio.get(
      '/api/events/archived',
      queryParameters: {if (teamId != null) 'teamId': teamId},
    );
    final data = response.data as List<dynamic>? ?? const <dynamic>[];
    return data
        .whereType<Map<String, dynamic>>()
        .map(EventMapper.fromJson)
        .toList(growable: false);
  }

  Future<EventEntity> getEventById(String eventId) async {
    final response = await _dio.get('/api/events/$eventId');
    return EventMapper.fromJson(Map<String, dynamic>.from(response.data));
  }

  Future<EventEntity> createEvent(EventCreateRequestEntity request) async {
    final response = await _dio.post(
      '/api/events',
      data: EventMapper.createRequestToJson(request),
    );
    return EventMapper.fromJson(Map<String, dynamic>.from(response.data));
  }

  Future<EventEntity> updateEvent(
    String eventId,
    EventUpdateRequestEntity request,
  ) async {
    final response = await _dio.patch(
      '/api/events/$eventId',
      data: EventMapper.updateRequestToJson(request),
    );
    return EventMapper.fromJson(Map<String, dynamic>.from(response.data));
  }

  /// Sets the CURRENT user's own reminder for this event — independent of
  /// anyone else's, whether they're the creator or a participant. See
  /// `PATCH /api/events/{eventId}/reminders/mine` on note_sondage_event.
  Future<EventEntity> updateMyReminder(
    String eventId,
    List<int> reminderOffsets,
    EventReminderAnchor reminderAnchor,
  ) async {
    final response = await _dio.patch(
      '/api/events/$eventId/reminders/mine',
      data: {
        'reminderOffsets': reminderOffsets,
        'reminderAnchor': reminderAnchor.wireValue,
      },
    );
    return EventMapper.fromJson(Map<String, dynamic>.from(response.data));
  }

  Future<EventEntity> archiveEvent(String eventId) async {
    final response = await _dio.post('/api/events/$eventId/archive');
    return EventMapper.fromJson(Map<String, dynamic>.from(response.data));
  }

  Future<EventEntity> unarchiveEvent(String eventId) async {
    final response = await _dio.post('/api/events/$eventId/unarchive');
    return EventMapper.fromJson(Map<String, dynamic>.from(response.data));
  }

  Future<void> deleteEventPermanently(String eventId) async {
    await _dio.delete('/api/events/$eventId');
  }
}
