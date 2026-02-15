import 'package:note_sondage/domain/entities/user_entity.dart';

abstract class IAuthRepository {
  UserEntity get currentUser;
  Future<UserEntity> login(dynamic credentials);
  Future<UserEntity> register(UserEntity user);
  Future<void> logout();
  Future<void> sendPasswordResetEmail(String email);
}
