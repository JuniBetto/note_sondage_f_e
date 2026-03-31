part of 'auth_bloc.dart';

/// Eventi per l'AuthBloc.
sealed class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

/// Evento interno: il stream di Firebase ha emesso un nuovo utente.
final class _AuthUserChanged extends AuthEvent {
  final AuthUserEntity user;

  const _AuthUserChanged(this.user);

  @override
  List<Object?> get props => [user];
}

/// L'utente vuole fare login con email e password.
final class AuthLoginRequested extends AuthEvent {
  final String email;
  final String password;

  const AuthLoginRequested({required this.email, required this.password});

  @override
  List<Object?> get props => [email, password];
}

/// L'utente vuole registrarsi con email e password.
final class AuthRegisterRequested extends AuthEvent {
  final String email;
  final String password;
  final String? displayName;

  const AuthRegisterRequested({
    required this.email,
    required this.password,
    this.displayName,
  });

  @override
  List<Object?> get props => [email, password, displayName];
}

/// L'utente vuole fare login con Google.
final class AuthGoogleSignInRequested extends AuthEvent {
  const AuthGoogleSignInRequested();
}

/// L'utente vuole resettare la password.
final class AuthPasswordResetRequested extends AuthEvent {
  final String email;

  const AuthPasswordResetRequested({required this.email});

  @override
  List<Object?> get props => [email];
}

/// L'utente vuole fare logout.
final class AuthLogoutRequested extends AuthEvent {
  const AuthLogoutRequested();
}

/// Richiede il reload dei dati utente (es. al ritorno dal background).
final class AuthReloadRequested extends AuthEvent {
  const AuthReloadRequested();
}
