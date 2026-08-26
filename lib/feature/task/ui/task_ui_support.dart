import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:note_sondage/feature/task/domain/entities/task_entity.dart';
import 'package:note_sondage/feature/task/domain/entities/task_priority.dart';
import 'package:note_sondage/feature/task/domain/entities/task_status.dart';
import 'package:note_sondage/feature/team/domain/entities/team_entity.dart';
import 'package:note_sondage/languages/l10n/app_localizations.dart';
import 'package:note_sondage/theme/extensions/color_scheme/color_scheme.dart';

String taskPriorityLabel(TaskPriority priority, BuildContext context) {
  final l10n = AppLocalizations.of(context)!;
  return switch (priority) {
    TaskPriority.low => l10n.taskPriorityLow,
    TaskPriority.medium => l10n.taskPriorityMedium,
    TaskPriority.high => l10n.taskPriorityHigh,
  };
}

String taskStatusLabel(TaskStatus status, BuildContext context) {
  final l10n = AppLocalizations.of(context)!;
  return switch (status) {
    TaskStatus.open => l10n.taskStatusOpen,
    TaskStatus.inProgress => l10n.taskStatusInProgress,
    TaskStatus.blocked => l10n.taskStatusBlocked,
    TaskStatus.done => l10n.taskStatusDone,
    TaskStatus.canceled => l10n.taskStatusCanceled,
  };
}

Color taskPriorityColor(TaskPriority priority, ColorScheme colorScheme) {
  return switch (priority) {
    TaskPriority.low => colorScheme.successColor,
    TaskPriority.medium => colorScheme.warningColor,
    TaskPriority.high => colorScheme.errorColor,
  };
}

Color taskStatusColor(TaskStatus status, ColorScheme colorScheme) {
  return switch (status) {
    TaskStatus.open => colorScheme.infoColor,
    // Not the semantic "warning" yellow — "in progress" isn't a warning
    // state, and yellow doesn't sit well next to the rest of the app's
    // palette. Uses the app's own purple accent instead.
    TaskStatus.inProgress => colorScheme.primaryColor ?? colorScheme.primary,
    TaskStatus.blocked => colorScheme.errorColor,
    TaskStatus.done => colorScheme.successColor,
    TaskStatus.canceled => colorScheme.onSurfaceVariant,
  };
}

double taskStatusProgress(TaskStatus status) {
  return switch (status) {
    TaskStatus.open => 0.0,
    TaskStatus.blocked => 0.25,
    TaskStatus.inProgress => 0.6,
    TaskStatus.done => 1.0,
    TaskStatus.canceled => 1.0,
  };
}

String taskDateTimeLabel(DateTime value, BuildContext context) {
  return DateFormat(
    'dd/MM/yyyy HH:mm',
    Localizations.localeOf(context).toLanguageTag(),
  ).format(value.toLocal());
}

List<TaskStatus> allowedTaskStatuses(
  TaskEntity task, {
  required bool canManageTask,
}) {
  return switch (task.status) {
    TaskStatus.open => <TaskStatus>[
      TaskStatus.open,
      TaskStatus.inProgress,
      TaskStatus.blocked,
      TaskStatus.done,
      if (canManageTask) TaskStatus.canceled,
    ],
    TaskStatus.inProgress => <TaskStatus>[
      TaskStatus.inProgress,
      TaskStatus.blocked,
      TaskStatus.done,
      if (canManageTask) TaskStatus.canceled,
    ],
    TaskStatus.blocked => const <TaskStatus>[
      TaskStatus.blocked,
      TaskStatus.inProgress,
      TaskStatus.done,
    ],
    TaskStatus.done => const <TaskStatus>[TaskStatus.done],
    TaskStatus.canceled => const <TaskStatus>[TaskStatus.canceled],
  };
}

List<TeamEntity> taskEditAvailableTeams({
  required TaskEntity task,
  required TeamEntity? taskTeam,
  required List<TeamEntity> manageableTeams,
}) {
  if (task.isPersonal) {
    return manageableTeams;
  }
  if (taskTeam == null) {
    return const <TeamEntity>[];
  }
  return <TeamEntity>[taskTeam];
}

String normalizeTaskRoleCode(String? value) {
  return value?.trim().toUpperCase() ?? '';
}

Set<String> normalizeTaskPermissions(
  String roleCode,
  List<String>? permissions,
) {
  if (permissions == null || permissions.isEmpty) {
    return switch (roleCode) {
      'OWNER' => {'READ', 'UPDATE', 'ADMIN', 'DELETE', 'MANAGE'},
      'ADMIN' => {'READ', 'UPDATE', 'ADMIN', 'DELETE'},
      _ => {'READ'},
    };
  }
  return permissions
      .map((permission) => permission.trim().toUpperCase())
      .where((permission) => permission.isNotEmpty)
      .toSet();
}
