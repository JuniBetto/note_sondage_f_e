import 'package:note_sondage/feature/event/domain/entities/event_create_request_entity.dart';
import 'package:note_sondage/feature/event/domain/entities/event_entity.dart';
import 'package:note_sondage/feature/event/domain/entities/event_update_request_entity.dart';
import 'package:note_sondage/feature/event/domain/repositories/event_repository.dart';
import 'package:note_sondage/feature/event/infrastructure/data_source/data_source_local/event_local_data_source.dart';
import 'package:note_sondage/feature/event/infrastructure/data_source/event_remote_data_source.dart';

class EventRepositoryImpl implements EventRepository {
  EventRepositoryImpl(this._local, this._remote);

  final EventLocalDataSource _local;
  final EventRemoteDataSource _remote;

  @override
  Future<List<EventEntity>> getEventsByTeam(String? teamId) async {
    try {
      final remote = await _remote.getEventsByTeam(teamId);
      if (teamId == null) {
        for (final event in remote) {
          await _upsertInCache(event);
        }
      } else {
        await _replaceTeamSliceInCache(
          teamId: teamId,
          archived: false,
          incoming: remote,
        );
      }
      return remote;
    } catch (e) {
      if (teamId == null) {
        throw Exception('Failed to fetch my events: $e');
      }
      final cached = await _local.getAll();
      final localSlice = cached
          .where((event) => event.teamId == teamId && !event.isArchived)
          .toList(growable: false);
      if (localSlice.isNotEmpty) {
        return localSlice;
      }
      throw Exception('Failed to fetch events: $e');
    }
  }

  @override
  Future<List<EventEntity>> getArchivedEventsByTeam(String? teamId) async {
    try {
      final remote = await _remote.getArchivedEventsByTeam(teamId);
      if (teamId == null) {
        for (final event in remote) {
          await _upsertInCache(event);
        }
      } else {
        await _replaceTeamSliceInCache(
          teamId: teamId,
          archived: true,
          incoming: remote,
        );
      }
      return remote;
    } catch (e) {
      if (teamId == null) {
        throw Exception('Failed to fetch my archived events: $e');
      }
      final cached = await _local.getAll();
      final localSlice = cached
          .where((event) => event.teamId == teamId && event.isArchived)
          .toList(growable: false);
      if (localSlice.isNotEmpty) {
        return localSlice;
      }
      throw Exception('Failed to fetch archived events: $e');
    }
  }

  @override
  Future<EventEntity> getEventById(String eventId) async {
    try {
      final event = await _remote.getEventById(eventId);
      await _upsertInCache(event);
      return event;
    } catch (e) {
      final cached = await _local.getAll();
      final local = cached.where((event) => event.id == eventId).firstOrNull;
      if (local != null) {
        return local;
      }
      throw Exception('Failed to fetch event: $e');
    }
  }

  @override
  Future<EventEntity> createEvent(EventCreateRequestEntity request) async {
    final created = await _remote.createEvent(request);
    await _upsertInCache(created);
    return created;
  }

  @override
  Future<EventEntity> updateEvent(
    String eventId,
    EventUpdateRequestEntity request,
  ) async {
    final updated = await _remote.updateEvent(eventId, request);
    await _upsertInCache(updated);
    return updated;
  }

  @override
  Future<EventEntity> archiveEvent(String eventId) async {
    final archived = await _remote.archiveEvent(eventId);
    await _upsertInCache(archived);
    return archived;
  }

  @override
  Future<EventEntity> unarchiveEvent(String eventId) async {
    final restored = await _remote.unarchiveEvent(eventId);
    await _upsertInCache(restored);
    return restored;
  }

  @override
  Future<void> deleteEventPermanently(String eventId) async {
    await _remote.deleteEventPermanently(eventId);
    final cached = await _local.getAll();
    await _local.saveAll(
      cached.where((event) => event.id != eventId).toList(growable: false),
    );
  }

  Future<void> _upsertInCache(EventEntity event) async {
    final cached = await _local.getAll();
    final next = [
      for (final existing in cached)
        if (existing.id != event.id) existing,
      event,
    ];
    await _local.saveAll(next);
  }

  Future<void> _replaceTeamSliceInCache({
    required String teamId,
    required bool archived,
    required List<EventEntity> incoming,
  }) async {
    final cached = await _local.getAll();
    final rest = cached
        .where(
          (event) => !(event.teamId == teamId && event.isArchived == archived),
        )
        .toList(growable: false);
    await _local.saveAll([...rest, ...incoming]);
  }
}
