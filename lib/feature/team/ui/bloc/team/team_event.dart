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

class RemoveTeamFromCacheEvent extends TeamEvent {
  final String teamId;

  const RemoveTeamFromCacheEvent(this.teamId);

  @override
  List<Object?> get props => [teamId];
}

/// Internal event — dispatched when the background remote refresh completes.
class _TeamsRefreshedEvent extends TeamEvent {
  final List<TeamEntity> teams;
  const _TeamsRefreshedEvent(this.teams);

  @override
  List<Object?> get props => [teams];
}

class _TeamsRefreshFailedEvent extends TeamEvent {
  final String message;
  final bool hadLocalData;

  const _TeamsRefreshFailedEvent({
    required this.message,
    required this.hadLocalData,
  });

  @override
  List<Object?> get props => [message, hadLocalData];
}

class _TeamCreateCommittedEvent extends TeamEvent {
  final String temporaryId;
  final TeamEntity team;

  const _TeamCreateCommittedEvent(this.temporaryId, this.team);

  @override
  List<Object?> get props => [temporaryId, team];
}

class _TeamUpdateCommittedEvent extends TeamEvent {
  final String teamId;
  final TeamUpdate team;

  const _TeamUpdateCommittedEvent(this.teamId, this.team);

  @override
  List<Object?> get props => [teamId, team];
}

class _TeamDeleteCommittedEvent extends TeamEvent {
  final String teamId;

  const _TeamDeleteCommittedEvent(this.teamId);

  @override
  List<Object?> get props => [teamId];
}

class _TeamMutationFailedEvent extends TeamEvent {
  final String message;
  final List<TeamEntity> rollbackTeams;
  final Set<String> syncingIdsToClear;

  const _TeamMutationFailedEvent({
    required this.message,
    required this.rollbackTeams,
    required this.syncingIdsToClear,
  });

  @override
  List<Object?> get props => [message, rollbackTeams, syncingIdsToClear];
}
