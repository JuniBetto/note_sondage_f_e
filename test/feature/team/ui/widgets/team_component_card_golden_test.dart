import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:note_sondage/feature/team/ui/widgets/team_component_card.dart';

import '../../../../support/team_fixtures.dart';
import '../../../../support/test_app.dart';

void main() {
  group('TeamComponentCard golden base', () {
    const boundaryKey = Key('team-card-golden-boundary');

    testWidgets(
      'default card matches golden',
      (tester) async {
        await tester.pumpWidget(
          buildTestApp(
            child: RepaintBoundary(
              key: boundaryKey,
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
          ),
        );
        await tester.pumpAndSettle();

        await expectLater(
          find.byKey(boundaryKey),
          matchesGoldenFile(
            'goldens/team_component_card/team_component_card_default.png',
          ),
        );
      },
      );

    testWidgets(
      'owner card matches golden',
      (tester) async {
        await tester.pumpWidget(
          buildTestApp(
            child: RepaintBoundary(
              key: boundaryKey,
              child: TeamComponentCard(
                colorTeam: Colors.green,
                isActive: false,
                teamName: 'Operations',
                teamFocus: 'Daily ops',
                teamId: 'team-2',
                members: buildTeamMembersViewData(),
                memberCount: 3,
                isOwner: true,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        await expectLater(
          find.byKey(boundaryKey),
          matchesGoldenFile(
            'goldens/team_component_card/team_component_card_owner.png',
          ),
        );
      },
      );
  });
}
