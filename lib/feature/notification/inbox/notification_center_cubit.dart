import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:note_sondage/feature/auth/infrastructure/data/backend_auth_data_source.dart';
import 'package:note_sondage/feature/notification/inbox/notification_center_item.dart';
import 'package:note_sondage/feature/notification/realtime/realtime_notification_model.dart';

part 'notification_center_state.dart';

class NotificationCenterCubit extends Cubit<NotificationCenterState> {
  NotificationCenterCubit({required BackendAuthDataSource backendAuth})
    : _backendAuth = backendAuth,
      super(const NotificationCenterState());

  final BackendAuthDataSource _backendAuth;

  Future<void> loadNotifications({bool force = false}) async {
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
      final notifications = await _backendAuth.getMyNotifications();
      emit(
        state.copyWith(
          status: NotificationCenterStatus.loaded,
          notifications: notifications,
          seenNotificationIds: state.seenNotificationIds,
          completedActionNotificationIds: state.completedActionNotificationIds,
          errorMessage: null,
        ),
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
        notification.eventType.startsWith('SYSTEM_')) {
      return;
    }

    final item = NotificationCenterItem.fromRealtime(notification);
    final current = List<NotificationCenterItem>.from(state.notifications);
    current.removeWhere((entry) => entry.notificationId == item.notificationId);
    current.insert(0, item);
    emit(
      state.copyWith(
        status: NotificationCenterStatus.loaded,
        notifications: current,
        seenNotificationIds: state.seenNotificationIds,
        completedActionNotificationIds: state.completedActionNotificationIds,
      ),
    );
  }

  void markAsSeen(String notificationId) {
    if (notificationId.isEmpty) return;
    final seen = Set<String>.from(state.seenNotificationIds)..add(notificationId);
    emit(state.copyWith(seenNotificationIds: seen));
  }

  void markManyAsSeen(Iterable<String> notificationIds) {
    final filtered = notificationIds.where((id) => id.trim().isNotEmpty).toSet();
    if (filtered.isEmpty) return;
    final seen = Set<String>.from(state.seenNotificationIds)..addAll(filtered);
    emit(state.copyWith(seenNotificationIds: seen));
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
    }
  }

  void reset() {
    emit(const NotificationCenterState());
  }

  Future<void> _performAction(
    String notificationId,
    Future<void> Function() action,
  ) async {
    final processing = Set<String>.from(state.processingNotificationIds)
      ..add(notificationId);
    emit(state.copyWith(processingNotificationIds: processing, errorMessage: null));

    try {
      await action();
      final completed = Set<String>.from(state.completedActionNotificationIds)
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
          seenNotificationIds: Set<String>.from(state.seenNotificationIds)
            ..add(notificationId),
          errorMessage: null,
        ),
      );
    } catch (e) {
      processing.remove(notificationId);
      emit(
        state.copyWith(
          processingNotificationIds: processing,
          errorMessage: e.toString(),
        ),
      );
    }
  }
}
