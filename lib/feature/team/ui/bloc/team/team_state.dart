part of 'team_bloc.dart';

abstract class TeamState extends Equatable {
  const TeamState();

  @override
  List<Object?> get props => [];
}

class TeamInitial extends TeamState {}

class TeamLoading extends TeamState {}

class TeamsLoaded extends TeamState {
  final List<TeamEntity> teams;
  final DateTime _timestamp;

  TeamsLoaded(this.teams) : _timestamp = DateTime.now();

  @override
  List<Object?> get props => [teams, _timestamp];
}

class TeamLoaded extends TeamState {
  final TeamEntity team;

  const TeamLoaded(this.team);

  @override
  List<Object?> get props => [team];
}

class TeamCreated extends TeamState {
  final TeamEntity team;

  const TeamCreated(this.team);

  @override
  List<Object?> get props => [team];
}

class TeamUpdated extends TeamState {
  final TeamEntity team;

  const TeamUpdated(this.team);

  @override
  List<Object?> get props => [team];
}

class TeamDeleted extends TeamState {}

class TeamError extends TeamState {
  final String message;

  const TeamError(this.message);

  @override
  List<Object?> get props => [message];
}
