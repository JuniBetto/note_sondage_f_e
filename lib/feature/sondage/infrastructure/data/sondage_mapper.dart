import 'package:flutter/material.dart';
import 'package:note_sondage/feature/sondage/domain/entities/sondage_entity.dart';

class SondageMapper {
  static SondageEntity fromJson(Map<String, dynamic> json) {
    DateTime? createdDate;
    if (json['createdDate'] != null) {
      try {
        createdDate = DateTime.parse(json['createdDate'] as String);
      } catch (_) {
        createdDate = DateTime.now();
      }
    }

    DateTime? expiryDate;
    if (json['expiryDate'] != null) {
      try {
        expiryDate = DateTime.parse(json['expiryDate'] as String);
      } catch (_) {
        expiryDate = null;
      }
    }

    return SondageEntity(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      focus: json['focus']?.toString() ?? '',
      status: SondageStatus.fromString(json['status']?.toString() ?? 'draft'),
      responses: (json['responses'] as num?)?.toInt() ?? 0,
      totalQuestions: (json['totalQuestions'] as num?)?.toInt() ?? 0,
      createdDate: createdDate ?? DateTime.now(),
      expiryDate: expiryDate,
      color: Color(json['color'] as int? ?? 0xFF2196F3),
      createdByUserId: json['createdByUserId']?.toString(),
      teamId: json['teamId']?.toString(),
      description: json['description']?.toString(),
    );
  }

  static Map<String, dynamic> toJson(SondageEntity entity) {
    return {
      'id': entity.id,
      'name': entity.name,
      'focus': entity.focus,
      'status': entity.status.name,
      'responses': entity.responses,
      'totalQuestions': entity.totalQuestions,
      'createdDate': entity.createdDate.toIso8601String(),
      if (entity.expiryDate != null)
        'expiryDate': entity.expiryDate!.toIso8601String(),
      'color': entity.color.toARGB32(),
      if (entity.createdByUserId != null)
        'createdByUserId': entity.createdByUserId,
      if (entity.teamId != null) 'teamId': entity.teamId,
      if (entity.description != null) 'description': entity.description,
    };
  }
}
