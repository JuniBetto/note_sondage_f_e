part of 'user_bloc.dart';

abstract class UserState extends Equatable {
  const UserState();

  @override
  List<Object?> get props => [];
}

class UserInitial extends UserState {}

class UserLoading extends UserState {}

class UsersLoaded extends UserState {
  final List<UserEntity> users;

  const UsersLoaded(this.users);

  @override
  List<Object?> get props => [users];
}

class UsersUpdateLoaded extends UserState {
  final List<UserEntityForUpdate> users;

  const UsersUpdateLoaded(this.users);

  @override
  List<Object?> get props => [users];
}

class UserLoaded extends UserState {
  final UserEntity user;

  const UserLoaded(this.user);

  @override
  List<Object?> get props => [user];
}

class UserNotFound extends UserState {
  final String email;

  const UserNotFound(this.email);

  @override
  List<Object?> get props => [email];
}

/// Stato emesso quando un utente viene trovato o creato
class UserFoundOrCreated extends UserState {
  final UserEntity user;
  final bool wasCreated; // true se l'utente è stato appena creato

  const UserFoundOrCreated(this.user, {required this.wasCreated});

  @override
  List<Object?> get props => [user, wasCreated];
}

class UserCreated extends UserState {
  final UserEntity user;

  const UserCreated(this.user);

  @override
  List<Object?> get props => [user];
}

class UserUpdated extends UserState {
  final UserEntity user;

  const UserUpdated(this.user);

  @override
  List<Object?> get props => [user];
}

class UserDeleted extends UserState {}

class UserError extends UserState {
  final String message;

  const UserError(this.message);

  @override
  List<Object?> get props => [message];
}
