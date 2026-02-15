import 'package:note_sondage/core/network/setup_dio.dart';
import 'package:note_sondage/feature/team/domain/entities/permission_entity.dart';
import 'package:note_sondage/feature/team/domain/repositories/crud_service.dart';
import 'package:note_sondage/feature/team/domain/repositories/permission_repository.dart';
import 'package:note_sondage/feature/team/infrastructure/data/permission_mapper.dart';
import 'package:note_sondage/feature/team/infrastructure/data_source/permission_remote_data_source.dart';

class PermissionRepositoryImpl implements PermissionRepository {
  final PermissionRemoteDataSource remoteDataSource;
  PermissionRepositoryImpl(this.remoteDataSource);

  @override
  Future<List<PermissionEntity>> getAll() async {
    try {
      final res = await remoteDataSource.getAll();
      return res;
    } catch (e) {
      throw Exception('Failed to fetch permissions: $e');
    }
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
