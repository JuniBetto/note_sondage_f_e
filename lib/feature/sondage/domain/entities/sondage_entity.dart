import 'package:flutter/material.dart';

/// Status possibili di un sondaggio
enum SondageStatus {
  draft,
  active,
  completed,
  archived;

  factory SondageStatus.fromString(String value) {
    switch (value.toLowerCase()) {
      case 'published':
      case 'active':
        return SondageStatus.active;
      case 'closed':
      case 'completed':
        return SondageStatus.completed;
      case 'archived':
        return SondageStatus.archived;
      default:
        return SondageStatus.draft;
    }
  }
}

class SondageOptionEntity {
  final String id;
  final String label;
  final int sortOrder;
  final int voteCount;

  const SondageOptionEntity({
    required this.id,
    required this.label,
    required this.sortOrder,
    this.voteCount = 0,
  });

  SondageOptionEntity copyWith({
    String? id,
    String? label,
    int? sortOrder,
    int? voteCount,
  }) {
    return SondageOptionEntity(
      id: id ?? this.id,
      label: label ?? this.label,
      sortOrder: sortOrder ?? this.sortOrder,
      voteCount: voteCount ?? this.voteCount,
    );
  }
}

/// Entità Sondage — dominio puro, nessuna dipendenza infrastrutturale
class SondageEntity {
  final String id;
  final String name;
  final String focus;
  final SondageStatus status;
  final int responses;
  final int totalVotes;
  final int totalQuestions;
  final DateTime createdDate;
  final DateTime? expiryDate;
  final Color color;
  final String? createdByUserId;
  final String? teamId;
  final String? teamName;
  final String? description;
  final bool allowMultipleResponses;
  final List<SondageOptionEntity> options;
  final String? currentUserOptionId;
  final List<String> currentUserOptionIds;
  final List<String> voterUserIds;
  final bool canEdit;
  final bool canDelete;
  final bool canPublish;
  final bool canVote;
  final bool canClose;
  final bool canReopen;

  const SondageEntity({
    required this.id,
    required this.name,
    required this.focus,
    required this.status,
    this.responses = 0,
    this.totalVotes = 0,
    this.totalQuestions = 0,
    required this.createdDate,
    this.expiryDate,
    this.color = Colors.blue,
    this.createdByUserId,
    this.teamId,
    this.teamName,
    this.description,
    this.allowMultipleResponses = false,
    this.options = const [],
    this.currentUserOptionId,
    this.currentUserOptionIds = const [],
    this.voterUserIds = const [],
    this.canEdit = false,
    this.canDelete = false,
    this.canPublish = false,
    this.canVote = false,
    this.canClose = false,
    this.canReopen = false,
  });

  SondageEntity copyWith({
    String? id,
    String? name,
    String? focus,
    SondageStatus? status,
    int? responses,
    int? totalVotes,
    int? totalQuestions,
    DateTime? createdDate,
    DateTime? expiryDate,
    Color? color,
    String? createdByUserId,
    String? teamId,
    String? teamName,
    String? description,
    bool? allowMultipleResponses,
    List<SondageOptionEntity>? options,
    String? currentUserOptionId,
    List<String>? currentUserOptionIds,
    List<String>? voterUserIds,
    bool? canEdit,
    bool? canDelete,
    bool? canPublish,
    bool? canVote,
    bool? canClose,
    bool? canReopen,
  }) {
    return SondageEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      focus: focus ?? this.focus,
      status: status ?? this.status,
      responses: responses ?? this.responses,
      totalVotes: totalVotes ?? this.totalVotes,
      totalQuestions: totalQuestions ?? this.totalQuestions,
      createdDate: createdDate ?? this.createdDate,
      expiryDate: expiryDate ?? this.expiryDate,
      color: color ?? this.color,
      createdByUserId: createdByUserId ?? this.createdByUserId,
      teamId: teamId ?? this.teamId,
      teamName: teamName ?? this.teamName,
      description: description ?? this.description,
      allowMultipleResponses:
          allowMultipleResponses ?? this.allowMultipleResponses,
      options: options ?? this.options,
      currentUserOptionId: currentUserOptionId ?? this.currentUserOptionId,
      currentUserOptionIds: currentUserOptionIds ?? this.currentUserOptionIds,
      voterUserIds: voterUserIds ?? this.voterUserIds,
      canEdit: canEdit ?? this.canEdit,
      canDelete: canDelete ?? this.canDelete,
      canPublish: canPublish ?? this.canPublish,
      canVote: canVote ?? this.canVote,
      canClose: canClose ?? this.canClose,
      canReopen: canReopen ?? this.canReopen,
    );
  }

  /// Verifica se il sondaggio è scaduto
  bool get isExpired =>
      expiryDate != null && DateTime.now().isAfter(expiryDate!);

  /// Percentuale di completamento (risposte / totale domande)
  double get completionRate =>
      totalQuestions > 0 ? responses / totalQuestions : 0.0;
}
