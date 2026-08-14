import 'package:flutter/material.dart';
import 'package:note_sondage/feature/notification/shared/workflow_context_metadata.dart';

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
  final List<String> voterUserIds;

  const SondageOptionEntity({
    required this.id,
    required this.label,
    required this.sortOrder,
    this.voteCount = 0,
    this.voterUserIds = const [],
  });

  SondageOptionEntity copyWith({
    String? id,
    String? label,
    int? sortOrder,
    int? voteCount,
    List<String>? voterUserIds,
  }) {
    return SondageOptionEntity(
      id: id ?? this.id,
      label: label ?? this.label,
      sortOrder: sortOrder ?? this.sortOrder,
      voteCount: voteCount ?? this.voteCount,
      voterUserIds: voterUserIds ?? this.voterUserIds,
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
  final String? contextType;
  final String? contextId;
  final String? sourceType;
  final String? sourceId;
  final String? sourceMessageId;
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
    this.contextType,
    this.contextId,
    this.sourceType,
    this.sourceId,
    this.sourceMessageId,
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
    String? contextType,
    String? contextId,
    String? sourceType,
    String? sourceId,
    String? sourceMessageId,
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
      contextType: contextType ?? this.contextType,
      contextId: contextId ?? this.contextId,
      sourceType: sourceType ?? this.sourceType,
      sourceId: sourceId ?? this.sourceId,
      sourceMessageId: sourceMessageId ?? this.sourceMessageId,
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

  WorkflowContextMetadata get workflowContext {
    final metadata = <String, String>{
      if (teamId != null && teamId!.trim().isNotEmpty) 'teamId': teamId!.trim(),
      if (id.trim().isNotEmpty) 'sondageId': id.trim(),
      if (contextType != null && contextType!.trim().isNotEmpty)
        WorkflowContextMetadata.contextTypeKey: contextType!.trim(),
      if (contextId != null && contextId!.trim().isNotEmpty)
        WorkflowContextMetadata.contextIdKey: contextId!.trim(),
      if (sourceType != null && sourceType!.trim().isNotEmpty)
        WorkflowContextMetadata.sourceTypeKey: sourceType!.trim(),
      if (sourceId != null && sourceId!.trim().isNotEmpty)
        WorkflowContextMetadata.sourceIdKey: sourceId!.trim(),
      if (sourceMessageId != null && sourceMessageId!.trim().isNotEmpty)
        WorkflowContextMetadata.sourceMessageIdKey: sourceMessageId!.trim(),
    };
    return WorkflowContextMetadata.fromMetadata(metadata);
  }

  bool get isShiftGapAvailabilityWorkflow {
    final normalizedSourceType = sourceType?.trim().toLowerCase();
    if (normalizedSourceType == 'shift_gap_availability') {
      return true;
    }
    return workflowContext.pointsToShift;
  }

  SondageOptionEntity? get workflowAvailableOption {
    if (!isShiftGapAvailabilityWorkflow) {
      return null;
    }
    for (final option in options) {
      if (_matchesAvailabilityLabel(option.label, const {
        'disponibile',
        'available',
        'disponible',
      })) {
        return option;
      }
    }
    return null;
  }

  SondageOptionEntity? get workflowUnavailableOption {
    if (!isShiftGapAvailabilityWorkflow) {
      return null;
    }
    for (final option in options) {
      if (_matchesAvailabilityLabel(option.label, const {
        'non_disponibile',
        'not_available',
        'indisponible',
        'no_disponible',
      })) {
        return option;
      }
    }
    return null;
  }

  List<String> get workflowAvailableResponderUserIds =>
      workflowAvailableOption?.voterUserIds ?? const <String>[];

  List<String> get workflowUnavailableResponderUserIds =>
      workflowUnavailableOption?.voterUserIds ?? const <String>[];

  static bool _matchesAvailabilityLabel(String raw, Set<String> allowed) {
    final normalized = raw.trim().toLowerCase().replaceAll('-', ' ');
    if (normalized.isEmpty) {
      return false;
    }
    final compact = normalized.replaceAll(RegExp(r'\s+'), '_');
    return allowed.contains(compact);
  }
}
