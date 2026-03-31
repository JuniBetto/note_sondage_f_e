import 'package:note_sondage/feature/auth/domain/entities/auth_user_entity.dart';

/// Repository astratto per l'autenticazione.
/// Definisce il contratto che ogni implementazione (Firebase, mock, etc.) deve rispettare.
abstract class AuthRepository {
  /// Stream che emette l'utente corrente ad ogni cambio di stato auth.
  Stream<AuthUserEntity> get authStateChanges;

  /// Utente corrente (sincrono, può essere empty).
  AuthUserEntity get currentUser;

  /// Login con email e password.
  Future<AuthUserEntity> signInWithEmailAndPassword({
    required String email,
    required String password,
  });

  /// Registrazione con email e password.
  Future<AuthUserEntity> createUserWithEmailAndPassword({
    required String email,
    required String password,
    String? displayName,
  });

  /// Login con Google SSO.
  Future<AuthUserEntity> signInWithGoogle();

  /// Invio email di reset password.
  Future<void> sendPasswordResetEmail({required String email});

  /// Logout.
  Future<void> signOut();

  /// Verifica se l'utente è attualmente autenticato.
  bool get isAuthenticated;

  /// Ricarica l'utente corrente dal server (utile per background → foreground).
  Future<void> reloadUser();
}
