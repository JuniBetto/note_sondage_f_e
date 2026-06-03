import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:note_sondage/feature/auth/domain/entities/auth_mfa_required_exception.dart';
import 'package:note_sondage/feature/auth/domain/entities/auth_user_entity.dart';
import 'package:note_sondage/feature/auth/domain/entities/mfa_factor_hint_entity.dart';
import 'package:note_sondage/feature/auth/domain/use_case/auth_use_case.dart';
import 'package:note_sondage/feature/auth/ui/auth_user_message_resolver.dart';

part 'auth_event.dart';
part 'auth_state.dart';

/// BLoC di autenticazione.
///
/// Ascolta lo stream di [authStateChanges] di Firebase Auth
/// e aggiorna lo stato di conseguenza.
/// GoRouter ascolta questo BLoC per fare redirect automatici.
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthUseCase _authUseCase;
  late final StreamSubscription<AuthUserEntity> _authSubscription;

  AuthBloc({required AuthUseCase authUseCase})
    : _authUseCase = authUseCase,
      super(const AuthState.unknown()) {
    on<_AuthUserChanged>(_onUserChanged);
    on<AuthLoginRequested>(_onLoginRequested);
    on<AuthRegisterRequested>(_onRegisterRequested);
    on<AuthGoogleSignInRequested>(_onGoogleSignIn);
    on<AuthPasswordResetRequested>(_onPasswordReset);
    on<AuthLogoutRequested>(_onLogout);
    on<AuthReloadRequested>(_onReload);
    on<AuthProfileEmailUpdated>(_onProfileEmailUpdated);
    on<AuthProfileDisplayNameUpdated>(_onProfileDisplayNameUpdated);
    on<AuthProfilePhotoUpdated>(_onProfilePhotoUpdated);
    on<AuthMfaChallengeDismissed>(_onMfaChallengeDismissed);

    // Ascolta i cambiamenti di stato auth da Firebase
    _authSubscription = _authUseCase.authStateChanges.listen(
      (user) => add(_AuthUserChanged(user)),
    );
  }

  /// Helper per GoRouter e widget.
  bool get isAuthenticated => state.status == AuthStatus.authenticated;

  void _onUserChanged(_AuthUserChanged event, Emitter<AuthState> emit) {
    if (event.user.isEmpty) {
      emit(const AuthState.unauthenticated());
    } else {
      emit(AuthState.authenticated(event.user));
    }
  }

  Future<void> _onLoginRequested(
    AuthLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthState.loading());
    try {
      await _authUseCase.signInWithEmailAndPassword(
        email: event.email,
        password: event.password,
      );
      // Lo stream _authSubscription aggiornerà lo stato automaticamente
    } on AuthMfaRequiredException catch (e) {
      emit(AuthState.mfaRequired(e.factors, e.message));
    } catch (e) {
      final message = AuthUserMessageResolver.resolve(e);
      final lowered = message.toLowerCase();
      if (lowered.contains('confirm your registration before signing in') ||
          lowered.contains('verify your email address before logging in')) {
        emit(AuthState.verificationEmailRequired(event.email));
        return;
      }
      emit(AuthState.error(message));
    }
  }

  Future<void> _onRegisterRequested(
    AuthRegisterRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthState.loading());
    try {
      await _authUseCase.createUserWithEmailAndPassword(
        email: event.email,
        password: event.password,
        displayName: event.displayName,
        profileImageBytes: event.profileImageBytes,
        profileImageFileName: event.profileImageFileName,
      );
      emit(AuthState.verificationEmailSent(event.email));
    } catch (e) {
      emit(AuthState.error(AuthUserMessageResolver.resolve(e)));
    }
  }

  Future<void> _onGoogleSignIn(
    AuthGoogleSignInRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthState.loading());
    try {
      await _authUseCase.signInWithGoogle();
    } on AuthMfaRequiredException catch (e) {
      emit(AuthState.mfaRequired(e.factors, e.message));
    } catch (e) {
      emit(AuthState.error(AuthUserMessageResolver.resolve(e)));
    }
  }

  Future<void> _onPasswordReset(
    AuthPasswordResetRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthState.loading());
    try {
      await _authUseCase.sendPasswordResetEmail(email: event.email);
      emit(const AuthState.passwordResetSent());
    } catch (e) {
      emit(AuthState.error(AuthUserMessageResolver.resolve(e)));
    }
  }

  Future<void> _onLogout(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      await _authUseCase.signOut();
      // Lo stream _authSubscription aggiornerà lo stato automaticamente
    } catch (e) {
      emit(AuthState.error(AuthUserMessageResolver.resolve(e)));
    }
  }

  Future<void> _onReload(
    AuthReloadRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      await _authUseCase.reloadUser();
      // Dopo il reload, verifica lo stato corrente dell'utente.
      // Firebase persiste la sessione su disco: se l'utente è ancora valido,
      // currentUser non sarà vuoto anche dopo un lungo background.
      final user = _authUseCase.currentUser;
      if (user.isEmpty && state.status == AuthStatus.authenticated) {
        // L'utente è stato invalidato server-side (es. account eliminato)
        emit(const AuthState.unauthenticated());
      } else if (user.isNotEmpty && user != state.user) {
        // Aggiorna anche cambiamenti come emailVerified o displayName.
        emit(AuthState.authenticated(user));
      } else if (user.isNotEmpty && state.status != AuthStatus.authenticated) {
        // La sessione è ancora valida — ripristina lo stato autenticato
        emit(AuthState.authenticated(user));
      }
    } catch (_) {
      // Errore di rete: non disconnettere l'utente, mantenere lo stato attuale.
      // Firebase Auth ha i token cached, l'utente può continuare offline.
    }
  }

  void _onProfileEmailUpdated(
    AuthProfileEmailUpdated event,
    Emitter<AuthState> emit,
  ) {
    if (state.status != AuthStatus.authenticated) return;
    emit(AuthState.authenticated(state.user.copyWith(email: event.email)));
  }

  void _onProfileDisplayNameUpdated(
    AuthProfileDisplayNameUpdated event,
    Emitter<AuthState> emit,
  ) {
    if (state.status != AuthStatus.authenticated) return;
    emit(
      AuthState.authenticated(
        state.user.copyWith(displayName: event.displayName),
      ),
    );
  }

  void _onProfilePhotoUpdated(
    AuthProfilePhotoUpdated event,
    Emitter<AuthState> emit,
  ) {
    if (state.status != AuthStatus.authenticated) return;
    emit(
      AuthState.authenticated(state.user.copyWith(photoUrl: event.photoUrl)),
    );
  }

  void _onMfaChallengeDismissed(
    AuthMfaChallengeDismissed event,
    Emitter<AuthState> emit,
  ) {
    _authUseCase.clearPendingMfaSignInChallenge();
    emit(const AuthState.unauthenticated());
  }

  @override
  Future<void> close() {
    _authSubscription.cancel();
    return super.close();
  }
}
