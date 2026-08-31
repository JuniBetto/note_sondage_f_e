import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:note_sondage/feature/auth/domain/entities/auth_user_entity.dart';
import 'package:note_sondage/feature/auth/domain/entities/mfa_factor_hint_entity.dart';
import 'package:note_sondage/feature/auth/domain/entities/phone_sign_in_start_result.dart';
import 'package:note_sondage/feature/auth/domain/entities/totp_enrollment_secret_entity.dart';
import 'package:note_sondage/feature/auth/domain/repositories/auth_repository.dart';
import 'package:note_sondage/feature/auth/domain/use_case/auth_use_case.dart';
import 'package:note_sondage/feature/auth/ui/bloc/app_lifecycle_bloc.dart';
import 'package:note_sondage/feature/auth/ui/bloc/auth_bloc.dart';

class _FakeAuthRepository implements AuthRepository {
  _FakeAuthRepository()
    : _controller = StreamController<AuthUserEntity>.broadcast();

  final StreamController<AuthUserEntity> _controller;
  int reloadCalls = 0;

  @override
  Stream<AuthUserEntity> get authStateChanges => _controller.stream;

  @override
  AuthUserEntity get currentUser => AuthUserEntity.empty;

  Future<void> dispose() async {
    await _controller.close();
  }

  @override
  Future<void> reloadUser() async {
    reloadCalls++;
  }

  @override
  void clearPendingMfaSignInChallenge() {}

  @override
  bool get isAuthenticated => false;

  @override
  Future<void> refreshBackendSession() async {}

  @override
  Future<void> signOut() async {}

  @override
  Future<AuthUserEntity> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) => throw UnimplementedError();

  @override
  Future<AuthUserEntity> createUserWithEmailAndPassword({
    required String email,
    required String password,
    String? displayName,
    List<int>? profileImageBytes,
    String? profileImageFileName,
  }) => throw UnimplementedError();

  @override
  Future<AuthUserEntity> signInWithGoogle() => throw UnimplementedError();

  @override
  Future<PhoneSignInStartResult> startPhoneSignIn({
    required String phoneNumber,
  }) => throw UnimplementedError();

  @override
  Future<AuthUserEntity> confirmPhoneSignIn({
    required String sessionId,
    required String smsCode,
  }) => throw UnimplementedError();

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
  Future<void> requestAccountErasure({required String email}) =>
      throw UnimplementedError();

  @override
  Future<void> confirmAccountErasure({required String token}) =>
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
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _FakeAuthRepository repository;
  late AuthBloc authBloc;
  late AppLifecycleBloc bloc;

  setUp(() {
    repository = _FakeAuthRepository();
    authBloc = AuthBloc(authUseCase: AuthUseCase(repository));
    bloc = AppLifecycleBloc(authBloc: authBloc);
  });

  tearDown(() async {
    await bloc.close();
    await authBloc.close();
    await repository.dispose();
  });

  group('AppLifecycleBloc', () {
    test(
      'paused and hidden states emit background-compatible lifecycle states',
      () async {
        final emittedStates = <AppLifecycleBlocState>[];
        final subscription = bloc.stream.listen(emittedStates.add);

        bloc.add(const AppLifecycleChanged(AppLifecycleEnum.paused));
        await pumpEventQueue(times: 10);
        bloc.add(const AppLifecycleChanged(AppLifecycleEnum.hidden));
        await pumpEventQueue(times: 10);

        expect(
          emittedStates.map((state) => state.status).toList(),
          <AppLifecycleStatusEnum>[AppLifecycleStatusEnum.background],
        );

        await subscription.cancel();
      },
    );

    test('resumed triggers auth reload and emits active state', () async {
      final emittedStates = <AppLifecycleBlocState>[];
      final subscription = bloc.stream.listen(emittedStates.add);

      bloc.add(const AppLifecycleChanged(AppLifecycleEnum.paused));
      await pumpEventQueue(times: 10);
      emittedStates.clear();

      bloc.add(const AppLifecycleChanged(AppLifecycleEnum.resumed));
      await pumpEventQueue(times: 20);

      expect(repository.reloadCalls, 1);
      expect(emittedStates.last.status, AppLifecycleStatusEnum.active);

      await subscription.cancel();
    });

    test('inactive and detached emit the expected lifecycle states', () async {
      final emittedStates = <AppLifecycleBlocState>[];
      final subscription = bloc.stream.listen(emittedStates.add);

      bloc.add(const AppLifecycleChanged(AppLifecycleEnum.inactive));
      await pumpEventQueue(times: 10);
      bloc.add(const AppLifecycleChanged(AppLifecycleEnum.detached));
      await pumpEventQueue(times: 10);

      expect(
        emittedStates.map((state) => state.status).toList(),
        <AppLifecycleStatusEnum>[
          AppLifecycleStatusEnum.inactive,
          AppLifecycleStatusEnum.terminated,
        ],
      );

      await subscription.cancel();
    });
  });
}
