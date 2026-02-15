import 'package:note_sondage/domain/entities/all_enum.dart';
import 'package:note_sondage/domain/entities/user_entity.dart';
import 'package:note_sondage/feature/team/domain/entities/user_status.dart';

class UserEntityMapper {
  // Add mapping methods here

  // Factory method per creare un User da JSON
  static UserEntity fromJson(Map<String, dynamic> json) {
    return UserEntity(
      id: json['id'] as String,
      fullName: json['fullName'] as String,
      email: json['email'] as String,
      status: UserStatus.fromString(json['status'] as String),
      role: UserRole.fromString(json['role'] as String),
      contractsId: json['contracts_id'] as String?,
      isDefinitiveDeleted: json['is_definitive_deleted'] as bool,
      deleteAt: json['delete_at'] != null
          ? DateTime.parse(json['delete_at'] as String)
          : null,
      authProviderUid: json['firebase_uid'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  // Metodo per convertire User in JSON
  static Map<String, dynamic> toJson(UserEntity user) {
    return {
      'id': user.id,
      'fullName': user.fullName,
      'email': user.email,
      'status': user.status.value,
      'role': user.role.value,
      'contracts_id': user.contractsId,
      'is_definitive_deleted': user.isDefinitiveDeleted,
      'delete_at': user.deleteAt?.toIso8601String(),
      'firebase_uid': user.authProviderUid,
      'created_at': user.createdAt.toIso8601String(),
      'updated_at': user.updatedAt.toIso8601String(),
    };
  }

  // Metodo per creare una copia modificata
  static UserEntity copyWith(
    UserEntity user, {
    String? id,
    String? fullName,
    String? email,
    UserStatus? status,
    UserRole? role,
    String? contractsId,
    bool? isDefinitiveDeleted,
    DateTime? deleteAt,
    String? firebaseUid,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserEntity(
      id: id ?? user.id,
      fullName: fullName ?? user.fullName,
      email: email ?? user.email,
      status: status ?? user.status,
      role: role ?? user.role,
      contractsId: contractsId ?? user.contractsId,
      isDefinitiveDeleted: isDefinitiveDeleted ?? user.isDefinitiveDeleted,
      deleteAt: deleteAt ?? user.deleteAt,
      authProviderUid: firebaseUid ?? user.authProviderUid,
      createdAt: createdAt ?? user.createdAt,
      updatedAt: updatedAt ?? user.updatedAt,
    );
  }

  static String toStringOf(UserEntity user) {
    return 'User(id: ${user.id}, fullName: ${user.fullName}, email: ${user.email}, '
        'status: ${user.status}, role: ${user.role}, contractsId: ${user.contractsId}, '
        'isDefinitiveDeleted: ${user.isDefinitiveDeleted}, deleteAt: ${user.deleteAt}, '
        'firebaseUid: ${user.authProviderUid}, createdAt: ${user.createdAt}, updatedAt: ${user.updatedAt})';
  }

  static bool equals(UserEntity a, Object other) {
    if (identical(a, other)) return true;
    return other is UserEntity &&
        other.id == a.id &&
        other.fullName == a.fullName &&
        other.email == a.email &&
        other.status == a.status &&
        other.role == a.role &&
        other.contractsId == a.contractsId &&
        other.isDefinitiveDeleted == a.isDefinitiveDeleted &&
        other.deleteAt == a.deleteAt &&
        other.authProviderUid == a.authProviderUid &&
        other.createdAt == a.createdAt &&
        other.updatedAt == a.updatedAt;
  }

  static int hashCodeOf(UserEntity user) {
    return Object.hash(
      user.id,
      user.fullName,
      user.email,
      user.status,
      user.role,
      user.contractsId,
      user.isDefinitiveDeleted,
      user.deleteAt,
      user.authProviderUid,
      user.createdAt,
      user.updatedAt,
    );
  }
}
