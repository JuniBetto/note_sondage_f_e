import 'package:note_sondage/domain/entities/all_enum.dart';
import 'package:note_sondage/feature/team/domain/entities/user_status.dart';

class UserEntity {
  final String id;
  final String fullName;
  final String email;
  final UserStatus status;
  final UserRole role;
  final String? contractsId;
  final bool isDefinitiveDeleted;
  final DateTime? deleteAt;
  final String? authProviderUid;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserEntity({
    required this.id,
    required this.fullName,
    required this.email,
    required this.status,
    required this.role,
    this.contractsId,
    required this.isDefinitiveDeleted,
    this.deleteAt,
    this.authProviderUid,
    required this.createdAt,
    required this.updatedAt,
  });
}
