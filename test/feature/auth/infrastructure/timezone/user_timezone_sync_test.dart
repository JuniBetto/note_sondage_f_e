import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:note_sondage/feature/auth/infrastructure/timezone/user_timezone_sync.dart';

void main() {
  testWidgets('syncs on activation and reasserts on resume, not every poll', (
    tester,
  ) async {
    final saved = <String>[];
    final sync = UserTimezoneSync(
      currentUserId: () => 'user',
      readTimezone: () async => 'America/Mexico_City',
      saveTimezone: (uid, zone) async => saved.add('$uid:$zone'),
    );
    addTearDown(sync.dispose);

    sync.resume();
    await tester.pump();
    expect(saved, ['user:America/Mexico_City']);
    await tester.pump(const Duration(minutes: 1));
    expect(saved.length, 1);
    sync.pause();
    await tester.pump(const Duration(minutes: 2));
    expect(saved.length, 1);
    sync.resume();
    await tester.pump();
    expect(saved.length, 2);
    sync.dispose();
  });

  testWidgets('detects travel while open and retries failed updates', (
    tester,
  ) async {
    var zone = 'Europe/Rome';
    var fail = false;
    final saved = <String>[];
    final sync = UserTimezoneSync(
      currentUserId: () => 'user',
      readTimezone: () async => zone,
      saveTimezone: (uid, value) async {
        if (fail) throw StateError('offline');
        saved.add(value);
      },
    );
    addTearDown(sync.dispose);
    sync.resume();
    await tester.pump();
    zone = 'America/New_York';
    fail = true;
    await tester.pump(const Duration(minutes: 1));
    expect(saved, ['Europe/Rome']);
    fail = false;
    await tester.pump(const Duration(minutes: 1));
    expect(saved, ['Europe/Rome', 'America/New_York']);
    sync.dispose();
  });

  testWidgets('does not send a stale timezone after account switch', (
    tester,
  ) async {
    String? uid = 'first';
    final detected = Completer<String>();
    var reads = 0;
    final saved = <String>[];
    final sync = UserTimezoneSync(
      currentUserId: () => uid,
      readTimezone: () =>
          reads++ == 0 ? detected.future : Future.value('America/Mexico_City'),
      saveTimezone: (user, zone) async => saved.add('$user:$zone'),
    );
    addTearDown(sync.dispose);
    sync.resume();
    uid = null;
    sync.pause();
    uid = 'second';
    sync.resume();
    await tester.pump();
    detected.complete('Europe/Rome');
    await tester.pump();
    expect(saved, ['second:America/Mexico_City']);
    sync.dispose();
  });

  testWidgets('timezone detection failure never invents a UTC fallback', (
    tester,
  ) async {
    var fail = true;
    final saved = <String>[];
    final sync = UserTimezoneSync(
      currentUserId: () => 'user',
      readTimezone: () async {
        if (fail) throw StateError('plugin unavailable');
        return 'Asia/Kathmandu';
      },
      saveTimezone: (uid, zone) async => saved.add(zone),
    );
    addTearDown(sync.dispose);
    sync.resume();
    await tester.pump();
    expect(saved, isEmpty);
    fail = false;
    await tester.pump(const Duration(minutes: 1));
    expect(saved, ['Asia/Kathmandu']);
    sync.dispose();
  });

  testWidgets('does not sync without a signed-in user', (tester) async {
    var reads = 0;
    final sync = UserTimezoneSync(
      currentUserId: () => null,
      readTimezone: () async {
        reads++;
        return 'Europe/Rome';
      },
      saveTimezone: (uid, zone) async => fail('Unexpected timezone update'),
    );
    addTearDown(sync.dispose);
    sync.resume();
    await tester.pump(const Duration(minutes: 1));
    expect(reads, 0);
    sync.dispose();
  });
}
