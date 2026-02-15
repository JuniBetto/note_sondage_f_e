import 'package:note_sondage/application/factory/auth_factory.dart';
import 'package:note_sondage/domain/entities/all_enum.dart';
import 'package:note_sondage/domain/entities/user_entity.dart';

class LoginUseCase {
  final AuthFactory loginFactory;
  LoginUseCase(this.loginFactory);

  Future<UserEntity> login(dynamic credentials) async {
    final authRepository = loginFactory.createAuthRepository();
    return await authRepository.login(credentials);
  }

  UserEntity get currentUser {
    final authRepository = loginFactory.createAuthRepository();
    return authRepository.currentUser;
  }

  Future<UserEntity> register(UserEntity user) async {
    final authRepository = loginFactory.createAuthRepository();
    return await authRepository.register(user);
  }

  Future<void> logout() async {
    final authRepository = loginFactory.createAuthRepository();
    return await authRepository.logout();
  }
}
