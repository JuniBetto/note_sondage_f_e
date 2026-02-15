import 'package:flutter/material.dart';

class RoleFormData {
  final TextEditingController fullNameController;
  final TextEditingController emailController;
  final TextEditingController statusController;
  final TextEditingController roleController;
  final TextEditingController permissionController;

  RoleFormData({
    required this.fullNameController,
    required this.emailController,
    required this.statusController,
    required this.roleController,
    required this.permissionController,
  });

  void dispose() {
    fullNameController.dispose();
    statusController.dispose();
    emailController.dispose();
    roleController.dispose();
    permissionController.dispose();
  }

  void reset() {
    fullNameController.clear();
    statusController.clear();
    emailController.clear();
    roleController.clear();
    permissionController.clear();
  }
}
