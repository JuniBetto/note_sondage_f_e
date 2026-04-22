part of 'team_bloc.dart';

abstract class TeamEvent extends Equatable {
  const TeamEvent();

  @override
  List<Object?> get props => [];
}

class LoadTeamsEvent extends TeamEvent {}

class LoadTeamsByUserIdEvent extends TeamEvent {
  final String userId;

  const LoadTeamsByUserIdEvent(this.userId);

  @override
  List<Object?> get props => [userId];
}

class LoadTeamByIdEvent extends TeamEvent {
  final String id;

  const LoadTeamByIdEvent(this.id);

  @override
  List<Object?> get props => [id];
}

class CreateTeamEvent extends TeamEvent {
  final TeamEntity team;
  final String? userId;

  const CreateTeamEvent(this.team, {this.userId});

  @override
  List<Object?> get props => [team, userId];
}

class UpdateTeamEvent extends TeamEvent {
  final TeamUpdate team;
  //final String? userId;

  const UpdateTeamEvent(this.team /* {this.userId} */);

  @override
  List<Object?> get props => [team /* userId */];
}

class DeleteTeamEvent extends TeamEvent {
  final String id;
  final String? userId;

  const DeleteTeamEvent(this.id, {this.userId});

  @override
  List<Object?> get props => [id, userId];
}

class ResetTeamCacheEvent extends TeamEvent {
  const ResetTeamCacheEvent();
}

/// Internal event — dispatched when the background remote refresh completes.
class _TeamsRefreshedEvent extends TeamEvent {
  final List<TeamEntity> teams;
  const _TeamsRefreshedEvent(this.teams);

  @override
  List<Object?> get props => [teams];
}
