import 'package:note_sondage/domain/entities/user_entity.dart';
import 'package:note_sondage/domain/repositories/interface_auth.dart';

class FirebaseLoginRepositoryImpl implements IAuthRepository {
  @override
  UserEntity get currentUser {
    // Implementazione per ottenere l'utente corrente da Firebase
    throw UnimplementedError();
  }

  @override
  Future<UserEntity> login(dynamic credentials) async {
    // Implementazione del login con Firebase
    throw UnimplementedError();
  }

  @override
  Future<UserEntity> register(UserEntity user) async {
    // Implementazione della registrazione con Firebase
    throw UnimplementedError();
  }

  @override
  Future<void> logout() async {
    // Implementazione del logout con Firebase
    throw UnimplementedError();
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    // Implementazione per inviare email di reset password con Firebase
    throw UnimplementedError();
  }
}
