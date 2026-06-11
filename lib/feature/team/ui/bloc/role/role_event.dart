part of 'role_bloc.dart';

abstract class RoleEvent extends Equatable {
  const RoleEvent();

  @override
  List<Object?> get props => [];
}

class LoadRolesEvent extends RoleEvent {}

class LoadRolesEventByTeamId extends RoleEvent {
  final String teamId;

  const LoadRolesEventByTeamId(this.teamId);

  @override
  List<Object?> get props => [teamId];
}

class LoadRoleByIdEvent extends RoleEvent {
  final String id;

  const LoadRoleByIdEvent(this.id);

  @override
  List<Object?> get props => [id];
}

class CreateRoleEvent extends RoleEvent {
  final RoleEntity role;
  final String teamId;

  const CreateRoleEvent(this.role, {required this.teamId});

  @override
  List<Object?> get props => [role, teamId];
}

class UpdateRoleEvent extends RoleEvent {
  final RoleEntity role;

  const UpdateRoleEvent(this.role);

  @override
  List<Object?> get props => [role];
}

class DeleteRoleEvent extends RoleEvent {
  final String id;
  final String teamId;

  const DeleteRoleEvent(this.id, {required this.teamId});

  @override
  List<Object?> get props => [id, teamId];
}
