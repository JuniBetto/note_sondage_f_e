import 'package:firebase_auth/firebase_auth.dart' as firebase;
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:note_sondage/core/network/token_service.dart';
import 'package:note_sondage/feature/auth/domain/entities/auth_user_entity.dart';
import 'package:note_sondage/feature/auth/domain/repositories/auth_repository.dart';
import 'package:note_sondage/feature/auth/infrastructure/data/auth_mapper.dart';
import 'package:note_sondage/feature/auth/infrastructure/data/backend_auth_data_source.dart';

/// Implementazione concreta di [AuthRepository] con Firebase Auth.
///
/// Gestisce:
/// - Login/Register con email + password
/// - Login con Google SSO
/// - Reset password
/// - Stream di stato auth (per GoRouter refresh)
/// - Reload utente (per background → foreground)
class FirebaseAuthRepositoryImpl implements AuthRepository {
  final firebase.FirebaseAuth _firebaseAuth;
  final BackendAuthDataSource _backendAuth;
  final TokenService _tokenService;

  FirebaseAuthRepositoryImpl({
    firebase.FirebaseAuth? firebaseAuth,
    BackendAuthDataSource? backendAuth,
    TokenService? tokenService,
  }) : _firebaseAuth = firebaseAuth ?? firebase.FirebaseAuth.instance,
       _backendAuth = backendAuth ?? BackendAuthDataSource(),
       _tokenService = tokenService ?? TokenService();

  /// Scambia il Firebase ID Token con un JWT del backend.
  /// Non lancia eccezioni: se lo scambio fallisce, logga e continua.
  /// L'utente resta autenticato con Firebase, il JWT verrà ritentato.
  Future<void> _exchangeTokenWithBackend(firebase.User user) async {
    try {
      final firebaseIdToken = await user.getIdToken();
      if (firebaseIdToken != null) {
        final backendJwt = await _backendAuth.exchangeToken(firebaseIdToken);
        await _tokenService.saveToken(backendJwt);
        debugPrint('[Auth] Backend JWT ottenuto con successo.');
      }
    } catch (e) {
      debugPrint('[Auth] Scambio token con backend fallito: $e');
      // Non blocchiamo il login: l'utente è comunque autenticato con Firebase.
      // Il token verrà ritentato dall'AuthInterceptor al prossimo 401.
    }
  }

  @override
  Stream<AuthUserEntity> get authStateChanges {
    return _firebaseAuth.authStateChanges().map(
      (firebaseUser) => AuthMapper.fromFirebaseUser(firebaseUser),
    );
  }

  @override
  AuthUserEntity get currentUser {
    return AuthMapper.fromFirebaseUser(_firebaseAuth.currentUser);
  }

  @override
  bool get isAuthenticated => _firebaseAuth.currentUser != null;

  @override
  Future<AuthUserEntity> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Scambia il Firebase token con il backend per ottenere il JWT interno
      if (credential.user != null) {
        await _exchangeTokenWithBackend(credential.user!);
      }

      return AuthMapper.fromFirebaseUser(credential.user);
    } on firebase.FirebaseAuthException catch (e) {
      throw _mapFirebaseAuthException(e);
    }
  }

  @override
  Future<AuthUserEntity> createUserWithEmailAndPassword({
    required String email,
    required String password,
    String? displayName,
  }) async {
    try {
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Aggiorna il displayName se fornito
      if (displayName != null && credential.user != null) {
        await credential.user!.updateDisplayName(displayName);
        await credential.user!.reload();
      }

      // Scambia il Firebase token con il backend per ottenere il JWT interno
      final currentUser = _firebaseAuth.currentUser;
      if (currentUser != null) {
        await _exchangeTokenWithBackend(currentUser);
      }

      return AuthMapper.fromFirebaseUser(_firebaseAuth.currentUser);
    } on firebase.FirebaseAuthException catch (e) {
      throw _mapFirebaseAuthException(e);
    }
  }

  @override
  Future<AuthUserEntity> signInWithGoogle() async {
    try {
      final googleSignIn = GoogleSignIn.instance;

      // authenticate() shows the Google sign-in UI and returns a GoogleSignInAccount
      final googleUser = await googleSignIn.authenticate();

      // Get the idToken from the authentication result
      final idToken = googleUser.authentication.idToken;

      final credential = firebase.GoogleAuthProvider.credential(
        idToken: idToken,
      );

      final userCredential = await _firebaseAuth.signInWithCredential(
        credential,
      );

      // Scambia il Firebase token con il backend per ottenere il JWT interno
      if (userCredential.user != null) {
        await _exchangeTokenWithBackend(userCredential.user!);
      }

      return AuthMapper.fromFirebaseUser(userCredential.user);
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        throw const AuthException(
          code: 'google-sign-in-cancelled',
          message: 'Google sign-in was cancelled by user.',
        );
      }
      throw AuthException(
        code: 'google-sign-in-failed',
        message: e.description ?? 'Google sign-in failed.',
      );
    } on firebase.FirebaseAuthException catch (e) {
      throw _mapFirebaseAuthException(e);
    } catch (e) {
      throw AuthException(code: 'google-sign-in-failed', message: e.toString());
    }
  }

  @override
  Future<void> sendPasswordResetEmail({required String email}) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
    } on firebase.FirebaseAuthException catch (e) {
      throw _mapFirebaseAuthException(e);
    }
  }

  @override
  Future<void> signOut() async {
    try {
      // Rimuovi il JWT del backend
      await _tokenService.clearToken();

      await Future.wait([
        _firebaseAuth.signOut(),
        GoogleSignIn.instance.signOut(),
      ]);
    } catch (e) {
      throw AuthException(code: 'sign-out-failed', message: e.toString());
    }
  }

  @override
  Future<void> reloadUser() async {
    try {
      await _firebaseAuth.currentUser?.reload();
    } catch (e) {
      // Se il reload fallisce (es. token scaduto), non propagare
      // l'errore — il listener authStateChanges gestirà il logout
    }
  }

  /// Mappa le eccezioni Firebase in [AuthException] leggibili.
  AuthException _mapFirebaseAuthException(firebase.FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return const AuthException(
          code: 'user-not-found',
          message: 'No user found with this email address.',
        );
      case 'wrong-password':
        return const AuthException(
          code: 'wrong-password',
          message: 'Incorrect password.',
        );
      case 'email-already-in-use':
        return const AuthException(
          code: 'email-already-in-use',
          message: 'An account already exists with this email.',
        );
      case 'weak-password':
        return const AuthException(
          code: 'weak-password',
          message: 'The password is too weak.',
        );
      case 'invalid-email':
        return const AuthException(
          code: 'invalid-email',
          message: 'The email address is invalid.',
        );
      case 'user-disabled':
        return const AuthException(
          code: 'user-disabled',
          message: 'This user account has been disabled.',
        );
      case 'too-many-requests':
        return const AuthException(
          code: 'too-many-requests',
          message: 'Too many attempts. Please try again later.',
        );
      case 'network-request-failed':
        return const AuthException(
          code: 'network-error',
          message: 'A network error occurred. Check your connection.',
        );
      default:
        return AuthException(
          code: e.code,
          message: e.message ?? 'An authentication error occurred.',
        );
    }
  }
}

/// Eccezione personalizzata per errori di autenticazione.
class AuthException implements Exception {
  final String code;
  final String message;

  const AuthException({required this.code, required this.message});

  @override
  String toString() => 'AuthException($code): $message';
}
