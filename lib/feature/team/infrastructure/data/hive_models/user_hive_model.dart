import 'package:hive/hive.dart';

part 'user_hive_model.g.dart';

@HiveType(typeId: 6)
class UserHiveModel extends HiveObject {
  @HiveField(0)
  final String? id;

  @HiveField(1)
  final String fullName;

  @HiveField(2)
  final String email;

  @HiveField(3)
  final String createdAt; // ISO 8601 string

  UserHiveModel({
    required this.id,
    required this.fullName,
    required this.email,
    required this.createdAt,
  });
}
