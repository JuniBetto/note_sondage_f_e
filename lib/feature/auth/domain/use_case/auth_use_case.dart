import 'package:note_sondage/feature/auth/domain/entities/auth_user_entity.dart';
import 'package:note_sondage/feature/auth/domain/entities/mfa_factor_hint_entity.dart';
import 'package:note_sondage/feature/auth/domain/entities/phone_sign_in_start_result.dart';
import 'package:note_sondage/feature/auth/domain/entities/totp_enrollment_secret_entity.dart';
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

  Future<void> sendEmailVerification() async {
    try {
      return await _repository.sendEmailVerification();
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

  Future<void> updateMyProfile({
    String? displayName,
    List<int>? profileImageBytes,
    String? profileImageFileName,
  }) async {
    try {
      return await _repository.updateMyProfile(
        displayName: displayName,
        profileImageBytes: profileImageBytes,
        profileImageFileName: profileImageFileName,
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<List<MfaFactorHintEntity>> getEnrolledMfaFactors() async {
    try {
      return await _repository.getEnrolledMfaFactors();
    } catch (e) {
      rethrow;
    }
  }

  Future<PhoneSignInStartResult> startSmsMfaEnrollment({
    required String phoneNumber,
  }) async {
    try {
      return await _repository.startSmsMfaEnrollment(phoneNumber: phoneNumber);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> confirmSmsMfaEnrollment({
    required String sessionId,
    required String smsCode,
    String? displayName,
  }) async {
    try {
      return await _repository.confirmSmsMfaEnrollment(
        sessionId: sessionId,
        smsCode: smsCode,
        displayName: displayName,
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<TotpEnrollmentSecretEntity> startTotpMfaEnrollment({
    String? issuer,
    String? accountName,
  }) async {
    try {
      return await _repository.startTotpMfaEnrollment(
        issuer: issuer,
        accountName: accountName,
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<void> confirmTotpMfaEnrollment({
    required String verificationCode,
    String? displayName,
  }) async {
    try {
      return await _repository.confirmTotpMfaEnrollment(
        verificationCode: verificationCode,
        displayName: displayName,
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<PhoneSignInStartResult> requestPendingMfaSignInCode({
    String? factorUid,
  }) async {
    try {
      return await _repository.requestPendingMfaSignInCode(
        factorUid: factorUid,
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<AuthUserEntity> confirmPendingMfaSignIn({
    required String sessionId,
    required String smsCode,
  }) async {
    try {
      return await _repository.confirmPendingMfaSignIn(
        sessionId: sessionId,
        smsCode: smsCode,
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<AuthUserEntity> confirmPendingTotpMfaSignIn({
    required String factorUid,
    required String verificationCode,
  }) async {
    try {
      return await _repository.confirmPendingTotpMfaSignIn(
        factorUid: factorUid,
        verificationCode: verificationCode,
      );
    } catch (e) {
      rethrow;
    }
  }

  void clearPendingMfaSignInChallenge() {
    _repository.clearPendingMfaSignInChallenge();
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
