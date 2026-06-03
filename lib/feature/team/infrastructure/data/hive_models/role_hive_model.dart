import 'package:hive/hive.dart';

part 'role_hive_model.g.dart';

@HiveType(typeId: 3)
class RoleHiveModel extends HiveObject {
  @HiveField(0)
  final String? id;

  @HiveField(1)
  final String teamId;

  @HiveField(2)
  final String name;

  @HiveField(3)
  final List<String> permissions;

  @HiveField(4)
  final String? description;

  RoleHiveModel({
    required this.id,
    required this.teamId,
    required this.name,
    required this.permissions,
    this.description,
  });
}
