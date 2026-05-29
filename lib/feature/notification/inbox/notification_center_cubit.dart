import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:note_sondage/feature/auth/infrastructure/data/backend_auth_data_source.dart';
import 'package:note_sondage/feature/notification/inbox/notification_center_item.dart';
import 'package:note_sondage/feature/notification/realtime/realtime_notification_model.dart';
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
    if (notificationId.isEmpty) return;
    final seen = Set<String>.from(state.seenNotificationIds)
      ..add(notificationId);
    emit(state.copyWith(seenNotificationIds: seen));
    unawaited(_persistLocalState(seenNotificationIds: seen));
  }

  void markManyAsSeen(Iterable<String> notificationIds) {
    final filtered = notificationIds
        .where((id) => id.trim().isNotEmpty)
        .toSet();
    if (filtered.isEmpty) return;
    final seen = Set<String>.from(state.seenNotificationIds)..addAll(filtered);
    emit(state.copyWith(seenNotificationIds: seen));
    unawaited(_persistLocalState(seenNotificationIds: seen));
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
      _persistLocalState(
        seenNotificationIds: seen,
        dismissedNotificationIds: dismissed,
      ),
    );
  }

  Future<void> acceptInvitation(NotificationCenterItem item) async {
    final invitationId = item.invitationId;
    if (invitationId == null) {
      return;
    }
    await _performAction(
      item.notificationId,
      () => _backendAuth.acceptTeamInvitationById(invitationId),
    );
  }

  Future<void> rejectInvitation(NotificationCenterItem item) async {
    final invitationId = item.invitationId;
    if (invitationId == null) {
      return;
    }
    await _performAction(
      item.notificationId,
      () => _backendAuth.rejectTeamInvitationById(invitationId),
    );
  }

  Future<void> approveClockingDecision(NotificationCenterItem item) async {
    final teamId = item.metadata['teamId']?.trim();
    final requesterUserId = item.requesterUserId;
    final requestedDate = item.requestedDate;
    if (teamId == null ||
        teamId.isEmpty ||
        requesterUserId == null ||
        requestedDate == null) {
      return;
    }

    await _performAction(item.notificationId, () async {
      switch (item.requestType) {
        case 'clocking':
          await _backendAuth.approveClockingRequest(
            teamId: teamId,
            requesterUserId: requesterUserId,
            requestedDate: requestedDate,
            note: item.metadata['note']?.trim(),
          );
          break;
        case 'vacation':
          await _backendAuth.approveVacationRequest(
            teamId: teamId,
            requesterUserId: requesterUserId,
            requestedDate: requestedDate,
            note: item.metadata['note']?.trim(),
          );
          break;
        case 'permission':
          await _backendAuth.approvePermissionRequest(
            teamId: teamId,
            requesterUserId: requesterUserId,
            requestedDate: requestedDate,
            startTime: item.permissionStartTime ?? '',
            endTime: item.permissionEndTime ?? '',
            note: item.metadata['note']?.trim(),
          );
          break;
      }
    });
  }

  Future<void> rejectClockingDecision(NotificationCenterItem item) async {
    final teamId = item.metadata['teamId']?.trim();
    final requesterUserId = item.requesterUserId;
    final requestedDate = item.requestedDate;
    if (teamId == null ||
        teamId.isEmpty ||
        requesterUserId == null ||
        requestedDate == null) {
      return;
    }

    await _performAction(item.notificationId, () async {
      switch (item.requestType) {
        case 'clocking':
          await _backendAuth.rejectClockingRequest(
            teamId: teamId,
            requesterUserId: requesterUserId,
            requestedDate: requestedDate,
            note: item.metadata['note']?.trim(),
          );
          break;
        case 'vacation':
          await _backendAuth.rejectVacationRequest(
            teamId: teamId,
            requesterUserId: requesterUserId,
            requestedDate: requestedDate,
            note: item.metadata['note']?.trim(),
          );
          break;
        case 'permission':
          await _backendAuth.rejectPermissionRequest(
            teamId: teamId,
            requesterUserId: requesterUserId,
            requestedDate: requestedDate,
            startTime: item.permissionStartTime ?? '',
            endTime: item.permissionEndTime ?? '',
            note: item.metadata['note']?.trim(),
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

  Future<void> _performAction(
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
          seenNotificationIds: Set<String>.from(state.seenNotificationIds)
            ..add(notificationId),
          errorMessage: null,
        ),
      );
      await _persistLocalState(
        seenNotificationIds: Set<String>.from(state.seenNotificationIds),
        dismissedNotificationIds: dismissed,
        completedActionNotificationIds: completed,
      );
    } catch (e) {
      processing.remove(notificationId);
      if (_isTerminalInvitationConflict(e)) {
        final completed = Set<String>.from(state.completedActionNotificationIds)
          ..add(notificationId);
        final dismissed = Set<String>.from(state.dismissedNotificationIds)
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
            seenNotificationIds: Set<String>.from(state.seenNotificationIds)
              ..add(notificationId),
            errorMessage: null,
          ),
        );
        await _persistLocalState(
          seenNotificationIds: Set<String>.from(state.seenNotificationIds),
          dismissedNotificationIds: dismissed,
          completedActionNotificationIds: completed,
        );
        return;
      }
      emit(
        state.copyWith(
          processingNotificationIds: processing,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  bool _isTerminalInvitationConflict(Object error) {
    final raw = error.toString().toLowerCase();
    return raw.contains('409') ||
        raw.contains('not pending') ||
        raw.contains('already accepted') ||
        raw.contains('has expired') ||
        raw.contains('expired');
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
