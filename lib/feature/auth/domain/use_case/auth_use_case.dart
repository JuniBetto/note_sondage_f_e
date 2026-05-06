import 'package:note_sondage/feature/auth/domain/entities/auth_user_entity.dart';
import 'package:note_sondage/feature/auth/domain/entities/phone_sign_in_start_result.dart';
import 'package:note_sondage/feature/auth/domain/repositories/auth_repository.dart';

/// Caso d'uso per le operazioni di autenticazione.
/// Agisce come intermediario tra il BLoC e il Repository.
class AuthUseCase {
  final AuthRepository _repository;

  AuthUseCase(this._repository);

  /// Stream dei cambiamenti di stato auth.
  Stream<AuthUserEntity> get authStateChanges => _repository.authStateChanges;

  /// Utente corrente.
  AuthUserEntity get currentUser => _repository.currentUser;

  /// Login con email/password.
  Future<AuthUserEntity> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      return await _repository.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Registrazione con email/password.
  Future<AuthUserEntity> createUserWithEmailAndPassword({
    required String email,
    required String password,
    String? displayName,
    List<int>? profileImageBytes,
    String? profileImageFileName,
  }) async {
    try {
      return await _repository.createUserWithEmailAndPassword(
        email: email,
        password: password,
        displayName: displayName,
        profileImageBytes: profileImageBytes,
        profileImageFileName: profileImageFileName,
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Login con Google.
  Future<AuthUserEntity> signInWithGoogle() async {
    try {
      return await _repository.signInWithGoogle();
    } catch (e) {
      rethrow;
    }
  }

  Future<PhoneSignInStartResult> startPhoneSignIn({
    required String phoneNumber,
  }) async {
    try {
      return await _repository.startPhoneSignIn(phoneNumber: phoneNumber);
    } catch (e) {
      rethrow;
    }
  }

  Future<AuthUserEntity> confirmPhoneSignIn({
    required String sessionId,
    required String smsCode,
  }) async {
    try {
      return await _repository.confirmPhoneSignIn(
        sessionId: sessionId,
        smsCode: smsCode,
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Invio email reset password.
  Future<void> sendPasswordResetEmail({required String email}) async {
    try {
      return await _repository.sendPasswordResetEmail(email: email);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateContactEmail({required String email}) async {
    try {
      return await _repository.updateContactEmail(email: email);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> refreshBackendSession() async {
    try {
      return await _repository.refreshBackendSession();
    } catch (e) {
      rethrow;
    }
  }

  /// Logout.
  Future<void> signOut() async {
    try {
      return await _repository.signOut();
    } catch (e) {
      rethrow;
    }
  }

  /// Utente autenticato?
  bool get isAuthenticated => _repository.isAuthenticated;

  /// Ricarica utente dal server.
  Future<void> reloadUser() async {
    try {
      return await _repository.reloadUser();
    } catch (e) {
      rethrow;
    }
  }
}
