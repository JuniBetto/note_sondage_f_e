import 'dart:async';
import 'dart:ui' as ui;

import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:note_sondage/feature/auth/ui/bloc/auth_bloc.dart';

part 'app_lifecycle_event.dart';
part 'app_lifecycle_state.dart';

/// BLoC che gestisce il ciclo di vita dell'app.
///
/// Quando l'app torna dal background (resumed):
/// - Ricarica l'utente Firebase per verificare la sessione
/// - Può essere esteso per riconnettere WebSocket, refresh token API, ecc.
///
/// Quando l'app va in background (paused):
/// - Può chiudere connessioni, salvare stato locale, ecc.
///
/// Uso: WidgetsBindingObserver → dispatchLifecycleChanged → AppLifecycleBloc
class AppLifecycleBloc extends Bloc<AppLifecycleEvent, AppLifecycleBlocState>
    with WidgetsBindingObserver {
  final AuthBloc _authBloc;
  Timer? _inactivityTimer;

  /// Durata massima in background prima di forzare il logout (default: 24 ore).
  /// Firebase Auth gestisce già il refresh del token in modo persistente,
  /// quindi non serve un timeout aggressivo. Questo è solo un limite di sicurezza.
  static const Duration maxBackgroundDuration = Duration(hours: 24);

  DateTime? _backgroundTimestamp;

  AppLifecycleBloc({required AuthBloc authBloc})
    : _authBloc = authBloc,
      super(const AppLifecycleBlocState.active()) {
    on<AppLifecycleChanged>(_onLifecycleChanged);
    on<AppStarted>(_onAppStarted);

    // Registra l'observer per ricevere le callback del sistema
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(ui.AppLifecycleState state) {
    final mapped = switch (state) {
      ui.AppLifecycleState.resumed => AppLifecycleEnum.resumed,
      ui.AppLifecycleState.inactive => AppLifecycleEnum.inactive,
      ui.AppLifecycleState.paused => AppLifecycleEnum.paused,
      ui.AppLifecycleState.detached => AppLifecycleEnum.detached,
      ui.AppLifecycleState.hidden => AppLifecycleEnum.hidden,
    };
    add(AppLifecycleChanged(mapped));
  }

  Future<void> _onAppStarted(
    AppStarted event,
    Emitter<AppLifecycleBlocState> emit,
  ) async {
    emit(const AppLifecycleBlocState.active());
  }

  Future<void> _onLifecycleChanged(
    AppLifecycleChanged event,
    Emitter<AppLifecycleBlocState> emit,
  ) async {
    switch (event.state) {
      case AppLifecycleEnum.resumed:
        _inactivityTimer?.cancel();
        _inactivityTimer = null;

        // Controlla se l'app è stata in background troppo a lungo
        if (_backgroundTimestamp != null) {
          final elapsed = DateTime.now().difference(_backgroundTimestamp!);
          _backgroundTimestamp = null;

          if (elapsed > maxBackgroundDuration) {
            // Sessione scaduta per limite di sicurezza — forza logout
            _authBloc.add(const AuthLogoutRequested());
            emit(const AppLifecycleBlocState.sessionExpired());
            return;
          }
        }

        // Ricarica l'utente Firebase per verificare/ripristinare la sessione.
        // Questo funziona anche se authStateChanges non ha ancora ri-emesso:
        // Firebase Auth persiste la sessione su disco e la ripristina
        // automaticamente. Il reload forza un check del token.
        _authBloc.add(const AuthReloadRequested());

        emit(const AppLifecycleBlocState.active());

      case AppLifecycleEnum.inactive:
        emit(const AppLifecycleBlocState.inactive());

      case AppLifecycleEnum.paused:
        _backgroundTimestamp = DateTime.now();
        emit(const AppLifecycleBlocState.background());

      case AppLifecycleEnum.detached:
        _inactivityTimer?.cancel();
        emit(const AppLifecycleBlocState.terminated());

      case AppLifecycleEnum.hidden:
        emit(const AppLifecycleBlocState.background());
    }
  }

  @override
  Future<void> close() {
    WidgetsBinding.instance.removeObserver(this);
    _inactivityTimer?.cancel();
    return super.close();
  }
}
