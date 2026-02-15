import 'package:note_sondage/feature/team/domain/entities/user_entity.dart';

class UserMapper {
  static UserEntity fromJson(Map<String, dynamic> json) {
    return UserEntity(
      json['id'] as String?,
      fullName: json['full_name'] as String? ?? '',
      email: json['email'] as String,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  static Map<String, dynamic> toJson(UserEntity user) {
    return {
      'id': user.id,
      'full_name': user.fullName,
      'email': user.email,
      'created_at': user.createdAt.toIso8601String(),
    };
  }

  /// Crea un JSON per un utente inattivo (solo email)
  static Map<String, dynamic> toJsonForInactiveUser(String email) {
    return {'email': email, 'is_active': false};
  }

  static UserEntityForUpdate fromJsonUpdate(Map<String, dynamic> json) {
    return UserEntityForUpdate(
      json['id'] as String?,
      fullName: json['full_name'] as String? ?? '',
      email: json['email'] as String,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      isActive: json['is_active'] as bool? ?? true,
      teamMemberId: json['team_member_id'] as String? ?? '',
      imageUrl: json['image_url'] as String? ?? '',
      role: json['role'] as String? ?? 'Member',
      status: json['status'] as String? ?? 'ACTIVE',
    );
  }

  static Map<String, dynamic> toJsonUpdate(UserEntityForUpdate user) {
    return {
      'id': user.id,
      'full_name': user.fullName,
      'email': user.email,
      'created_at': user.createdAt.toIso8601String(),
      'is_active': user.isActive,
      'team_member_id': user.teamMemberId,
      'image_url': user.imageUrl,
      'role': user.role,
      'status': user.status,
    };
  }
}
