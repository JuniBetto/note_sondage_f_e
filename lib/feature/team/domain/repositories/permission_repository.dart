import 'package:note_sondage/feature/team/domain/entities/permission_entity.dart';

abstract class PermissionRepository {
  Future<List<PermissionEntity>> getAll();
  Future<PermissionEntity> getById(String id);
  Future<PermissionEntity> create(PermissionEntity entity);
  Future<PermissionEntity> update(String id, PermissionEntity entity);
  Future<void> delete(String id);
}
