import 'package:hive/hive.dart';

part 'task_hive_model.g.dart';

@HiveType(typeId: 9)
class TaskHiveModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String? teamId;

  @HiveField(2)
  final String title;

  @HiveField(3)
  final String? description;

  @HiveField(4)
  final String status;

  @HiveField(5)
  final String priority;

  @HiveField(6)
  final String? startAt;

  @HiveField(7)
  final String? dueAt;

  @HiveField(8)
  final String? assigneeUserId;

  @HiveField(9)
  final String? assigneeDisplayName;

  @HiveField(10)
  final String createdByUserId;

  @HiveField(11)
  final String? createdByDisplayName;

  @HiveField(12)
  final String? workflowMetadataJson;

  @HiveField(13)
  final String? completedAt;

  @HiveField(14)
  final String? archivedAt;

  @HiveField(15)
  final String createdAt;

  @HiveField(16)
  final String updatedAt;

  @HiveField(17)
  final String? reminderOffsetsCsv;

  @HiveField(18)
  final String? reminderAnchor;

  TaskHiveModel({
    required this.id,
    this.teamId,
    required this.title,
    required this.description,
    required this.status,
    required this.priority,
    this.startAt,
    this.dueAt,
    this.assigneeUserId,
    this.assigneeDisplayName,
    required this.createdByUserId,
    this.createdByDisplayName,
    this.workflowMetadataJson,
    this.completedAt,
    this.archivedAt,
    required this.createdAt,
    required this.updatedAt,
    this.reminderOffsetsCsv,
    this.reminderAnchor,
  });
}
