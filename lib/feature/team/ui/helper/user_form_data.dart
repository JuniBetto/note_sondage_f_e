import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';

class UserFormData {
  final TextEditingController emailController;
  final TextEditingController statusController;
  final TextEditingController roleController;

  final String userId; // Optional user ID (for updates)

  /// Avatar image file (for mobile)
  File? avatarFile;

  String? avatarUrl; // Optional URL for existing avatar (for updates)
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

  /// Returns true if an avatar is set (either file or bytes)
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
