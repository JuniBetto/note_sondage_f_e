import 'package:hive/hive.dart';

part 'sondage_hive_model.g.dart';

@HiveType(typeId: 7)
class SondageHiveModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String focus;

  @HiveField(3)
  final String status;

  @HiveField(4)
  final int responses;

  @HiveField(5)
  final int totalQuestions;

  @HiveField(6)
  final String createdDate;

  @HiveField(7)
  final String? expiryDate;

  @HiveField(8)
  final int color;

  @HiveField(9)
  final String? createdByUserId;

  @HiveField(10)
  final String? teamId;

  @HiveField(11)
  final String? description;

  SondageHiveModel({
    required this.id,
    required this.name,
    required this.focus,
    required this.status,
    required this.responses,
    required this.totalQuestions,
    required this.createdDate,
    this.expiryDate,
    required this.color,
    this.createdByUserId,
    this.teamId,
    this.description,
  });
}
