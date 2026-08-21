import 'package:flutter_test/flutter_test.dart';
import 'package:note_sondage/feature/task/domain/entities/task_entity.dart';
import 'package:note_sondage/feature/task/domain/entities/task_priority.dart';
import 'package:note_sondage/feature/task/domain/entities/task_status.dart';
import 'package:note_sondage/feature/task/ui/task_ui_support.dart';
import 'package:note_sondage/feature/team/domain/entities/team_entity.dart';

TaskEntity buildTask({required TaskStatus status, String? teamId = 'team-1'}) {
  final now = DateTime.utc(2026, 8, 20, 10);
  return TaskEntity(
    id: 'task-1',
    teamId: teamId,
    title: 'Task demo',
    description: 'desc',
    status: status,
    priority: TaskPriority.medium,
    createdByUserId: 'creator-1',
    createdByDisplayName: 'Creator',
    createdAt: now,
    updatedAt: now,
  );
}

TeamEntity buildTeam(String id, String name) {
  return TeamEntity(
    id,
    null,
    null,
    name: name,
    description: 'desc',
    createdByUserId: 'owner-1',
  );
}

void main() {
  group('allowedTaskStatuses', () {
    test('keeps canceled available for managers on open tasks', () {
      final statuses = allowedTaskStatuses(
        buildTask(status: TaskStatus.open),
        canManageTask: true,
      );

      expect(statuses, <TaskStatus>[
        TaskStatus.open,
        TaskStatus.inProgress,
        TaskStatus.blocked,
        TaskStatus.done,
        TaskStatus.canceled,
      ]);
    });

    test('hides canceled for assignee-only users on open tasks', () {
      final statuses = allowedTaskStatuses(
        buildTask(status: TaskStatus.open),
        canManageTask: false,
      );

      expect(statuses, <TaskStatus>[
        TaskStatus.open,
        TaskStatus.inProgress,
        TaskStatus.blocked,
        TaskStatus.done,
      ]);
      expect(statuses, isNot(contains(TaskStatus.canceled)));
    });

    test('hides canceled for assignee-only users on in-progress tasks', () {
      final statuses = allowedTaskStatuses(
        buildTask(status: TaskStatus.inProgress),
        canManageTask: false,
      );

      expect(statuses, <TaskStatus>[
        TaskStatus.inProgress,
        TaskStatus.blocked,
        TaskStatus.done,
      ]);
      expect(statuses, isNot(contains(TaskStatus.canceled)));
    });
  });

  group('taskEditAvailableTeams', () {
    test('uses manageable teams for personal task editing', () {
      final ops = buildTeam('team-1', 'Ops');
      final sales = buildTeam('team-2', 'Sales');

      final result = taskEditAvailableTeams(
        task: buildTask(status: TaskStatus.open, teamId: null),
        taskTeam: null,
        manageableTeams: <TeamEntity>[ops, sales],
      );

      expect(result, <TeamEntity>[ops, sales]);
    });

    test('uses the task team even when current page selection differs', () {
      final taskTeam = buildTeam('team-7', 'Support');

      final result = taskEditAvailableTeams(
        task: buildTask(status: TaskStatus.open, teamId: 'team-7'),
        taskTeam: taskTeam,
        manageableTeams: <TeamEntity>[buildTeam('team-3', 'Other')],
      );

      expect(result, <TeamEntity>[taskTeam]);
    });

    test('returns empty when a team task has no resolvable team', () {
      final result = taskEditAvailableTeams(
        task: buildTask(status: TaskStatus.open, teamId: 'missing-team'),
        taskTeam: null,
        manageableTeams: <TeamEntity>[buildTeam('team-3', 'Other')],
      );

      expect(result, isEmpty);
    });
  });
}
