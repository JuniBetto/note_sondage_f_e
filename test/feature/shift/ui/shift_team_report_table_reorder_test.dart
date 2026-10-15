import 'package:flutter/material.dart';
// ignore: depend_on_referenced_packages
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:note_sondage/feature/shift/domain/entities/shift_assignment_entity.dart';
import 'package:note_sondage/feature/shift/domain/repositories/shift_repository.dart';
import 'package:note_sondage/feature/shift/ui/widgets/shift_team_report_dialog.dart';
import 'package:note_sondage/feature/team/domain/entities/team_entity.dart';
import 'package:note_sondage/feature/team/domain/entities/team_member_entity.dart';
import 'package:note_sondage/feature/team/domain/use_case/team_member/team_member_use_case.dart';
import 'package:note_sondage/languages/l10n/app_localizations.dart';

class _FakeShiftRepository implements ShiftRepository {
  @override
  Future<List<ShiftAssignmentEntity>> getAssignments({
    required DateTime from,
    required DateTime to,
    List<String>? visibleTeamIds,
    List<String>? visibleUserIds,
  }) async => [
    ShiftAssignmentEntity(
      id: '1',
      userId: 'u1',
      userName: 'arth juni',
      shiftDate: DateTime(2026, 8, 16),
      teamId: 'team-1',
      startTime: const TimeOfDay(hour: 9, minute: 0),
      endTime: const TimeOfDay(hour: 18, minute: 0),
      overnight: false,
      alarmOffsets: const [],
      isPublic: true,
    ),
    ShiftAssignmentEntity(
      id: '2',
      userId: 'u2',
      userName: 'Anna',
      shiftDate: DateTime(2026, 8, 17),
      teamId: 'team-1',
      startTime: const TimeOfDay(hour: 9, minute: 0),
      endTime: const TimeOfDay(hour: 18, minute: 0),
      overnight: false,
      alarmOffsets: const [],
      isPublic: true,
    ),
  ];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeTeamMemberUseCase implements TeamMemberUseCase {
  @override
  Future<List<TeamMemberEntity>> getAllMembersByTeamId(String teamId) async =>
      const [];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  setUp(() {
    final getIt = GetIt.instance;
    getIt.registerSingleton<ShiftRepository>(_FakeShiftRepository());
    getIt.registerSingleton<TeamMemberUseCase>(_FakeTeamMemberUseCase());
  });

  tearDown(() => GetIt.instance.reset());

  Future<void> pumpDialog(WidgetTester tester, {required Size size}) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final team = TeamEntityForView(
      team: TeamEntity(
        'team-1',
        null,
        null,
        name: 'team_test',
        description: '',
        createdByUserId: 'u1',
      ),
      members: const [],
    );
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: ShiftTeamReportDialog(teams: [team], compact: size.width < 900),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  double headerX(WidgetTester tester, String label) =>
      tester.getTopLeft(find.text(label.toUpperCase())).dx;

  for (final size in const [Size(1400, 1000), Size(390, 1600)]) {
    testWidgets('table header is shown and columns can be dragged '
        '(${size.width.toInt()}px)', (tester) async {
      await pumpDialog(tester, size: size);

      expect(find.text('DATE'), findsOneWidget);
      expect(find.text('USER'), findsOneWidget);
      expect(headerX(tester, 'Date'), lessThan(headerX(tester, 'User')));

      final gesture = await tester.startGesture(
        tester.getCenter(find.text('DATE')),
      );
      await tester.pump(const Duration(milliseconds: 700));
      await gesture.moveTo(tester.getCenter(find.text('USER')));
      await tester.pump();
      await gesture.moveBy(const Offset(4, 0));
      await tester.pump();
      await gesture.up();
      await tester.pumpAndSettle();

      expect(headerX(tester, 'User'), lessThan(headerX(tester, 'Date')));
    });
  }

  group('touch devices (phone width)', () {
    const phone = Size(390, 1600);

    testWidgets('dragging the handle moves the column right away', (
      tester,
    ) async {
      await pumpDialog(tester, size: phone);
      expect(headerX(tester, 'Date'), lessThan(headerX(tester, 'User')));

      // The ⠿ handle sits at the start of the first header cell.
      final handle = find.byIcon(Icons.drag_indicator_rounded).first;
      final gesture = await tester.startGesture(tester.getCenter(handle));
      // No long press: the drag must start with the very first movement.
      await gesture.moveBy(const Offset(20, 0));
      await tester.pump();
      await gesture.moveTo(tester.getCenter(find.text('USER')));
      await tester.pump();
      await gesture.moveBy(const Offset(4, 0));
      await tester.pump();
      await gesture.up();
      await tester.pumpAndSettle();

      expect(headerX(tester, 'User'), lessThan(headerX(tester, 'Date')));
    });

    testWidgets('a column can be dropped on one that is off screen: the table '
        'scrolls by itself near the edge', (tester) async {
      await pumpDialog(tester, size: phone);

      // TYPE starts outside the 390px viewport.
      expect(tester.getTopLeft(find.text('TYPE')).dx, greaterThan(phone.width));

      final gesture = await tester.startGesture(
        tester.getCenter(find.text('DATE')),
      );
      await tester.pump(const Duration(milliseconds: 400));
      await gesture.moveTo(Offset(phone.width - 8, 200));
      await tester.pump();
      // Keep the finger at the right edge while the table scrolls.
      for (var i = 0; i < 90; i++) {
        await tester.pump(const Duration(milliseconds: 16));
      }

      final typeX = tester.getCenter(find.text('TYPE')).dx;
      expect(
        typeX,
        lessThan(phone.width),
        reason: 'auto-scroll should have brought TYPE into view',
      );

      await gesture.moveTo(
        Offset(typeX, tester.getCenter(find.text('TYPE')).dy),
      );
      await tester.pump();
      await gesture.moveBy(const Offset(2, 0));
      await tester.pump();
      await gesture.up();
      await tester.pumpAndSettle();

      expect(headerX(tester, 'Date'), greaterThan(headerX(tester, 'Type')));
    });
  });

  group('table size button (mobile)', () {
    const phone = Size(390, 1600);

    testWidgets('is not shown on wide screens', (tester) async {
      await pumpDialog(tester, size: const Size(1400, 1000));
      expect(find.byIcon(Icons.format_size_rounded), findsNothing);
    });

    testWidgets('shrinks the table and its content', (tester) async {
      await pumpDialog(tester, size: phone);
      expect(find.byIcon(Icons.format_size_rounded), findsOneWidget);

      final before = tester.getRect(find.text('USER')).size;
      final startX = tester.getTopLeft(find.text('USER')).dx;

      await tester.tap(find.byIcon(Icons.format_size_rounded));
      await tester.pumpAndSettle();
      expect(find.text('100%'), findsOneWidget);
      expect(find.text('55%'), findsOneWidget);
      expect(find.text('35%'), findsOneWidget);
      await tester.tap(find.text('55%'));
      await tester.pumpAndSettle();

      final after = tester.getRect(find.text('USER')).size;
      expect(after.width, closeTo(before.width * 0.55, 1.5));
      expect(after.height, closeTo(before.height * 0.55, 1.5));
      // The columns get closer together as well, not just the text.
      expect(tester.getTopLeft(find.text('USER')).dx, lessThan(startX));
      expect(tester.takeException(), isNull);

      // Back to 100%.
      await tester.tap(find.byIcon(Icons.format_size_rounded));
      await tester.pumpAndSettle();
      await tester.tap(find.text('100%'));
      await tester.pumpAndSettle();
      expect(
        tester.getRect(find.text('USER')).size.width,
        closeTo(before.width, 1),
      );
    });

    testWidgets('35% is the smallest level and still renders without errors', (
      tester,
    ) async {
      await pumpDialog(tester, size: phone);
      final before = tester.getRect(find.text('USER')).size;

      await tester.tap(find.byIcon(Icons.format_size_rounded));
      await tester.pumpAndSettle();
      await tester.tap(find.text('35%'));
      await tester.pumpAndSettle();

      final after = tester.getRect(find.text('USER')).size;
      expect(after.width, closeTo(before.width * 0.35, 1.5));
      expect(after.height, closeTo(before.height * 0.35, 1.5));
      expect(tester.takeException(), isNull);
    });

    testWidgets('columns can still be dragged while zoomed out', (
      tester,
    ) async {
      await pumpDialog(tester, size: phone);
      await tester.tap(find.byIcon(Icons.format_size_rounded));
      await tester.pumpAndSettle();
      await tester.tap(find.text('70%'));
      await tester.pumpAndSettle();

      final handle = find.byIcon(Icons.drag_indicator_rounded).first;
      final gesture = await tester.startGesture(tester.getCenter(handle));
      await gesture.moveBy(const Offset(20, 0));
      await tester.pump();
      await gesture.moveTo(tester.getCenter(find.text('USER')));
      await tester.pump();
      await gesture.moveBy(const Offset(4, 0));
      await tester.pump();
      await gesture.up();
      await tester.pumpAndSettle();

      expect(headerX(tester, 'User'), lessThan(headerX(tester, 'Date')));
    });
  });
}
