import 'dart:io';
import 'dart:typed_data';

import 'package:note_sondage/feature/team/domain/entities/user_status.dart';

class TeamMemberEntity {
  final String? id;
  final String userEmail;
  final String teamId;
  final UserStatus status;
  final String roleId;
  final String? imageUrl; // URL dell'immagine dal server

  /// Image file for mobile upload
  final File? imageFile;

  /// Image bytes for web upload
  final Uint8List? imageBytes;

  /// File name (used with imageBytes)
  final String? fileName;
  final String? initialName;

  TeamMemberEntity({
    this.id,
    required this.userEmail,
    required this.teamId,
    required this.status,
    required this.roleId,
    this.imageUrl,
    this.imageFile,
    this.imageBytes,
    this.fileName,
    this.initialName,
  });

  /// Returns true if there's an image to upload
  bool get hasImageToUpload => imageFile != null || imageBytes != null;

  TeamMemberEntity copyWith({
    String? id,
    String? userEmail,
    String? teamId,
    UserStatus? status,
    String? roleId,
    String? imageUrl,
    File? imageFile,
    Uint8List? imageBytes,
    String? fileName,
    String? initialName,
  }) {
    return TeamMemberEntity(
      id: id ?? this.id,
      userEmail: userEmail ?? this.userEmail,
      teamId: teamId ?? this.teamId,
      status: status ?? this.status,
      roleId: roleId ?? this.roleId,
      imageUrl: imageUrl,
      imageFile: imageFile,
      imageBytes: imageBytes,
      fileName: fileName ?? this.fileName,
      initialName: initialName ?? this.initialName,
    );
  }
}

class TeamMemberUpdateTeam {
  final String userId;
  final String email;
  final String status;
  final String teamMemberId;
  final String imageUrl;
  final String role;

  TeamMemberUpdateTeam({
    required this.userId,
    required this.email,
    required this.status,
    required this.teamMemberId,
    required this.imageUrl,
    required this.role,
  });
  TeamMemberUpdateTeam copyWith({
    String? userId,
    String? fullName,
    String? email,
    DateTime? createdAt,
    bool? isActive,
    String? status,
    String? teamMemberId,
    String? imageUrl,
    String? role,
  }) {
    return TeamMemberUpdateTeam(
      email: email ?? this.email,
      status: status ?? this.status,
      teamMemberId: teamMemberId ?? this.teamMemberId,
      imageUrl: imageUrl ?? this.imageUrl,
      role: role ?? this.role,
      userId: userId ?? this.userId,
    );
  }
}
