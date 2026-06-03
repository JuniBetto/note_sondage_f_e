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
      _cachedTeams = _dedupeTeams(_cachedTeams);
      hadLocalData = true;
      emit(TeamsLoaded(_cachedTeams));
    } else {
      final local = await teamUseCase.getLocalTeams();
      if (local.isNotEmpty) {
        hadLocalData = true;
        _cachedTeams = _dedupeTeams(local);
        await teamLocalDataSource.saveAll(_cachedTeams);
        emit(TeamsLoaded(_cachedTeams));
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
      _cachedTeams = _dedupeTeams(_cachedTeams);
      hadLocalData = true;
      emit(TeamsLoaded(_cachedTeams));
    } else {
      final local = await teamUseCase.getLocalTeams();
      if (local.isNotEmpty) {
        hadLocalData = true;
        _cachedTeams = _dedupeTeams(local);
        await teamLocalDataSource.saveAll(_cachedTeams);
        emit(TeamsLoaded(_cachedTeams));
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
    _cachedTeams = _mergeRemoteTeams(event.teams);
    await teamLocalDataSource.saveAll(_cachedTeams);
    emit(TeamsLoaded(_cachedTeams));
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
    final temporaryIndex = _cachedTeams.indexWhere(
      (team) => team.id == event.temporaryId,
    );
    final confirmedIndex = _cachedTeams.indexWhere(
      (team) => team.id == event.team.id,
    );
    final logicalDuplicateIndex = _cachedTeams.indexWhere(
      (team) =>
          team.id != event.temporaryId &&
          _sameLogicalTeam(team, event.team) &&
          (_isTemporaryId(team.id) || _isTemporaryId(event.team.id)),
    );

    if (temporaryIndex != -1) {
      _cachedTeams = List<TeamEntity>.from(_cachedTeams)
        ..[temporaryIndex] = event.team;
    } else if (confirmedIndex != -1) {
      _cachedTeams = List<TeamEntity>.from(_cachedTeams)
        ..[confirmedIndex] = event.team;
    } else if (logicalDuplicateIndex != -1) {
      _cachedTeams = List<TeamEntity>.from(_cachedTeams)
        ..[logicalDuplicateIndex] = event.team;
    } else {
      _cachedTeams = [..._cachedTeams, event.team];
    }

    _cachedTeams = _dedupeTeams(_cachedTeams);
    _syncingTeamIds.remove(event.temporaryId);
    await teamLocalDataSource.saveAll(_cachedTeams);
    emit(TeamsLoaded(_cachedTeams));
    _refreshTeamsInBackground();
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
    _refreshTeamsInBackground();
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

  void _refreshTeamsInBackground() {
    const requestKey = 'all';
    if (_teamsRefreshKey == requestKey) {
      return;
    }
    _teamsRefreshKey = requestKey;
    unawaited(
      teamUseCase
          .getAllTeams()
          .then((remote) {
            if (!isClosed) {
              add(_TeamsRefreshedEvent(remote));
            }
          })
          .catchError((_) {
            // Best-effort silent reconciliation: keep the optimistic UI and
            // avoid surfacing a second error after a successful mutation.
          })
          .whenComplete(() {
            if (_teamsRefreshKey == requestKey) {
              _teamsRefreshKey = null;
            }
          }),
    );
  }

  List<TeamEntity> _mergeRemoteTeams(List<TeamEntity> remoteTeams) {
    final merged = List<TeamEntity>.from(remoteTeams);

    for (final localTeam in _cachedTeams) {
      final localId = localTeam.id ?? '';
      final isSyncing = _syncingTeamIds.contains(localId);
      if (!isSyncing) {
        continue;
      }

      if (_isTemporaryId(localTeam.id)) {
        final remoteMatchIndex = merged.indexWhere(
          (remoteTeam) => _sameLogicalTeam(remoteTeam, localTeam),
        );
        if (remoteMatchIndex == -1) {
          merged.add(localTeam);
        } else {
          _syncingTeamIds.remove(localId);
        }
        continue;
      }

      final remoteMatchIndex = merged.indexWhere(
        (remoteTeam) => remoteTeam.id == localTeam.id,
      );
      if (remoteMatchIndex == -1) {
        merged.add(localTeam);
      } else {
        merged[remoteMatchIndex] = localTeam;
      }
    }

    return _dedupeTeams(merged);
  }

  List<TeamEntity> _dedupeTeams(List<TeamEntity> teams) {
    final deduped = <TeamEntity>[];

    for (final team in teams) {
      final existingIndex = deduped.indexWhere(
        (existing) => _isSameTeamIdentity(existing, team),
      );
      if (existingIndex == -1) {
        deduped.add(team);
      } else {
        deduped[existingIndex] = _preferTeamVersion(
          deduped[existingIndex],
          team,
        );
      }
    }

    return deduped;
  }

  bool _isSameTeamIdentity(TeamEntity a, TeamEntity b) {
    if (a.id != null && b.id != null && a.id == b.id) {
      return true;
    }

    final oneIsTemporary = _isTemporaryId(a.id) || _isTemporaryId(b.id);
    return oneIsTemporary && _sameLogicalTeam(a, b);
  }

  TeamEntity _preferTeamVersion(TeamEntity current, TeamEntity candidate) {
    final currentIsTemporary = _isTemporaryId(current.id);
    final candidateIsTemporary = _isTemporaryId(candidate.id);

    if (currentIsTemporary && !candidateIsTemporary) {
      return candidate;
    }
    if (!currentIsTemporary && candidateIsTemporary) {
      return current;
    }

    final currentIsSyncing = _syncingTeamIds.contains(current.id ?? '');
    final candidateIsSyncing = _syncingTeamIds.contains(candidate.id ?? '');
    if (currentIsSyncing && !candidateIsSyncing) {
      return current;
    }
    if (!currentIsSyncing && candidateIsSyncing) {
      return candidate;
    }

    return candidate;
  }

  bool _isTemporaryId(String? id) => id?.startsWith('local_') ?? false;

  bool _sameLogicalTeam(TeamEntity a, TeamEntity b) {
    final normalizedNameA = a.name.trim().toLowerCase();
    final normalizedNameB = b.name.trim().toLowerCase();
    final normalizedDescriptionA = a.description.trim().toLowerCase();
    final normalizedDescriptionB = b.description.trim().toLowerCase();
    final normalizedColorA = (a.color ?? '').trim().toLowerCase();
    final normalizedColorB = (b.color ?? '').trim().toLowerCase();
    final normalizedOwnerA = a.createdByUserId.trim().toLowerCase();
    final normalizedOwnerB = b.createdByUserId.trim().toLowerCase();

    return normalizedNameA == normalizedNameB &&
        normalizedDescriptionA == normalizedDescriptionB &&
        normalizedColorA == normalizedColorB &&
        normalizedOwnerA == normalizedOwnerB;
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
