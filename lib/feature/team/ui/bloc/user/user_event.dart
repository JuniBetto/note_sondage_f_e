part of 'user_bloc.dart';

abstract class UserEvent extends Equatable {
  const UserEvent();

  @override
  List<Object?> get props => [];
}

class LoadUsersEvent extends UserEvent {}

class LoadUserByIdEvent extends UserEvent {
  final String id;

  const LoadUserByIdEvent(this.id);

  @override
  List<Object?> get props => [id];
}

class LoadUserByEmailEvent extends UserEvent {
  final String email;

  const LoadUserByEmailEvent(this.email);

  @override
  List<Object?> get props => [email];
}

class LoadUserByTeamIdEvent extends UserEvent {
  final String teamId;

  const LoadUserByTeamIdEvent(this.teamId);

  @override
  List<Object?> get props => [teamId];
}

/// Evento per cercare un utente per email, e crearlo se non esiste
class GetOrCreateUserByEmailEvent extends UserEvent {
  final String email;

  const GetOrCreateUserByEmailEvent(this.email);

  @override
  List<Object?> get props => [email];
}

class CreateUserEvent extends UserEvent {
  final UserEntity user;

  const CreateUserEvent(this.user);

  @override
  List<Object?> get props => [user];
}

class CreateInactiveUserEvent extends UserEvent {
  final String email;

  const CreateInactiveUserEvent(this.email);

  @override
  List<Object?> get props => [email];
}

class UpdateUserEvent extends UserEvent {
  final UserEntity user;

  const UpdateUserEvent(this.user);

  @override
  List<Object?> get props => [user];
}

class DeleteUserEvent extends UserEvent {
  final String id;

  const DeleteUserEvent(this.id);

  @override
  List<Object?> get props => [id];
}
