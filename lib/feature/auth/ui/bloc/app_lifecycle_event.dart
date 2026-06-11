part of 'app_lifecycle_bloc.dart';

/// Enum che riflette gli stati del ciclo di vita di Flutter
/// senza dipendere direttamente da [ui.AppLifecycleState].
enum AppLifecycleEnum { resumed, inactive, paused, detached, hidden }

/// Eventi per AppLifecycleBloc.
sealed class AppLifecycleEvent extends Equatable {
  const AppLifecycleEvent();

  @override
  List<Object?> get props => [];
}

/// L'app è stata avviata.
final class AppStarted extends AppLifecycleEvent {
  const AppStarted();
}

/// Il ciclo di vita dell'app è cambiato.
final class AppLifecycleChanged extends AppLifecycleEvent {
  final AppLifecycleEnum state;

  const AppLifecycleChanged(this.state);

  @override
  List<Object?> get props => [state];
}
