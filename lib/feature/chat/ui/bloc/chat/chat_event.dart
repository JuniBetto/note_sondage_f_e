part of 'chat_bloc.dart';

abstract class ChatEvent extends Equatable {
  const ChatEvent();

  @override
  List<Object?> get props => [];
}

/// Fetches the user's teams and resolves which one should be selected.
///
/// [preferredTeamId], when provided (e.g. from a deep link), wins over the
/// bloc's current selection if it still exists in the fetched team list.
class ChatTeamsRequested extends ChatEvent {
  const ChatTeamsRequested({this.preferredTeamId});

  final String? preferredTeamId;

  @override
  List<Object?> get props => [preferredTeamId];
}

/// Loads (and caches for the session) the member list and role list for
/// [teamId], used to resolve permissions in the chat header and in the
/// smart-action workflows. A no-op if already cached or already in flight.
class ChatTeamAccessContextRequested extends ChatEvent {
  const ChatTeamAccessContextRequested(this.teamId);

  final String teamId;

  @override
  List<Object?> get props => [teamId];
}

class _ChatTeamsLoadedEvent extends ChatEvent {
  const _ChatTeamsLoadedEvent({required this.teams, this.selectedTeamId});

  final List<TeamEntity> teams;
  final String? selectedTeamId;

  @override
  List<Object?> get props => [teams, selectedTeamId];
}

class _ChatTeamsLoadFailedEvent extends ChatEvent {
  const _ChatTeamsLoadFailedEvent(this.error);

  final Object error;

  @override
  List<Object?> get props => [error];
}
