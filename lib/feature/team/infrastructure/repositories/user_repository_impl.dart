import 'package:note_sondage/feature/team/domain/entities/user_entity.dart';
import 'package:note_sondage/feature/team/domain/repositories/user_repository.dart';
import 'package:note_sondage/feature/team/infrastructure/data_source/data_source_local/user_local_data_source.dart';
import 'package:note_sondage/feature/team/infrastructure/data_source/data_source_remote/user_remote_data_source.dart';

class UserRepositoryImpl implements UserRepository {
  final UserLocalDataSource _local;
  final UserRemoteDataSource _remote;

  UserRepositoryImpl({
    required UserLocalDataSource local,
    required UserRemoteDataSource remote,
  }) : _local = local,
       _remote = remote;

  @override
  Future<List<UserEntity>> getAll() async {
    try {
      final local = await _local.getAll();
      if (local.isNotEmpty) {
        _remote.getAll().catchError((_) => <UserEntity>[]);
        return local;
      }
      return await _remote.getAll();
    } catch (e) {
      final cached = await _local.getAll();
      if (cached.isNotEmpty) return cached;
      throw Exception('Failed to fetch users: $e');
    }
  }

  @override
  Future<UserEntity?> getById(String id) async {
    return await _remote.getById(id);
  }

  @override
  Future<UserEntity?> getByEmail(String email) async {
    return await _remote.getByEmail(email);
  }

  @override
  Future<UserEntity> create(UserEntity user) async {
    return await _remote.create(user);
  }

  @override
  Future<UserEntity> createInactive(String email) async {
    return await _remote.createInactive(email);
  }

  @override
  Future<UserEntity> update(UserEntity user) async {
    return await _remote.update(user);
  }

  @override
  Future<bool> delete(String id) async {
    await _remote.delete(id);
    return true;
  }

  @override
  Future<List<UserEntityForUpdate>> getAllByTeamId(String teamId) async {
    return await _remote.getAllByTeamId(teamId);
  }

  Future<void> refreshAll() async {
    await _remote.getAll();
  }
}
