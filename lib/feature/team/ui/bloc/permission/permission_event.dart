// permission_event.dart
part of 'permission_bloc.dart';

sealed class PermissionEvent extends Equatable {
  const PermissionEvent();

  @override
  List<Object> get props => [];
}

class LoadPermissionsEvent extends PermissionEvent {}

class LoadPermissionByIdEvent extends PermissionEvent {
  final String id;

  const LoadPermissionByIdEvent(this.id);

  @override
  List<Object> get props => [id];
}

class CreatePermissionEvent extends PermissionEvent {
  final PermissionEntity permission;

  const CreatePermissionEvent(this.permission);

  @override
  List<Object> get props => [permission];
}

class UpdatePermissionEvent extends PermissionEvent {
  final String id;
  final PermissionEntity permission;

  const UpdatePermissionEvent(this.id, this.permission);

  @override
  List<Object> get props => [id, permission];
}

class DeletePermissionEvent extends PermissionEvent {
  final String id;

  const DeletePermissionEvent(this.id);

  @override
  List<Object> get props => [id];
}
