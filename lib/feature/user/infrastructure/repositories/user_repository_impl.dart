import 'package:note_sondage/feature/team/domain/entities/user_entity.dart';
import 'package:note_sondage/feature/user/domain/repositories/user_repository.dart';
import 'package:note_sondage/feature/user/infrastructure/data_source/user_remote_data_source.dart';

class UserRepositoryImpl implements UserRepository {
  final UserRemoteDataSource remoteDataSource;

  UserRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<UserEntity>> getAll() async {
    return await remoteDataSource.getAll();
  }

  @override
  Future<UserEntity?> getById(String id) async {
    return await remoteDataSource.getById(id);
  }

  @override
  Future<UserEntity?> getByEmail(String email) async {
    return await remoteDataSource.getByEmail(email);
  }

  @override
  Future<UserEntity> create(UserEntity user) async {
    return await remoteDataSource.create(user);
  }

  @override
  Future<UserEntity> createInactive(String email) async {
    return await remoteDataSource.createInactive(email);
  }

  @override
  Future<UserEntity> update(UserEntity user) async {
    return await remoteDataSource.update(user);
  }

  @override
  Future<bool> delete(String id) async {
    await remoteDataSource.delete(id);
    return true;
  }
}
