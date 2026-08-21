import 'package:note_sondage/feature/event/domain/entities/event_entity.dart';

class EventLocalDataSource {
  final Map<String, EventEntity> _cache = <String, EventEntity>{};

  Future<void> saveAll(List<EventEntity> events) async {
    _cache
      ..clear()
      ..addEntries(events.map((event) => MapEntry(event.id, event)));
  }

  Future<List<EventEntity>> getAll() async {
    return _cache.values.toList(growable: false);
  }
}
