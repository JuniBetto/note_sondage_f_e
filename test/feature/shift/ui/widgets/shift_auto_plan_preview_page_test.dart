import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:note_sondage/feature/shift/domain/entities/shift_assignment_entity.dart';
import 'package:note_sondage/feature/shift/domain/entities/shift_auto_plan_entity.dart';
import 'package:note_sondage/feature/shift/ui/widgets/shift_auto_plan_preview_page.dart';
import 'package:note_sondage/languages/l10n/app_localizations.dart';

void main() {
  group('ShiftAutoPlanPreviewPage', () {
    testWidgets('disables confirm when preview is not fully feasible', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('it'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: ShiftAutoPlanPreviewPage(
            request: _request(),
            preview: _preview(fullyFeasible: false, warnings: ['Coverage gap']),
            onConfirm: () async => _result(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Anteprima Auto Planner'), findsOneWidget);
      expect(find.text('Coverage gap'), findsOneWidget);
      expect(find.text('Calendario preview'), findsOneWidget);

      final confirmButton = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Conferma e crea'),
      );
      expect(confirmButton.onPressed, isNull);
    });

    testWidgets('confirms preview and returns the final planner result', (
      tester,
    ) async {
      ShiftAutoPlanResultEntity? returnedResult;
      var confirmCalls = 0;

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('it'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: Center(
                  child: FilledButton(
                    onPressed: () async {
                      returnedResult = await ShiftAutoPlanPreviewPage.show(
                        context,
                        request: _request(),
                        preview: _preview(),
                        onConfirm: () async {
                          confirmCalls++;
                          return _result();
                        },
                      );
                    },
                    child: const Text('Open preview'),
                  ),
                ),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Open preview'));
      await tester.pumpAndSettle();

      expect(find.text('Anteprima Auto Planner'), findsOneWidget);
      expect(find.text('Calendario preview'), findsOneWidget);

      await tester.tap(find.text('1').first);
      await tester.pumpAndSettle();

      expect(find.text('Mario Rossi'), findsOneWidget);
      expect(find.text('Nuovo'), findsOneWidget);

      await tester.tap(find.widgetWithText(FilledButton, 'Conferma e crea'));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(confirmCalls, 1);
      expect(returnedResult?.createdAssignmentsCount, 1);
      expect(returnedResult?.warnings, isEmpty);
      expect(find.text('Anteprima Auto Planner'), findsNothing);
    });
  });
}

ShiftAutoPlanRequestEntity _request() {
  return ShiftAutoPlanRequestEntity(
    teamId: 'team-1',
    from: DateTime(2026, 8, 1),
    to: DateTime(2026, 8, 2),
    plannerMode: ShiftAutoPlannerMode.coverage,
    replaceExistingAssignments: true,
    templates: const [
      ShiftAutoPlanTemplateEntity(
        profileId: 'profile-1',
        requiredMemberCount: 1,
        simultaneousMemberCount: 1,
      ),
    ],
  );
}

ShiftAutoPlanPreviewEntity _preview({
  bool fullyFeasible = true,
  List<String> warnings = const [],
}) {
  return ShiftAutoPlanPreviewEntity(
    snapshotToken: 'snapshot-1',
    fullyFeasible: fullyFeasible,
    createdAssignmentsCountPreview: 1,
    preservedAssignmentsCount: 0,
    deletedAssignmentsCountPreview: 0,
    uncoveredSlotsCount: fullyFeasible ? 0 : 1,
    warnings: warnings,
    days: [
      ShiftAutoPlanPreviewDayEntity(
        date: DateTime(2026, 8, 1),
        items: [
          ShiftAutoPlanPreviewAssignmentEntity(
            action: ShiftAutoPlanPreviewAction.create,
            assignment: _assignment(),
          ),
        ],
      ),
    ],
  );
}

ShiftAssignmentEntity _assignment() {
  return ShiftAssignmentEntity(
    id: 'assignment-1',
    userId: 'user-1',
    userName: 'Mario Rossi',
    shiftDate: DateTime(2026, 8, 1),
    teamId: 'team-1',
    teamShiftGroupId: 'group-1',
    profileId: 'profile-1',
    profileName: 'Mattina',
    profileColor: '#00AAFF',
    startTime: const TimeOfDay(hour: 8, minute: 0),
    endTime: const TimeOfDay(hour: 12, minute: 0),
    overnight: false,
    note: null,
    alarmOffsets: const <int>[],
    isPublic: true,
    memberEditUnlocked: false,
    memberChangeRequestPending: false,
  );
}

ShiftAutoPlanResultEntity _result() {
  return const ShiftAutoPlanResultEntity(
    createdAssignmentsCount: 1,
    preservedAssignmentsCount: 0,
    uncoveredSlotsCount: 0,
    warnings: [],
  );
}
