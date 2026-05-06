part of 'auth_bloc.dart';

/// Stati dell'AuthBloc.
///
/// Lo stato è un singolo oggetto immutabile con un [status] e un [user].
/// GoRouter controlla [status] per decidere le redirects.
class AuthState extends Equatable {
  final AuthStatus status;
  final AuthUserEntity user;
  final String? errorMessage;
  final bool passwordResetSent;
  final bool verificationEmailSent;
  final String? verificationEmail;

  const AuthState._({
    required this.status,
    this.user = AuthUserEntity.empty,
    this.errorMessage,
    this.passwordResetSent = false,
    this.verificationEmailSent = false,
    this.verificationEmail,
  });

  /// Stato iniziale: non sappiamo ancora se l'utente è loggato.
  const AuthState.unknown() : this._(status: AuthStatus.unknown);

  /// L'utente è autenticato.
  const AuthState.authenticated(AuthUserEntity user)
    : this._(status: AuthStatus.authenticated, user: user);

  /// L'utente non è autenticato.
  const AuthState.unauthenticated()
    : this._(status: AuthStatus.unauthenticated);

  /// Caricamento in corso (login / register / SSO).
  /// Usa status = loading così GoRouter NON fa redirect (l'utente resta
  /// sulla pagina corrente mentre l'operazione è in corso).
  const AuthState.loading() : this._(status: AuthStatus.loading);

  /// Errore durante un'operazione auth.
  const AuthState.error(String message)
    : this._(status: AuthStatus.unauthenticated, errorMessage: message);

  /// Email di reset password inviata con successo.
  const AuthState.passwordResetSent()
    : this._(status: AuthStatus.unauthenticated, passwordResetSent: true);

  /// Registrazione completata: attendiamo la conferma email prima del login.
  const AuthState.verificationEmailSent(String email)
    : this._(
        status: AuthStatus.unauthenticated,
        verificationEmailSent: true,
        verificationEmail: email,
      );

  @override
  List<Object?> get props => [
    status,
    user,
    errorMessage,
    passwordResetSent,
    verificationEmailSent,
    verificationEmail,
  ];
}
