import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:note_sondage/feature/team/ui/widgets/team_clocking_requirement_section.dart';

import '../../../../support/test_app.dart';

void main() {
  testWidgets('keeps AM/PM picker and sends an unchanged local HH:mm time', (
    tester,
  ) async {
    String? selected;
    await tester.pumpWidget(
      buildTestApp(
        child: SingleChildScrollView(
          child: TeamClockingRequirementSection(
            clockingRequired: true,
            onClockingRequiredChanged: (_) {},
            requiredStartDate: '2026-09-16',
            onRequiredStartDateChanged: (_) {},
            requiredEndDate: null,
            onRequiredEndDateChanged: (_) {},
            reminderTime: '14:40',
            onReminderTimeChanged: (value) => selected = value,
            missingAlertTime: '14:45',
            onMissingAlertTimeChanged: (_) {},
            openAlertTime: '18:00',
            onOpenAlertTimeChanged: (_) {},
          ),
        ),
      ),
    );

    await tester.ensureVisible(find.text('14:40'));
    await tester.tap(find.text('14:40'));
    await tester.pumpAndSettle();
    expect(find.text('AM'), findsOneWidget);
    expect(find.text('PM'), findsOneWidget);
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(selected, '14:40');
  });
}
