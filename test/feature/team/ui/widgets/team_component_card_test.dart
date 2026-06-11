import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:note_sondage/feature/team/ui/widgets/team_component_card.dart';

import '../../../../support/team_fixtures.dart';
import '../../../../support/test_app.dart';

void main() {
  group('TeamComponentCard', () {
    testWidgets('renders team information and visible members', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          child: TeamComponentCard(
            colorTeam: Colors.blue,
            isActive: true,
            teamName: 'Platform',
            teamFocus: 'Core product',
            teamId: 'team-1',
            members: buildTeamMembersViewData(),
            memberCount: 3,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Platform'), findsOneWidget);
      expect(find.text('Core product'), findsOneWidget);
      expect(find.byType(CircleAvatar), findsNWidgets(2));
      expect(find.textContaining('3'), findsOneWidget);
      expect(find.byIcon(Icons.edit), findsOneWidget);
      expect(find.byIcon(Icons.delete_forever_outlined), findsNothing);
    });

    testWidgets('shows delete confirmation and calls callback for owners',
        (tester) async {
      String? deletedTeamId;

      await tester.pumpWidget(
        buildTestApp(
          child: TeamComponentCard(
            colorTeam: Colors.green,
            isActive: false,
            teamName: 'Operations',
            teamFocus: 'Daily ops',
            teamId: 'team-delete',
            members: buildTeamMembersViewData(),
            isOwner: true,
            onDeleteTap: (teamId) => deletedTeamId = teamId,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.delete_forever_outlined));
      await tester.pumpAndSettle();

      expect(find.text('Elimina team'), findsOneWidget);
      expect(find.text('Elimina'), findsOneWidget);

      await tester.tap(find.widgetWithText(FilledButton, 'Elimina'));
      await tester.pumpAndSettle();

      expect(deletedTeamId, 'team-delete');
    });

    testWidgets('navigates to update team route when edit is tapped',
        (tester) async {
      await tester.pumpWidget(
        buildRouterTestApp(
          child: TeamComponentCard(
            colorTeam: Colors.purple,
            isActive: false,
            teamName: 'Design',
            teamFocus: 'UI system',
            teamId: 'team-22',
            members: buildTeamMembersViewData(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.edit));
      await tester.pumpAndSettle();

      expect(find.text('Update team page'), findsOneWidget);
    });
  });
}
