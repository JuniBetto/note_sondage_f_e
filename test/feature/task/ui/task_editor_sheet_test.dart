import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:note_sondage/feature/task/domain/entities/task_entity.dart';
import 'package:note_sondage/feature/task/domain/entities/task_priority.dart';
import 'package:note_sondage/feature/task/domain/entities/task_status.dart';
import 'package:note_sondage/feature/task/domain/entities/task_update_request_entity.dart';
import 'package:note_sondage/feature/task/ui/task_editor_sheet.dart';
import 'package:note_sondage/feature/team/domain/entities/team_entity.dart';


import '../../../support/test_app.dart';

void main() {
  group('showTaskEditorSheet', () {
    testWidgets(
      'preserves the current assignee when it is no longer in the active loader list',
      (tester) async {
        tester.view.physicalSize = const Size(1280, 2200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final team = TeamEntity(
          'team-1',
          null,
          null,
          name: 'Ops',
          description: 'desc',
          createdByUserId: 'owner-1',
        );
        final now = DateTime.utc(2026, 8, 20, 10);
        final existingTask = TaskEntity(
          id: 'task-1',
          teamId: 'team-1',
          title: 'Copertura mattina',
          description: 'desc',
          status: TaskStatus.open,
          priority: TaskPriority.medium,
          assigneeUserId: 'legacy-user',
          assigneeDisplayName: 'Legacy Member',
          createdByUserId: 'creator-1',
          createdByDisplayName: 'Creator',
          createdAt: now,
          updatedAt: now,
        );

        TaskUpdateRequestEntity? capturedRequest;

        await tester.pumpWidget(
          buildTestApp(
            child: Builder(
              builder: (context) {
                return FilledButton(
                  onPressed: () {
                    showTaskEditorSheet(
                      context: context,
                      availableTeams: <TeamEntity>[team],
                      loadAssignees: (_) async => const <TaskAssigneeOption>[
                        TaskAssigneeOption(
                          userId: 'active-user',
                          label: 'Active Member',
                        ),
                      ],
                      onCreate: (_) async => throw UnimplementedError(),
                      onUpdate: (existing, request) async {
                        capturedRequest = request;
                        return existing.copyWith(
                          assigneeUserId: request.clearAssignee
                              ? null
                              : request.assigneeUserId,
                          assigneeDisplayName: request.clearAssignee
                              ? null
                              : request.assigneeDisplayName,
                        );
                      },
                      actorUserId: 'creator-1',
                      actorDisplayName: 'Creator',
                      existingTask: existingTask,
                      lockTeamSelection: true,
                    );
                  },
                  child: const Text('Open editor'),
                );
              },
            ),
          ),
        );

        await tester.tap(find.text('Open editor'));
        await tester.pumpAndSettle();

        expect(find.text('Legacy Member', skipOffstage: false), findsOneWidget);

        final saveFinder = find.text('Salva modifiche', skipOffstage: false);
        await tester.ensureVisible(saveFinder);
        await tester.tap(saveFinder);
        await tester.pump();
        await tester.pumpAndSettle();

        expect(capturedRequest, isNotNull);
        expect(capturedRequest!.assigneeUserId, 'legacy-user');
        expect(capturedRequest!.assigneeDisplayName, 'Legacy Member');
        expect(capturedRequest!.clearAssignee, isFalse);
      },
    );
  });
}
