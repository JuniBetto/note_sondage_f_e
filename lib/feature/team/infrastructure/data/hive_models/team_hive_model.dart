import 'package:hive/hive.dart';

part 'team_hive_model.g.dart';

@HiveType(typeId: 4)
class TeamHiveModel extends HiveObject {
  @HiveField(0)
  final String? id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String description;

  @HiveField(3)
  final String createdByUserId;

  @HiveField(4)
  final String createdAt; // ISO 8601 string

  @HiveField(5)
  final String? color;

  @HiveField(6)
  final bool clockingRequired;

  @HiveField(7)
  final String? clockingRequiredStartDate;

  @HiveField(8)
  final String? clockingReminderTime;

  @HiveField(9)
  final String? clockingMissingAlertTime;

  @HiveField(10)
  final String? clockingOpenAlertTime;

  @HiveField(11)
  final String? planningWorkerTypesJson;

  @HiveField(12)
  final String? clockingRequiredEndDate;

  @HiveField(13)
  final bool workflowAiEnabled;

  TeamHiveModel({
    required this.id,
    required this.name,
    required this.description,
    required this.createdByUserId,
    required this.createdAt,
    this.color,
    this.clockingRequired = false,
    this.clockingRequiredStartDate,
    this.clockingReminderTime,
    this.clockingMissingAlertTime,
    this.clockingOpenAlertTime,
    this.planningWorkerTypesJson,
    this.clockingRequiredEndDate,
    this.workflowAiEnabled = false,
  });
}
