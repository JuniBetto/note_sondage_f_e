import 'dart:async';
import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart' as firebase;
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:note_sondage/core/config/runtime_config.dart';
import 'package:note_sondage/core/network/token_service.dart';
import 'package:note_sondage/feature/auth/domain/entities/auth_mfa_required_exception.dart';
import 'package:note_sondage/feature/auth/domain/entities/auth_user_entity.dart';
import 'package:note_sondage/feature/auth/domain/entities/mfa_factor_hint_entity.dart';
import 'package:note_sondage/feature/auth/domain/entities/phone_sign_in_start_result.dart';
import 'package:note_sondage/feature/auth/domain/entities/totp_enrollment_secret_entity.dart';
import 'package:note_sondage/feature/auth/domain/repositories/auth_repository.dart';
import 'package:note_sondage/feature/auth/infrastructure/data/auth_mapper.dart';
import 'package:note_sondage/feature/auth/infrastructure/data/backend_auth_data_source.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Implementazione concreta di [AuthRepository] con Firebase Auth.
///
/// Gestisce:
/// - Login/Register con email + password
/// - Login con Google SSO
/// - Reset password
/// - Stream di stato auth (per GoRouter refresh)
/// - Reload utente (per background → foreground)
class FirebaseAuthRepositoryImpl implements AuthRepository {
  static const _pendingAvatarUidKey = 'pending_registration_avatar_uid';
  static const _pendingAvatarBytesKey = 'pending_registration_avatar_bytes';
  static const _pendingAvatarFileNameKey =
      'pending_registration_avatar_file_name';
  static const _webPhoneSessionPrefix = 'web-phone:';

  final firebase.FirebaseAuth _firebaseAuth;
  final BackendAuthDataSource _backendAuth;
  final TokenService _tokenService;
  final Map<String, firebase.ConfirmationResult> _webPhoneSessions = {};
  firebase.MultiFactorResolver? _pendingMfaResolver;
  firebase.TotpSecret? _pendingTotpEnrollmentSecret;
  Future<void>? _backendExchangeInFlight;
  String? _backendExchangeUid;
  DateTime? _lastSuccessfulExchangeAt;
  String? _lastSuccessfulExchangeUid;

  FirebaseAuthRepositoryImpl({
    firebase.FirebaseAuth? firebaseAuth,
    BackendAuthDataSource? backendAuth,
    TokenService? tokenService,
  }) : _firebaseAuth = firebaseAuth ?? firebase.FirebaseAuth.instance,
       _backendAuth = backendAuth ?? BackendAuthDataSource(),
       _tokenService = tokenService ?? TokenService();

  /// Scambia il Firebase ID Token con un JWT del backend.
  /// Di default non lancia eccezioni: se lo scambio fallisce, logga e continua.
  /// Quando [propagateErrors] è true, il login corrente fallisce in modo esplicito.
  Future<void> _exchangeTokenWithBackend(
    firebase.User user, {
    bool propagateErrors = false,
  }) async {
    final uid = user.uid;
    final now = DateTime.now();

    if (_backendExchangeInFlight != null && _backendExchangeUid == uid) {
      await _backendExchangeInFlight;
      return;
    }

    if (_lastSuccessfulExchangeUid == uid &&
        _lastSuccessfulExchangeAt != null &&
        now.difference(_lastSuccessfulExchangeAt!) <
            const Duration(seconds: 10)) {
      return;
    }

    late final Future<void> exchangeFuture;
    _backendExchangeUid = uid;
    exchangeFuture = () async {
      try {
        final firebaseIdToken = await user.getIdToken();
        if (firebaseIdToken != null) {
          final backendJwt = await _backendAuth.exchangeToken(firebaseIdToken);
          await _tokenService.saveToken(backendJwt);
          _lastSuccessfulExchangeUid = uid;
          _lastSuccessfulExchangeAt = DateTime.now();
          debugPrint('[Auth] Backend JWT ottenuto con successo.');
        }
      } catch (e) {
        debugPrint('[Auth] Scambio token con backend fallito: $e');
        if (propagateErrors) {
          if (_isTransientBackendExchangeError(e)) {
            debugPrint(
              '[Auth] Backend exchange failed temporarily. The session stays active and will retry on the next protected request.',
            );
            return;
          }
          await signOut();
          throw _mapBackendExchangeError(e);
        }
        // Non blocchiamo il recupero background della sessione: il token verrà
        // ritentato dall'AuthInterceptor al prossimo 401.
      } finally {
        if (identical(_backendExchangeInFlight, exchangeFuture)) {
          _backendExchangeInFlight = null;
          _backendExchangeUid = null;
        }
      }
    }();

    _backendExchangeInFlight = exchangeFuture;

    try {
      await exchangeFuture;
    } finally {
      if (identical(_backendExchangeInFlight, exchangeFuture)) {
        _backendExchangeInFlight = null;
        _backendExchangeUid = null;
      }
    }
  }

  @override
  Stream<AuthUserEntity> get authStateChanges {
    return _firebaseAuth.authStateChanges().map((firebaseUser) {
      if (firebaseUser != null) {
        unawaited(_exchangeTokenWithBackend(firebaseUser));
      } else {
        _backendExchangeInFlight = null;
        _backendExchangeUid = null;
        _lastSuccessfulExchangeAt = null;
        _lastSuccessfulExchangeUid = null;
        unawaited(_tokenService.clearToken());
      }
      return AuthMapper.fromFirebaseUser(firebaseUser);
    });
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

      await credential.user?.reload();
      final currentUser = _firebaseAuth.currentUser ?? credential.user;
      if (currentUser != null) {
        await _exchangeTokenWithBackend(currentUser, propagateErrors: true);
        await _syncBackendProfile(
          currentUser: currentUser,
          displayName: currentUser.displayName,
        );
        await _syncPendingRegistrationProfile(currentUser);
      }

      _pendingMfaResolver = null;
      _pendingTotpEnrollmentSecret = null;
      return AuthMapper.fromFirebaseUser(currentUser);
    } on firebase.FirebaseAuthMultiFactorException catch (e) {
      _pendingMfaResolver = e.resolver;
      throw AuthMfaRequiredException(
        factors: _mapFactorHints(e.resolver.hints),
        message: 'Enter the verification code sent to your second factor.',
      );
    } on firebase.FirebaseAuthException catch (e) {
      throw _mapFirebaseAuthException(e);
    }
  }

  @override
  Future<AuthUserEntity> createUserWithEmailAndPassword({
    required String email,
    required String password,
    String? displayName,
    List<int>? profileImageBytes,
    String? profileImageFileName,
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

      final currentUser = _firebaseAuth.currentUser;
      if (currentUser != null) {
        await _sendEmailVerification(currentUser);
        await _cachePendingRegistrationProfile(
          firebaseUid: currentUser.uid,
          profileImageBytes: profileImageBytes,
          profileImageFileName: profileImageFileName,
        );
      }

      final registeredUser = AuthMapper.fromFirebaseUser(currentUser);
      await signOut();
      return registeredUser;
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
        await _exchangeTokenWithBackend(
          userCredential.user!,
          propagateErrors: true,
        );
        await _syncBackendProfile(
          currentUser: userCredential.user!,
          displayName: userCredential.user!.displayName,
        );
      }

      _pendingMfaResolver = null;
      _pendingTotpEnrollmentSecret = null;
      return AuthMapper.fromFirebaseUser(userCredential.user);
    } on firebase.FirebaseAuthMultiFactorException catch (e) {
      _pendingMfaResolver = e.resolver;
      throw AuthMfaRequiredException(
        factors: _mapFactorHints(e.resolver.hints),
        message: 'Enter the verification code sent to your second factor.',
      );
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
      throw const AuthException(
        code: 'google-sign-in-failed',
        message:
            'We could not complete Google sign-in right now. Please try again.',
      );
    }
  }

  @override
  Future<PhoneSignInStartResult> startPhoneSignIn({
    required String phoneNumber,
  }) async {
    final normalizedPhone = phoneNumber.trim();
    if (normalizedPhone.isEmpty) {
      throw const AuthException(
        code: 'invalid-phone-number',
        message: 'Please enter a valid phone number.',
      );
    }

    if (kIsWeb) {
      try {
        final confirmation = await _firebaseAuth.signInWithPhoneNumber(
          normalizedPhone,
        );
        final sessionId =
            '$_webPhoneSessionPrefix${confirmation.verificationId}';
        _webPhoneSessions[sessionId] = confirmation;
        return PhoneSignInStartResult.codeSent(sessionId);
      } on firebase.FirebaseAuthException catch (e) {
        throw _mapFirebaseAuthException(e);
      }
    }

    final completer = Completer<PhoneSignInStartResult>();
    try {
      await _firebaseAuth.verifyPhoneNumber(
        phoneNumber: normalizedPhone,
        verificationCompleted: (credential) async {
          if (completer.isCompleted) return;
          try {
            final userCredential = await _firebaseAuth.signInWithCredential(
              credential,
            );
            if (userCredential.user != null) {
              await _exchangeTokenWithBackend(
                userCredential.user!,
                propagateErrors: true,
              );
              completer.complete(
                PhoneSignInStartResult.completed(
                  AuthMapper.fromFirebaseUser(userCredential.user),
                ),
              );
            } else {
              completer.completeError(
                const AuthException(
                  code: 'phone-sign-in-failed',
                  message: 'Phone sign-in did not return a valid user.',
                ),
              );
            }
          } catch (e) {
            completer.completeError(e);
          }
        },
        verificationFailed: (error) {
          if (!completer.isCompleted) {
            completer.completeError(_mapFirebaseAuthException(error));
          }
        },
        codeSent: (verificationId, _) {
          if (!completer.isCompleted) {
            completer.complete(PhoneSignInStartResult.codeSent(verificationId));
          }
        },
        codeAutoRetrievalTimeout: (_) {
          if (!completer.isCompleted) {
            completer.completeError(
              const AuthException(
                code: 'phone-code-timeout',
                message:
                    'The verification code request timed out. Please try again.',
              ),
            );
          }
        },
      );
      return await completer.future;
    } on firebase.FirebaseAuthException catch (e) {
      throw _mapFirebaseAuthException(e);
    }
  }

  @override
  Future<AuthUserEntity> confirmPhoneSignIn({
    required String sessionId,
    required String smsCode,
  }) async {
    final normalizedCode = smsCode.trim();
    if (normalizedCode.isEmpty) {
      throw const AuthException(
        code: 'missing-sms-code',
        message: 'Please enter the verification code you received.',
      );
    }

    try {
      firebase.UserCredential userCredential;
      if (sessionId.startsWith(_webPhoneSessionPrefix)) {
        final confirmation = _webPhoneSessions.remove(sessionId);
        if (confirmation == null) {
          throw const AuthException(
            code: 'phone-session-expired',
            message:
                'This phone verification session has expired. Please request a new code.',
          );
        }
        userCredential = await confirmation.confirm(normalizedCode);
      } else {
        final credential = firebase.PhoneAuthProvider.credential(
          verificationId: sessionId,
          smsCode: normalizedCode,
        );
        userCredential = await _firebaseAuth.signInWithCredential(credential);
      }

      final user = userCredential.user;
      if (user == null) {
        throw const AuthException(
          code: 'phone-sign-in-failed',
          message: 'Phone sign-in did not return a valid user.',
        );
      }

      await _exchangeTokenWithBackend(user, propagateErrors: true);
      return AuthMapper.fromFirebaseUser(user);
    } on firebase.FirebaseAuthException catch (e) {
      throw _mapFirebaseAuthException(e);
    }
  }

  @override
  Future<void> sendPasswordResetEmail({required String email}) async {
    final normalizedEmail = email.trim();
    try {
      await _backendAuth.requestPasswordReset(normalizedEmail);
      await _firebaseAuth.sendPasswordResetEmail(
        email: normalizedEmail,
        actionCodeSettings: _buildPasswordResetActionCodeSettings(),
      );
    } on firebase.FirebaseAuthException catch (e) {
      throw _mapFirebaseAuthException(e);
    }
  }

  @override
  Future<void> sendEmailVerification() async {
    final currentUser = _firebaseAuth.currentUser;
    if (currentUser == null) {
      throw const AuthException(
        code: 'not-authenticated',
        message: 'You need to be signed in to verify your email address.',
      );
    }

    await _sendEmailVerification(currentUser);
  }

  @override
  Future<void> requestAccountDeletion({required String email}) async {
    await _backendAuth.requestAccountDeletion(email.trim());
  }

  @override
  Future<void> confirmAccountDeletion({required String token}) async {
    final response = await _backendAuth.confirmAccountDeletion(token.trim());
    final deletedFirebaseUid = response['firebaseUid']?.toString().trim();
    final currentUser = _firebaseAuth.currentUser;

    if (currentUser != null &&
        deletedFirebaseUid != null &&
        deletedFirebaseUid.isNotEmpty &&
        currentUser.uid == deletedFirebaseUid) {
      await signOut();
      return;
    }

    try {
      await currentUser?.reload();
    } catch (_) {
      // Ignore reload failures for public confirmation flows.
    }
  }

  @override
  Future<void> requestAccountReactivation({required String email}) async {
    await _backendAuth.requestAccountReactivation(email.trim());
  }

  @override
  Future<void> confirmAccountReactivation({required String token}) async {
    final response = await _backendAuth.confirmAccountReactivation(token.trim());
    final reactivatedFirebaseUid = response['firebaseUid']?.toString().trim();
    final currentUser = _firebaseAuth.currentUser;

    if (currentUser != null &&
        reactivatedFirebaseUid != null &&
        reactivatedFirebaseUid.isNotEmpty &&
        currentUser.uid == reactivatedFirebaseUid) {
      await _exchangeTokenWithBackend(currentUser, propagateErrors: true);
      return;
    }
  }

  @override
  Future<void> updateContactEmail({required String email}) async {
    await _backendAuth.updateContactEmail(email);
    await refreshBackendSession();
  }

  @override
  Future<void> updateMyProfile({
    String? displayName,
    List<int>? profileImageBytes,
    String? profileImageFileName,
  }) async {
    final currentUser = _firebaseAuth.currentUser;
    if (currentUser == null) {
      throw const AuthException(
        code: 'not-authenticated',
        message: 'You need to be signed in to update your profile.',
      );
    }

    final normalizedDisplayName = displayName?.trim();
    final hasDisplayNameUpdate =
        normalizedDisplayName != null && normalizedDisplayName.isNotEmpty;
    final hasProfileImageUpdate =
        profileImageBytes != null && profileImageBytes.isNotEmpty;

    if (!hasDisplayNameUpdate && !hasProfileImageUpdate) {
      return;
    }

    String? avatarPath;
    if (hasProfileImageUpdate) {
      avatarPath = await _backendAuth.uploadProfileImage(
        firebaseUid: currentUser.uid,
        imageBytes: profileImageBytes!,
        fileName: profileImageFileName ?? 'profile.jpg',
      );
    }

    await _backendAuth.updateMyProfile(
      fullName: hasDisplayNameUpdate ? normalizedDisplayName : null,
      avatarUrl: avatarPath,
    );

    if (hasDisplayNameUpdate) {
      await currentUser.updateDisplayName(normalizedDisplayName);
    }
    if (avatarPath != null && avatarPath.isNotEmpty) {
      await currentUser.updatePhotoURL(avatarPath);
    }
    await currentUser.reload();
    await refreshBackendSession();
  }

  @override
  Future<List<MfaFactorHintEntity>> getEnrolledMfaFactors() async {
    final currentUser = _firebaseAuth.currentUser;
    if (currentUser == null) {
      throw const AuthException(
        code: 'not-authenticated',
        message:
            'You need to be signed in to manage two-factor authentication.',
      );
    }

    await currentUser.reload();
    final factors = await currentUser.multiFactor.getEnrolledFactors();
    return _mapFactorHints(factors);
  }

  @override
  Future<PhoneSignInStartResult> startSmsMfaEnrollment({
    required String phoneNumber,
  }) async {
    final normalizedPhone = phoneNumber.trim();
    if (normalizedPhone.isEmpty) {
      throw const AuthException(
        code: 'invalid-phone-number',
        message: 'Please enter a valid phone number.',
      );
    }

    final currentUser = _firebaseAuth.currentUser;
    if (currentUser == null) {
      throw const AuthException(
        code: 'not-authenticated',
        message:
            'You need to be signed in to enable two-factor authentication.',
      );
    }
    if (!currentUser.emailVerified) {
      throw const AuthException(
        code: 'email-not-verified',
        message:
            'Verify your email address before enabling two-factor authentication.',
      );
    }

    final completer = Completer<PhoneSignInStartResult>();
    try {
      _pendingTotpEnrollmentSecret = null;
      final multiFactorSession = await currentUser.multiFactor.getSession();
      await _firebaseAuth.verifyPhoneNumber(
        phoneNumber: normalizedPhone,
        multiFactorSession: multiFactorSession,
        verificationCompleted: (_) {},
        verificationFailed: (error) {
          if (!completer.isCompleted) {
            completer.completeError(_mapFirebaseAuthException(error));
          }
        },
        codeSent: (verificationId, _) {
          if (!completer.isCompleted) {
            completer.complete(PhoneSignInStartResult.codeSent(verificationId));
          }
        },
        codeAutoRetrievalTimeout: (_) {
          if (!completer.isCompleted) {
            completer.completeError(
              const AuthException(
                code: 'phone-code-timeout',
                message:
                    'The verification code request timed out. Please try again.',
              ),
            );
          }
        },
      );
      return await completer.future;
    } on firebase.FirebaseAuthException catch (e) {
      throw _mapFirebaseAuthException(e);
    }
  }

  @override
  Future<void> confirmSmsMfaEnrollment({
    required String sessionId,
    required String smsCode,
    String? displayName,
  }) async {
    final currentUser = _firebaseAuth.currentUser;
    if (currentUser == null) {
      throw const AuthException(
        code: 'not-authenticated',
        message:
            'You need to be signed in to enable two-factor authentication.',
      );
    }

    final normalizedCode = smsCode.trim();
    if (sessionId.trim().isEmpty || normalizedCode.isEmpty) {
      throw const AuthException(
        code: 'missing-sms-code',
        message: 'Please enter the verification code you received.',
      );
    }

    try {
      final credential = firebase.PhoneAuthProvider.credential(
        verificationId: sessionId.trim(),
        smsCode: normalizedCode,
      );
      await currentUser.multiFactor.enroll(
        firebase.PhoneMultiFactorGenerator.getAssertion(credential),
        displayName: displayName?.trim().isEmpty ?? true
            ? null
            : displayName?.trim(),
      );
      await currentUser.reload();
      await refreshBackendSession();
    } on firebase.FirebaseAuthException catch (e) {
      throw _mapFirebaseAuthException(e);
    }
  }

  @override
  Future<TotpEnrollmentSecretEntity> startTotpMfaEnrollment({
    String? issuer,
    String? accountName,
  }) async {
    final currentUser = _firebaseAuth.currentUser;
    if (currentUser == null) {
      throw const AuthException(
        code: 'not-authenticated',
        message:
            'You need to be signed in to enable two-factor authentication.',
      );
    }
    if (!currentUser.emailVerified) {
      throw const AuthException(
        code: 'email-not-verified',
        message:
            'Verify your email address before enabling two-factor authentication.',
      );
    }

    try {
      final multiFactorSession = await currentUser.multiFactor.getSession();
      final secret = await firebase.TotpMultiFactorGenerator.generateSecret(
        multiFactorSession,
      );
      final resolvedAccountName = accountName?.trim().isNotEmpty == true
          ? accountName!.trim()
          : currentUser.email?.trim().isNotEmpty == true
          ? currentUser.email!.trim()
          : currentUser.uid;
      final resolvedIssuer = issuer?.trim().isNotEmpty == true
          ? issuer!.trim()
          : 'NoteSondage';
      final qrCodeUrl = await secret.generateQrCodeUrl(
        accountName: resolvedAccountName,
        issuer: resolvedIssuer,
      );
      _pendingTotpEnrollmentSecret = secret;
      return TotpEnrollmentSecretEntity(
        secretKey: secret.secretKey,
        qrCodeUrl: qrCodeUrl,
        accountName: resolvedAccountName,
        issuer: resolvedIssuer,
        codeLength: secret.codeLength,
        codeIntervalSeconds: secret.codeIntervalSeconds,
      );
    } on firebase.FirebaseAuthException catch (e) {
      throw _mapFirebaseAuthException(e);
    }
  }

  @override
  Future<void> confirmTotpMfaEnrollment({
    required String verificationCode,
    String? displayName,
  }) async {
    final currentUser = _firebaseAuth.currentUser;
    if (currentUser == null) {
      throw const AuthException(
        code: 'not-authenticated',
        message:
            'You need to be signed in to enable two-factor authentication.',
      );
    }

    final secret = _pendingTotpEnrollmentSecret;
    final normalizedCode = verificationCode.trim();
    if (secret == null) {
      throw const AuthException(
        code: 'totp-setup-expired',
        message:
            'The authenticator setup expired. Generate a new QR code and try again.',
      );
    }
    if (normalizedCode.isEmpty) {
      throw const AuthException(
        code: 'missing-verification-code',
        message: 'Enter the verification code from your authenticator app.',
      );
    }

    try {
      final assertion =
          await firebase.TotpMultiFactorGenerator.getAssertionForEnrollment(
            secret,
            normalizedCode,
          );
      final resolvedDisplayName = displayName?.trim().isNotEmpty == true
          ? displayName!.trim()
          : 'Authenticator app';
      await currentUser.multiFactor.enroll(
        assertion,
        displayName: resolvedDisplayName,
      );
      _pendingTotpEnrollmentSecret = null;
      await currentUser.reload();
      await refreshBackendSession();
    } on firebase.FirebaseAuthException catch (e) {
      throw _mapFirebaseAuthException(e);
    }
  }

  @override
  Future<PhoneSignInStartResult> requestPendingMfaSignInCode({
    String? factorUid,
  }) async {
    final resolver = _pendingMfaResolver;
    if (resolver == null) {
      throw const AuthException(
        code: 'no-pending-mfa-challenge',
        message: 'There is no pending two-factor sign-in challenge.',
      );
    }

    firebase.MultiFactorInfo? selectedFactor;
    if (factorUid != null && factorUid.trim().isNotEmpty) {
      for (final factor in resolver.hints) {
        if (factor.uid == factorUid.trim()) {
          selectedFactor = factor;
          break;
        }
      }
    }
    selectedFactor ??= resolver.hints.isNotEmpty ? resolver.hints.first : null;
    if (selectedFactor == null ||
        selectedFactor is! firebase.PhoneMultiFactorInfo) {
      throw const AuthException(
        code: 'unsupported-second-factor',
        message: 'No supported second factor is available for this account.',
      );
    }

    final completer = Completer<PhoneSignInStartResult>();
    try {
      await _firebaseAuth.verifyPhoneNumber(
        multiFactorSession: resolver.session,
        multiFactorInfo: selectedFactor,
        verificationCompleted: (_) {},
        verificationFailed: (error) {
          if (!completer.isCompleted) {
            completer.completeError(_mapFirebaseAuthException(error));
          }
        },
        codeSent: (verificationId, _) {
          if (!completer.isCompleted) {
            completer.complete(PhoneSignInStartResult.codeSent(verificationId));
          }
        },
        codeAutoRetrievalTimeout: (_) {
          if (!completer.isCompleted) {
            completer.completeError(
              const AuthException(
                code: 'phone-code-timeout',
                message:
                    'The verification code request timed out. Please try again.',
              ),
            );
          }
        },
      );
      return await completer.future;
    } on firebase.FirebaseAuthException catch (e) {
      throw _mapFirebaseAuthException(e);
    }
  }

  @override
  Future<AuthUserEntity> confirmPendingMfaSignIn({
    required String sessionId,
    required String smsCode,
  }) async {
    final resolver = _pendingMfaResolver;
    if (resolver == null) {
      throw const AuthException(
        code: 'no-pending-mfa-challenge',
        message: 'There is no pending two-factor sign-in challenge.',
      );
    }

    final normalizedCode = smsCode.trim();
    if (sessionId.trim().isEmpty || normalizedCode.isEmpty) {
      throw const AuthException(
        code: 'missing-sms-code',
        message: 'Please enter the verification code you received.',
      );
    }

    try {
      final credential = firebase.PhoneAuthProvider.credential(
        verificationId: sessionId.trim(),
        smsCode: normalizedCode,
      );
      final result = await resolver.resolveSignIn(
        firebase.PhoneMultiFactorGenerator.getAssertion(credential),
      );
      final user = result.user;
      if (user == null) {
        throw const AuthException(
          code: 'phone-sign-in-failed',
          message: 'Two-factor sign-in did not return a valid user.',
        );
      }

      _pendingMfaResolver = null;
      await _exchangeTokenWithBackend(user, propagateErrors: true);
      await _syncBackendProfile(
        currentUser: user,
        displayName: user.displayName,
      );
      return AuthMapper.fromFirebaseUser(user);
    } on firebase.FirebaseAuthException catch (e) {
      throw _mapFirebaseAuthException(e);
    }
  }

  @override
  Future<AuthUserEntity> confirmPendingTotpMfaSignIn({
    required String factorUid,
    required String verificationCode,
  }) async {
    final resolver = _pendingMfaResolver;
    if (resolver == null) {
      throw const AuthException(
        code: 'no-pending-mfa-challenge',
        message: 'There is no pending two-factor sign-in challenge.',
      );
    }

    final normalizedFactorUid = factorUid.trim();
    final normalizedCode = verificationCode.trim();
    if (normalizedFactorUid.isEmpty || normalizedCode.isEmpty) {
      throw const AuthException(
        code: 'missing-verification-code',
        message: 'Enter the verification code from your authenticator app.',
      );
    }

    try {
      final assertion =
          await firebase.TotpMultiFactorGenerator.getAssertionForSignIn(
            normalizedFactorUid,
            normalizedCode,
          );
      final result = await resolver.resolveSignIn(assertion);
      final user = result.user;
      if (user == null) {
        throw const AuthException(
          code: 'totp-sign-in-failed',
          message: 'Two-factor sign-in did not return a valid user.',
        );
      }

      _pendingMfaResolver = null;
      _pendingTotpEnrollmentSecret = null;
      await _exchangeTokenWithBackend(user, propagateErrors: true);
      await _syncBackendProfile(
        currentUser: user,
        displayName: user.displayName,
      );
      return AuthMapper.fromFirebaseUser(user);
    } on firebase.FirebaseAuthException catch (e) {
      throw _mapFirebaseAuthException(e);
    }
  }

  @override
  void clearPendingMfaSignInChallenge() {
    _pendingMfaResolver = null;
    _pendingTotpEnrollmentSecret = null;
  }

  @override
  Future<void> refreshBackendSession() async {
    final currentUser = _firebaseAuth.currentUser;
    if (currentUser == null) {
      throw const AuthException(
        code: 'not-authenticated',
        message: 'You need to be signed in to refresh the session.',
      );
    }
    await _exchangeTokenWithBackend(currentUser, propagateErrors: true);
  }

  @override
  Future<void> signOut() async {
    try {
      // Rimuovi il JWT del backend
      await _tokenService.clearToken();
      _pendingMfaResolver = null;
      _pendingTotpEnrollmentSecret = null;
      _backendExchangeInFlight = null;
      _backendExchangeUid = null;
      _lastSuccessfulExchangeAt = null;
      _lastSuccessfulExchangeUid = null;

      await Future.wait([
        _firebaseAuth.signOut(),
        GoogleSignIn.instance.signOut(),
      ]);
    } catch (e) {
      throw const AuthException(
        code: 'sign-out-failed',
        message: 'We could not sign you out right now. Please try again.',
      );
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
      case 'invalid-phone-number':
        return const AuthException(
          code: 'invalid-phone-number',
          message: 'The phone number format is invalid.',
        );
      case 'invalid-verification-code':
        return const AuthException(
          code: 'invalid-verification-code',
          message: 'The verification code is incorrect.',
        );
      case 'invalid-verification-id':
        return const AuthException(
          code: 'invalid-verification-id',
          message: 'The phone verification session is no longer valid.',
        );
      case 'session-expired':
        return const AuthException(
          code: 'session-expired',
          message:
              'The verification code has expired. Please request a new one.',
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
      case 'requires-recent-login':
        return const AuthException(
          code: 'requires-recent-login',
          message:
              'For security reasons, sign out and sign in again before enabling two-factor authentication.',
        );
      case 'second-factor-already-in-use':
        return const AuthException(
          code: 'second-factor-already-in-use',
          message:
              'This phone number is already registered as a second factor.',
        );
      case 'maximum-second-factor-count-exceeded':
        return const AuthException(
          code: 'maximum-second-factor-count-exceeded',
          message: 'You have reached the maximum number of second factors.',
        );
      case 'unverified-email':
        return const AuthException(
          code: 'unverified-email',
          message:
              'Verify your email address before enabling two-factor authentication.',
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

  Future<void> _sendEmailVerification(firebase.User user) async {
    final targetUrl = _buildEmailConfirmationUrl();
    if (targetUrl == null) {
      await user.sendEmailVerification();
      return;
    }

    await user.sendEmailVerification(
      firebase.ActionCodeSettings(url: targetUrl, handleCodeInApp: false),
    );
  }

  String? _buildEmailConfirmationUrl() {
    if (RuntimeConfig.hasCustomEmailConfirmationUrl) {
      return RuntimeConfig.resolvedEmailConfirmationUrl;
    }

    if (kIsWeb) {
      return '${Uri.base.origin}/confirm-registration';
    }

    return null;
  }

  firebase.ActionCodeSettings? _buildPasswordResetActionCodeSettings() {
    final targetUrl = _buildPasswordResetUrl();
    if (targetUrl == null) {
      return null;
    }

    return firebase.ActionCodeSettings(url: targetUrl, handleCodeInApp: false);
  }

  String? _buildPasswordResetUrl() {
    if (RuntimeConfig.hasCustomPasswordResetUrl) {
      return RuntimeConfig.resolvedPasswordResetUrl;
    }

    if (kIsWeb) {
      return '${Uri.base.origin}/reset-password';
    }

    return null;
  }

  Future<void> _cachePendingRegistrationProfile({
    required String firebaseUid,
    List<int>? profileImageBytes,
    String? profileImageFileName,
  }) async {
    if (profileImageBytes == null || profileImageBytes.isEmpty) {
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_pendingAvatarUidKey, firebaseUid);
    await prefs.setString(
      _pendingAvatarBytesKey,
      base64Encode(profileImageBytes),
    );
    await prefs.setString(
      _pendingAvatarFileNameKey,
      profileImageFileName ?? 'profile.jpg',
    );
  }

  Future<void> _syncPendingRegistrationProfile(
    firebase.User currentUser,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final pendingUid = prefs.getString(_pendingAvatarUidKey);
    final pendingBytes = prefs.getString(_pendingAvatarBytesKey);

    if (pendingUid != currentUser.uid ||
        pendingBytes == null ||
        pendingBytes.isEmpty) {
      return;
    }

    try {
      await _syncBackendProfile(
        currentUser: currentUser,
        profileImageBytes: base64Decode(pendingBytes),
        profileImageFileName:
            prefs.getString(_pendingAvatarFileNameKey) ?? 'profile.jpg',
      );
      await _clearPendingRegistrationProfile();
    } catch (e) {
      debugPrint('[Auth] Pending avatar sync failed: $e');
    }
  }

  Future<void> _clearPendingRegistrationProfile() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_pendingAvatarUidKey);
    await prefs.remove(_pendingAvatarBytesKey);
    await prefs.remove(_pendingAvatarFileNameKey);
  }

  Future<void> _syncBackendProfile({
    required firebase.User currentUser,
    String? displayName,
    List<int>? profileImageBytes,
    String? profileImageFileName,
  }) async {
    try {
      String? avatarPath;
      if (profileImageBytes != null && profileImageBytes.isNotEmpty) {
        avatarPath = await _backendAuth.uploadProfileImage(
          firebaseUid: currentUser.uid,
          imageBytes: profileImageBytes,
          fileName: profileImageFileName ?? 'profile.jpg',
        );
      }

      if ((displayName != null && displayName.trim().isNotEmpty) ||
          (avatarPath != null && avatarPath.isNotEmpty)) {
        await _backendAuth.updateMyProfile(
          fullName: displayName,
          avatarUrl: avatarPath,
        );
      }

      if (avatarPath != null && avatarPath.isNotEmpty) {
        await currentUser.updatePhotoURL(avatarPath);
        await currentUser.reload();
      }
    } catch (e) {
      debugPrint('[Auth] Profile sync after registration failed: $e');
    }
  }

  AuthException _mapBackendExchangeError(Object error) {
    final message = error.toString();
    final lowered = message.toLowerCase();
    if (lowered.contains('403') && lowered.contains('email not verified')) {
      return const AuthException(
        code: 'email-not-verified',
        message: 'Please verify your email address before logging in.',
      );
    }

    return const AuthException(
      code: 'backend-auth-failed',
      message: 'Unable to complete sign-in right now. Please try again.',
    );
  }

  bool _isTransientBackendExchangeError(Object error) {
    final lowered = error.toString().toLowerCase();
    return lowered.contains('timed out') ||
        lowered.contains('timeout') ||
        lowered.contains('receive timeout') ||
        lowered.contains('connect timeout') ||
        lowered.contains('send timeout') ||
        lowered.contains('socketexception') ||
        lowered.contains('network error') ||
        lowered.contains('failed host lookup') ||
        lowered.contains('connection error') ||
        lowered.contains('no status');
  }

  List<MfaFactorHintEntity> _mapFactorHints(
    List<firebase.MultiFactorInfo> hints,
  ) {
    return hints.map((hint) {
      final type = switch (hint) {
        firebase.PhoneMultiFactorInfo _ => MfaFactorType.sms,
        firebase.TotpMultiFactorInfo _ => MfaFactorType.totp,
        _ => hint.factorId == 'totp' ? MfaFactorType.totp : MfaFactorType.sms,
      };
      final phoneNumber = hint is firebase.PhoneMultiFactorInfo
          ? hint.phoneNumber
          : null;
      return MfaFactorHintEntity(
        uid: hint.uid,
        type: type,
        displayName: hint.displayName,
        phoneNumber: phoneNumber,
      );
    }).toList();
  }
}

/// Eccezione personalizzata per errori di autenticazione.
class AuthException implements Exception {
  final String code;
  final String message;

  const AuthException({required this.code, required this.message});

  @override
  String toString() => message;
}
