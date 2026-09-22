part of 'chat_bloc.dart';

/// A one-shot signal (error, success, "draft ready") riding alongside
/// [ChatState]. Unlike the other fields, a handler that doesn't explicitly
/// pass `transient:` to `copyWith` clears it — mirroring
/// `NotificationCenterState.errorMessage`, so listeners never re-react to a
/// stale signal from an earlier state.
abstract class ChatTransient extends Equatable {
  const ChatTransient();

  @override
  List<Object?> get props => [];
}

class ChatErrorOccurred extends ChatTransient {
  const ChatErrorOccurred(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

class ChatState extends Equatable {
  const ChatState({
    this.teams = const <TeamEntity>[],
    this.loadingTeams = false,
    this.selectedTeamId,
    this.teamMembersByTeamId = const <String, List<TeamMemberEntity>>{},
    this.rolesByTeamId = const <String, List<RoleEntity>>{},
    this.transient,
  });

  final List<TeamEntity> teams;
  final bool loadingTeams;
  final String? selectedTeamId;
  final Map<String, List<TeamMemberEntity>> teamMembersByTeamId;
  final Map<String, List<RoleEntity>> rolesByTeamId;
  final ChatTransient? transient;

  ChatState copyWith({
    List<TeamEntity>? teams,
    bool? loadingTeams,
    String? selectedTeamId,
    bool clearSelectedTeamId = false,
    Map<String, List<TeamMemberEntity>>? teamMembersByTeamId,
    Map<String, List<RoleEntity>>? rolesByTeamId,
    ChatTransient? transient,
  }) {
    return ChatState(
      teams: teams ?? this.teams,
      loadingTeams: loadingTeams ?? this.loadingTeams,
      selectedTeamId: clearSelectedTeamId
          ? null
          : (selectedTeamId ?? this.selectedTeamId),
      teamMembersByTeamId: teamMembersByTeamId ?? this.teamMembersByTeamId,
      rolesByTeamId: rolesByTeamId ?? this.rolesByTeamId,
      transient: transient,
    );
  }

  @override
  List<Object?> get props => [
    teams,
    loadingTeams,
    selectedTeamId,
    teamMembersByTeamId,
    rolesByTeamId,
    transient,
  ];
}
