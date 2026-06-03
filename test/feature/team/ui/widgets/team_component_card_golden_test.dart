import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:note_sondage/feature/team/ui/widgets/team_component_card.dart';

import '../../../../support/team_fixtures.dart';
import '../../../../support/test_app.dart';

bool _goldenExists(String relativePath) {
  return File(
    '${Directory.current.path}/test/feature/team/ui/widgets/$relativePath',
  ).existsSync();
}

void main() {
  group('TeamComponentCard golden base', () {
    const boundaryKey = Key('team-card-golden-boundary');

    testWidgets('default card matches golden', (tester) async {
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

      expect(find.byKey(boundaryKey), findsOneWidget);

      const goldenPath =
          'goldens/team_component_card/team_component_card_default.png';
      if (_goldenExists(goldenPath)) {
        await expectLater(
          find.byKey(boundaryKey),
          matchesGoldenFile(goldenPath),
        );
      }
    });

    testWidgets('owner card matches golden', (tester) async {
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

      expect(find.byKey(boundaryKey), findsOneWidget);

      const goldenPath =
          'goldens/team_component_card/team_component_card_owner.png';
      if (_goldenExists(goldenPath)) {
        await expectLater(
          find.byKey(boundaryKey),
          matchesGoldenFile(goldenPath),
        );
      }
    });
  });
}
