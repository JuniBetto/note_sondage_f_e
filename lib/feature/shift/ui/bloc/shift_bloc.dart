import 'dart:async';

import 'package:flutter/material.dart';
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
  final Set<String> _syncingProfileIds = <String>{};
  final Set<String> _syncingAssignmentIds = <String>{};
  bool _profilesRefreshInFlight = false;
  String? _assignmentsRefreshKey;

  Set<String> get syncingProfileIds => Set.unmodifiable(_syncingProfileIds);
  Set<String> get syncingAssignmentIds =>
      Set.unmodifiable(_syncingAssignmentIds);

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
    on<ShiftProfileCreateCommittedEvent>(_onProfileCreateCommitted);
    on<ShiftProfileUpdateCommittedEvent>(_onProfileUpdateCommitted);
    on<ShiftProfileDeleteCommittedEvent>(_onProfileDeleteCommitted);
    on<CreateShiftProfileEvent>(_onCreateProfile);
    on<UpdateShiftProfileEvent>(_onUpdateProfile);
    on<DeleteShiftProfileEvent>(_onDeleteProfile);
    on<LoadShiftAssignmentsEvent>(_onLoadAssignments);
    on<ShiftAssignmentCreateCommittedEvent>(_onAssignmentCreateCommitted);
    on<ShiftAssignmentUpdateCommittedEvent>(_onAssignmentUpdateCommitted);
    on<ShiftAssignmentDeleteCommittedEvent>(_onAssignmentDeleteCommitted);
    on<ShiftMutationFailedEvent>(_onMutationFailed);
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
      await _localDataSource.saveProfiles(_cachedProfiles);
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
      final rollbackProfiles = List<ShiftProfileEntity>.from(_cachedProfiles);
      final optimisticProfile = ShiftProfileEntity(
        id: _temporaryId('shift_profile'),
        userId: null,
        name: event.name,
        color: event.color,
        startTime: event.startTime,
        endTime: event.endTime,
        overnight: event.overnight,
        isSystem: false,
        alarmOffsets: List<int>.from(event.alarmOffsets),
        isPublic: event.isPublic,
      );
      _syncingProfileIds.add(optimisticProfile.id);
      _upsertProfileCache(optimisticProfile);
      await _localDataSource.saveProfiles(_cachedProfiles);
      emit(ShiftProfileCreated(optimisticProfile));

      unawaited(() async {
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
          if (!isClosed) {
            add(
              ShiftProfileCreateCommittedEvent(optimisticProfile.id, profile),
            );
          }
        } catch (e) {
          if (!isClosed) {
            add(
              ShiftMutationFailedEvent(
                message: AppErrorMessageResolver.resolve(
                  e,
                  fallback: 'We could not create the shift profile right now.',
                ),
                rollbackProfiles: rollbackProfiles,
                syncingProfileIdsToClear: {optimisticProfile.id},
              ),
            );
          }
        }
      }());
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
    try {
      final rollbackProfiles = List<ShiftProfileEntity>.from(_cachedProfiles);
      final previous = _cachedProfiles
          .where((profile) => profile.id == event.profileId)
          .firstOrNull;
      final optimisticProfile = ShiftProfileEntity(
        id: event.profileId,
        userId: previous?.userId,
        name: event.name,
        color: event.color,
        startTime: event.startTime,
        endTime: event.endTime,
        overnight: event.overnight,
        isSystem: previous?.isSystem ?? false,
        alarmOffsets: List<int>.from(event.alarmOffsets),
        isPublic: event.isPublic,
      );
      _syncingProfileIds.add(event.profileId);
      _upsertProfileCache(optimisticProfile);
      await _localDataSource.saveProfiles(_cachedProfiles);
      emit(ShiftProfileUpdated(optimisticProfile));

      unawaited(() async {
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
          if (!isClosed) {
            add(ShiftProfileUpdateCommittedEvent(event.profileId, profile));
          }
        } catch (e) {
          if (!isClosed) {
            add(
              ShiftMutationFailedEvent(
                message: AppErrorMessageResolver.resolve(
                  e,
                  fallback: 'We could not update the shift profile right now.',
                ),
                rollbackProfiles: rollbackProfiles,
                syncingProfileIdsToClear: {event.profileId},
              ),
            );
          }
        }
      }());
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
      final rollbackProfiles = List<ShiftProfileEntity>.from(_cachedProfiles);
      _syncingProfileIds.add(event.profileId);
      _removeProfileCache(event.profileId);
      await _localDataSource.saveProfiles(_cachedProfiles);
      emit(ShiftProfileDeleted(event.profileId));

      unawaited(() async {
        try {
          await _repository.deleteProfile(event.profileId);
          if (!isClosed) {
            add(ShiftProfileDeleteCommittedEvent(event.profileId));
          }
        } catch (e) {
          if (!isClosed) {
            add(
              ShiftMutationFailedEvent(
                message: AppErrorMessageResolver.resolve(
                  e,
                  fallback: 'We could not delete the shift profile right now.',
                ),
                rollbackProfiles: rollbackProfiles,
                syncingProfileIdsToClear: {event.profileId},
              ),
            );
          }
        }
      }());
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
        '${event.from.year}-${event.from.month}-${event.from.day}:${event.to.year}-${event.to.month}-${event.to.day}:'
        '${(event.visibleTeamIds ?? const <String>[]).join(",")}:'
        '${(event.visibleUserIds ?? const <String>[]).join(",")}';
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
        visibleTeamIds: event.visibleTeamIds,
        visibleUserIds: event.visibleUserIds,
      );
      _cachedAssignments = assignments;
      await _localDataSource.saveAssignments(_cachedAssignments);
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
      final rollbackAssignments = List<ShiftAssignmentEntity>.from(
        _cachedAssignments,
      );
      final optimisticAssignment = _buildOptimisticAssignmentForCreate(event);
      _syncingAssignmentIds.add(optimisticAssignment.id);
      _upsertAssignmentCache(optimisticAssignment);
      await _localDataSource.saveAssignments(_cachedAssignments);
      emit(ShiftAssigned(optimisticAssignment));

      unawaited(() async {
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
          if (!isClosed) {
            add(
              ShiftAssignmentCreateCommittedEvent(
                optimisticAssignment.id,
                assignment,
              ),
            );
          }
        } catch (e) {
          if (!isClosed) {
            add(
              ShiftMutationFailedEvent(
                message: AppErrorMessageResolver.resolve(
                  e,
                  fallback: 'We could not save the shift right now.',
                ),
                rollbackAssignments: rollbackAssignments,
                syncingAssignmentIdsToClear: {optimisticAssignment.id},
              ),
            );
          }
        }
      }());
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
      final rollbackAssignments = List<ShiftAssignmentEntity>.from(
        _cachedAssignments,
      );
      final previous = _cachedAssignments
          .where((assignment) => assignment.id == event.assignmentId)
          .firstOrNull;
      if (previous == null) {
        throw StateError('Shift assignment not found for optimistic update.');
      }
      final optimisticAssignment = _buildOptimisticAssignmentForUpdate(
        event,
        previous,
      );
      _syncingAssignmentIds.add(event.assignmentId);
      _upsertAssignmentCache(optimisticAssignment);
      await _localDataSource.saveAssignments(_cachedAssignments);
      emit(ShiftAssignmentUpdated(optimisticAssignment));

      unawaited(() async {
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
          if (!isClosed) {
            add(
              ShiftAssignmentUpdateCommittedEvent(
                event.assignmentId,
                assignment,
              ),
            );
          }
        } catch (e) {
          if (!isClosed) {
            add(
              ShiftMutationFailedEvent(
                message: AppErrorMessageResolver.resolve(
                  e,
                  fallback: 'We could not update the shift right now.',
                ),
                rollbackAssignments: rollbackAssignments,
                syncingAssignmentIdsToClear: {event.assignmentId},
              ),
            );
          }
        }
      }());
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
      final rollbackAssignments = List<ShiftAssignmentEntity>.from(
        _cachedAssignments,
      );
      _syncingAssignmentIds.add(event.assignmentId);
      _removeAssignmentCache(event.assignmentId);
      await _localDataSource.saveAssignments(_cachedAssignments);
      emit(ShiftAssignmentDeleted(event.assignmentId));

      unawaited(() async {
        try {
          await _repository.deleteAssignment(event.assignmentId);
          if (!isClosed) {
            add(ShiftAssignmentDeleteCommittedEvent(event.assignmentId));
          }
        } catch (e) {
          if (!isClosed) {
            add(
              ShiftMutationFailedEvent(
                message: AppErrorMessageResolver.resolve(
                  e,
                  fallback: 'We could not delete the shift right now.',
                ),
                rollbackAssignments: rollbackAssignments,
                syncingAssignmentIdsToClear: {event.assignmentId},
              ),
            );
          }
        }
      }());
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

  Future<void> _onProfileCreateCommitted(
    ShiftProfileCreateCommittedEvent event,
    Emitter<ShiftState> emit,
  ) async {
    final index = _cachedProfiles.indexWhere(
      (profile) => profile.id == event.temporaryId,
    );
    if (index == -1) {
      _upsertProfileCache(event.profile);
    } else {
      _cachedProfiles = List<ShiftProfileEntity>.from(_cachedProfiles)
        ..[index] = event.profile;
    }
    _syncingProfileIds.remove(event.temporaryId);
    await _localDataSource.saveProfiles(_cachedProfiles);
    emit(ShiftProfilesLoaded(List<ShiftProfileEntity>.from(_cachedProfiles)));
  }

  Future<void> _onProfileUpdateCommitted(
    ShiftProfileUpdateCommittedEvent event,
    Emitter<ShiftState> emit,
  ) async {
    _upsertProfileCache(event.profile);
    _syncingProfileIds.remove(event.profileId);
    await _localDataSource.saveProfiles(_cachedProfiles);
    emit(ShiftProfilesLoaded(List<ShiftProfileEntity>.from(_cachedProfiles)));
  }

  Future<void> _onProfileDeleteCommitted(
    ShiftProfileDeleteCommittedEvent event,
    Emitter<ShiftState> emit,
  ) async {
    _syncingProfileIds.remove(event.profileId);
    await _localDataSource.saveProfiles(_cachedProfiles);
    emit(ShiftProfilesLoaded(List<ShiftProfileEntity>.from(_cachedProfiles)));
  }

  Future<void> _onAssignmentCreateCommitted(
    ShiftAssignmentCreateCommittedEvent event,
    Emitter<ShiftState> emit,
  ) async {
    final index = _cachedAssignments.indexWhere(
      (assignment) => assignment.id == event.temporaryId,
    );
    if (index == -1) {
      _upsertAssignmentCache(event.assignment);
    } else {
      _cachedAssignments = List<ShiftAssignmentEntity>.from(_cachedAssignments)
        ..[index] = event.assignment;
    }
    _syncingAssignmentIds.remove(event.temporaryId);
    await _localDataSource.saveAssignments(_cachedAssignments);
    emit(
      ShiftAssignmentsLoaded(
        List<ShiftAssignmentEntity>.from(_cachedAssignments),
      ),
    );
  }

  Future<void> _onAssignmentUpdateCommitted(
    ShiftAssignmentUpdateCommittedEvent event,
    Emitter<ShiftState> emit,
  ) async {
    _upsertAssignmentCache(event.assignment);
    _syncingAssignmentIds.remove(event.assignmentId);
    await _localDataSource.saveAssignments(_cachedAssignments);
    emit(
      ShiftAssignmentsLoaded(
        List<ShiftAssignmentEntity>.from(_cachedAssignments),
      ),
    );
  }

  Future<void> _onAssignmentDeleteCommitted(
    ShiftAssignmentDeleteCommittedEvent event,
    Emitter<ShiftState> emit,
  ) async {
    _syncingAssignmentIds.remove(event.assignmentId);
    await _localDataSource.saveAssignments(_cachedAssignments);
    emit(
      ShiftAssignmentsLoaded(
        List<ShiftAssignmentEntity>.from(_cachedAssignments),
      ),
    );
  }

  Future<void> _onMutationFailed(
    ShiftMutationFailedEvent event,
    Emitter<ShiftState> emit,
  ) async {
    if (event.rollbackProfiles != null) {
      _cachedProfiles = List<ShiftProfileEntity>.from(event.rollbackProfiles!);
      await _localDataSource.saveProfiles(_cachedProfiles);
    }
    if (event.rollbackAssignments != null) {
      _cachedAssignments = List<ShiftAssignmentEntity>.from(
        event.rollbackAssignments!,
      );
      await _localDataSource.saveAssignments(_cachedAssignments);
    }
    _syncingProfileIds.removeAll(event.syncingProfileIdsToClear);
    _syncingAssignmentIds.removeAll(event.syncingAssignmentIdsToClear);
    emit(ShiftError(event.message));
    if (event.rollbackProfiles != null) {
      emit(ShiftProfilesLoaded(List<ShiftProfileEntity>.from(_cachedProfiles)));
    }
    if (event.rollbackAssignments != null) {
      emit(
        ShiftAssignmentsLoaded(
          List<ShiftAssignmentEntity>.from(_cachedAssignments),
        ),
      );
    }
  }

  ShiftAssignmentEntity _buildOptimisticAssignmentForCreate(
    AssignShiftEvent event,
  ) {
    final selectedProfile = event.profileId == null
        ? null
        : _cachedProfiles
              .where((profile) => profile.id == event.profileId)
              .firstOrNull;
    final startTime =
        event.startTime ??
        selectedProfile?.startTime ??
        const TimeOfDay(hour: 9, minute: 0);
    final endTime =
        event.endTime ??
        selectedProfile?.endTime ??
        const TimeOfDay(hour: 18, minute: 0);
    final overnight = event.overnight ?? selectedProfile?.overnight ?? false;
    final alarmOffsets = List<int>.from(
      event.alarmOffsets ?? selectedProfile?.alarmOffsets ?? const <int>[],
    );

    return ShiftAssignmentEntity(
      id: _temporaryId('shift_assignment'),
      userId: event.targetUserId ?? 'pending-user',
      userName: null,
      shiftDate: event.shiftDate,
      teamId: event.teamId,
      teamShiftGroupId: event.teamShiftGroupId,
      profileId: selectedProfile?.id ?? event.profileId,
      profileName: selectedProfile?.name,
      profileColor: selectedProfile?.color,
      startTime: startTime,
      endTime: endTime,
      overnight: overnight,
      note: event.note,
      alarmOffsets: alarmOffsets,
      profile: selectedProfile,
      isPublic: event.isPublic,
    );
  }

  ShiftAssignmentEntity _buildOptimisticAssignmentForUpdate(
    UpdateShiftAssignmentEvent event,
    ShiftAssignmentEntity previous,
  ) {
    final selectedProfile = event.profileId == null
        ? previous.profile
        : _cachedProfiles
              .where((profile) => profile.id == event.profileId)
              .firstOrNull;
    final startTime =
        event.startTime ?? selectedProfile?.startTime ?? previous.startTime;
    final endTime =
        event.endTime ?? selectedProfile?.endTime ?? previous.endTime;
    final overnight =
        event.overnight ?? selectedProfile?.overnight ?? previous.overnight;
    final alarmOffsets = List<int>.from(
      event.alarmOffsets ??
          selectedProfile?.alarmOffsets ??
          previous.alarmOffsets,
    );

    return ShiftAssignmentEntity(
      id: previous.id,
      userId: event.targetUserId ?? previous.userId,
      userName: previous.userName,
      shiftDate: previous.shiftDate,
      teamId: event.teamId ?? previous.teamId,
      teamShiftGroupId: event.teamShiftGroupId ?? previous.teamShiftGroupId,
      profileId: selectedProfile?.id ?? event.profileId ?? previous.profileId,
      profileName: selectedProfile?.name ?? previous.profileName,
      profileColor: selectedProfile?.color ?? previous.profileColor,
      startTime: startTime,
      endTime: endTime,
      overnight: overnight,
      note: event.note ?? previous.note,
      alarmOffsets: alarmOffsets,
      profile: selectedProfile ?? previous.profile,
      isPublic: event.isPublic,
    );
  }

  String _temporaryId(String prefix) {
    return 'local_${prefix}_${DateTime.now().microsecondsSinceEpoch}';
  }
}
