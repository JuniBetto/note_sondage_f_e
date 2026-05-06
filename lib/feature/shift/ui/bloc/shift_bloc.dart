import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:note_sondage/feature/shift/domain/repositories/shift_repository.dart';
import 'shift_event.dart';

export 'shift_event.dart';

class ShiftBloc extends Bloc<ShiftEvent, ShiftState> {
  final ShiftRepository _repository;

  ShiftBloc(this._repository) : super(ShiftInitial()) {
    on<LoadShiftProfilesEvent>(_onLoadProfiles);
    on<CreateShiftProfileEvent>(_onCreateProfile);
    on<UpdateShiftProfileEvent>(_onUpdateProfile);
    on<DeleteShiftProfileEvent>(_onDeleteProfile);
    on<LoadShiftAssignmentsEvent>(_onLoadAssignments);
    on<AssignShiftEvent>(_onAssign);
    on<UpdateShiftAssignmentEvent>(_onUpdateAssignment);
    on<DeleteShiftAssignmentEvent>(_onDeleteAssignment);
  }

  Future<void> _onLoadProfiles(
    LoadShiftProfilesEvent event,
    Emitter<ShiftState> emit,
  ) async {
    emit(ShiftLoading());
    try {
      final profiles = await _repository.getProfiles();
      emit(ShiftProfilesLoaded(profiles));
    } catch (e) {
      emit(ShiftError(e.toString()));
    }
  }

  Future<void> _onCreateProfile(
    CreateShiftProfileEvent event,
    Emitter<ShiftState> emit,
  ) async {
    emit(ShiftLoading());
    try {
      final profile = await _repository.createProfile(
        name: event.name,
        startTime: event.startTime,
        endTime: event.endTime,
        overnight: event.overnight,
        alarmOffsets: event.alarmOffsets,
        color: event.color,
        isPublic: event.isPublic,
      );
      emit(ShiftProfileCreated(profile));
    } catch (e) {
      emit(ShiftError(e.toString()));
    }
  }

  Future<void> _onUpdateProfile(
    UpdateShiftProfileEvent event,
    Emitter<ShiftState> emit,
  ) async {
    emit(ShiftLoading());
    try {
      final profile = await _repository.updateProfile(
        event.profileId,
        name: event.name,
        startTime: event.startTime,
        endTime: event.endTime,
        overnight: event.overnight,
        alarmOffsets: event.alarmOffsets,
        color: event.color,
        isPublic: event.isPublic,
      );
      emit(ShiftProfileUpdated(profile));
    } catch (e) {
      emit(ShiftError(e.toString()));
    }
  }

  Future<void> _onDeleteProfile(
    DeleteShiftProfileEvent event,
    Emitter<ShiftState> emit,
  ) async {
    try {
      await _repository.deleteProfile(event.profileId);
      emit(ShiftProfileDeleted());
    } catch (e) {
      emit(ShiftError(e.toString()));
    }
  }

  Future<void> _onLoadAssignments(
    LoadShiftAssignmentsEvent event,
    Emitter<ShiftState> emit,
  ) async {
    emit(ShiftLoading());
    try {
      final assignments = await _repository.getAssignments(
        from: event.from,
        to: event.to,
      );
      emit(ShiftAssignmentsLoaded(assignments));
    } catch (e) {
      emit(ShiftError(e.toString()));
    }
  }

  Future<void> _onAssign(
    AssignShiftEvent event,
    Emitter<ShiftState> emit,
  ) async {
    try {
      final assignment = await _repository.assign(
        shiftDate: event.shiftDate,
        profileId: event.profileId,
        startTime: event.startTime,
        endTime: event.endTime,
        overnight: event.overnight,
        note: event.note,
        alarmOffsets: event.alarmOffsets,
        isPublic: event.isPublic,
        teamId: event.teamId,
        targetUserId: event.targetUserId,
      );
      emit(ShiftAssigned(assignment));
    } catch (e) {
      emit(ShiftError(e.toString()));
    }
  }

  Future<void> _onUpdateAssignment(
    UpdateShiftAssignmentEvent event,
    Emitter<ShiftState> emit,
  ) async {
    try {
      final assignment = await _repository.updateAssignment(
        event.assignmentId,
        profileId: event.profileId,
        startTime: event.startTime,
        endTime: event.endTime,
        overnight: event.overnight,
        note: event.note,
        alarmOffsets: event.alarmOffsets,
        isPublic: event.isPublic,
        teamId: event.teamId,
        targetUserId: event.targetUserId,
      );
      emit(ShiftAssignmentUpdated(assignment));
    } catch (e) {
      emit(ShiftError(e.toString()));
    }
  }

  Future<void> _onDeleteAssignment(
    DeleteShiftAssignmentEvent event,
    Emitter<ShiftState> emit,
  ) async {
    try {
      await _repository.deleteAssignment(event.assignmentId);
      emit(ShiftAssignmentDeleted());
    } catch (e) {
      emit(ShiftError(e.toString()));
    }
  }
}
