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

/// Restituisce un messaggio d'errore se [email] e' gia' presente in [invites]
/// (confronto case-insensitive, spazi ai bordi ignorati), escludendo la voce
/// il cui email controller e' [excludeController] (la riga che si sta
/// compilando in questo momento). Usato per impedire di invitare due volte lo
/// stesso indirizzo nella stessa lista di inviti in sospeso, sia in
/// creazione che in modifica di un team, su web e mobile.
String? duplicateInviteEmailError(
  String email,
  List<InviteFormData> invites,
  TextEditingController excludeController,
) {
  final normalized = email.trim().toLowerCase();
  if (normalized.isEmpty) return null;

  final isDuplicate = invites.any(
    (invite) =>
        invite.emailController != excludeController &&
        invite.emailController.text.trim().toLowerCase() == normalized,
  );

  return isDuplicate ? 'This email has already been added to the list.' : null;
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
