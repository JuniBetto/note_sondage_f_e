import 'package:hive/hive.dart';

part 'permission_hive_model.g.dart';

@HiveType(typeId: 2)
class PermissionHiveModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String code;

  @HiveField(2)
  final String description;

  PermissionHiveModel({
    required this.id,
    required this.code,
    required this.description,
  });
}
