part of 'role_bloc.dart';

abstract class RoleState extends Equatable {
  const RoleState();

  @override
  List<Object?> get props => [];
}

class RoleInitial extends RoleState {}

class RoleLoading extends RoleState {}

class RolesLoaded extends RoleState {
  final List<RoleEntity> roles;

  const RolesLoaded(this.roles);

  @override
  List<Object?> get props => [roles];
}

class RoleLoaded extends RoleState {
  final RoleEntity role;

  const RoleLoaded(this.role);

  @override
  List<Object?> get props => [role];
}

class RoleCreated extends RoleState {
  final RoleEntity role;

  const RoleCreated(this.role);

  @override
  List<Object?> get props => [role];
}

class RoleUpdated extends RoleState {
  final RoleEntity role;

  const RoleUpdated(this.role);

  @override
  List<Object?> get props => [role];
}

class RoleDeleted extends RoleState {}

class RoleError extends RoleState {
  final String message;

  const RoleError(this.message);

  @override
  List<Object?> get props => [message];
}
