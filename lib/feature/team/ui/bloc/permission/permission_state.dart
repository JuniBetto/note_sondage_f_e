// permission_state.dart
part of 'permission_bloc.dart';

sealed class PermissionState extends Equatable {
  const PermissionState();

  @override
  List<Object> get props => [];
}

class PermissionInitial extends PermissionState {}

class PermissionLoading extends PermissionState {}

class PermissionsLoaded extends PermissionState {
  final List<PermissionEntity> permissions;

  const PermissionsLoaded(this.permissions);

  @override
  List<Object> get props => [permissions];
}

class PermissionLoaded extends PermissionState {
  final PermissionEntity permission;

  const PermissionLoaded(this.permission);

  @override
  List<Object> get props => [permission];
}

class PermissionCreated extends PermissionState {
  final PermissionEntity permission;

  const PermissionCreated(this.permission);

  @override
  List<Object> get props => [permission];
}

class PermissionUpdated extends PermissionState {
  final PermissionEntity permission;

  const PermissionUpdated(this.permission);

  @override
  List<Object> get props => [permission];
}

class PermissionDeleted extends PermissionState {}

class PermissionError extends PermissionState {
  final String message;

  const PermissionError(this.message);

  @override
  List<Object> get props => [message];
}
