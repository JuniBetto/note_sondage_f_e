import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:note_sondage/feature/auth/domain/entities/auth_user_entity.dart';
import 'package:note_sondage/feature/auth/domain/use_case/auth_use_case.dart';

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
    } catch (e) {
      emit(AuthState.error(e.toString()));
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
      );
      // Lo stream _authSubscription aggiornerà lo stato automaticamente
    } catch (e) {
      emit(AuthState.error(e.toString()));
    }
  }

  Future<void> _onGoogleSignIn(
    AuthGoogleSignInRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthState.loading());
    try {
      await _authUseCase.signInWithGoogle();
    } catch (e) {
      emit(AuthState.error(e.toString()));
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
      emit(AuthState.error(e.toString()));
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
      emit(AuthState.error(e.toString()));
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
      } else if (user.isNotEmpty && state.status != AuthStatus.authenticated) {
        // La sessione è ancora valida — ripristina lo stato autenticato
        emit(AuthState.authenticated(user));
      }
    } catch (_) {
      // Errore di rete: non disconnettere l'utente, mantenere lo stato attuale.
      // Firebase Auth ha i token cached, l'utente può continuare offline.
    }
  }

  @override
  Future<void> close() {
    _authSubscription.cancel();
    return super.close();
  }
}
