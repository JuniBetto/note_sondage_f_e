import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:note_sondage/core/utils/app_error_message_resolver.dart';
import 'package:note_sondage/feature/shift/domain/repositories/shift_repository.dart';
import 'package:note_sondage/feature/shift/infrastructure/data_source/shift_local_data_source.dart';
import '../../domain/entities/shift_assignment_entity.dart';
import '../../domain/entities/shift_profile_entity.dart';
import 'shift_event.dart';

export 'shift_event.dart';

class ShiftBloc extends Bloc<ShiftEvent, ShiftState> {
  final ShiftRepository _repository;
  final ShiftLocalDataSource _localDataSource;
  List<ShiftProfileEntity> _cachedProfiles = <ShiftProfileEntity>[];
  List<ShiftAssignmentEntity> _cachedAssignments = <ShiftAssignmentEntity>[];
  bool _profilesRefreshInFlight = false;
  String? _assignmentsRefreshKey;

  void _upsertProfileCache(ShiftProfileEntity profile) {
    _cachedProfiles = [
      ..._cachedProfiles.where((item) => item.id != profile.id),
      profile,
    ]..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  }

  void _removeProfileCache(String profileId) {
    _cachedProfiles = _cachedProfiles
        .where((profile) => profile.id != profileId)
        .toList();
  }

  void _upsertAssignmentCache(ShiftAssignmentEntity assignment) {
    _cachedAssignments = [
      ..._cachedAssignments.where((item) => item.id != assignment.id),
      assignment,
    ]..sort((a, b) => a.shiftDate.compareTo(b.shiftDate));
  }

  void _removeAssignmentCache(String assignmentId) {
    _cachedAssignments = _cachedAssignments
        .where((assignment) => assignment.id != assignmentId)
        .toList();
  }

  ShiftBloc(this._repository, this._localDataSource) : super(ShiftInitial()) {
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
    if (_cachedProfiles.isNotEmpty) {
      emit(ShiftProfilesLoaded(_cachedProfiles));
    } else {
      final local = await _localDataSource.getProfiles();
      if (local.isNotEmpty) {
        _cachedProfiles = local;
        emit(ShiftProfilesLoaded(local));
      } else {
        emit(ShiftLoading());
      }
    }
    if (_profilesRefreshInFlight) {
      return;
    }
    _profilesRefreshInFlight = true;
    try {
      final profiles = await _repository.getProfiles();
      _cachedProfiles = profiles;
      emit(ShiftProfilesLoaded(profiles));
    } catch (e) {
      emit(
        ShiftError(
          AppErrorMessageResolver.resolve(
            e,
            fallback: 'We could not load the shift profiles right now.',
          ),
        ),
      );
      if (_cachedProfiles.isNotEmpty) {
        emit(ShiftProfilesLoaded(_cachedProfiles));
      }
    } finally {
      _profilesRefreshInFlight = false;
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
      _upsertProfileCache(profile);
      emit(ShiftProfileCreated(profile));
    } catch (e) {
      emit(
        ShiftError(
          AppErrorMessageResolver.resolve(
            e,
            fallback: 'We could not create the shift profile right now.',
          ),
        ),
      );
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
      _upsertProfileCache(profile);
      emit(ShiftProfileUpdated(profile));
    } catch (e) {
      emit(
        ShiftError(
          AppErrorMessageResolver.resolve(
            e,
            fallback: 'We could not update the shift profile right now.',
          ),
        ),
      );
    }
  }

  Future<void> _onDeleteProfile(
    DeleteShiftProfileEvent event,
    Emitter<ShiftState> emit,
  ) async {
    try {
      await _repository.deleteProfile(event.profileId);
      _removeProfileCache(event.profileId);
      emit(ShiftProfileDeleted(event.profileId));
    } catch (e) {
      emit(
        ShiftError(
          AppErrorMessageResolver.resolve(
            e,
            fallback: 'We could not delete the shift profile right now.',
          ),
        ),
      );
    }
  }

  Future<void> _onLoadAssignments(
    LoadShiftAssignmentsEvent event,
    Emitter<ShiftState> emit,
  ) async {
    final requestKey =
        '${event.from.year}-${event.from.month}-${event.from.day}:${event.to.year}-${event.to.month}-${event.to.day}';
    if (_cachedAssignments.isNotEmpty) {
      emit(ShiftAssignmentsLoaded(_cachedAssignments));
    } else {
      final local = await _localDataSource.getAssignments(
        from: event.from,
        to: event.to,
      );
      if (local.isNotEmpty) {
        _cachedAssignments = local;
        emit(ShiftAssignmentsLoaded(local));
      } else {
        emit(ShiftLoading());
      }
    }
    if (_assignmentsRefreshKey == requestKey) {
      return;
    }
    _assignmentsRefreshKey = requestKey;
    try {
      final assignments = await _repository.getAssignments(
        from: event.from,
        to: event.to,
      );
      _cachedAssignments = assignments;
      emit(ShiftAssignmentsLoaded(assignments));
    } catch (e) {
      emit(
        ShiftError(
          AppErrorMessageResolver.resolve(
            e,
            fallback: 'We could not load the shifts right now.',
          ),
        ),
      );
      if (_cachedAssignments.isNotEmpty) {
        emit(ShiftAssignmentsLoaded(_cachedAssignments));
      }
    } finally {
      if (_assignmentsRefreshKey == requestKey) {
        _assignmentsRefreshKey = null;
      }
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
        teamShiftGroupId: event.teamShiftGroupId,
        targetUserId: event.targetUserId,
      );
      _upsertAssignmentCache(assignment);
      emit(ShiftAssigned(assignment));
    } catch (e) {
      emit(
        ShiftError(
          AppErrorMessageResolver.resolve(
            e,
            fallback: 'We could not save the shift right now.',
          ),
        ),
      );
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
        teamShiftGroupId: event.teamShiftGroupId,
        targetUserId: event.targetUserId,
      );
      _upsertAssignmentCache(assignment);
      emit(ShiftAssignmentUpdated(assignment));
    } catch (e) {
      emit(
        ShiftError(
          AppErrorMessageResolver.resolve(
            e,
            fallback: 'We could not update the shift right now.',
          ),
        ),
      );
    }
  }

  Future<void> _onDeleteAssignment(
    DeleteShiftAssignmentEvent event,
    Emitter<ShiftState> emit,
  ) async {
    try {
      await _repository.deleteAssignment(event.assignmentId);
      _removeAssignmentCache(event.assignmentId);
      emit(ShiftAssignmentDeleted(event.assignmentId));
    } catch (e) {
      emit(
        ShiftError(
          AppErrorMessageResolver.resolve(
            e,
            fallback: 'We could not delete the shift right now.',
          ),
        ),
      );
    }
  }
}
