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

  List<ClockingRecordEntity> _cachedMyRecords = [];
  List<ClockingRecordEntity> _cachedTeamRecords = [];
  String? _selectedTeamId;

  String? get selectedTeamId => _selectedTeamId;

  ClockingBloc({
    required this.clockingUseCase,
    required ClockingLocalDataSource clockingLocalDataSource,
  }) : super(ClockingInitial()) {
    on<LoadClockingRecordsEvent>(_onLoadRecords);
    on<LoadClockingByDateEvent>(_onLoadByDate);
    on<LoadClockingByUserIdEvent>(_onLoadByUserId);
    on<LoadClockingByTeamIdEvent>(_onLoadByTeamId);
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
      emit(ClockingLoading());
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
  }

  Future<void> _onDecommitRecord(
    DecommitClockingRecordEvent event,
    Emitter<ClockingState> emit,
  ) async {
    await _performAction(
      emit,
      () => clockingUseCase.decommitTeamRecord(event.id),
    );
  }

  Future<void> _onCommitRecord(
    CommitClockingRecordEvent event,
    Emitter<ClockingState> emit,
  ) async {
    await _performAction(
      emit,
      () => clockingUseCase.commitTeamRecord(event.id),
    );
  }

  Future<void> _onDelete(
    DeleteClockingRecordEvent event,
    Emitter<ClockingState> emit,
  ) async {
    try {
      emit(_inProgressState());
      await clockingUseCase.deleteRecord(event.id);
      emit(ClockingDeleted());
      await _reloadDashboard();
      emit(_loadedState());
    } catch (e) {
      emit(
        ClockingError(
          AppErrorMessageResolver.resolve(
            e,
            fallback: 'We could not delete the clocking record right now.',
          ),
        ),
      );
      if (_cachedMyRecords.isNotEmpty || _cachedTeamRecords.isNotEmpty) {
        emit(_loadedState());
      }
    }
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
    );
  }

  ClockingActionInProgress _inProgressState() {
    return ClockingActionInProgress(
      myRecords: List<ClockingRecordEntity>.from(_cachedMyRecords),
      teamRecords: List<ClockingRecordEntity>.from(_cachedTeamRecords),
      selectedTeamId: _selectedTeamId,
    );
  }
}
