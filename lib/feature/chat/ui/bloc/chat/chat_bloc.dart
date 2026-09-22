import 'dart:async';

// chat_bloc.dart
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:note_sondage/core/utils/app_error_message_resolver.dart';
import 'package:note_sondage/feature/team/domain/entities/role_entity.dart';
import 'package:note_sondage/feature/team/domain/entities/team_entity.dart';
import 'package:note_sondage/feature/team/domain/entities/team_member_entity.dart';
import 'package:note_sondage/feature/team/domain/use_case/role/role_use_case.dart';
import 'package:note_sondage/feature/team/domain/use_case/team/team_use_case.dart';
import 'package:note_sondage/feature/team/domain/use_case/team_member/team_member_use_case.dart';

part 'chat_event.dart';
part 'chat_state.dart';

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  ChatBloc({
    required this.teamUseCase,
    required this.teamMemberUseCase,
    required this.roleUseCase,
  }) : super(const ChatState()) {
    on<ChatTeamsRequested>(_onTeamsRequested);
    on<_ChatTeamsLoadedEvent>(_onTeamsLoaded);
    on<_ChatTeamsLoadFailedEvent>(_onTeamsLoadFailed);
    // `sequential` (not the framework's default `concurrent` transformer):
    // guarantees one ChatTeamAccessContextRequested fully resolves (and
    // populates the cache) before the next one for the same team is
    // processed, so the "already cached" check below is enough to dedupe
    // — no separate in-flight guard needed, unlike the widget method this
    // replaces (which could have genuinely overlapping invocations).
    on<ChatTeamAccessContextRequested>(
      _onTeamAccessContextRequested,
      transformer: (events, mapper) => events.asyncExpand(mapper),
    );
  }

  final TeamUseCase teamUseCase;
  final TeamMemberUseCase teamMemberUseCase;
  final RoleUseCase roleUseCase;

  Future<void> _onTeamsRequested(
    ChatTeamsRequested event,
    Emitter<ChatState> emit,
  ) async {
    emit(state.copyWith(loadingTeams: true));
    try {
      final teams = await teamUseCase.getAllTeams();
      final nextTeamId = _resolveNextTeamId(teams, event.preferredTeamId);
      if (!isClosed) {
        add(_ChatTeamsLoadedEvent(teams: teams, selectedTeamId: nextTeamId));
      }
    } catch (error) {
      if (!isClosed) {
        add(_ChatTeamsLoadFailedEvent(error));
      }
    }
  }

  String? _resolveNextTeamId(List<TeamEntity> teams, String? preferredTeamId) {
    final effectivePreferred = preferredTeamId ?? state.selectedTeamId;
    if (effectivePreferred != null &&
        teams.any((team) => team.id == effectivePreferred)) {
      return effectivePreferred;
    }
    return teams.isNotEmpty ? teams.first.id : null;
  }

  void _onTeamsLoaded(_ChatTeamsLoadedEvent event, Emitter<ChatState> emit) {
    emit(
      state.copyWith(
        teams: event.teams,
        loadingTeams: false,
        selectedTeamId: event.selectedTeamId,
        clearSelectedTeamId: event.selectedTeamId == null,
      ),
    );
  }

  void _onTeamsLoadFailed(
    _ChatTeamsLoadFailedEvent event,
    Emitter<ChatState> emit,
  ) {
    emit(
      state.copyWith(
        loadingTeams: false,
        transient: ChatErrorOccurred(
          AppErrorMessageResolver.resolve(
            event.error,
            fallback: 'We could not load your teams. Please try again.',
          ),
        ),
      ),
    );
  }

  Future<void> _onTeamAccessContextRequested(
    ChatTeamAccessContextRequested event,
    Emitter<ChatState> emit,
  ) async {
    final teamId = event.teamId.trim();
    if (teamId.isEmpty) {
      return;
    }

    final futures = <Future<void>>[];

    if (!state.teamMembersByTeamId.containsKey(teamId)) {
      futures.add(
        teamMemberUseCase
            .getAllMembersByTeamId(teamId)
            .then((members) {
              emit(
                state.copyWith(
                  teamMembersByTeamId: {
                    ...state.teamMembersByTeamId,
                    teamId: members,
                  },
                ),
              );
            })
            .catchError((_) {}),
      );
    }

    if (!state.rolesByTeamId.containsKey(teamId)) {
      futures.add(
        roleUseCase
            .getAllRolesByTeamId(teamId)
            .then((roles) {
              emit(
                state.copyWith(
                  rolesByTeamId: {...state.rolesByTeamId, teamId: roles},
                ),
              );
            })
            .catchError((_) {}),
      );
    }

    if (futures.isNotEmpty) {
      await Future.wait(futures);
    }
  }
}
