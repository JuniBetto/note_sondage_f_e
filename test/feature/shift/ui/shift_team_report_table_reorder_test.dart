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

  for (final size in const [Size(1400, 1000), Size(390, 844)]) {
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
}
