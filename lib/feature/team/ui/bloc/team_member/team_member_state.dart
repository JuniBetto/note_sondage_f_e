part of 'team_member_bloc.dart';

abstract class TeamMemberState extends Equatable {
  const TeamMemberState();

  @override
  List<Object?> get props => [];
}

class TeamMemberInitial extends TeamMemberState {}

class TeamMemberLoading extends TeamMemberState {}

class TeamMembersLoaded extends TeamMemberState {
  final List<TeamMemberEntity> members;
  final DateTime _timestamp;

  TeamMembersLoaded(this.members) : _timestamp = DateTime.now();

  @override
  List<Object?> get props => [members, _timestamp];
}

class TeamMemberLoaded extends TeamMemberState {
  final TeamMemberEntity member;

  const TeamMemberLoaded(this.member);

  @override
  List<Object?> get props => [member];
}

class TeamMemberCreated extends TeamMemberState {
  final TeamMemberEntity member;

  const TeamMemberCreated(this.member);

  @override
  List<Object?> get props => [member];
}

class TeamMemberUpdated extends TeamMemberState {
  final TeamMemberEntity member;

  const TeamMemberUpdated(this.member);

  @override
  List<Object?> get props => [member];
}

class TeamMemberDeleted extends TeamMemberState {}

class TeamMemberInvited extends TeamMemberState {}

class TeamInvitationCancelled extends TeamMemberState {}

class TeamInvitationsLoaded extends TeamMemberState {
  final List<dynamic> invitations; // List<TeamInvitationEntity>
  final DateTime _ts;
  TeamInvitationsLoaded(this.invitations) : _ts = DateTime.now();
  @override
  List<Object?> get props => [invitations, _ts];
}

class TeamMemberError extends TeamMemberState {
  final String message;

  const TeamMemberError(this.message);

  @override
  List<Object?> get props => [message];
}
