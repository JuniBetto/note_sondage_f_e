import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:note_sondage/feature/task/domain/entities/task_entity.dart';
import 'package:note_sondage/feature/task/domain/entities/task_priority.dart';
import 'package:note_sondage/feature/task/domain/entities/task_status.dart';

String taskText(
  String locale, {
  required String it,
  required String en,
  String? fr,
  String? es,
}) {
  return switch (locale) {
    'it' => it,
    'fr' => fr ?? en,
    'es' => es ?? en,
    _ => en,
  };
}

String taskPriorityLabel(TaskPriority priority, String locale) {
  return switch (priority) {
    TaskPriority.low => taskText(locale, it: 'Bassa', en: 'Low'),
    TaskPriority.medium => taskText(locale, it: 'Media', en: 'Medium'),
    TaskPriority.high => taskText(locale, it: 'Alta', en: 'High'),
  };
}

String taskStatusLabel(TaskStatus status, String locale) {
  return switch (status) {
    TaskStatus.open => taskText(locale, it: 'Aperto', en: 'Open'),
    TaskStatus.inProgress => taskText(
      locale,
      it: 'In corso',
      en: 'In progress',
    ),
    TaskStatus.blocked => taskText(locale, it: 'Bloccato', en: 'Blocked'),
    TaskStatus.done => taskText(locale, it: 'Completato', en: 'Done'),
    TaskStatus.canceled => taskText(locale, it: 'Annullato', en: 'Canceled'),
  };
}

Color taskPriorityColor(TaskPriority priority) {
  return switch (priority) {
    TaskPriority.low => Colors.green,
    TaskPriority.medium => Colors.orange,
    TaskPriority.high => Colors.red,
  };
}

Color taskStatusColor(TaskStatus status) {
  return switch (status) {
    TaskStatus.open => Colors.blue,
    TaskStatus.inProgress => Colors.orange,
    TaskStatus.blocked => Colors.red,
    TaskStatus.done => Colors.green,
    TaskStatus.canceled => Colors.grey,
  };
}

String taskDateTimeLabel(DateTime value, BuildContext context) {
  return DateFormat(
    'dd/MM/yyyy HH:mm',
    Localizations.localeOf(context).toLanguageTag(),
  ).format(value.toLocal());
}

List<TaskStatus> allowedTaskStatuses(TaskEntity task) {
  return switch (task.status) {
    TaskStatus.open => const <TaskStatus>[
      TaskStatus.open,
      TaskStatus.inProgress,
      TaskStatus.blocked,
      TaskStatus.done,
      TaskStatus.canceled,
    ],
    TaskStatus.inProgress => const <TaskStatus>[
      TaskStatus.inProgress,
      TaskStatus.blocked,
      TaskStatus.done,
      TaskStatus.canceled,
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
