// team_bloc.dart
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:note_sondage/feature/team/domain/entities/team_entity.dart';
import 'package:note_sondage/feature/team/domain/use_case/team/team_use_case.dart';
import 'package:note_sondage/feature/team/infrastructure/data_source/data_source_local/team_local_data_source.dart';

part 'team_event.dart';
part 'team_state.dart';

class TeamBloc extends Bloc<TeamEvent, TeamState> {
  final TeamUseCase teamUseCase;
  final TeamLocalDataSource teamLocalDataSource;

  /// In-memory cache to avoid flickering on CRUD operations
  List<TeamEntity> _cachedTeams = [];

  TeamBloc({required this.teamUseCase, required this.teamLocalDataSource})
    : super(TeamInitial()) {
    on<LoadTeamsEvent>(_onLoadTeams);
    on<LoadTeamsByUserIdEvent>(_onLoadTeamsByUserId);
    on<LoadTeamByIdEvent>(_onLoadTeamById);
    on<_TeamsRefreshedEvent>(_onTeamsRefreshed);
    on<CreateTeamEvent>(_onCreateTeam);
    on<UpdateTeamEvent>(_onUpdateTeam);
    on<DeleteTeamEvent>(_onDeleteTeam);
    on<ResetTeamCacheEvent>(_onResetCache);
  }

  Future<void> _onLoadTeams(
    LoadTeamsEvent event,
    Emitter<TeamState> emit,
  ) async {
    // Phase 1: emit in-memory cache or Hive immediately (synchronous feel)
    if (_cachedTeams.isNotEmpty) {
      emit(TeamsLoaded(_cachedTeams));
    } else {
      final local = await teamUseCase.getLocalTeams();
      if (local.isNotEmpty) {
        _cachedTeams = local;
        emit(TeamsLoaded(local));
      } else {
        emit(TeamLoading());
      }
    }
    // Phase 2: fire-and-forget — never blocks the event queue
    teamUseCase
        .getAllTeams()
        .then((remote) {
          _cachedTeams = remote;
          if (!isClosed) add(_TeamsRefreshedEvent(remote));
        })
        .catchError((_) {});
  }

  Future<void> _onLoadTeamsByUserId(
    LoadTeamsByUserIdEvent event,
    Emitter<TeamState> emit,
  ) async {
    // Phase 1: emit in-memory cache or Hive immediately (synchronous feel)
    if (_cachedTeams.isNotEmpty) {
      emit(TeamsLoaded(_cachedTeams));
    } else {
      final local = await teamUseCase.getLocalTeams();
      if (local.isNotEmpty) {
        _cachedTeams = local;
        emit(TeamsLoaded(local));
      } else {
        emit(TeamLoading());
      }
    }
    // Phase 2: fire-and-forget — never blocks the event queue
    teamUseCase
        .getAllTeamsByUserId(event.userId)
        .then((remote) {
          _cachedTeams = remote;
          if (!isClosed) add(_TeamsRefreshedEvent(remote));
        })
        .catchError((_) {});
  }

  Future<void> _onTeamsRefreshed(
    _TeamsRefreshedEvent event,
    Emitter<TeamState> emit,
  ) async {
    emit(TeamsLoaded(event.teams));
  }

  Future<void> _onLoadTeamById(
    LoadTeamByIdEvent event,
    Emitter<TeamState> emit,
  ) async {
    // Check in-memory cache for instant display
    final cached = _cachedTeams.where((t) => t.id == event.id).firstOrNull;
    if (cached != null) {
      emit(TeamLoaded(cached));
    } else {
      emit(TeamLoading());
    }
    // Always fetch fresh detail from remote
    try {
      final team = await teamUseCase.getTeamById(event.id);
      if (team != null) {
        emit(TeamLoaded(team));
      } else {
        if (cached == null) emit(const TeamError('Team not found'));
      }
    } catch (e) {
      if (cached == null) emit(TeamError(e.toString()));
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

  Future<void> _onResetCache(
    ResetTeamCacheEvent event,
    Emitter<TeamState> emit,
  ) async {
    _cachedTeams = [];
    await teamLocalDataSource.clearAll();
    emit(TeamInitial());
  }
}
