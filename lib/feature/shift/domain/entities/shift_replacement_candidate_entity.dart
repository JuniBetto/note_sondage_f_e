import 'package:flutter/material.dart';

class ShiftReplacementCandidateIssueEntity {
  const ShiftReplacementCandidateIssueEntity({
    required this.code,
    required this.message,
  });

  final String code;
  final String message;
}

class ShiftReplacementCandidateEntity {
  const ShiftReplacementCandidateEntity({
    required this.userId,
    required this.email,
    required this.fullName,
    required this.avatarUrl,
    required this.role,
    required this.compatible,
    required this.incompatibilities,
  });

  final String userId;
  final String? email;
  final String? fullName;
  final String? avatarUrl;
  final String? role;
  final bool compatible;
  final List<ShiftReplacementCandidateIssueEntity> incompatibilities;

  String get displayName {
    final normalizedFullName = fullName?.trim();
    if (normalizedFullName != null && normalizedFullName.isNotEmpty) {
      return normalizedFullName;
    }
    final normalizedEmail = email?.trim();
    if (normalizedEmail != null && normalizedEmail.isNotEmpty) {
      return normalizedEmail;
    }
    return userId;
  }

  String? get subtitle {
    final normalizedEmail = email?.trim();
    final normalizedFullName = fullName?.trim();
    if (normalizedEmail == null || normalizedEmail.isEmpty) {
      return null;
    }
    if (normalizedFullName != null &&
        normalizedFullName.isNotEmpty &&
        normalizedFullName.toLowerCase() == normalizedEmail.toLowerCase()) {
      return null;
    }
    return normalizedEmail;
  }
}

class ShiftReplacementCandidatesEntity {
  const ShiftReplacementCandidatesEntity({
    required this.assignmentId,
    required this.teamId,
    required this.teamName,
    required this.sourceUserId,
    required this.sourceUserDisplayName,
    required this.shiftDate,
    required this.startTime,
    required this.endTime,
    required this.overnight,
    required this.hasCompatibleCandidates,
    required this.candidates,
  });

  final String assignmentId;
  final String? teamId;
  final String? teamName;
  final String? sourceUserId;
  final String? sourceUserDisplayName;
  final DateTime shiftDate;
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final bool overnight;
  final bool hasCompatibleCandidates;
  final List<ShiftReplacementCandidateEntity> candidates;
}
