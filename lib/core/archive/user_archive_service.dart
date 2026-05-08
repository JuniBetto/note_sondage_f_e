import 'package:shared_preferences/shared_preferences.dart';

class ArchiveBuckets {
  static const String teams = 'teams';
  static const String sondages = 'sondages';
  static const String clockingRecords = 'clocking_records';
  static const String shiftAssignments = 'shift_assignments';
}

class UserArchiveService {
  final Map<String, Set<String>> _cache = <String, Set<String>>{};

  Future<Set<String>> loadArchivedIds({
    required String userId,
    required String bucket,
  }) async {
    if (userId.trim().isEmpty) {
      return <String>{};
    }

    final cacheKey = _buildKey(userId: userId, bucket: bucket);
    final cached = _cache[cacheKey];
    if (cached != null) {
      return Set<String>.from(cached);
    }

    final prefs = await SharedPreferences.getInstance();
    final values = prefs.getStringList(cacheKey) ?? const <String>[];
    final archived = values
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toSet();
    _cache[cacheKey] = archived;
    return Set<String>.from(archived);
  }

  Future<void> setArchived({
    required String userId,
    required String bucket,
    required String itemId,
    required bool archived,
  }) async {
    final normalizedUserId = userId.trim();
    final normalizedItemId = itemId.trim();
    if (normalizedUserId.isEmpty || normalizedItemId.isEmpty) {
      return;
    }

    final cacheKey = _buildKey(userId: normalizedUserId, bucket: bucket);
    final current = await loadArchivedIds(
      userId: normalizedUserId,
      bucket: bucket,
    );

    if (archived) {
      current.add(normalizedItemId);
    } else {
      current.remove(normalizedItemId);
    }

    _cache[cacheKey] = current;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(cacheKey, current.toList()..sort());
  }

  Future<void> toggleArchived({
    required String userId,
    required String bucket,
    required String itemId,
  }) async {
    final current = await loadArchivedIds(userId: userId, bucket: bucket);
    await setArchived(
      userId: userId,
      bucket: bucket,
      itemId: itemId,
      archived: !current.contains(itemId.trim()),
    );
  }

  String _buildKey({required String userId, required String bucket}) {
    return 'user_archive::$bucket::${userId.trim()}';
  }
}
