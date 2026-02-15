// team_bloc.dart
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:note_sondage/feature/team/domain/entities/team_entity.dart';
import 'package:note_sondage/feature/team/domain/use_case/team/team_use_case.dart';

part 'team_event.dart';
part 'team_state.dart';

class TeamBloc extends Bloc<TeamEvent, TeamState> {
  final TeamUseCase teamUseCase;

  /// Cache of loaded teams to avoid flickering on CRUD operations
  List<TeamEntity> _cachedTeams = [];

  TeamBloc({required this.teamUseCase}) : super(TeamInitial()) {
    on<LoadTeamsEvent>(_onLoadTeams);
    on<LoadTeamsByUserIdEvent>(_onLoadTeamsByUserId);
    on<LoadTeamByIdEvent>(_onLoadTeamById);
    on<CreateTeamEvent>(_onCreateTeam);
    on<UpdateTeamEvent>(_onUpdateTeam);
    on<DeleteTeamEvent>(_onDeleteTeam);
  }

  Future<void> _onLoadTeams(
    LoadTeamsEvent event,
    Emitter<TeamState> emit,
  ) async {
    // Show loading only on first load (cache is empty)
    if (_cachedTeams.isEmpty) {
      emit(TeamLoading());
    }
    try {
      final teams = await teamUseCase.getAllTeams();
      _cachedTeams = teams;
      emit(TeamsLoaded(teams));
    } catch (e) {
      emit(TeamError(e.toString()));
    }
  }

  Future<void> _onLoadTeamsByUserId(
    LoadTeamsByUserIdEvent event,
    Emitter<TeamState> emit,
  ) async {
    // Show loading only on first load (cache is empty)
    if (_cachedTeams.isEmpty) {
      emit(TeamLoading());
    }
    try {
      final teams = await teamUseCase.getAllTeamsByUserId(event.userId);
      _cachedTeams = teams;
      emit(TeamsLoaded(teams));
    } catch (e) {
      emit(TeamError(e.toString()));
    }
  }

  Future<void> _onLoadTeamById(
    LoadTeamByIdEvent event,
    Emitter<TeamState> emit,
  ) async {
    emit(TeamLoading());
    try {
      final team = await teamUseCase.getTeamById(event.id);
      if (team != null) {
        emit(TeamLoaded(team));
      } else {
        emit(const TeamError('Team not found'));
      }
    } catch (e) {
      emit(TeamError(e.toString()));
    }
  }

  Future<void> _onCreateTeam(
    CreateTeamEvent event,
    Emitter<TeamState> emit,
  ) async {
    try {
      final TeamEntity team;
      if (event.userId != null && event.userId!.isNotEmpty) {
        team = await teamUseCase.createTeamByUser(event.team, event.userId!);
      } else {
        team = await teamUseCase.createTeam(event.team);
      }
      emit(TeamCreated(team));

      // Optimistic update: add to cache immediately
      _cachedTeams = [..._cachedTeams, team];
      emit(TeamsLoaded(_cachedTeams));
    } catch (e) {
      emit(TeamError(e.toString()));
      // Re-emit cached teams so UI doesn't break
      if (_cachedTeams.isNotEmpty) {
        emit(TeamsLoaded(_cachedTeams));
      }
    }
  }

  Future<void> _onUpdateTeam(
    UpdateTeamEvent event,
    Emitter<TeamState> emit,
  ) async {
    try {
      final team = await teamUseCase.updateTeam(event.team);
      emit(TeamUpdated(team));

      // Optimistic update: replace in cache
      _cachedTeams = _cachedTeams.map((t) {
        return t.id == team.id ? team : t;
      }).toList();
      emit(TeamsLoaded(_cachedTeams));
    } catch (e) {
      emit(TeamError(e.toString()));
      if (_cachedTeams.isNotEmpty) {
        emit(TeamsLoaded(_cachedTeams));
      }
    }
  }

  Future<void> _onDeleteTeam(
    DeleteTeamEvent event,
    Emitter<TeamState> emit,
  ) async {
    try {
      final success = await teamUseCase.deleteTeam(event.id);
      if (success) {
        emit(TeamDeleted());

        // Optimistic update: remove from cache
        _cachedTeams = _cachedTeams.where((t) => t.id != event.id).toList();
        emit(TeamsLoaded(_cachedTeams));
      } else {
        emit(const TeamError('Failed to delete team'));
        if (_cachedTeams.isNotEmpty) {
          emit(TeamsLoaded(_cachedTeams));
        }
      }
    } catch (e) {
      emit(TeamError(e.toString()));
      if (_cachedTeams.isNotEmpty) {
        emit(TeamsLoaded(_cachedTeams));
      }
    }
  }
}
