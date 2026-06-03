part of 'app_lifecycle_bloc.dart';

/// Enum per lo stato del ciclo di vita dell'app.
enum AppLifecycleStatusEnum {
  active,
  inactive,
  background,
  terminated,
  sessionExpired,
}

/// Stato del ciclo di vita dell'app.
class AppLifecycleBlocState extends Equatable {
  final AppLifecycleStatusEnum status;

  const AppLifecycleBlocState._({required this.status});

  /// L'app è attiva e in primo piano.
  const AppLifecycleBlocState.active()
    : this._(status: AppLifecycleStatusEnum.active);

  /// L'app è inattiva (es. durante una chiamata, o switch app).
  const AppLifecycleBlocState.inactive()
    : this._(status: AppLifecycleStatusEnum.inactive);

  /// L'app è in background.
  const AppLifecycleBlocState.background()
    : this._(status: AppLifecycleStatusEnum.background);

  /// L'app è stata terminata.
  const AppLifecycleBlocState.terminated()
    : this._(status: AppLifecycleStatusEnum.terminated);

  /// La sessione è scaduta dopo essere stata in background troppo a lungo.
  const AppLifecycleBlocState.sessionExpired()
    : this._(status: AppLifecycleStatusEnum.sessionExpired);

  @override
  List<Object?> get props => [status];
}
