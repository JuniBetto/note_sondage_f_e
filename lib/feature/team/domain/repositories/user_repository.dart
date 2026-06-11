import 'package:note_sondage/feature/team/domain/entities/user_entity.dart';

abstract class UserRepository {
  Future<List<UserEntity>> getAll();
  Future<UserEntity?> getById(String id);
  Future<UserEntity?> getByEmail(String email);
  Future<UserEntity> create(UserEntity user);
  Future<UserEntity> createInactive(String email);
  Future<UserEntity> update(UserEntity user);
  Future<bool> delete(String id);
  Future<List<UserEntityForUpdate>> getAllByTeamId(String teamId);
}
