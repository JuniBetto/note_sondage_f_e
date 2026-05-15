import 'package:note_sondage/feature/auth/domain/entities/auth_user_entity.dart';
import 'package:note_sondage/feature/auth/domain/entities/mfa_factor_hint_entity.dart';
import 'package:note_sondage/feature/auth/domain/entities/phone_sign_in_start_result.dart';
import 'package:note_sondage/feature/auth/domain/entities/totp_enrollment_secret_entity.dart';

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
    List<int>? profileImageBytes,
    String? profileImageFileName,
  });

  /// Login con Google SSO.
  Future<AuthUserEntity> signInWithGoogle();

  /// Avvia login con telefono e invio OTP.
  Future<PhoneSignInStartResult> startPhoneSignIn({
    required String phoneNumber,
  });

  /// Conferma OTP del login telefonico.
  Future<AuthUserEntity> confirmPhoneSignIn({
    required String sessionId,
    required String smsCode,
  });

  /// Invio email di reset password.
  Future<void> sendPasswordResetEmail({required String email});

  /// Invia o reinvia l'email di verifica per l'utente autenticato.
  Future<void> sendEmailVerification();

  /// Richiede l'invio dell'email di conferma per cancellare l'account.
  Future<void> requestAccountDeletion({required String email});

  /// Conferma la cancellazione dell'account usando il token ricevuto via email.
  Future<void> confirmAccountDeletion({required String token});

  /// Richiede l'invio dell'email di conferma per riattivare l'account.
  Future<void> requestAccountReactivation({required String email});

  /// Conferma la riattivazione dell'account usando il token ricevuto via email.
  Future<void> confirmAccountReactivation({required String token});

  /// Aggiorna l'email di contatto usata da inviti e notifiche.
  Future<void> updateContactEmail({required String email});

  /// Aggiorna il profilo dell'utente autenticato.
  Future<void> updateMyProfile({
    String? displayName,
    List<int>? profileImageBytes,
    String? profileImageFileName,
  });

  /// Fattori MFA attualmente registrati per l'utente autenticato.
  Future<List<MfaFactorHintEntity>> getEnrolledMfaFactors();

  /// Avvia l'enrollment di un secondo fattore SMS.
  Future<PhoneSignInStartResult> startSmsMfaEnrollment({
    required String phoneNumber,
  });

  /// Conferma l'enrollment del secondo fattore SMS.
  Future<void> confirmSmsMfaEnrollment({
    required String sessionId,
    required String smsCode,
    String? displayName,
  });

  /// Avvia l'enrollment di un secondo fattore TOTP.
  Future<TotpEnrollmentSecretEntity> startTotpMfaEnrollment({
    String? issuer,
    String? accountName,
  });

  /// Conferma l'enrollment del secondo fattore TOTP.
  Future<void> confirmTotpMfaEnrollment({
    required String verificationCode,
    String? displayName,
  });

  /// Invia il codice per completare un login MFA pendente.
  Future<PhoneSignInStartResult> requestPendingMfaSignInCode({
    String? factorUid,
  });

  /// Conferma il codice per completare il login MFA pendente.
  Future<AuthUserEntity> confirmPendingMfaSignIn({
    required String sessionId,
    required String smsCode,
  });

  /// Conferma il login MFA pendente con TOTP.
  Future<AuthUserEntity> confirmPendingTotpMfaSignIn({
    required String factorUid,
    required String verificationCode,
  });

  /// Pulisce un eventuale challenge MFA pendente.
  void clearPendingMfaSignInChallenge();

  /// Rigenera il JWT interno del backend per riallineare gli header utente.
  Future<void> refreshBackendSession();

  /// Logout.
  Future<void> signOut();

  /// Verifica se l'utente è attualmente autenticato.
  bool get isAuthenticated;

  /// Ricarica l'utente corrente dal server (utile per background → foreground).
  Future<void> reloadUser();
}
