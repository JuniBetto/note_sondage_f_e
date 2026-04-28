import 'package:flutter/material.dart';
import 'package:note_sondage/feature/sondage/domain/entities/sondage_entity.dart';

class SondageMapper {
  static Color _deriveColor(Map<String, dynamic> json) {
    final rawColor = json['color'];
    if (rawColor is int) {
      return Color(rawColor);
    }
    final seed = (json['teamId']?.toString() ?? json['id']?.toString() ?? '')
        .runes
        .fold<int>(0, (sum, rune) => sum + rune);
    final palette = <Color>[
      const Color(0xFF1565C0),
      const Color(0xFF2E7D32),
      const Color(0xFFEF6C00),
      const Color(0xFF6A1B9A),
      const Color(0xFF00838F),
      const Color(0xFFC62828),
    ];
    return palette[seed % palette.length];
  }

  static SondageEntity fromJson(Map<String, dynamic> json) {
    DateTime? createdDate;
    final createdAtRaw = json['createdDate'] ?? json['createdAt'];
    if (createdAtRaw != null) {
      try {
        createdDate = DateTime.parse(createdAtRaw.toString());
      } catch (_) {
        createdDate = DateTime.now();
      }
    }

    DateTime? expiryDate;
    final expiresAtRaw = json['expiryDate'] ?? json['expiresAt'];
    if (expiresAtRaw != null) {
      try {
        expiryDate = DateTime.parse(expiresAtRaw.toString());
      } catch (_) {
        expiryDate = null;
      }
    }

    final rawOptions = json['options'];
    final options = <SondageOptionEntity>[];
    if (rawOptions is List) {
      for (final item in rawOptions) {
        if (item is Map<String, dynamic>) {
          options.add(
            SondageOptionEntity(
              id: item['id']?.toString() ?? '',
              label: item['label']?.toString() ?? '',
              sortOrder: (item['sortOrder'] as num?)?.toInt() ?? 0,
              voteCount: (item['voteCount'] as num?)?.toInt() ?? 0,
            ),
          );
        } else if (item is Map) {
          options.add(
            SondageOptionEntity(
              id: item['id']?.toString() ?? '',
              label: item['label']?.toString() ?? '',
              sortOrder: (item['sortOrder'] as num?)?.toInt() ?? 0,
              voteCount: (item['voteCount'] as num?)?.toInt() ?? 0,
            ),
          );
        }
      }
    }

    final name = json['name']?.toString() ?? json['title']?.toString() ?? '';
    final description = json['description']?.toString();

    return SondageEntity(
      id: json['id']?.toString() ?? '',
      name: name,
      focus: json['focus']?.toString() ?? description ?? '',
      status: SondageStatus.fromString(json['status']?.toString() ?? 'draft'),
      responses: (json['responses'] as num?)?.toInt() ??
          (json['totalVotes'] as num?)?.toInt() ??
          0,
      totalQuestions: (json['totalQuestions'] as num?)?.toInt() ??
          options.length,
      createdDate: createdDate ?? DateTime.now(),
      expiryDate: expiryDate,
      color: _deriveColor(json),
      createdByUserId: json['createdByUserId']?.toString(),
      teamId: json['teamId']?.toString(),
      teamName: json['teamName']?.toString(),
      description: description,
      options: options,
      currentUserOptionId: json['currentUserOptionId']?.toString(),
      canEdit: json['canEdit'] == true,
      canDelete: json['canDelete'] == true,
      canPublish: json['canPublish'] == true,
      canVote: json['canVote'] == true,
      canClose: json['canClose'] == true,
    );
  }

  static Map<String, dynamic> toJson(SondageEntity entity) {
    return {
      if (entity.teamId != null && entity.teamId!.isNotEmpty)
        'teamId': entity.teamId,
      'title': entity.name,
      'description': entity.description ?? entity.focus,
      if (entity.expiryDate != null) 'expiresAt': entity.expiryDate!.toIso8601String(),
      'options': entity.options.map((option) => option.label).toList(),
    };
  }
}
