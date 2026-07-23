import 'package:flutter_test/flutter_test.dart';
import 'package:note_sondage/feature/notification/realtime/clocking_realtime_coordinator.dart';
import 'package:note_sondage/feature/notification/realtime/realtime_notification_model.dart';
import 'package:note_sondage/feature/notification/realtime/shift_realtime_coordinator.dart';
import 'package:note_sondage/feature/notification/realtime/sondage_realtime_coordinator.dart';
import 'package:note_sondage/feature/notification/realtime/team_realtime_coordinator.dart';

RealtimeNotification buildRealtimeNotification({
  required String eventType,
  required String sourceService,
  String title = '',
  String body = '',
  Map<String, String> metadata = const {},
}) {
  return RealtimeNotification(
    notificationId: 'notif-1',
    eventType: eventType,
    sourceService: sourceService,
    title: title,
    body: body,
    occurredAt: DateTime.utc(2026, 7, 22),
    metadata: metadata,
  );
}

void main() {
  group('RealtimeNotification', () {
    test(
      'fromJson stringifies metadata values and keeps missing fields safe',
      () {
        final notification = RealtimeNotification.fromJson({
          'notificationId': 42,
          'eventType': 'TEAM_UPDATED',
          'sourceService': 'team-service',
          'metadata': {'teamId': 7, 'deleted': true},
        });

        expect(notification.notificationId, '42');
        expect(notification.metadata, {'teamId': '7', 'deleted': 'true'});
        expect(notification.title, isEmpty);
        expect(notification.body, isEmpty);
      },
    );
  });

  group('TeamRealtimeCoordinator', () {
    test('suppresses snackbar when the affected team is currently open', () {
      final coordinator = TeamRealtimeCoordinator();
      coordinator.activateTeamContext('team-1');
      final notification = buildRealtimeNotification(
        eventType: 'TEAM_UPDATED',
        sourceService: 'team-service',
        title: 'Team updated',
        body: 'The team changed',
        metadata: {'teamId': 'team-1'},
      );

      final decision = coordinator.resolveGlobalDecision(
        notification,
        currentUserId: 'user-1',
      );

      expect(decision.refreshTeams, isTrue);
      expect(decision.showSnackBar, isFalse);
      expect(decision.snackBarMessage, isNull);
    });

    test('asks to leave cache and shows message when a team is deleted', () {
      final coordinator = TeamRealtimeCoordinator();
      final notification = buildRealtimeNotification(
        eventType: 'TEAM_UPDATED',
        sourceService: 'team-service',
        metadata: {
          'teamId': 'team-2',
          'deleted': 'true',
          'teamName': 'Ops Team',
        },
      );

      final decision = coordinator.resolveGlobalDecision(
        notification,
        currentUserId: 'user-1',
      );

      expect(decision.teamIdToRemoveFromCache, 'team-2');
      expect(decision.showSnackBar, isTrue);
      expect(decision.snackBarMessage, "Il team 'Ops Team' è stato eliminato.");
    });

    test(
      'screen decision leaves current team when the current user is removed',
      () {
        final coordinator = TeamRealtimeCoordinator();
        final notification = buildRealtimeNotification(
          eventType: 'TEAM_MEMBER_REMOVED',
          sourceService: 'team-service',
          metadata: {'teamId': 'team-3', 'removedUserId': 'user-1'},
        );

        final decision = coordinator.resolveScreenDecision(
          notification,
          teamId: 'team-3',
          currentUserId: 'user-1',
        );

        expect(decision.refreshTeam, isTrue);
        expect(decision.refreshMembers, isTrue);
        expect(decision.shouldLeaveCurrentTeam, isTrue);
      },
    );
  });

  group('ShiftRealtimeCoordinator', () {
    test('refreshes calendar for regular shift updates', () {
      final coordinator = ShiftRealtimeCoordinator();
      final decision = coordinator.resolveDecision(
        buildRealtimeNotification(
          eventType: 'SHIFT_UPDATED',
          sourceService: 'shift-service',
        ),
        currentUserId: 'user-1',
      );

      expect(decision.refreshCalendar, isTrue);
      expect(decision.showAlarmBanner, isFalse);
    });

    test(
      'shows alarm banner without forcing refresh when alarm says otherwise',
      () {
        final coordinator = ShiftRealtimeCoordinator();
        final decision = coordinator.resolveDecision(
          buildRealtimeNotification(
            eventType: 'SHIFT_ALARM_REMINDER',
            sourceService: 'shift-service',
            metadata: {
              'shiftDate': '2026-07-23',
              'profileName': 'Night Shift',
              'minutesBefore': '30',
            },
          ),
          currentUserId: 'user-1',
        );

        expect(decision.refreshCalendar, isFalse);
        expect(decision.showAlarmBanner, isTrue);
        expect(decision.alarmShiftDate, '2026-07-23');
        expect(decision.alarmProfileName, 'Night Shift');
        expect(decision.alarmMinutesBefore, 30);
      },
    );
  });

  group('ClockingRealtimeCoordinator', () {
    test(
      'refreshes clocking and dashboard for current user clock-in on selected team',
      () {
        final coordinator = ClockingRealtimeCoordinator();
        final decision = coordinator.resolveDecision(
          buildRealtimeNotification(
            eventType: 'CLOCKING_CLOCKED_IN',
            sourceService: 'clocking-service',
            metadata: {'teamId': 'team-1', 'targetUserId': 'user-1'},
          ),
          currentUserId: 'user-1',
          selectedTeamId: 'team-1',
        );

        expect(decision.refreshClocking, isTrue);
        expect(decision.refreshDashboard, isTrue);
      },
    );

    test(
      'does not refresh when notification targets another team and user',
      () {
        final coordinator = ClockingRealtimeCoordinator();
        final decision = coordinator.resolveDecision(
          buildRealtimeNotification(
            eventType: 'CLOCKING_BREAK_STARTED',
            sourceService: 'clocking-service',
            metadata: {'teamId': 'team-2', 'targetUserId': 'user-2'},
          ),
          currentUserId: 'user-1',
          selectedTeamId: 'team-1',
        );

        expect(decision.refreshClocking, isFalse);
        expect(decision.refreshDashboard, isFalse);
      },
    );
  });

  group('SondageRealtimeCoordinator', () {
    test('refreshes sondages but not dashboard for draft updates', () {
      final coordinator = SondageRealtimeCoordinator();
      final decision = coordinator.resolveDecision(
        buildRealtimeNotification(
          eventType: 'SONDAGE_DRAFT_UPDATED',
          sourceService: 'sondage-service',
        ),
      );

      expect(decision.refreshSondages, isTrue);
      expect(decision.refreshDashboard, isFalse);
    });

    test('refreshes dashboard for voting events', () {
      final coordinator = SondageRealtimeCoordinator();
      final decision = coordinator.resolveDecision(
        buildRealtimeNotification(
          eventType: 'SONDAGE_VOTED',
          sourceService: 'sondage-service',
        ),
      );

      expect(decision.refreshSondages, isTrue);
      expect(decision.refreshDashboard, isTrue);
    });
  });
}
