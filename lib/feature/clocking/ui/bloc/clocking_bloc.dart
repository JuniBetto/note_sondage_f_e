import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:note_sondage/core/utils/app_error_message_resolver.dart';
import 'package:note_sondage/feature/clocking/domain/entities/clocking_record_entity.dart';
import 'package:note_sondage/feature/clocking/domain/use_case/clocking_use_case.dart';
import 'package:note_sondage/feature/clocking/infrastructure/data_source/data_source_local/clocking_local_data_source.dart';

part 'clocking_event.dart';
part 'clocking_state.dart';

class ClockingBloc extends Bloc<ClockingEvent, ClockingState> {
  final ClockingUseCase clockingUseCase;
  final ClockingLocalDataSource _clockingLocalDataSource;

  List<ClockingRecordEntity> _cachedMyRecords = [];
  List<ClockingRecordEntity> _cachedTeamRecords = [];
  final Set<String> _syncingRecordIds = <String>{};
  String? _selectedTeamId;

  String? get selectedTeamId => _selectedTeamId;
  Set<String> get syncingRecordIds => Set.unmodifiable(_syncingRecordIds);

  ClockingBloc({
    required this.clockingUseCase,
    required ClockingLocalDataSource clockingLocalDataSource,
  }) : _clockingLocalDataSource = clockingLocalDataSource,
       super(ClockingInitial()) {
    on<LoadClockingRecordsEvent>(_onLoadRecords);
    on<LoadClockingByDateEvent>(_onLoadByDate);
    on<LoadClockingByUserIdEvent>(_onLoadByUserId);
    on<LoadClockingByTeamIdEvent>(_onLoadByTeamId);
    on<CreateManualClockingEntriesEvent>(_onCreateManualClockingEntries);
    on<_ClockingRecordCommittedEvent>(_onRecordCommitted);
    on<_ClockingRecordDeletedCommittedEvent>(_onRecordDeletedCommitted);
    on<_ClockingMutationFailedEvent>(_onMutationFailed);
    on<_ManualClockingEntriesCommittedEvent>(_onManualEntriesCommitted);
    on<_ManualClockingEntriesFailedEvent>(_onManualEntriesFailed);
    on<ClockInEvent>(_onClockIn);
    on<ClockOutEvent>(_onClockOut);
    on<StartBreakEvent>(_onStartBreak);
    on<StopBreakEvent>(_onStopBreak);
    on<MarkVacationEvent>(_onMarkVacation);
    on<MarkPermissionEvent>(_onMarkPermission);
    on<UpdateClockingRecordEvent>(_onUpdateRecord);
    on<DecommitClockingRecordEvent>(_onDecommitRecord);
    on<CommitClockingRecordEvent>(_onCommitRecord);
    on<DeleteClockingRecordEvent>(_onDelete);
  }

  Future<void> _onLoadRecords(
    LoadClockingRecordsEvent event,
    Emitter<ClockingState> emit,
  ) async {
    _selectedTeamId = event.teamId;
    if (_cachedMyRecords.isNotEmpty || _cachedTeamRecords.isNotEmpty) {
      emit(_loadedState());
    } else {
      final local = await _clockingLocalDataSource.getAll();
      if (local.isNotEmpty) {
        _cachedMyRecords = local;
        emit(_loadedState());
      } else {
        emit(ClockingLoading());
      }
    }

    try {
      await _reloadDashboard();
      emit(_loadedState());
    } catch (e) {
      emit(
        ClockingError(
          AppErrorMessageResolver.resolve(
            e,
            fallback: 'We could not refresh the clocking records right now.',
          ),
        ),
      );
      if (_cachedMyRecords.isNotEmpty || _cachedTeamRecords.isNotEmpty) {
        emit(_loadedState());
      }
    }
  }

  Future<void> _onLoadByDate(
    LoadClockingByDateEvent event,
    Emitter<ClockingState> emit,
  ) async {
    emit(ClockingLoading());
    try {
      _cachedMyRecords = await clockingUseCase.getRecordsByDate(event.date);
      _cachedTeamRecords = [];
      await _clockingLocalDataSource.saveAll(_cachedMyRecords);
      emit(_loadedState());
    } catch (e) {
      emit(
        ClockingError(
          AppErrorMessageResolver.resolve(
            e,
            fallback: 'We could not load the clocking records for this date.',
          ),
        ),
      );
    }
  }

  Future<void> _onLoadByUserId(
    LoadClockingByUserIdEvent event,
    Emitter<ClockingState> emit,
  ) async {
    emit(ClockingLoading());
    try {
      _cachedMyRecords = await clockingUseCase.getRecordsByUserId(event.userId);
      _cachedTeamRecords = [];
      await _clockingLocalDataSource.saveAll(_cachedMyRecords);
      emit(_loadedState());
    } catch (e) {
      emit(
        ClockingError(
          AppErrorMessageResolver.resolve(
            e,
            fallback: 'We could not load the clocking records for this user.',
          ),
        ),
      );
    }
  }

  Future<void> _onLoadByTeamId(
    LoadClockingByTeamIdEvent event,
    Emitter<ClockingState> emit,
  ) async {
    _selectedTeamId = event.teamId;
    emit(ClockingLoading());
    try {
      _cachedTeamRecords = await clockingUseCase.getRecordsByTeamId(
        event.teamId,
      );
      emit(_loadedState());
    } catch (e) {
      emit(
        ClockingError(
          AppErrorMessageResolver.resolve(
            e,
            fallback: 'We could not load the team clocking records right now.',
          ),
        ),
      );
    }
  }

  Future<void> _onClockIn(
    ClockInEvent event,
    Emitter<ClockingState> emit,
  ) async {
    await _performAction(
      emit,
      () => clockingUseCase.clockIn(teamId: event.teamId, note: event.note),
    );
  }

  Future<void> _onClockOut(
    ClockOutEvent event,
    Emitter<ClockingState> emit,
  ) async {
    await _performAction(
      emit,
      () => clockingUseCase.clockOut(teamId: event.teamId, note: event.note),
    );
  }

  Future<void> _onStartBreak(
    StartBreakEvent event,
    Emitter<ClockingState> emit,
  ) async {
    await _performAction(
      emit,
      () => clockingUseCase.startBreak(teamId: event.teamId, note: event.note),
    );
  }

  Future<void> _onMarkVacation(
    MarkVacationEvent event,
    Emitter<ClockingState> emit,
  ) async {
    await _performAction(
      emit,
      () => clockingUseCase.markVacation(
        teamId: event.teamId,
        date: event.date,
        targetUserId: event.targetUserId,
        note: event.note,
      ),
    );
  }

  Future<void> _onMarkPermission(
    MarkPermissionEvent event,
    Emitter<ClockingState> emit,
  ) async {
    await _performAction(
      emit,
      () => clockingUseCase.markPermission(
        teamId: event.teamId,
        date: event.date,
        startTime: event.startTime,
        endTime: event.endTime,
        targetUserId: event.targetUserId,
        note: event.note,
      ),
    );
  }

  Future<void> _onStopBreak(
    StopBreakEvent event,
    Emitter<ClockingState> emit,
  ) async {
    await _performAction(
      emit,
      () => clockingUseCase.stopBreak(teamId: event.teamId, note: event.note),
    );
  }

  Future<void> _onUpdateRecord(
    UpdateClockingRecordEvent event,
    Emitter<ClockingState> emit,
  ) async {
    final rollbackMyRecords = List<ClockingRecordEntity>.from(_cachedMyRecords);
    final rollbackTeamRecords = List<ClockingRecordEntity>.from(
      _cachedTeamRecords,
    );
    final previous = _findRecordById(event.id);
    if (previous == null) {
      await _performAction(
        emit,
        () => clockingUseCase.updateTeamRecord(
          id: event.id,
          clockInAt: event.clockInAt,
          clockOutAt: event.clockOutAt,
          totalBreakMinutes: event.totalBreakMinutes,
          note: event.note,
        ),
      );
      return;
    }

    final optimisticRecord = previous.copyWith(
      clockInTime: event.clockInAt ?? previous.clockInTime,
      clockOutTime: event.clockOutAt ?? previous.clockOutTime,
      note: event.note ?? previous.note,
      totalBreakMinutes: event.totalBreakMinutes ?? previous.totalBreakMinutes,
    );
    await _applyOptimisticRecordMutation(emit, optimisticRecord);

    unawaited(() async {
      try {
        final record = await clockingUseCase.updateTeamRecord(
          id: event.id,
          clockInAt: event.clockInAt,
          clockOutAt: event.clockOutAt,
          totalBreakMinutes: event.totalBreakMinutes,
          note: event.note,
        );
        if (!isClosed) {
          add(
            _ClockingRecordCommittedEvent(previousId: event.id, record: record),
          );
        }
      } catch (e) {
        if (!isClosed) {
          add(
            _ClockingMutationFailedEvent(
              message: AppErrorMessageResolver.resolve(
                e,
                fallback: 'We could not save the clocking change right now.',
              ),
              rollbackMyRecords: rollbackMyRecords,
              rollbackTeamRecords: rollbackTeamRecords,
              syncingIdsToClear: {event.id},
            ),
          );
        }
      }
    }());
  }

  Future<void> _onCreateManualClockingEntries(
    CreateManualClockingEntriesEvent event,
    Emitter<ClockingState> emit,
  ) async {
    final rollbackMyRecords = List<ClockingRecordEntity>.from(_cachedMyRecords);
    final rollbackTeamRecords = List<ClockingRecordEntity>.from(
      _cachedTeamRecords,
    );
    final syncingIds = event.optimisticRecords
        .map((record) => record.id)
        .toSet();

    _syncingRecordIds.addAll(syncingIds);
    _cachedMyRecords = [
      ...event.optimisticRecords,
      ..._cachedMyRecords.where(
        (existing) => !syncingIds.contains(existing.id),
      ),
    ]..sort((a, b) => _recordSortDate(b).compareTo(_recordSortDate(a)));

    if (_selectedTeamId != null &&
        _selectedTeamId!.isNotEmpty &&
        _selectedTeamId == event.teamId) {
      _cachedTeamRecords = [
        ...event.optimisticRecords,
        ..._cachedTeamRecords.where(
          (existing) => !syncingIds.contains(existing.id),
        ),
      ]..sort((a, b) => _recordSortDate(b).compareTo(_recordSortDate(a)));
    }

    await _clockingLocalDataSource.saveAll(_cachedMyRecords);
    emit(_loadedState());

    unawaited(() async {
      try {
        await clockingUseCase.createManualClockingEntries(
          teamId: event.teamId,
          dates: event.dates,
          clockInMinutes: event.clockInMinutes,
          clockOutMinutes: event.clockOutMinutes,
          breakMinutes: event.breakMinutes,
          note: event.note,
        );
        if (!isClosed) {
          add(_ManualClockingEntriesCommittedEvent(syncingIds));
        }
      } catch (e) {
        if (!isClosed) {
          add(
            _ManualClockingEntriesFailedEvent(
              message: AppErrorMessageResolver.resolve(
                e,
                fallback:
                    'We could not save the manual clocking entries right now.',
              ),
              rollbackMyRecords: rollbackMyRecords,
              rollbackTeamRecords: rollbackTeamRecords,
              syncingIdsToClear: syncingIds,
            ),
          );
        }
      }
    }());
  }

  Future<void> _onDecommitRecord(
    DecommitClockingRecordEvent event,
    Emitter<ClockingState> emit,
  ) async {
    final previous = _findRecordById(event.id);
    if (previous == null) {
      await _performAction(
        emit,
        () => clockingUseCase.decommitTeamRecord(event.id),
      );
      return;
    }
    final rollbackMyRecords = List<ClockingRecordEntity>.from(_cachedMyRecords);
    final rollbackTeamRecords = List<ClockingRecordEntity>.from(
      _cachedTeamRecords,
    );
    final optimisticRecord = previous.copyWith(
      status: ClockingStatus.decommitted,
      decommittedAt: DateTime.now(),
      committedAt: null,
      canCommit: true,
      canDecommit: false,
    );
    await _applyOptimisticRecordMutation(emit, optimisticRecord);

    unawaited(() async {
      try {
        final record = await clockingUseCase.decommitTeamRecord(event.id);
        if (!isClosed) {
          add(
            _ClockingRecordCommittedEvent(previousId: event.id, record: record),
          );
        }
      } catch (e) {
        if (!isClosed) {
          add(
            _ClockingMutationFailedEvent(
              message: AppErrorMessageResolver.resolve(
                e,
                fallback: 'We could not save the clocking change right now.',
              ),
              rollbackMyRecords: rollbackMyRecords,
              rollbackTeamRecords: rollbackTeamRecords,
              syncingIdsToClear: {event.id},
            ),
          );
        }
      }
    }());
  }

  Future<void> _onCommitRecord(
    CommitClockingRecordEvent event,
    Emitter<ClockingState> emit,
  ) async {
    final previous = _findRecordById(event.id);
    if (previous == null) {
      await _performAction(
        emit,
        () => clockingUseCase.commitTeamRecord(event.id),
      );
      return;
    }
    final rollbackMyRecords = List<ClockingRecordEntity>.from(_cachedMyRecords);
    final rollbackTeamRecords = List<ClockingRecordEntity>.from(
      _cachedTeamRecords,
    );
    final optimisticRecord = previous.copyWith(
      status: ClockingStatus.committed,
      committedAt: DateTime.now(),
      decommittedAt: null,
      canCommit: false,
      canDecommit: true,
    );
    await _applyOptimisticRecordMutation(emit, optimisticRecord);

    unawaited(() async {
      try {
        final record = await clockingUseCase.commitTeamRecord(event.id);
        if (!isClosed) {
          add(
            _ClockingRecordCommittedEvent(previousId: event.id, record: record),
          );
        }
      } catch (e) {
        if (!isClosed) {
          add(
            _ClockingMutationFailedEvent(
              message: AppErrorMessageResolver.resolve(
                e,
                fallback: 'We could not save the clocking change right now.',
              ),
              rollbackMyRecords: rollbackMyRecords,
              rollbackTeamRecords: rollbackTeamRecords,
              syncingIdsToClear: {event.id},
            ),
          );
        }
      }
    }());
  }

  Future<void> _onDelete(
    DeleteClockingRecordEvent event,
    Emitter<ClockingState> emit,
  ) async {
    final rollbackMyRecords = List<ClockingRecordEntity>.from(_cachedMyRecords);
    final rollbackTeamRecords = List<ClockingRecordEntity>.from(
      _cachedTeamRecords,
    );
    _syncingRecordIds.add(event.id);
    _cachedMyRecords = _cachedMyRecords
        .where((record) => record.id != event.id)
        .toList();
    _cachedTeamRecords = _cachedTeamRecords
        .where((record) => record.id != event.id)
        .toList();
    await _clockingLocalDataSource.saveAll(_cachedMyRecords);
    emit(ClockingDeleted());
    emit(_loadedState());

    unawaited(() async {
      try {
        await clockingUseCase.deleteRecord(event.id);
        if (!isClosed) {
          add(_ClockingRecordDeletedCommittedEvent(event.id));
        }
      } catch (e) {
        if (!isClosed) {
          add(
            _ClockingMutationFailedEvent(
              message: AppErrorMessageResolver.resolve(
                e,
                fallback: 'We could not delete the clocking record right now.',
              ),
              rollbackMyRecords: rollbackMyRecords,
              rollbackTeamRecords: rollbackTeamRecords,
              syncingIdsToClear: {event.id},
            ),
          );
        }
      }
    }());
  }

  Future<void> _performAction(
    Emitter<ClockingState> emit,
    Future<ClockingRecordEntity> Function() action,
  ) async {
    try {
      emit(_inProgressState());
      final record = await action();

      // ── Optimistic update ──────────────────────────────────────────────
      // Immediately reflect the new/updated record in the cache so the UI
      // feels instant. We replace an existing record with the same id, or
      // prepend it if it is brand-new.
      final myIdx = _cachedMyRecords.indexWhere((r) => r.id == record.id);
      if (myIdx >= 0) {
        _cachedMyRecords = List<ClockingRecordEntity>.from(_cachedMyRecords)
          ..[myIdx] = record;
      } else {
        _cachedMyRecords = [record, ..._cachedMyRecords];
      }
      final teamIdx = _cachedTeamRecords.indexWhere((r) => r.id == record.id);
      if (teamIdx >= 0) {
        _cachedTeamRecords = List<ClockingRecordEntity>.from(_cachedTeamRecords)
          ..[teamIdx] = record;
      }
      // ──────────────────────────────────────────────────────────────────

      emit(
        ClockingActionSuccess(
          record: record,
          myRecords: List<ClockingRecordEntity>.from(_cachedMyRecords),
          teamRecords: List<ClockingRecordEntity>.from(_cachedTeamRecords),
          selectedTeamId: _selectedTeamId,
          syncingRecordIds: Set<String>.from(_syncingRecordIds),
        ),
      );

      // Background reload to get the authoritative server state.
      try {
        await _reloadDashboard();
      } catch (_) {}
      emit(_loadedState());
    } catch (e) {
      emit(
        ClockingError(
          AppErrorMessageResolver.resolve(
            e,
            fallback: 'We could not save the clocking change right now.',
          ),
        ),
      );
      try {
        await _reloadDashboard();
      } catch (_) {}
      if (_cachedMyRecords.isNotEmpty || _cachedTeamRecords.isNotEmpty) {
        emit(_loadedState());
      }
    }
  }

  Future<void> _reloadDashboard() async {
    _cachedMyRecords = await clockingUseCase.getAllRecords();
    await _clockingLocalDataSource.saveAll(_cachedMyRecords);
    if (_selectedTeamId != null && _selectedTeamId!.isNotEmpty) {
      _cachedTeamRecords = await clockingUseCase.getRecordsByTeamId(
        _selectedTeamId!,
      );
    } else {
      _cachedTeamRecords = [];
    }
  }

  ClockingRecordsLoaded _loadedState() {
    return ClockingRecordsLoaded(
      myRecords: List<ClockingRecordEntity>.from(_cachedMyRecords),
      teamRecords: List<ClockingRecordEntity>.from(_cachedTeamRecords),
      selectedTeamId: _selectedTeamId,
      syncingRecordIds: Set<String>.from(_syncingRecordIds),
    );
  }

  ClockingActionInProgress _inProgressState() {
    return ClockingActionInProgress(
      myRecords: List<ClockingRecordEntity>.from(_cachedMyRecords),
      teamRecords: List<ClockingRecordEntity>.from(_cachedTeamRecords),
      selectedTeamId: _selectedTeamId,
      syncingRecordIds: Set<String>.from(_syncingRecordIds),
    );
  }

  DateTime _recordSortDate(ClockingRecordEntity record) {
    return record.clockOutTime ??
        record.currentBreakStartedAt ??
        record.clockInTime ??
        record.date;
  }

  Future<void> _applyOptimisticRecordMutation(
    Emitter<ClockingState> emit,
    ClockingRecordEntity record,
  ) async {
    _syncingRecordIds.add(record.id);
    _upsertRecord(record);
    await _clockingLocalDataSource.saveAll(_cachedMyRecords);
    emit(_inProgressState());
    emit(
      ClockingActionSuccess(
        record: record,
        myRecords: List<ClockingRecordEntity>.from(_cachedMyRecords),
        teamRecords: List<ClockingRecordEntity>.from(_cachedTeamRecords),
        selectedTeamId: _selectedTeamId,
        syncingRecordIds: Set<String>.from(_syncingRecordIds),
      ),
    );
  }

  void _upsertRecord(ClockingRecordEntity record) {
    final myIndex = _cachedMyRecords.indexWhere((item) => item.id == record.id);
    if (myIndex >= 0) {
      _cachedMyRecords = List<ClockingRecordEntity>.from(_cachedMyRecords)
        ..[myIndex] = record;
    }
    final teamIndex = _cachedTeamRecords.indexWhere(
      (item) => item.id == record.id,
    );
    if (teamIndex >= 0) {
      _cachedTeamRecords = List<ClockingRecordEntity>.from(_cachedTeamRecords)
        ..[teamIndex] = record;
    }
  }

  ClockingRecordEntity? _findRecordById(String id) {
    final inMyRecords = _cachedMyRecords
        .where((record) => record.id == id)
        .firstOrNull;
    if (inMyRecords != null) {
      return inMyRecords;
    }
    return _cachedTeamRecords.where((record) => record.id == id).firstOrNull;
  }

  Future<void> _onRecordCommitted(
    _ClockingRecordCommittedEvent event,
    Emitter<ClockingState> emit,
  ) async {
    _syncingRecordIds.remove(event.previousId);
    _upsertRecord(event.record);
    await _clockingLocalDataSource.saveAll(_cachedMyRecords);
    emit(
      ClockingActionSuccess(
        record: event.record,
        myRecords: List<ClockingRecordEntity>.from(_cachedMyRecords),
        teamRecords: List<ClockingRecordEntity>.from(_cachedTeamRecords),
        selectedTeamId: _selectedTeamId,
        syncingRecordIds: Set<String>.from(_syncingRecordIds),
      ),
    );
    emit(_loadedState());
  }

  Future<void> _onRecordDeletedCommitted(
    _ClockingRecordDeletedCommittedEvent event,
    Emitter<ClockingState> emit,
  ) async {
    _syncingRecordIds.remove(event.recordId);
    await _clockingLocalDataSource.saveAll(_cachedMyRecords);
    emit(_loadedState());
  }

  Future<void> _onMutationFailed(
    _ClockingMutationFailedEvent event,
    Emitter<ClockingState> emit,
  ) async {
    _cachedMyRecords = List<ClockingRecordEntity>.from(event.rollbackMyRecords);
    _cachedTeamRecords = List<ClockingRecordEntity>.from(
      event.rollbackTeamRecords,
    );
    _syncingRecordIds.removeAll(event.syncingIdsToClear);
    await _clockingLocalDataSource.saveAll(_cachedMyRecords);
    emit(ClockingError(event.message));
    emit(_loadedState());
  }

  Future<void> _onManualEntriesCommitted(
    _ManualClockingEntriesCommittedEvent event,
    Emitter<ClockingState> emit,
  ) async {
    _syncingRecordIds.removeAll(event.syncingIdsToClear);
    try {
      await _reloadDashboard();
    } catch (_) {}
    emit(_loadedState());
  }

  Future<void> _onManualEntriesFailed(
    _ManualClockingEntriesFailedEvent event,
    Emitter<ClockingState> emit,
  ) async {
    _cachedMyRecords = List<ClockingRecordEntity>.from(event.rollbackMyRecords);
    _cachedTeamRecords = List<ClockingRecordEntity>.from(
      event.rollbackTeamRecords,
    );
    _syncingRecordIds.removeAll(event.syncingIdsToClear);
    await _clockingLocalDataSource.saveAll(_cachedMyRecords);
    emit(ClockingError(event.message));
    try {
      await _reloadDashboard();
    } catch (_) {}
    emit(_loadedState());
  }
}
