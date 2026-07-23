import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:note_sondage/feature/auth/domain/entities/auth_mfa_required_exception.dart';
import 'package:note_sondage/feature/auth/domain/entities/auth_user_entity.dart';
import 'package:note_sondage/feature/auth/domain/entities/mfa_factor_hint_entity.dart';
import 'package:note_sondage/feature/auth/domain/entities/phone_sign_in_start_result.dart';
import 'package:note_sondage/feature/auth/domain/entities/totp_enrollment_secret_entity.dart';
import 'package:note_sondage/feature/auth/domain/repositories/auth_repository.dart';
import 'package:note_sondage/feature/auth/domain/use_case/auth_use_case.dart';
import 'package:note_sondage/feature/auth/ui/bloc/auth_bloc.dart';

class _FakeAuthRepository implements AuthRepository {
  _FakeAuthRepository() : _authStateController = StreamController.broadcast();

  final StreamController<AuthUserEntity> _authStateController;

  Future<AuthUserEntity> Function({
    required String email,
    required String password,
  })?
  signInHandler;
  Future<AuthUserEntity> Function({
    required String email,
    required String password,
    String? displayName,
    List<int>? profileImageBytes,
    String? profileImageFileName,
  })?
  createUserHandler;
  Future<void> Function()? reloadUserHandler;

  AuthUserEntity currentUserValue = AuthUserEntity.empty;
  int clearPendingMfaChallengeCalls = 0;

  @override
  Stream<AuthUserEntity> get authStateChanges => _authStateController.stream;

  @override
  AuthUserEntity get currentUser => currentUserValue;

  void emitUser(AuthUserEntity user) {
    currentUserValue = user;
    _authStateController.add(user);
  }

  Future<void> dispose() async {
    await _authStateController.close();
  }

  @override
  void clearPendingMfaSignInChallenge() {
    clearPendingMfaChallengeCalls++;
  }

  @override
  Future<AuthUserEntity> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) {
    return signInHandler?.call(email: email, password: password) ??
        Future<AuthUserEntity>.value(currentUserValue);
  }

  @override
  Future<AuthUserEntity> createUserWithEmailAndPassword({
    required String email,
    required String password,
    String? displayName,
    List<int>? profileImageBytes,
    String? profileImageFileName,
  }) {
    return createUserHandler?.call(
          email: email,
          password: password,
          displayName: displayName,
          profileImageBytes: profileImageBytes,
          profileImageFileName: profileImageFileName,
        ) ??
        Future<AuthUserEntity>.value(currentUserValue);
  }

  @override
  Future<void> reloadUser() async {
    await reloadUserHandler?.call();
  }

  @override
  bool get isAuthenticated => currentUserValue.isNotEmpty;

  @override
  Future<void> refreshBackendSession() async {}

  @override
  Future<void> signOut() async {}

  @override
  Future<AuthUserEntity> signInWithGoogle() => throw UnimplementedError();

  @override
  Future<void> sendPasswordResetEmail({required String email}) =>
      throw UnimplementedError();

  @override
  Future<void> sendEmailVerification() => throw UnimplementedError();

  @override
  Future<void> requestAccountDeletion({required String email}) =>
      throw UnimplementedError();

  @override
  Future<void> confirmAccountDeletion({required String token}) =>
      throw UnimplementedError();

  @override
  Future<void> requestAccountReactivation({required String email}) =>
      throw UnimplementedError();

  @override
  Future<void> confirmAccountReactivation({required String token}) =>
      throw UnimplementedError();

  @override
  Future<void> updateContactEmail({required String email}) =>
      throw UnimplementedError();

  @override
  Future<void> updateMyProfile({
    String? displayName,
    List<int>? profileImageBytes,
    String? profileImageFileName,
  }) => throw UnimplementedError();

  @override
  Future<List<MfaFactorHintEntity>> getEnrolledMfaFactors() =>
      throw UnimplementedError();

  @override
  Future<PhoneSignInStartResult> startSmsMfaEnrollment({
    required String phoneNumber,
  }) => throw UnimplementedError();

  @override
  Future<void> confirmSmsMfaEnrollment({
    required String sessionId,
    required String smsCode,
    String? displayName,
  }) => throw UnimplementedError();

  @override
  Future<TotpEnrollmentSecretEntity> startTotpMfaEnrollment({
    String? issuer,
    String? accountName,
  }) => throw UnimplementedError();

  @override
  Future<void> confirmTotpMfaEnrollment({
    required String verificationCode,
    String? displayName,
  }) => throw UnimplementedError();

  @override
  Future<PhoneSignInStartResult> requestPendingMfaSignInCode({
    String? factorUid,
  }) => throw UnimplementedError();

  @override
  Future<AuthUserEntity> confirmPendingMfaSignIn({
    required String sessionId,
    required String smsCode,
  }) => throw UnimplementedError();

  @override
  Future<AuthUserEntity> confirmPendingTotpMfaSignIn({
    required String factorUid,
    required String verificationCode,
  }) => throw UnimplementedError();

  @override
  Future<PhoneSignInStartResult> startPhoneSignIn({
    required String phoneNumber,
  }) => throw UnimplementedError();

  @override
  Future<AuthUserEntity> confirmPhoneSignIn({
    required String sessionId,
    required String smsCode,
  }) => throw UnimplementedError();
}

void main() {
  late _FakeAuthRepository repository;
  late AuthBloc bloc;

  setUp(() {
    repository = _FakeAuthRepository();
    bloc = AuthBloc(authUseCase: AuthUseCase(repository));
  });

  tearDown(() async {
    await bloc.close();
    await repository.dispose();
  });

  group('AuthBloc', () {
    test(
      'login emits loading and then authenticated when auth stream updates',
      () async {
        final emittedStates = <AuthState>[];
        final signedInUser = const AuthUserEntity(
          uid: 'user-1',
          email: 'mario@example.com',
          displayName: 'Mario Rossi',
        );

        repository.signInHandler = ({required email, required password}) async {
          repository.emitUser(signedInUser);
          return signedInUser;
        };

        final subscription = bloc.stream.listen(emittedStates.add);

        bloc.add(
          const AuthLoginRequested(
            email: 'mario@example.com',
            password: 'secret123',
          ),
        );
        await pumpEventQueue(times: 20);

        expect(emittedStates.first, const AuthState.loading());
        expect(emittedStates.last, AuthState.authenticated(signedInUser));

        await subscription.cancel();
      },
    );

    test(
      'login emits verificationEmailRequired when backend requests email verification',
      () async {
        final emittedStates = <AuthState>[];

        repository.signInHandler = ({required email, required password}) {
          return Future<AuthUserEntity>.error(
            Exception('Please verify your email address before logging in'),
          );
        };

        final subscription = bloc.stream.listen(emittedStates.add);

        bloc.add(
          const AuthLoginRequested(
            email: 'pending@example.com',
            password: 'secret123',
          ),
        );
        await pumpEventQueue(times: 20);

        expect(emittedStates.first, const AuthState.loading());
        expect(
          emittedStates.last,
          const AuthState.verificationEmailRequired('pending@example.com'),
        );

        await subscription.cancel();
      },
    );

    test('login emits mfaRequired when a second factor is required', () async {
      final emittedStates = <AuthState>[];
      const factors = <MfaFactorHintEntity>[
        MfaFactorHintEntity(
          uid: 'sms-1',
          type: MfaFactorType.sms,
          phoneNumber: '+39 333 1234567',
        ),
      ];

      repository.signInHandler = ({required email, required password}) {
        return Future<AuthUserEntity>.error(
          const AuthMfaRequiredException(
            factors: factors,
            message: 'Second factor required',
          ),
        );
      };

      final subscription = bloc.stream.listen(emittedStates.add);

      bloc.add(
        const AuthLoginRequested(
          email: 'mfa@example.com',
          password: 'secret123',
        ),
      );
      await pumpEventQueue(times: 20);

      expect(emittedStates.first, const AuthState.loading());
      expect(
        emittedStates.last,
        const AuthState.mfaRequired(factors, 'Second factor required'),
      );

      await subscription.cancel();
    });

    test(
      'register emits verificationEmailSent after successful creation',
      () async {
        final emittedStates = <AuthState>[];

        repository.createUserHandler =
            ({
              required email,
              required password,
              displayName,
              profileImageBytes,
              profileImageFileName,
            }) async {
              return const AuthUserEntity(
                uid: 'user-2',
                email: 'new@example.com',
                displayName: 'Nuovo Utente',
              );
            };

        final subscription = bloc.stream.listen(emittedStates.add);

        bloc.add(
          const AuthRegisterRequested(
            email: 'new@example.com',
            password: 'secret123',
            displayName: 'Nuovo Utente',
          ),
        );
        await pumpEventQueue(times: 20);

        expect(emittedStates.first, const AuthState.loading());
        expect(
          emittedStates.last,
          const AuthState.verificationEmailSent('new@example.com'),
        );

        await subscription.cancel();
      },
    );

    test(
      'reload emits unauthenticated when an authenticated session is no longer valid',
      () async {
        final emittedStates = <AuthState>[];
        final signedInUser = const AuthUserEntity(
          uid: 'user-3',
          email: 'active@example.com',
        );

        final subscription = bloc.stream.listen(emittedStates.add);
        repository.emitUser(signedInUser);
        await pumpEventQueue(times: 10);

        repository.reloadUserHandler = () async {
          repository.currentUserValue = AuthUserEntity.empty;
        };

        bloc.add(const AuthReloadRequested());
        await pumpEventQueue(times: 20);

        expect(emittedStates.last, const AuthState.unauthenticated());

        await subscription.cancel();
      },
    );

    test(
      'dismissing an MFA challenge clears the pending challenge and resets auth state',
      () async {
        final emittedStates = <AuthState>[];
        const factors = <MfaFactorHintEntity>[
          MfaFactorHintEntity(uid: 'totp-1', type: MfaFactorType.totp),
        ];

        repository.signInHandler = ({required email, required password}) {
          return Future<AuthUserEntity>.error(
            const AuthMfaRequiredException(factors: factors),
          );
        };

        final subscription = bloc.stream.listen(emittedStates.add);

        bloc.add(
          const AuthLoginRequested(
            email: 'totp@example.com',
            password: 'secret123',
          ),
        );
        await pumpEventQueue(times: 20);

        bloc.add(const AuthMfaChallengeDismissed());
        await pumpEventQueue(times: 20);

        expect(repository.clearPendingMfaChallengeCalls, 1);
        expect(emittedStates.last, const AuthState.unauthenticated());

        await subscription.cancel();
      },
    );
  });
}
