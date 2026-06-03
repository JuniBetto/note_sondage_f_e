import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:note_sondage/feature/team/domain/entities/invite_team_member_request_entity.dart';

// ─────────────────────────────────────────────────────────────────────────────
// InviteFormData — usato per il form "invita membro" (email + role only).
// Sostituisce UserFormData nei widget AddUserMobile / AddUserWeb.
// ─────────────────────────────────────────────────────────────────────────────
class InviteFormData {
  final TextEditingController emailController;
  final TextEditingController roleController;

  InviteFormData({required this.emailController, required this.roleController});

  /// Converte il form in entity da inviare all'API.
  InviteTeamMemberRequestEntity toEntity() {
    return InviteTeamMemberRequestEntity(
      email: emailController.text.trim(),
      roleId: roleController.text.trim(),
    );
  }

  void dispose() {
    emailController.dispose();
    roleController.dispose();
  }

  void reset() {
    emailController.clear();
    roleController.clear();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// UserFormData — mantenuto per compatibilità (update_team, edit membro).
// ─────────────────────────────────────────────────────────────────────────────
class UserFormData {
  final TextEditingController emailController;
  final TextEditingController statusController;
  final TextEditingController roleController;

  final String userId;

  /// Avatar image file (for mobile)
  File? avatarFile;

  String? avatarUrl;

  /// Avatar image bytes (for web)
  Uint8List? avatarBytes;

  /// Selected permissions for the user
  List<String> selectedPermissions;

  UserFormData({
    Key? key,
    required this.userId,
    required this.emailController,
    required this.statusController,
    required this.roleController,
    this.avatarFile,
    this.avatarBytes,
    this.avatarUrl,
    List<String>? selectedPermissions,
  }) : selectedPermissions = selectedPermissions ?? [];

  bool get hasAvatar =>
      avatarFile != null ||
      avatarBytes != null ||
      (avatarUrl != null && avatarUrl!.isNotEmpty);

  void dispose() {
    statusController.dispose();
    emailController.dispose();
    roleController.dispose();
  }

  void reset() {
    statusController.clear();
    emailController.clear();
    roleController.clear();
    avatarFile = null;
    avatarBytes = null;
    selectedPermissions = [];
  }
}
