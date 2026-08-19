import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:note_sondage/core/utils/app_error_message_resolver.dart';
import 'package:note_sondage/feature/auth/ui/bloc/auth_bloc.dart';
import 'package:note_sondage/feature/shift/domain/repositories/shift_repository.dart';
import 'package:note_sondage/feature/shift/domain/entities/shift_assignment_create_request_entity.dart';
import 'package:note_sondage/feature/shift/infrastructure/data_source/shift_local_data_source.dart';
import '../../domain/entities/shift_assignment_entity.dart';
import '../../domain/entities/shift_profile_entity.dart';
import 'shift_event.dart';

export 'shift_event.dart';

class ShiftBloc extends Bloc<ShiftEvent, ShiftState> {
  static const Duration _assignmentConsistencyGracePeriod = Duration(
    seconds: 5,
  );

  final ShiftRepository _repository;
  final ShiftLocalDataSource _localDataSource;
  List<ShiftProfileEntity> _cachedProfiles = <ShiftProfileEntity>[];
  List<ShiftAssignmentEntity> _cachedAssignments = <ShiftAssignmentEntity>[];
  String? _cachedAssignmentsRequestKey;
  final Set<String> _syncingProfileIds = <String>{};
  final Set<String> _syncingAssignmentIds = <String>{};
  final Map<String, _PendingAssignmentUpsert> _pendingAssignmentUpserts =
      <String, _PendingAssignmentUpsert>{};
  final Map<String, DateTime> _pendingAssignmentRemovals = <String, DateTime>{};
  bool _profilesRefreshInFlight = false;
  String? _assignmentsRefreshKey;
  int _assignmentsLoadVersion = 0;
  LoadShiftAssignmentsEvent? _queuedAssignmentsReload;

  Set<String> get syncingProfileIds => Set.unmodifiable(_syncingProfileIds);
  Set<String> get syncingAssignmentIds =>
      Set.unmodifiable(_syncingAssignmentIds);
  String? get _currentUserId {
    final value = GetIt.instance<AuthBloc>().state.user.uid.trim();
    return value.isEmpty ? null : value;
  }

  String? get _currentUserName {
    final value =
        GetIt.instance<AuthBloc>().state.user.displayName?.trim() ?? '';
    return value.isEmpty ? null : value;
  }

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

  void _removeAssignmentsCache(Iterable<String> assignmentIds) {
    final ids = assignmentIds.toSet();
    _cachedAssignments = _cachedAssignments
        .where((assignment) => !ids.contains(assignment.id))
        .toList();
  }

  void _trackPendingAssignmentUpsert(ShiftAssignmentEntity assignment) {
    final expiresAt = DateTime.now().add(_assignmentConsistencyGracePeriod);
    _pendingAssignmentUpserts[assignment.id] = _PendingAssignmentUpsert(
      assignment: assignment,
      expiresAt: expiresAt,
    );
    _pendingAssignmentRemovals.remove(assignment.id);
  }

  void _trackPendingAssignmentRemoval(Iterable<String> assignmentIds) {
    final expiresAt = DateTime.now().add(_assignmentConsistencyGracePeriod);
    for (final assignmentId in assignmentIds) {
      _pendingAssignmentUpserts.remove(assignmentId);
      _pendingAssignmentRemovals[assignmentId] = expiresAt;
    }
  }

  void _pruneExpiredPendingAssignmentConsistencyGuards() {
    final now = DateTime.now();
    _pendingAssignmentUpserts.removeWhere(
      (_, pending) => pending.expiresAt.isBefore(now),
    );
    _pendingAssignmentRemovals.removeWhere(
      (_, expiresAt) => expiresAt.isBefore(now),
    );
  }

  bool _assignmentMatchesLoadRequest(
    ShiftAssignmentEntity assignment,
    LoadShiftAssignmentsEvent event,
  ) {
    final assignmentDay = DateTime(
      assignment.shiftDate.year,
      assignment.shiftDate.month,
      assignment.shiftDate.day,
    );
    final requestFrom = DateTime(
      event.from.year,
      event.from.month,
      event.from.day,
    );
    final requestTo = DateTime(event.to.year, event.to.month, event.to.day);
    if (assignmentDay.isBefore(requestFrom) ||
        assignmentDay.isAfter(requestTo)) {
      return false;
    }

    final visibleTeamIds = (event.visibleTeamIds ?? const <String>[])
        .map((id) => id.trim())
        .where((id) => id.isNotEmpty)
        .toSet();
    final visibleUserIds = (event.visibleUserIds ?? const <String>[])
        .map((id) => id.trim())
        .where((id) => id.isNotEmpty)
        .toSet();

    if (visibleTeamIds.isEmpty && visibleUserIds.isEmpty) {
      return true;
    }

    final assignmentTeamId = assignment.teamId?.trim();
    final assignmentUserId = assignment.userId.trim();
    final matchesTeam =
        assignmentTeamId != null && visibleTeamIds.contains(assignmentTeamId);
    final matchesUser =
        assignmentUserId.isNotEmpty &&
        visibleUserIds.contains(assignmentUserId);

    if (visibleTeamIds.isNotEmpty && visibleUserIds.isNotEmpty) {
      return matchesTeam || matchesUser;
    }
    if (visibleTeamIds.isNotEmpty) {
      return matchesTeam;
    }
    return matchesUser;
  }

  List<ShiftAssignmentEntity> _mergeRemoteAssignmentsWithPendingLocalChanges(
    List<ShiftAssignmentEntity> assignments,
    LoadShiftAssignmentsEvent event,
  ) {
    _pruneExpiredPendingAssignmentConsistencyGuards();

    final merged = <String, ShiftAssignmentEntity>{
      for (final assignment in assignments) assignment.id: assignment,
    };

    for (final assignmentId in _pendingAssignmentRemovals.keys) {
      merged.remove(assignmentId);
    }

    for (final pending in _pendingAssignmentUpserts.values) {
      if (_assignmentMatchesLoadRequest(pending.assignment, event)) {
        merged[pending.assignment.id] = pending.assignment;
      }
    }

    final nextAssignments = merged.values.toList()
      ..sort(
        (left, right) => left.shiftDate.compareTo(right.shiftDate) != 0
            ? left.shiftDate.compareTo(right.shiftDate)
            : left.id.compareTo(right.id),
      );
    return nextAssignments;
  }

  bool _isDeleteAlreadyApplied(Object error) {
    return error is DioException && error.response?.statusCode == 404;
  }

  Future<void> _persistAssignmentsCache({
    bool invalidateOtherCaches = false,
  }) async {
    final requestKey = _cachedAssignmentsRequestKey;
    if (requestKey == null || requestKey.isEmpty) {
      if (invalidateOtherCaches) {
        await _localDataSource.invalidateAssignmentCaches();
      }
      return;
    }
    await _localDataSource.saveAssignments(
      _cachedAssignments,
      requestKey: requestKey,
    );
    if (invalidateOtherCaches) {
      await _localDataSource.invalidateAssignmentCaches(
        keepRequestKey: requestKey,
      );
    }
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
    on<RemoveAssignmentsForTeamEvent>(_onRemoveAssignmentsForTeam);
    on<ShiftAssignmentCreateCommittedEvent>(_onAssignmentCreateCommitted);
    on<ShiftAssignmentUpdateCommittedEvent>(_onAssignmentUpdateCommitted);
    on<ShiftAssignmentDeleteCommittedEvent>(_onAssignmentDeleteCommitted);
    on<ShiftMutationFailedEvent>(_onMutationFailed);
    on<AssignShiftEvent>(_onAssign);
    on<AssignShiftBatchEvent>(_onAssignBatch);
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
    final loadVersion = ++_assignmentsLoadVersion;
    final requestKey = ShiftLocalDataSource.buildAssignmentsRequestKey(
      from: event.from,
      to: event.to,
      visibleTeamIds: event.visibleTeamIds,
      visibleUserIds: event.visibleUserIds,
    );
    if (_cachedAssignments.isNotEmpty &&
        _cachedAssignmentsRequestKey == requestKey) {
      emit(ShiftAssignmentsLoaded(_cachedAssignments));
    } else {
      final local = await _localDataSource.getAssignments(
        from: event.from,
        to: event.to,
        requestKey: requestKey,
      );
      if (loadVersion != _assignmentsLoadVersion) {
        return;
      }
      if (local.isNotEmpty) {
        _cachedAssignments = local;
        _cachedAssignmentsRequestKey = requestKey;
        emit(ShiftAssignmentsLoaded(local));
      } else {
        emit(ShiftLoading());
      }
    }
    if (_assignmentsRefreshKey == requestKey) {
      _queuedAssignmentsReload = event;
      return;
    }
    _assignmentsRefreshKey = requestKey;
    try {
      final remoteAssignments = await _repository.getAssignments(
        from: event.from,
        to: event.to,
        visibleTeamIds: event.visibleTeamIds,
        visibleUserIds: event.visibleUserIds,
      );
      if (loadVersion != _assignmentsLoadVersion) {
        return;
      }
      final assignments = _mergeRemoteAssignmentsWithPendingLocalChanges(
        remoteAssignments,
        event,
      );
      _cachedAssignments = assignments;
      _cachedAssignmentsRequestKey = requestKey;
      await _persistAssignmentsCache();
      emit(ShiftAssignmentsLoaded(assignments));
    } catch (e) {
      if (loadVersion != _assignmentsLoadVersion) {
        return;
      }
      emit(
        ShiftError(
          AppErrorMessageResolver.resolve(
            e,
            fallback: 'We could not load the shifts right now.',
          ),
        ),
      );
      if (_cachedAssignments.isNotEmpty &&
          _cachedAssignmentsRequestKey == requestKey) {
        emit(ShiftAssignmentsLoaded(_cachedAssignments));
      }
    } finally {
      if (_assignmentsRefreshKey == requestKey) {
        _assignmentsRefreshKey = null;
      }
      final queuedReload = _queuedAssignmentsReload;
      if (queuedReload != null) {
        final queuedRequestKey =
            ShiftLocalDataSource.buildAssignmentsRequestKey(
              from: queuedReload.from,
              to: queuedReload.to,
              visibleTeamIds: queuedReload.visibleTeamIds,
              visibleUserIds: queuedReload.visibleUserIds,
            );
        if (queuedRequestKey == requestKey) {
          _queuedAssignmentsReload = null;
          if (!isClosed) {
            add(queuedReload);
          }
        }
      }
    }
  }

  Future<void> _onRemoveAssignmentsForTeam(
    RemoveAssignmentsForTeamEvent event,
    Emitter<ShiftState> emit,
  ) async {
    final teamId = event.teamId.trim();
    if (teamId.isEmpty) {
      return;
    }

    final nextAssignments = _cachedAssignments
        .where((assignment) => assignment.teamId != teamId)
        .toList();
    if (nextAssignments.length == _cachedAssignments.length) {
      return;
    }

    _cachedAssignments = nextAssignments;
    await _persistAssignmentsCache(invalidateOtherCaches: true);
    if (state is ShiftAssignmentsLoaded) {
      emit(ShiftAssignmentsLoaded(_cachedAssignments));
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
      await _persistAssignmentsCache(invalidateOtherCaches: true);
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

  Future<void> _onAssignBatch(
    AssignShiftBatchEvent event,
    Emitter<ShiftState> emit,
  ) async {
    if (event.requests.isEmpty) {
      return;
    }

    final rollbackAssignments = List<ShiftAssignmentEntity>.from(
      _cachedAssignments,
    );
    final optimisticAssignments = event.requests
        .map(_buildOptimisticAssignmentForBatchRequest)
        .toList(growable: false);
    final optimisticAssignmentIds = optimisticAssignments
        .map((assignment) => assignment.id)
        .toSet();

    try {
      _syncingAssignmentIds.addAll(optimisticAssignmentIds);
      for (final assignment in optimisticAssignments) {
        _upsertAssignmentCache(assignment);
      }
      await _persistAssignmentsCache(invalidateOtherCaches: true);
      emit(
        ShiftAssignmentsLoaded(
          List<ShiftAssignmentEntity>.from(_cachedAssignments),
        ),
      );

      final assignments = await _repository.assignBatch(
        requests: event.requests,
      );

      _removeAssignmentsCache(optimisticAssignmentIds);
      for (final assignment in assignments) {
        _upsertAssignmentCache(assignment);
        _trackPendingAssignmentUpsert(assignment);
      }
      _syncingAssignmentIds.removeAll(optimisticAssignmentIds);
      await _persistAssignmentsCache(invalidateOtherCaches: true);
      emit(
        ShiftAssignmentsLoaded(
          List<ShiftAssignmentEntity>.from(_cachedAssignments),
        ),
      );
      emit(ShiftBatchAssigned(assignments.length));
    } catch (e) {
      _cachedAssignments = rollbackAssignments;
      _syncingAssignmentIds.removeAll(optimisticAssignmentIds);
      await _persistAssignmentsCache(invalidateOtherCaches: true);
      emit(
        ShiftError(
          AppErrorMessageResolver.resolve(
            e,
            fallback:
                'We could not save all requested shifts. No shifts were created.',
          ),
        ),
      );
      emit(
        ShiftAssignmentsLoaded(
          List<ShiftAssignmentEntity>.from(_cachedAssignments),
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
      await _persistAssignmentsCache(invalidateOtherCaches: true);
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
      final assignmentIdsToDelete = event.relatedAssignmentIds;
      final rollbackAssignments = List<ShiftAssignmentEntity>.from(
        _cachedAssignments,
      );
      _syncingAssignmentIds.addAll(assignmentIdsToDelete);
      _removeAssignmentsCache(assignmentIdsToDelete);
      await _persistAssignmentsCache(invalidateOtherCaches: true);
      emit(ShiftAssignmentDeleted(assignmentIdsToDelete));

      unawaited(() async {
        try {
          await _repository.deleteAssignment(event.assignmentId);
          if (!isClosed) {
            add(ShiftAssignmentDeleteCommittedEvent(assignmentIdsToDelete));
          }
        } catch (e) {
          if (!isClosed) {
            if (_isDeleteAlreadyApplied(e)) {
              add(ShiftAssignmentDeleteCommittedEvent(assignmentIdsToDelete));
            } else {
              add(
                ShiftMutationFailedEvent(
                  message: AppErrorMessageResolver.resolve(
                    e,
                    fallback: 'We could not delete the shift right now.',
                  ),
                  rollbackAssignments: rollbackAssignments,
                  syncingAssignmentIdsToClear: assignmentIdsToDelete,
                ),
              );
            }
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
    _trackPendingAssignmentUpsert(event.assignment);
    _syncingAssignmentIds.remove(event.temporaryId);
    await _persistAssignmentsCache(invalidateOtherCaches: true);
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
    _trackPendingAssignmentUpsert(event.assignment);
    _syncingAssignmentIds.remove(event.assignmentId);
    await _persistAssignmentsCache(invalidateOtherCaches: true);
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
    _trackPendingAssignmentRemoval(event.assignmentIds);
    _syncingAssignmentIds.removeAll(event.assignmentIds);
    await _persistAssignmentsCache(invalidateOtherCaches: true);
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
      await _persistAssignmentsCache(invalidateOtherCaches: true);
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
      userId: event.targetUserId ?? _currentUserId ?? 'pending-user',
      userName: _currentUserName,
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

  ShiftAssignmentEntity _buildOptimisticAssignmentForBatchRequest(
    ShiftAssignmentCreateRequestEntity request,
  ) {
    final selectedProfile = request.profileId == null
        ? null
        : _cachedProfiles
              .where((profile) => profile.id == request.profileId)
              .firstOrNull;
    final startTime =
        request.startTime ??
        selectedProfile?.startTime ??
        const TimeOfDay(hour: 9, minute: 0);
    final endTime =
        request.endTime ??
        selectedProfile?.endTime ??
        const TimeOfDay(hour: 18, minute: 0);
    final overnight = request.overnight ?? selectedProfile?.overnight ?? false;
    final alarmOffsets = List<int>.from(
      request.alarmOffsets ?? selectedProfile?.alarmOffsets ?? const <int>[],
    );
    final targetUserId =
        request.targetUserId ?? _currentUserId ?? 'pending-user';
    final targetUserName =
        request.targetUserName ??
        (targetUserId == _currentUserId ? _currentUserName : null);

    return ShiftAssignmentEntity(
      id: _temporaryId('shift_assignment'),
      userId: targetUserId,
      userName: targetUserName,
      shiftDate: request.shiftDate,
      teamId: request.teamId,
      teamShiftGroupId: request.teamShiftGroupId,
      profileId: selectedProfile?.id ?? request.profileId,
      profileName: selectedProfile?.name,
      profileColor: selectedProfile?.color,
      startTime: startTime,
      endTime: endTime,
      overnight: overnight,
      note: request.note,
      alarmOffsets: alarmOffsets,
      profile: selectedProfile,
      isPublic: request.isPublic,
      contextType: request.contextType,
      contextId: request.contextId,
      sourceType: request.sourceType,
      sourceId: request.sourceId,
      sourceMessageId: request.sourceMessageId,
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
    final resolvedTeamId = event.isPublic ? event.teamId : null;
    final resolvedTeamShiftGroupId = resolvedTeamId == null
        ? null
        : (event.teamShiftGroupId ?? previous.teamShiftGroupId);

    return ShiftAssignmentEntity(
      id: previous.id,
      userId: event.targetUserId ?? previous.userId,
      userName: previous.userName,
      shiftDate: previous.shiftDate,
      teamId: resolvedTeamId,
      teamShiftGroupId: resolvedTeamShiftGroupId,
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
      contextType: previous.contextType,
      contextId: previous.contextId,
      sourceType: previous.sourceType,
      sourceId: previous.sourceId,
      sourceMessageId: previous.sourceMessageId,
    );
  }

  String _temporaryId(String prefix) {
    return 'local_${prefix}_${DateTime.now().microsecondsSinceEpoch}';
  }
}

class _PendingAssignmentUpsert {
  const _PendingAssignmentUpsert({
    required this.assignment,
    required this.expiresAt,
  });

  final ShiftAssignmentEntity assignment;
  final DateTime expiresAt;
}
