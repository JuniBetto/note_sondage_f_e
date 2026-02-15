import 'package:note_sondage/feature/team/domain/entities/permission_entity.dart';
import 'package:note_sondage/feature/team/domain/repositories/permission_repository.dart';

class PermissionUseCase {
  final PermissionRepository repository;
  PermissionUseCase(this.repository);

  Future<List<PermissionEntity>> getAllPermissions() async {
    return await repository.getAll();
  }

  Future<PermissionEntity> getPermissionById(String id) async {
    return await repository.getById(id);
  }

  Future<PermissionEntity> createPermission(PermissionEntity entity) async {
    return await repository.create(entity);
  }

  Future<PermissionEntity> updatePermission(
    String id,
    PermissionEntity entity,
  ) async {
    return await repository.update(id, entity);
  }

  Future<void> deletePermission(String id) async {
    return await repository.delete(id);
  }
}
