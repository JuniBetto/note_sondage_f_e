import 'package:flutter_test/flutter_test.dart';
import 'package:note_sondage/feature/notification/inbox/notification_center_item.dart';

void main() {
  group('NotificationCenterItem.supportsApprovedManualClockingFor', () {
    NotificationCenterItem buildItem({
      required Map<String, String> metadata,
      String eventType = 'CLOCKING_CLOCKING_REQUEST_APPROVED',
      String requesterUserId = 'user-1',
    }) {
      return NotificationCenterItem(
        notificationId: 'notification-1',
        eventType: eventType,
        sourceService: 'clocking-service',
        title: 'Approved',
        body: 'Body',
        occurredAt: DateTime.utc(2026, 7, 29, 8),
        metadata: <String, String>{
          'requesterUserId': requesterUserId,
          'requestedDate': '2026-07-27',
          ...metadata,
        },
      );
    }

    test('returns true when approved request matches selected team id', () {
      final item = buildItem(
        metadata: const {'teamId': 'team-1', 'teamName': 'Alpha Team'},
      );

      final matches = item.supportsApprovedManualClockingFor(
        currentUserId: 'user-1',
        teamId: 'team-1',
        teamName: 'Another Team Name',
        date: DateTime(2026, 7, 27),
      );

      expect(matches, isTrue);
    });

    test('returns false when approved request belongs to another team id', () {
      final item = buildItem(
        metadata: const {'teamId': 'team-1', 'teamName': 'Alpha Team'},
      );

      final matches = item.supportsApprovedManualClockingFor(
        currentUserId: 'user-1',
        teamId: 'team-2',
        teamName: 'Alpha Team',
        date: DateTime(2026, 7, 27),
      );

      expect(matches, isFalse);
    });

    test('falls back to team name when team id is missing', () {
      final item = buildItem(metadata: const {'teamName': 'Alpha Team'});

      final matches = item.supportsApprovedManualClockingFor(
        currentUserId: 'user-1',
        teamId: 'team-2',
        teamName: ' alpha team ',
        date: DateTime(2026, 7, 27),
      );

      expect(matches, isTrue);
    });

    test('returns false when fallback team name does not match', () {
      final item = buildItem(metadata: const {'teamName': 'Alpha Team'});

      final matches = item.supportsApprovedManualClockingFor(
        currentUserId: 'user-1',
        teamId: 'team-2',
        teamName: 'Beta Team',
        date: DateTime(2026, 7, 27),
      );

      expect(matches, isFalse);
    });
  });
}
