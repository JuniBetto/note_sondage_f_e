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

  TeamHiveModel({
    required this.id,
    required this.name,
    required this.description,
    required this.createdByUserId,
    required this.createdAt,
    this.color,
  });
}
