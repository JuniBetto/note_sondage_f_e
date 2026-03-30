import 'package:hive/hive.dart';

part 'team_member_hive_model.g.dart';

@HiveType(typeId: 5)
class TeamMemberHiveModel extends HiveObject {
  @HiveField(0)
  final String? id;

  @HiveField(1)
  final String userEmail;

  @HiveField(2)
  final String teamId;

  @HiveField(3)
  final String status; // stored as string value

  @HiveField(4)
  final String roleId;

  @HiveField(5)
  final String? imageUrl;

  @HiveField(6)
  final String? fileName;

  @HiveField(7)
  final String? initialName;

  TeamMemberHiveModel({
    required this.id,
    required this.userEmail,
    required this.teamId,
    required this.status,
    required this.roleId,
    this.imageUrl,
    this.fileName,
    this.initialName,
  });
}
