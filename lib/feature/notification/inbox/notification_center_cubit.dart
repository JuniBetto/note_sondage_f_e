import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:note_sondage/core/dependency_injection/dependency_injection.dart';
import 'package:note_sondage/feature/auth/infrastructure/data/backend_auth_data_source.dart';
import 'package:note_sondage/feature/home/ui/bloc/dashboard_bloc.dart';
import 'package:note_sondage/feature/notification/inbox/notification_center_item.dart';
import 'package:note_sondage/feature/notification/realtime/realtime_notification_model.dart';
import 'package:note_sondage/feature/team/ui/bloc/team/team_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'notification_center_state.dart';

const String _seenNotificationsKeyPrefix = 'notification_center_seen';
const String _dismissedNotificationsKeyPrefix = 'notification_center_dismissed';
const String _completedNotificationsKeyPrefix = 'notification_center_completed';

class NotificationCenterCubit extends Cubit<NotificationCenterState> {
  NotificationCenterCubit({
    required BackendAuthDataSource backendAuth,
    required String Function() currentUserIdProvider,
  }) : _backendAuth = backendAuth,
       _currentUserIdProvider = currentUserIdProvider,
       super(const NotificationCenterState());

  final BackendAuthDataSource _backendAuth;
  final String Function() _currentUserIdProvider;
  String _hydratedUserId = '';
  Future<void>? _hydrationFuture;

  Future<void> loadNotifications({bool force = false}) async {
    await _ensureHydrated();
    if (state.status == NotificationCenterStatus.loading) {
      return;
    }
    if (!force &&
        state.status == NotificationCenterStatus.loaded &&
        state.notifications.isNotEmpty) {
      return;
    }

    emit(state.copyWith(status: NotificationCenterStatus.loading));
    try {
      final notifications =
          _normalizeNotifications(
                (await _backendAuth.getMyNotifications())
                    .where((item) => !_isRealtimeOnlyMetadata(item.metadata))
                    .toList(),
              )
              .where(
                (item) => !state.dismissedNotificationIds.contains(
                  item.notificationId,
                ),
              )
              .toList();
      final activeNotificationIds = notifications
          .map((item) => item.notificationId.trim())
          .where((id) => id.isNotEmpty)
          .toSet();
      final seen = state.seenNotificationIds
          .where(activeNotificationIds.contains)
          .toSet();
      final dismissed = state.dismissedNotificationIds
          .where(activeNotificationIds.contains)
          .toSet();
      final completed = state.completedActionNotificationIds
          .where(activeNotificationIds.contains)
          .toSet();
      emit(
        state.copyWith(
          status: NotificationCenterStatus.loaded,
          notifications: notifications,
          seenNotificationIds: seen,
          dismissedNotificationIds: dismissed,
          completedActionNotificationIds: completed,
          errorMessage: null,
        ),
      );
      await _persistLocalState(
        seenNotificationIds: seen,
        dismissedNotificationIds: dismissed,
        completedActionNotificationIds: completed,
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: NotificationCenterStatus.error,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  void ingestRealtimeNotification(RealtimeNotification notification) {
    if (notification.notificationId.isEmpty ||
        notification.eventType.startsWith('SYSTEM_') ||
        _isRealtimeOnlyMetadata(notification.metadata)) {
      return;
    }

    final item = NotificationCenterItem.fromRealtime(notification);
    if (state.dismissedNotificationIds.contains(item.notificationId)) {
      return;
    }
    final current = List<NotificationCenterItem>.from(state.notifications);
    current.removeWhere((entry) => entry.notificationId == item.notificationId);

    if (item.isTerminalTeamInvitationEvent && item.invitationId != null) {
      current.removeWhere(
        (entry) =>
            entry.invitationId == item.invitationId &&
            entry.isPendingTeamInvitation,
      );
    } else {
      current.insert(0, item);
    }

    final normalized = _normalizeNotifications(current);
    emit(
      state.copyWith(
        status: NotificationCenterStatus.loaded,
        notifications: normalized,
        seenNotificationIds: state.seenNotificationIds,
        dismissedNotificationIds: state.dismissedNotificationIds,
        completedActionNotificationIds: state.completedActionNotificationIds,
      ),
    );
  }

  void markAsSeen(String notificationId) {
    consumeNotification(notificationId);
  }

  void markManyAsSeen(Iterable<String> notificationIds) {
    final filtered = notificationIds
        .where((id) => id.trim().isNotEmpty)
        .toSet();
    if (filtered.isEmpty) return;
    final seen = Set<String>.from(state.seenNotificationIds)..addAll(filtered);
    final dismissed = Set<String>.from(state.dismissedNotificationIds)
      ..addAll(filtered);
    final remainingNotifications = state.notifications
        .where((item) => !filtered.contains(item.notificationId))
        .toList();
    emit(
      state.copyWith(
        notifications: remainingNotifications,
        seenNotificationIds: seen,
        dismissedNotificationIds: dismissed,
      ),
    );
    unawaited(
      Future.wait([
        _persistLocalState(
          seenNotificationIds: seen,
          dismissedNotificationIds: dismissed,
        ),
        _dismissNotificationsRemotely(filtered),
      ]),
    );
  }

  void consumeNotification(String notificationId) {
    if (notificationId.trim().isEmpty) {
      return;
    }
    final seen = Set<String>.from(state.seenNotificationIds)
      ..add(notificationId);
    final dismissed = Set<String>.from(state.dismissedNotificationIds)
      ..add(notificationId);
    final remainingNotifications = state.notifications
        .where((item) => item.notificationId != notificationId)
        .toList();
    emit(
      state.copyWith(
        notifications: remainingNotifications,
        seenNotificationIds: seen,
        dismissedNotificationIds: dismissed,
      ),
    );
    unawaited(
      Future.wait([
        _persistLocalState(
          seenNotificationIds: seen,
          dismissedNotificationIds: dismissed,
        ),
        _dismissNotificationsRemotely([notificationId]),
      ]),
    );
  }

  Future<void> closeNotifications(
    Iterable<NotificationCenterItem> notifications, {
    required String currentUserId,
  }) async {
    await _ensureHydrated();

    final items = notifications
        .where((item) => item.notificationId.trim().isNotEmpty)
        .where(
          (item) =>
              !state.dismissedNotificationIds.contains(item.notificationId) &&
              !state.completedActionNotificationIds.contains(
                item.notificationId,
              ),
        )
        .toList(growable: false);

    if (items.isEmpty) {
      return;
    }

    final notificationIdsToDismiss = <String>{};
    var shouldRefreshTeamSurfaces = false;
    String? firstErrorMessage;

    for (final item in items) {
      final requiresRejectAction =
          item.supportsInviteDecisionFor(currentUserId) ||
          item.supportsClockingDecision();

      if (!requiresRejectAction) {
        notificationIdsToDismiss.add(item.notificationId);
        continue;
      }

      final resolved = await _performAction(item.notificationId, () async {
        if (item.supportsInviteDecisionFor(currentUserId)) {
          final invitationId = item.invitationId;
          if (invitationId == null) {
            return;
          }
          await _backendAuth.rejectTeamInvitationById(invitationId);
          return;
        }

        final teamId = item.metadata['teamId']?.trim();
        final requesterUserId = item.requesterUserId;
        final requestedDate = item.requestedDate;
        if (requesterUserId == null) {
          return;
        }

        switch (item.requestType) {
          case 'clocking':
            if (teamId == null || teamId.isEmpty || requestedDate == null) {
              return;
            }
            await _backendAuth.rejectClockingRequest(
              teamId: teamId,
              requesterUserId: requesterUserId,
              requestedDate: requestedDate,
              note: item.metadata['note']?.trim(),
            );
            break;
          case 'decommit':
            if (teamId == null || teamId.isEmpty || requestedDate == null) {
              return;
            }
            final recordId = item.recordId;
            if (recordId == null) {
              return;
            }
            await _backendAuth.rejectDecommitRequest(
              teamId: teamId,
              requesterUserId: requesterUserId,
              requestedDate: requestedDate,
              recordId: recordId,
              note: item.metadata['note']?.trim(),
            );
            break;
          case 'vacation':
            if (teamId == null || teamId.isEmpty || requestedDate == null) {
              return;
            }
            await _backendAuth.rejectVacationRequest(
              teamId: teamId,
              requesterUserId: requesterUserId,
              requestedDate: requestedDate,
              note: item.metadata['note']?.trim(),
            );
            break;
          case 'permission':
            if (teamId == null || teamId.isEmpty || requestedDate == null) {
              return;
            }
            await _backendAuth.rejectPermissionRequest(
              teamId: teamId,
              requesterUserId: requesterUserId,
              requestedDate: requestedDate,
              startTime: item.permissionStartTime ?? '',
              endTime: item.permissionEndTime ?? '',
              note: item.metadata['note']?.trim(),
            );
            break;
          case 'shift_change':
            final assignmentId = item.metadata['assignmentId']?.trim();
            if (assignmentId == null || assignmentId.isEmpty) {
              return;
            }
            await _backendAuth.rejectShiftChangeRequest(
              assignmentId: assignmentId,
              requesterUserId: requesterUserId,
              profileId: item.metadata['shiftProfileId']?.trim(),
              startTime: item.metadata['shiftStartTime']?.trim(),
              endTime: item.metadata['shiftEndTime']?.trim(),
              overnight: _parseOptionalBool(item.metadata['shiftOvernight']),
              note: item.metadata['shiftNote']?.trim(),
              alarmOffsets: _parseAlarmOffsets(
                item.metadata['shiftAlarmOffsets'],
              ),
            );
            break;
        }
      });

      if (resolved) {
        shouldRefreshTeamSurfaces = true;
      } else {
        firstErrorMessage ??= state.errorMessage;
      }
    }

    if (notificationIdsToDismiss.isNotEmpty) {
      markManyAsSeen(notificationIdsToDismiss);
    }

    if (shouldRefreshTeamSurfaces) {
      _refreshTeamSurfaces();
    }

    if (firstErrorMessage != null &&
        firstErrorMessage.trim().isNotEmpty &&
        state.errorMessage != firstErrorMessage) {
      emit(state.copyWith(errorMessage: firstErrorMessage));
    }
  }

  Future<void> acceptInvitation(NotificationCenterItem item) async {
    final invitationId = item.invitationId;
    if (invitationId == null) {
      return;
    }
    final resolved = await _performAction(
      item.notificationId,
      () => _backendAuth.acceptTeamInvitationById(invitationId),
    );
    if (resolved) {
      _refreshTeamSurfaces();
    }
  }

  Future<void> rejectInvitation(NotificationCenterItem item) async {
    final invitationId = item.invitationId;
    if (invitationId == null) {
      return;
    }
    final resolved = await _performAction(
      item.notificationId,
      () => _backendAuth.rejectTeamInvitationById(invitationId),
    );
    if (resolved) {
      _refreshTeamSurfaces();
    }
  }

  Future<void> approveClockingDecision(NotificationCenterItem item) async {
    final teamId = item.metadata['teamId']?.trim();
    final requesterUserId = item.requesterUserId;
    final requestedDate = item.requestedDate;
    if (requesterUserId == null) {
      return;
    }

    await _performAction(item.notificationId, () async {
      switch (item.requestType) {
        case 'clocking':
          if (teamId == null || teamId.isEmpty || requestedDate == null) {
            return;
          }
          await _backendAuth.approveClockingRequest(
            teamId: teamId,
            requesterUserId: requesterUserId,
            requestedDate: requestedDate,
            note: item.metadata['note']?.trim(),
          );
          break;
        case 'decommit':
          if (teamId == null || teamId.isEmpty || requestedDate == null) {
            return;
          }
          final recordId = item.recordId;
          if (recordId == null) {
            return;
          }
          await _backendAuth.approveDecommitRequest(
            teamId: teamId,
            requesterUserId: requesterUserId,
            requestedDate: requestedDate,
            recordId: recordId,
            note: item.metadata['note']?.trim(),
          );
          break;
        case 'vacation':
          if (teamId == null || teamId.isEmpty || requestedDate == null) {
            return;
          }
          await _backendAuth.approveVacationRequest(
            teamId: teamId,
            requesterUserId: requesterUserId,
            requestedDate: requestedDate,
            note: item.metadata['note']?.trim(),
          );
          break;
        case 'permission':
          if (teamId == null || teamId.isEmpty || requestedDate == null) {
            return;
          }
          await _backendAuth.approvePermissionRequest(
            teamId: teamId,
            requesterUserId: requesterUserId,
            requestedDate: requestedDate,
            startTime: item.permissionStartTime ?? '',
            endTime: item.permissionEndTime ?? '',
            note: item.metadata['note']?.trim(),
          );
          break;
        case 'shift_change':
          final assignmentId = item.metadata['assignmentId']?.trim();
          if (assignmentId == null || assignmentId.isEmpty) {
            return;
          }
          await _backendAuth.approveShiftChangeRequest(
            assignmentId: assignmentId,
            requesterUserId: requesterUserId,
            profileId: item.metadata['shiftProfileId']?.trim(),
            startTime: item.metadata['shiftStartTime']?.trim(),
            endTime: item.metadata['shiftEndTime']?.trim(),
            overnight: _parseOptionalBool(item.metadata['shiftOvernight']),
            note: item.metadata['shiftNote']?.trim(),
            alarmOffsets: _parseAlarmOffsets(
              item.metadata['shiftAlarmOffsets'],
            ),
          );
          break;
      }
    });
  }

  Future<void> rejectClockingDecision(NotificationCenterItem item) async {
    final teamId = item.metadata['teamId']?.trim();
    final requesterUserId = item.requesterUserId;
    final requestedDate = item.requestedDate;
    if (requesterUserId == null) {
      return;
    }

    await _performAction(item.notificationId, () async {
      switch (item.requestType) {
        case 'clocking':
          if (teamId == null || teamId.isEmpty || requestedDate == null) {
            return;
          }
          await _backendAuth.rejectClockingRequest(
            teamId: teamId,
            requesterUserId: requesterUserId,
            requestedDate: requestedDate,
            note: item.metadata['note']?.trim(),
          );
          break;
        case 'decommit':
          if (teamId == null || teamId.isEmpty || requestedDate == null) {
            return;
          }
          final recordId = item.recordId;
          if (recordId == null) {
            return;
          }
          await _backendAuth.rejectDecommitRequest(
            teamId: teamId,
            requesterUserId: requesterUserId,
            requestedDate: requestedDate,
            recordId: recordId,
            note: item.metadata['note']?.trim(),
          );
          break;
        case 'vacation':
          if (teamId == null || teamId.isEmpty || requestedDate == null) {
            return;
          }
          await _backendAuth.rejectVacationRequest(
            teamId: teamId,
            requesterUserId: requesterUserId,
            requestedDate: requestedDate,
            note: item.metadata['note']?.trim(),
          );
          break;
        case 'permission':
          if (teamId == null || teamId.isEmpty || requestedDate == null) {
            return;
          }
          await _backendAuth.rejectPermissionRequest(
            teamId: teamId,
            requesterUserId: requesterUserId,
            requestedDate: requestedDate,
            startTime: item.permissionStartTime ?? '',
            endTime: item.permissionEndTime ?? '',
            note: item.metadata['note']?.trim(),
          );
          break;
        case 'shift_change':
          final assignmentId = item.metadata['assignmentId']?.trim();
          if (assignmentId == null || assignmentId.isEmpty) {
            return;
          }
          await _backendAuth.rejectShiftChangeRequest(
            assignmentId: assignmentId,
            requesterUserId: requesterUserId,
            profileId: item.metadata['shiftProfileId']?.trim(),
            startTime: item.metadata['shiftStartTime']?.trim(),
            endTime: item.metadata['shiftEndTime']?.trim(),
            overnight: _parseOptionalBool(item.metadata['shiftOvernight']),
            note: item.metadata['shiftNote']?.trim(),
            alarmOffsets: _parseAlarmOffsets(
              item.metadata['shiftAlarmOffsets'],
            ),
          );
          break;
      }
    });
  }

  Future<void> handleActionIntent({
    required String notificationId,
    required String actionId,
    required Map<String, String> metadata,
  }) async {
    NotificationCenterItem? existingItem;
    for (final entry in state.notifications) {
      if (entry.notificationId == notificationId) {
        existingItem = entry;
        break;
      }
    }
    final item =
        existingItem ??
        NotificationCenterItem(
          notificationId: notificationId,
          eventType: metadata['eventType'] ?? '',
          sourceService: metadata['sourceService'] ?? 'push',
          title: metadata['title'] ?? '',
          body: metadata['body'] ?? '',
          occurredAt:
              DateTime.tryParse(metadata['occurredAt'] ?? '') ?? DateTime.now(),
          metadata: metadata,
        );

    if (actionId == 'accept_team_invite') {
      await acceptInvitation(item);
      return;
    }
    if (actionId == 'reject_team_invite') {
      await rejectInvitation(item);
      return;
    }
    if (actionId == 'approve_clocking_request') {
      await approveClockingDecision(item);
      return;
    }
    if (actionId == 'reject_clocking_request') {
      await rejectClockingDecision(item);
    }
  }

  void reset() {
    _hydratedUserId = '';
    _hydrationFuture = null;
    emit(const NotificationCenterState());
  }

  bool _isRealtimeOnlyMetadata(Map<String, String> metadata) {
    return metadata['realtimeOnly']?.toLowerCase() == 'true';
  }

  bool? _parseOptionalBool(String? value) {
    final normalized = value?.trim().toLowerCase();
    if (normalized == 'true') {
      return true;
    }
    if (normalized == 'false') {
      return false;
    }
    return null;
  }

  List<int>? _parseAlarmOffsets(String? value) {
    final normalized = value?.trim();
    if (normalized == null || normalized.isEmpty) {
      return null;
    }
    final offsets = normalized
        .split(',')
        .map((entry) => int.tryParse(entry.trim()))
        .whereType<int>()
        .toList(growable: false);
    if (offsets.isEmpty) {
      return null;
    }
    return offsets;
  }

  List<NotificationCenterItem> _normalizeNotifications(
    List<NotificationCenterItem> notifications,
  ) {
    final terminalInvitationIds = notifications
        .where((item) => item.isTerminalTeamInvitationEvent)
        .map((item) => item.invitationId)
        .whereType<String>()
        .toSet();

    return notifications.where((item) {
      if (item.isTerminalTeamInvitationEvent) {
        return false;
      }
      final invitationId = item.invitationId;
      if (item.isPendingTeamInvitation &&
          invitationId != null &&
          terminalInvitationIds.contains(invitationId)) {
        return false;
      }
      return true;
    }).toList();
  }

  Future<bool> _performAction(
    String notificationId,
    Future<void> Function() action,
  ) async {
    final processing = Set<String>.from(state.processingNotificationIds)
      ..add(notificationId);
    emit(
      state.copyWith(processingNotificationIds: processing, errorMessage: null),
    );

    try {
      await action();
      final completed = Set<String>.from(state.completedActionNotificationIds)
        ..add(notificationId);
      final dismissed = Set<String>.from(state.dismissedNotificationIds)
        ..add(notificationId);
      final seen = Set<String>.from(state.seenNotificationIds)
        ..add(notificationId);
      final remainingNotifications = state.notifications
          .where((item) => item.notificationId != notificationId)
          .toList();
      processing.remove(notificationId);
      emit(
        state.copyWith(
          notifications: remainingNotifications,
          processingNotificationIds: processing,
          completedActionNotificationIds: completed,
          dismissedNotificationIds: dismissed,
          seenNotificationIds: seen,
          errorMessage: null,
        ),
      );
      await Future.wait([
        _persistLocalState(
          seenNotificationIds: seen,
          dismissedNotificationIds: dismissed,
          completedActionNotificationIds: completed,
        ),
        _dismissNotificationsRemotely([notificationId]),
      ]);
      return true;
    } catch (e) {
      processing.remove(notificationId);
      if (_isTerminalInvitationConflict(e)) {
        final completed = Set<String>.from(state.completedActionNotificationIds)
          ..add(notificationId);
        final dismissed = Set<String>.from(state.dismissedNotificationIds)
          ..add(notificationId);
        final seen = Set<String>.from(state.seenNotificationIds)
          ..add(notificationId);
        final remainingNotifications = state.notifications
            .where((item) => item.notificationId != notificationId)
            .toList();
        emit(
          state.copyWith(
            notifications: remainingNotifications,
            processingNotificationIds: processing,
            completedActionNotificationIds: completed,
            dismissedNotificationIds: dismissed,
            seenNotificationIds: seen,
            errorMessage: null,
          ),
        );
        await Future.wait([
          _persistLocalState(
            seenNotificationIds: seen,
            dismissedNotificationIds: dismissed,
            completedActionNotificationIds: completed,
          ),
          _dismissNotificationsRemotely([notificationId]),
        ]);
        return true;
      }
      emit(
        state.copyWith(
          processingNotificationIds: processing,
          errorMessage: e.toString(),
        ),
      );
      return false;
    }
  }

  void _refreshTeamSurfaces() {
    final teamBloc = getIt<TeamBloc>();
    teamBloc.add(const ResetTeamCacheEvent());
    teamBloc.add(LoadTeamsEvent());
    getIt<DashboardBloc>().add(RefreshDashboardEvent());
    unawaited(loadNotifications(force: true));
  }

  bool _isTerminalInvitationConflict(Object error) {
    final raw = error.toString().toLowerCase();
    return raw.contains('409') ||
        raw.contains('failed to accept invitation: 404') ||
        raw.contains('failed to reject invitation: 404') ||
        raw.contains('invitation not found') ||
        raw.contains('not pending') ||
        raw.contains('already accepted') ||
        raw.contains('has expired') ||
        raw.contains('expired');
  }

  Future<void> _dismissNotificationsRemotely(
    Iterable<String> notificationIds,
  ) async {
    final ids = notificationIds
        .map((id) => id.trim())
        .where((id) => id.isNotEmpty)
        .toSet();
    if (ids.isEmpty) {
      return;
    }

    for (final id in ids) {
      try {
        await _backendAuth.dismissNotification(id);
      } catch (_) {
        // Keep the local dismissal even if the backend feed cannot be updated.
      }
    }
  }

  Future<void> _ensureHydrated() {
    final userId = _currentUserIdProvider().trim();
    if (userId.isEmpty) {
      _hydratedUserId = '';
      _hydrationFuture = null;
      return Future.value();
    }
    if (_hydratedUserId == userId) {
      return _hydrationFuture ?? Future.value();
    }

    final hydrationFuture = _hydrateLocalState(userId);
    _hydrationFuture = hydrationFuture;
    return hydrationFuture.whenComplete(() {
      if (identical(_hydrationFuture, hydrationFuture)) {
        _hydrationFuture = null;
      }
    });
  }

  Future<void> _hydrateLocalState(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final previousUserId = _hydratedUserId;
    _hydratedUserId = userId;

    emit(
      state.copyWith(
        notifications: previousUserId == userId
            ? state.notifications
            : const [],
        seenNotificationIds:
            prefs.getStringList(_seenKey(userId))?.toSet() ?? {},
        dismissedNotificationIds:
            prefs.getStringList(_dismissedKey(userId))?.toSet() ?? {},
        processingNotificationIds: const {},
        completedActionNotificationIds:
            prefs.getStringList(_completedKey(userId))?.toSet() ?? {},
        errorMessage: null,
      ),
    );
  }

  Future<void> _persistLocalState({
    Set<String>? seenNotificationIds,
    Set<String>? dismissedNotificationIds,
    Set<String>? completedActionNotificationIds,
  }) async {
    final userId = _hydratedUserId.isNotEmpty
        ? _hydratedUserId
        : _currentUserIdProvider().trim();
    if (userId.isEmpty) {
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    await Future.wait([
      prefs.setStringList(
        _seenKey(userId),
        _sortedIds(seenNotificationIds ?? state.seenNotificationIds),
      ),
      prefs.setStringList(
        _dismissedKey(userId),
        _sortedIds(dismissedNotificationIds ?? state.dismissedNotificationIds),
      ),
      prefs.setStringList(
        _completedKey(userId),
        _sortedIds(
          completedActionNotificationIds ??
              state.completedActionNotificationIds,
        ),
      ),
    ]);
  }

  List<String> _sortedIds(Set<String> ids) {
    final values = ids.where((id) => id.trim().isNotEmpty).toList()..sort();
    return values;
  }

  String _seenKey(String userId) => '${_seenNotificationsKeyPrefix}_$userId';

  String _dismissedKey(String userId) =>
      '${_dismissedNotificationsKeyPrefix}_$userId';

  String _completedKey(String userId) =>
      '${_completedNotificationsKeyPrefix}_$userId';
}
