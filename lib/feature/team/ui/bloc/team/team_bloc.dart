import 'dart:async';

// team_bloc.dart
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:note_sondage/core/utils/app_error_message_resolver.dart';
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
  final Set<String> _syncingTeamIds = <String>{};
  String? _teamsRefreshKey;

  Set<String> get syncingTeamIds => Set.unmodifiable(_syncingTeamIds);

  TeamBloc({required this.teamUseCase, required this.teamLocalDataSource})
    : super(TeamInitial()) {
    on<LoadTeamsEvent>(_onLoadTeams);
    on<LoadTeamsByUserIdEvent>(_onLoadTeamsByUserId);
    on<LoadTeamByIdEvent>(_onLoadTeamById);
    on<_TeamsRefreshedEvent>(_onTeamsRefreshed);
    on<_TeamsRefreshFailedEvent>(_onTeamsRefreshFailed);
    on<_TeamCreateCommittedEvent>(_onTeamCreateCommitted);
    on<_TeamUpdateCommittedEvent>(_onTeamUpdateCommitted);
    on<_TeamMutationFailedEvent>(_onTeamMutationFailed);
    on<CreateTeamEvent>(_onCreateTeam);
    on<UpdateTeamEvent>(_onUpdateTeam);
    on<DeleteTeamEvent>(_onDeleteTeam);
    on<ResetTeamCacheEvent>(_onResetCache);
  }

  Future<void> _onLoadTeams(
    LoadTeamsEvent event,
    Emitter<TeamState> emit,
  ) async {
    const requestKey = 'all';
    // Phase 1: emit in-memory cache or Hive immediately (synchronous feel)
    var hadLocalData = false;
    if (_cachedTeams.isNotEmpty) {
      hadLocalData = true;
      emit(TeamsLoaded(_cachedTeams));
    } else {
      final local = await teamUseCase.getLocalTeams();
      if (local.isNotEmpty) {
        hadLocalData = true;
        _cachedTeams = local;
        emit(TeamsLoaded(local));
      } else {
        emit(TeamLoading());
      }
    }
    // Phase 2: fire-and-forget — never blocks the event queue
    if (_teamsRefreshKey == requestKey) {
      return;
    }
    _teamsRefreshKey = requestKey;
    teamUseCase
        .getAllTeams()
        .then((remote) {
          _cachedTeams = remote;
          if (!isClosed) add(_TeamsRefreshedEvent(remote));
        })
        .catchError((error) {
          if (!isClosed) {
            add(
              _TeamsRefreshFailedEvent(
                message: AppErrorMessageResolver.resolve(
                  error,
                  fallback:
                      'We could not refresh your teams right now. Please try again.',
                ),
                hadLocalData: hadLocalData,
              ),
            );
          }
        })
        .whenComplete(() {
          if (_teamsRefreshKey == requestKey) {
            _teamsRefreshKey = null;
          }
        });
  }

  Future<void> _onLoadTeamsByUserId(
    LoadTeamsByUserIdEvent event,
    Emitter<TeamState> emit,
  ) async {
    final requestKey = 'user:${event.userId}';
    // Phase 1: emit in-memory cache or Hive immediately (synchronous feel)
    var hadLocalData = false;
    if (_cachedTeams.isNotEmpty) {
      hadLocalData = true;
      emit(TeamsLoaded(_cachedTeams));
    } else {
      final local = await teamUseCase.getLocalTeams();
      if (local.isNotEmpty) {
        hadLocalData = true;
        _cachedTeams = local;
        emit(TeamsLoaded(local));
      } else {
        emit(TeamLoading());
      }
    }
    // Phase 2: fire-and-forget — never blocks the event queue
    if (_teamsRefreshKey == requestKey) {
      return;
    }
    _teamsRefreshKey = requestKey;
    teamUseCase
        .getAllTeamsByUserId(event.userId)
        .then((remote) {
          _cachedTeams = remote;
          if (!isClosed) add(_TeamsRefreshedEvent(remote));
        })
        .catchError((error) {
          if (!isClosed) {
            add(
              _TeamsRefreshFailedEvent(
                message: AppErrorMessageResolver.resolve(
                  error,
                  fallback:
                      'We could not refresh your teams right now. Please try again.',
                ),
                hadLocalData: hadLocalData,
              ),
            );
          }
        })
        .whenComplete(() {
          if (_teamsRefreshKey == requestKey) {
            _teamsRefreshKey = null;
          }
        });
  }

  Future<void> _onTeamsRefreshed(
    _TeamsRefreshedEvent event,
    Emitter<TeamState> emit,
  ) async {
    emit(TeamsLoaded(event.teams));
  }

  Future<void> _onTeamsRefreshFailed(
    _TeamsRefreshFailedEvent event,
    Emitter<TeamState> emit,
  ) async {
    emit(TeamError(event.message));
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
      if (cached == null) {
        emit(
          TeamError(
            AppErrorMessageResolver.resolve(
              e,
              fallback: 'We could not load this team right now.',
            ),
          ),
        );
      }
    }
  }

  Future<void> _onCreateTeam(
    CreateTeamEvent event,
    Emitter<TeamState> emit,
  ) async {
    final rollbackTeams = List<TeamEntity>.from(_cachedTeams);
    final optimisticTeam = TeamEntity(
      _temporaryId('team'),
      event.team.color,
      event.team.pendingInvitations,
      name: event.team.name,
      description: event.team.description,
      createdByUserId: event.team.createdByUserId,
      memberCount: event.team.memberCount,
      createdAt: event.team.createdAt,
    );

    _syncingTeamIds.add(optimisticTeam.id ?? '');
    _cachedTeams = [..._cachedTeams, optimisticTeam];
    await teamLocalDataSource.saveAll(_cachedTeams);
    emit(TeamCreated(optimisticTeam));
    emit(TeamsLoaded(_cachedTeams));

    unawaited(() async {
      try {
        final TeamEntity created;
        if (event.userId != null && event.userId!.isNotEmpty) {
          created = await teamUseCase.createTeamByUser(
            event.team,
            event.userId!,
          );
        } else {
          created = await teamUseCase.createTeam(event.team);
        }
        if (!isClosed) {
          add(_TeamCreateCommittedEvent(optimisticTeam.id ?? '', created));
        }
      } catch (e) {
        if (!isClosed) {
          add(
            _TeamMutationFailedEvent(
              message: AppErrorMessageResolver.resolve(
                e,
                fallback: 'We could not create the team right now.',
              ),
              rollbackTeams: rollbackTeams,
              syncingIdsToClear: {optimisticTeam.id ?? ''},
            ),
          );
        }
      }
    }());
  }

  Future<void> _onUpdateTeam(
    UpdateTeamEvent event,
    Emitter<TeamState> emit,
  ) async {
    final rollbackTeams = List<TeamEntity>.from(_cachedTeams);
    final previousTeam = _cachedTeams
        .where((t) => t.id == event.team.id)
        .firstOrNull;
    final optimisticTeam = _teamEntityFromUpdate(
      event.team,
      previous: previousTeam,
    );

    _syncingTeamIds.add(optimisticTeam.id ?? '');
    final existingIndex = _cachedTeams.indexWhere(
      (team) => team.id == optimisticTeam.id,
    );
    if (existingIndex == -1) {
      _cachedTeams = [..._cachedTeams, optimisticTeam];
    } else {
      _cachedTeams = List<TeamEntity>.from(_cachedTeams)
        ..[existingIndex] = optimisticTeam;
    }

    await teamLocalDataSource.saveAll(_cachedTeams);
    emit(TeamUpdated(optimisticTeam));
    emit(TeamsLoaded(_cachedTeams));

    unawaited(() async {
      try {
        final updated = await teamUseCase.updateTeam(event.team);
        if (!isClosed) {
          add(_TeamUpdateCommittedEvent(optimisticTeam.id ?? '', updated));
        }
      } catch (e) {
        if (!isClosed) {
          add(
            _TeamMutationFailedEvent(
              message: AppErrorMessageResolver.resolve(
                e,
                fallback: 'We could not update the team right now.',
              ),
              rollbackTeams: rollbackTeams,
              syncingIdsToClear: {optimisticTeam.id ?? ''},
            ),
          );
        }
      }
    }());
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
        await teamLocalDataSource.saveAll(_cachedTeams);
        emit(TeamsLoaded(_cachedTeams));
      } else {
        emit(const TeamError('We could not delete the team right now.'));
        if (_cachedTeams.isNotEmpty) {
          emit(TeamsLoaded(_cachedTeams));
        }
      }
    } catch (e) {
      emit(
        TeamError(
          AppErrorMessageResolver.resolve(
            e,
            fallback: 'We could not delete the team right now.',
          ),
        ),
      );
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

  Future<void> _onTeamCreateCommitted(
    _TeamCreateCommittedEvent event,
    Emitter<TeamState> emit,
  ) async {
    final existingIndex = _cachedTeams.indexWhere(
      (team) => team.id == event.temporaryId,
    );
    if (existingIndex == -1) {
      _cachedTeams = [..._cachedTeams, event.team];
    } else {
      _cachedTeams = List<TeamEntity>.from(_cachedTeams)
        ..[existingIndex] = event.team;
    }
    _syncingTeamIds.remove(event.temporaryId);
    await teamLocalDataSource.saveAll(_cachedTeams);
    emit(TeamsLoaded(_cachedTeams));
  }

  Future<void> _onTeamUpdateCommitted(
    _TeamUpdateCommittedEvent event,
    Emitter<TeamState> emit,
  ) async {
    final existingIndex = _cachedTeams.indexWhere(
      (team) => team.id == event.teamId,
    );
    final current = existingIndex == -1 ? null : _cachedTeams[existingIndex];
    final confirmedTeam = _teamEntityFromUpdate(event.team, previous: current);

    if (existingIndex == -1) {
      _cachedTeams = [..._cachedTeams, confirmedTeam];
    } else {
      _cachedTeams = List<TeamEntity>.from(_cachedTeams)
        ..[existingIndex] = confirmedTeam;
    }

    _syncingTeamIds.remove(event.teamId);
    await teamLocalDataSource.saveAll(_cachedTeams);
    emit(TeamsLoaded(_cachedTeams));
  }

  Future<void> _onTeamMutationFailed(
    _TeamMutationFailedEvent event,
    Emitter<TeamState> emit,
  ) async {
    _cachedTeams = List<TeamEntity>.from(event.rollbackTeams);
    _syncingTeamIds.removeAll(event.syncingIdsToClear);
    await teamLocalDataSource.saveAll(_cachedTeams);
    emit(TeamError(event.message));
    emit(TeamsLoaded(_cachedTeams));
  }

  String _temporaryId(String prefix) {
    return 'local_${prefix}_${DateTime.now().microsecondsSinceEpoch}';
  }

  TeamEntity _teamEntityFromUpdate(TeamUpdate update, {TeamEntity? previous}) {
    return TeamEntity(
      update.id,
      update.color,
      previous?.pendingInvitations,
      name: update.name,
      description: update.description,
      createdByUserId: update.createdByUserId.isNotEmpty
          ? update.createdByUserId
          : (previous?.createdByUserId ?? ''),
      memberCount: previous?.memberCount ?? 0,
      createdAt: previous?.createdAt ?? update.createdAt,
    );
  }
}
