import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:note_sondage/ui/bloc/auth_bloc/auth_event.dart';
import 'package:note_sondage/ui/bloc/auth_bloc/auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc() : super(AuthUnknown()) {
    on<AuthStatusChanged>((event, emit) => emit(event.status));
    on<AuthLogoutRequested>((event, emit) => emit(AuthUnauthenticated()));

    // Simulazione del controllo iniziale dello stato
    // In una vera app, qui controlleresti il token Hive/SharedPreferences
    Future.delayed(const Duration(seconds: 2), () {
      add(
        AuthStatusChanged(AuthUnauthenticated()),
      ); // Inizializza come non loggato
    });
  }

  // Helper per ottenere lo stato di autenticazione
  bool get isAuthenticated => state is AuthAuthenticated;
}
