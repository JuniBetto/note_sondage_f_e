import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:note_sondage/feature/clocking/domain/entities/clocking_record_entity.dart';
import 'package:note_sondage/feature/clocking/domain/use_case/clocking_use_case.dart';

part 'clocking_event.dart';
part 'clocking_state.dart';

class ClockingBloc extends Bloc<ClockingEvent, ClockingState> {
  final ClockingUseCase clockingUseCase;

  /// Cache dei record per evitare flickering
  List<ClockingRecordEntity> _cachedRecords = [];

  ClockingBloc({required this.clockingUseCase}) : super(ClockingInitial()) {
    on<LoadClockingRecordsEvent>(_onLoadRecords);
    on<LoadClockingByDateEvent>(_onLoadByDate);
    on<LoadClockingByUserIdEvent>(_onLoadByUserId);
    on<LoadClockingByTeamIdEvent>(_onLoadByTeamId);
    on<ClockInEvent>(_onClockIn);
    on<ClockOutEvent>(_onClockOut);
    on<DeleteClockingRecordEvent>(_onDelete);
  }

  Future<void> _onLoadRecords(
    LoadClockingRecordsEvent event,
    Emitter<ClockingState> emit,
  ) async {
    if (_cachedRecords.isNotEmpty) {
      emit(ClockingRecordsLoaded(_cachedRecords));
    } else {
      emit(ClockingLoading());
    }
    try {
      final records = await clockingUseCase.getAllRecords();
      _cachedRecords = records;
      emit(ClockingRecordsLoaded(records));
    } catch (e) {
      if (_cachedRecords.isEmpty) {
        emit(ClockingError(e.toString()));
      }
    }
  }

  Future<void> _onLoadByDate(
    LoadClockingByDateEvent event,
    Emitter<ClockingState> emit,
  ) async {
    emit(ClockingLoading());
    try {
      final records = await clockingUseCase.getRecordsByDate(event.date);
      emit(ClockingRecordsLoaded(records));
    } catch (e) {
      emit(ClockingError(e.toString()));
    }
  }

  Future<void> _onLoadByUserId(
    LoadClockingByUserIdEvent event,
    Emitter<ClockingState> emit,
  ) async {
    emit(ClockingLoading());
    try {
      final records = await clockingUseCase.getRecordsByUserId(event.userId);
      emit(ClockingRecordsLoaded(records));
    } catch (e) {
      emit(ClockingError(e.toString()));
    }
  }

  Future<void> _onLoadByTeamId(
    LoadClockingByTeamIdEvent event,
    Emitter<ClockingState> emit,
  ) async {
    emit(ClockingLoading());
    try {
      final records = await clockingUseCase.getRecordsByTeamId(event.teamId);
      emit(ClockingRecordsLoaded(records));
    } catch (e) {
      emit(ClockingError(e.toString()));
    }
  }

  Future<void> _onClockIn(
    ClockInEvent event,
    Emitter<ClockingState> emit,
  ) async {
    try {
      final record = await clockingUseCase.clockIn(
        teamId: event.teamId,
        note: event.note,
      );
      emit(ClockingActionSuccess(record));
      _cachedRecords = [
        record,
        ..._cachedRecords.where((existing) => existing.id != record.id),
      ];
      emit(ClockingRecordsLoaded(_cachedRecords));
    } catch (e) {
      emit(ClockingError(e.toString()));
      if (_cachedRecords.isNotEmpty) {
        emit(ClockingRecordsLoaded(_cachedRecords));
      }
    }
  }

  Future<void> _onClockOut(
    ClockOutEvent event,
    Emitter<ClockingState> emit,
  ) async {
    try {
      final record = await clockingUseCase.clockOut(
        teamId: event.teamId,
        note: event.note,
      );
      emit(ClockingActionSuccess(record));
      _cachedRecords = _cachedRecords.map((r) {
        return r.id == record.id ? record : r;
      }).toList();
      if (!_cachedRecords.any((r) => r.id == record.id)) {
        _cachedRecords = [record, ..._cachedRecords];
      }
      emit(ClockingRecordsLoaded(_cachedRecords));
    } catch (e) {
      emit(ClockingError(e.toString()));
      if (_cachedRecords.isNotEmpty) {
        emit(ClockingRecordsLoaded(_cachedRecords));
      }
    }
  }

  Future<void> _onDelete(
    DeleteClockingRecordEvent event,
    Emitter<ClockingState> emit,
  ) async {
    try {
      await clockingUseCase.deleteRecord(event.id);
      emit(ClockingDeleted());
      _cachedRecords = _cachedRecords.where((r) => r.id != event.id).toList();
      emit(ClockingRecordsLoaded(_cachedRecords));
    } catch (e) {
      emit(ClockingError(e.toString()));
      if (_cachedRecords.isNotEmpty) {
        emit(ClockingRecordsLoaded(_cachedRecords));
      }
    }
  }
}
