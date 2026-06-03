import 'package:note_sondage/feature/team/domain/entities/permission_entity.dart';
import 'package:note_sondage/feature/team/domain/repositories/permission_repository.dart';
import 'package:note_sondage/feature/team/infrastructure/data_source/data_source_local/permission_local_data_source.dart';
import 'package:note_sondage/feature/team/infrastructure/data_source/data_source_remote/permission_remote_data_source.dart';

class PermissionRepositoryImpl implements PermissionRepository {
  final PermissionLocalDataSource _local;
  final PermissionRemoteDataSource _remote;

  PermissionRepositoryImpl(this._local, this._remote);

  @override
  Future<List<PermissionEntity>> getAll() async {
    try {
      final local = await _local.getAll();
      if (local.isNotEmpty) {
        // background refresh senza attendere
        _remote.getAll().catchError((_) => <PermissionEntity>[]);
        return local;
      }
      return await _remote.getAll();
    } catch (e) {
      final cached = await _local.getAll();
      if (cached.isNotEmpty) return cached;
      throw Exception('Failed to fetch permissions: $e');
    }
  }

  Future<void> refreshAll() async {
    await _remote.getAll();
  }

  @override
  Future<PermissionEntity> getById(String id) {
    throw UnimplementedError();
  }

  @override
  Future<PermissionEntity> create(PermissionEntity entity) {
    throw UnimplementedError();
  }

  @override
  Future<PermissionEntity> update(String id, PermissionEntity entity) {
    throw UnimplementedError();
  }

  @override
  Future<void> delete(String id) {
    throw UnimplementedError();
  }
}
