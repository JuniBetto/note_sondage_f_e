import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:hive/hive.dart';
import 'package:note_sondage/feature/task/domain/entities/task_entity.dart';
import 'package:note_sondage/feature/task/domain/entities/task_priority.dart';
import 'package:note_sondage/feature/task/domain/entities/task_reminder_anchor.dart';
import 'package:note_sondage/feature/task/domain/entities/task_status.dart';
import 'package:note_sondage/feature/task/domain/entities/task_workflow_metadata_entity.dart';
import 'package:note_sondage/feature/task/infrastructure/data/hive_models/task_hive_model.dart';

class TaskLocalDataSource {
  static const String _boxNamePrefix = 'tasks_box';

  String get _boxName {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null || userId.isEmpty) {
      return '${_boxNamePrefix}_anonymous';
    }
    return '${_boxNamePrefix}_$userId';
  }

  Future<Box<TaskHiveModel>> _openBox() async {
    if (Hive.isBoxOpen(_boxName)) {
      return Hive.box<TaskHiveModel>(_boxName);
    }
    return await Hive.openBox<TaskHiveModel>(_boxName);
  }

  Future<void> saveAll(List<TaskEntity> tasks) async {
    final box = await _openBox();
    await box.clear();
    await box.addAll(tasks.map(_toModel));
  }

  Future<void> clearAll() async {
    final box = await _openBox();
    await box.clear();
  }

  Future<List<TaskEntity>> getAll() async {
    final box = await _openBox();
    return box.values.map(_toEntity).toList();
  }

  TaskHiveModel _toModel(TaskEntity task) {
    return TaskHiveModel(
      id: task.id,
      teamId: task.teamId,
      title: task.title,
      description: task.description,
      status: task.status.wireValue,
      priority: task.priority.wireValue,
      startAt: task.startAt?.toIso8601String(),
      dueAt: task.dueAt?.toIso8601String(),
      assigneeUserId: task.assigneeUserId,
      assigneeDisplayName: task.assigneeDisplayName,
      createdByUserId: task.createdByUserId,
      createdByDisplayName: task.createdByDisplayName,
      workflowMetadataJson: task.workflowMetadata == null
          ? null
          : jsonEncode({
              'contextType': task.workflowMetadata!.contextType,
              'contextId': task.workflowMetadata!.contextId,
              'sourceType': task.workflowMetadata!.sourceType,
              'sourceId': task.workflowMetadata!.sourceId,
              'sourceMessageId': task.workflowMetadata!.sourceMessageId,
            }),
      completedAt: task.completedAt?.toIso8601String(),
      archivedAt: task.archivedAt?.toIso8601String(),
      createdAt: task.createdAt.toIso8601String(),
      updatedAt: task.updatedAt.toIso8601String(),
      reminderOffsetsCsv: task.reminderOffsets.isEmpty
          ? null
          : task.reminderOffsets.join(','),
      reminderAnchor: task.reminderAnchor.wireValue,
    );
  }

  TaskEntity _toEntity(TaskHiveModel model) {
    TaskWorkflowMetadataEntity? workflowMetadata;
    if (model.workflowMetadataJson != null) {
      try {
        final raw = jsonDecode(model.workflowMetadataJson!) as Map;
        workflowMetadata = TaskWorkflowMetadataEntity(
          contextType: raw['contextType'] as String?,
          contextId: raw['contextId'] as String?,
          sourceType: raw['sourceType'] as String?,
          sourceId: raw['sourceId'] as String?,
          sourceMessageId: raw['sourceMessageId'] as String?,
        );
      } catch (_) {
        workflowMetadata = null;
      }
    }
    return TaskEntity(
      id: model.id,
      teamId: model.teamId,
      title: model.title,
      description: model.description,
      status: TaskStatusWireValue.fromWireValue(model.status),
      priority: TaskPriorityWireValue.fromWireValue(model.priority),
      startAt: model.startAt == null ? null : DateTime.tryParse(model.startAt!),
      dueAt: model.dueAt == null ? null : DateTime.tryParse(model.dueAt!),
      assigneeUserId: model.assigneeUserId,
      assigneeDisplayName: model.assigneeDisplayName,
      createdByUserId: model.createdByUserId,
      createdByDisplayName: model.createdByDisplayName,
      workflowMetadata: workflowMetadata,
      completedAt: model.completedAt == null
          ? null
          : DateTime.tryParse(model.completedAt!),
      archivedAt: model.archivedAt == null
          ? null
          : DateTime.tryParse(model.archivedAt!),
      createdAt: DateTime.tryParse(model.createdAt) ?? DateTime.now(),
      updatedAt: DateTime.tryParse(model.updatedAt) ?? DateTime.now(),
      reminderOffsets: (model.reminderOffsetsCsv?.trim().isEmpty ?? true)
          ? const <int>[]
          : model.reminderOffsetsCsv!
                .split(',')
                .map((value) => int.tryParse(value.trim()))
                .whereType<int>()
                .toList(growable: false),
      reminderAnchor: TaskReminderAnchorWireValue.fromWireValue(
        model.reminderAnchor,
      ),
    );
  }
}
