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
      final local = await _local.getAll();
      if (local.isNotEmpty) {
        _remote.getAll().catchError((_) => <SondageEntity>[]);
        return local;
      }
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
      final local = await _local.getAll();
      if (local.isNotEmpty) {
        _remote.getAllByUserId(userId).catchError((_) => <SondageEntity>[]);
        return local;
      }
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
}
