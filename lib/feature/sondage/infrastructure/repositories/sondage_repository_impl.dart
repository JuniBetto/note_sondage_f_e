import 'package:note_sondage/feature/sondage/domain/entities/sondage_entity.dart';
import 'package:note_sondage/feature/sondage/domain/repositories/sondage_repository.dart';
import 'package:note_sondage/feature/sondage/infrastructure/data_source/data_source_local/sondage_local_data_source.dart';
import 'package:note_sondage/feature/sondage/infrastructure/data_source/data_source_remote/sondage_remote_data_source.dart';

class SondageRepositoryImpl implements SondageRepository {
  final SondageLocalDataSource _local;
  final SondageRemoteDataSource _remote;

  SondageRepositoryImpl(this._local, this._remote);

  @override
  Future<List<SondageEntity>> getAll() async {
    try {
      return await _remote.getAll();
    } catch (e) {
      final cached = await _local.getAll();
      if (cached.isNotEmpty) return cached;
      throw Exception('Failed to fetch sondages: $e');
    }
  }

  @override
  Future<List<SondageEntity>> getAllByUserId(String userId) async {
    try {
      return await _remote.getAllByUserId(userId);
    } catch (e) {
      final cached = await _local.getAll();
      if (cached.isNotEmpty) return cached;
      throw Exception('Failed to fetch sondages by user ID: $e');
    }
  }

  @override
  Future<SondageEntity?> getById(String id) async {
    try {
      return await _remote.getById(id);
    } catch (e) {
      throw Exception('Failed to fetch sondage: $e');
    }
  }

  @override
  Future<SondageEntity> create(SondageEntity sondage) async {
    try {
      return await _remote.create(sondage);
    } catch (e) {
      throw Exception('Failed to create sondage: $e');
    }
  }

  @override
  Future<SondageEntity> update(SondageEntity sondage) async {
    try {
      return await _remote.update(sondage);
    } catch (e) {
      throw Exception('Failed to update sondage: $e');
    }
  }

  @override
  Future<bool> delete(String id) async {
    try {
      await _remote.delete(id);
      return true;
    } catch (e) {
      throw Exception('Failed to delete sondage: $e');
    }
  }

  @override
  Future<SondageEntity> publish(String id) async {
    try {
      return await _remote.publish(id);
    } catch (e) {
      throw Exception('Failed to publish sondage: $e');
    }
  }

  @override
  Future<SondageEntity> close(String id) async {
    try {
      return await _remote.close(id);
    } catch (e) {
      throw Exception('Failed to close sondage: $e');
    }
  }

  @override
  Future<SondageEntity> reopen(String id) async {
    try {
      return await _remote.reopen(id);
    } catch (e) {
      throw Exception('Failed to reopen sondage: $e');
    }
  }

  @override
  Future<SondageEntity> vote(String sondageId, String optionId) async {
    try {
      return await _remote.vote(sondageId, optionId);
    } catch (e) {
      throw Exception('Failed to vote sondage: $e');
    }
  }

  @override
  Future<int> remindPendingVoters(
    String sondageId, {
    List<String>? recipientUserIds,
  }) async {
    try {
      return await _remote.remindPendingVoters(
        sondageId,
        recipientUserIds: recipientUserIds,
      );
    } catch (e) {
      throw Exception('Failed to remind pending voters: $e');
    }
  }
}
