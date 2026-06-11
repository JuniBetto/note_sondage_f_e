import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:note_sondage/feature/auth/domain/entities/auth_user_entity.dart';
import 'package:note_sondage/feature/auth/domain/entities/mfa_factor_hint_entity.dart';
import 'package:note_sondage/feature/auth/domain/entities/phone_sign_in_start_result.dart';
import 'package:note_sondage/feature/auth/domain/entities/totp_enrollment_secret_entity.dart';
import 'package:note_sondage/feature/auth/domain/repositories/auth_repository.dart';
import 'package:note_sondage/feature/auth/domain/use_case/auth_use_case.dart';
import 'package:note_sondage/feature/auth/ui/bloc/auth_bloc.dart';
import 'package:note_sondage/languages/l10n/app_localizations.dart';
import 'package:note_sondage/ui/mobile/widgets/login/login_mobile.dart';
import 'package:note_sondage/ui/mobile/widgets/login/tab_bar_component.dart';
import 'package:note_sondage/ui/widgets/custom_input_field.dart';
import 'package:note_sondage/ui/widgets/sso_login.dart';

class _TestAuthRepository implements AuthRepository {
  @override
  Stream<AuthUserEntity> get authStateChanges =>
      const Stream<AuthUserEntity>.empty();

  @override
  AuthUserEntity get currentUser => AuthUserEntity.empty;

  @override
  bool get isAuthenticated => false;

  @override
  void clearPendingMfaSignInChallenge() {}

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
  Future<void> confirmSmsMfaEnrollment({
    required String sessionId,
    required String smsCode,
    String? displayName,
  }) => throw UnimplementedError();

  @override
  Future<void> confirmTotpMfaEnrollment({
    required String verificationCode,
    String? displayName,
  }) => throw UnimplementedError();

  @override
  Future<void> confirmAccountDeletion({required String token}) =>
      throw UnimplementedError();

  @override
  Future<void> confirmAccountReactivation({required String token}) =>
      throw UnimplementedError();

  @override
  Future<AuthUserEntity> confirmPhoneSignIn({
    required String sessionId,
    required String smsCode,
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
  Future<List<MfaFactorHintEntity>> getEnrolledMfaFactors() =>
      throw UnimplementedError();

  @override
  Future<void> reloadUser() async {}

  @override
  Future<void> requestAccountDeletion({required String email}) =>
      throw UnimplementedError();

  @override
  Future<void> requestAccountReactivation({required String email}) =>
      throw UnimplementedError();

  @override
  Future<PhoneSignInStartResult> requestPendingMfaSignInCode({
    String? factorUid,
  }) => throw UnimplementedError();

  @override
  Future<void> refreshBackendSession() async {}

  @override
  Future<void> sendEmailVerification() async {}

  @override
  Future<void> sendPasswordResetEmail({required String email}) =>
      throw UnimplementedError();

  @override
  Future<AuthUserEntity> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) => throw UnimplementedError();

  @override
  Future<AuthUserEntity> signInWithGoogle() => throw UnimplementedError();

  @override
  Future<void> signOut() async {}

  @override
  Future<PhoneSignInStartResult> startPhoneSignIn({
    required String phoneNumber,
  }) => throw UnimplementedError();

  @override
  Future<PhoneSignInStartResult> startSmsMfaEnrollment({
    required String phoneNumber,
  }) => throw UnimplementedError();

  @override
  Future<TotpEnrollmentSecretEntity> startTotpMfaEnrollment({
    String? issuer,
    String? accountName,
  }) => throw UnimplementedError();

  @override
  Future<void> updateContactEmail({required String email}) =>
      throw UnimplementedError();

  @override
  Future<void> updateMyProfile({
    String? displayName,
    List<int>? profileImageBytes,
    String? profileImageFileName,
  }) => throw UnimplementedError();
}

void main() {
  Widget buildLoginPage() {
    return MediaQuery(
      data: const MediaQueryData(),
      child: MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: BlocProvider(
          create: (_) =>
              AuthBloc(authUseCase: AuthUseCase(_TestAuthRepository())),
          child: const LoginMobile(),
        ),
      ),
    );
  }

  final tabBar = find.byType(TabBarComponent);
  final ssoLogin = find.byType(SsoLogin);

  testWidgets('Login page section login is present', (
    WidgetTester tester,
  ) async {
    final l10n = await AppLocalizations.delegate.load(const Locale('en'));

    await tester.pumpWidget(buildLoginPage());
    await tester.pumpAndSettle();
    expect(tabBar, findsOneWidget);

    await tester.tap(find.byKey(const Key('login_tab')));
    await tester.pumpAndSettle();

    expect(find.text(l10n.login), findsWidgets);
    expect(find.byKey(const ValueKey('login_email_field')), findsOneWidget);
    expect(find.byKey(const ValueKey('login_Password_field')), findsOneWidget);
    expect(find.byType(CustomInputField), findsNWidgets(2));
    expect(
      find.byKey(const ValueKey('google_sso_login_button')),
      findsOneWidget,
    );
    expect(ssoLogin, findsOneWidget);
  });

  testWidgets('Login page section register is present', (
    WidgetTester tester,
  ) async {
    final l10n = await AppLocalizations.delegate.load(const Locale('en'));

    await tester.pumpWidget(buildLoginPage());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('register_tab')));
    await tester.pumpAndSettle();

    expect(find.text(l10n.register), findsWidgets);
    expect(
      find.byKey(const ValueKey('register_full_name_field')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('register_email_field')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('register_password_field')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('register_confirm_password_field')),
      findsOneWidget,
    );
    expect(find.byType(CustomInputField), findsNWidgets(4));
    expect(find.byKey(const ValueKey('register_button')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('google_sso_register_button')),
      findsOneWidget,
    );
    expect(ssoLogin, findsOneWidget);
  });
}
