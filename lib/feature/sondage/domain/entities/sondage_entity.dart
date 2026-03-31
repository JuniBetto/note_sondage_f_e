import 'package:flutter/material.dart';

/// Status possibili di un sondaggio
enum SondageStatus {
  draft,
  active,
  completed,
  archived;

  factory SondageStatus.fromString(String value) {
    return SondageStatus.values.firstWhere(
      (s) => s.name == value.toLowerCase(),
      orElse: () => SondageStatus.draft,
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
  final int totalQuestions;
  final DateTime createdDate;
  final DateTime? expiryDate;
  final Color color;
  final String? createdByUserId;
  final String? teamId;
  final String? description;

  const SondageEntity({
    required this.id,
    required this.name,
    required this.focus,
    required this.status,
    this.responses = 0,
    this.totalQuestions = 0,
    required this.createdDate,
    this.expiryDate,
    this.color = Colors.blue,
    this.createdByUserId,
    this.teamId,
    this.description,
  });

  SondageEntity copyWith({
    String? id,
    String? name,
    String? focus,
    SondageStatus? status,
    int? responses,
    int? totalQuestions,
    DateTime? createdDate,
    DateTime? expiryDate,
    Color? color,
    String? createdByUserId,
    String? teamId,
    String? description,
  }) {
    return SondageEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      focus: focus ?? this.focus,
      status: status ?? this.status,
      responses: responses ?? this.responses,
      totalQuestions: totalQuestions ?? this.totalQuestions,
      createdDate: createdDate ?? this.createdDate,
      expiryDate: expiryDate ?? this.expiryDate,
      color: color ?? this.color,
      createdByUserId: createdByUserId ?? this.createdByUserId,
      teamId: teamId ?? this.teamId,
      description: description ?? this.description,
    );
  }

  /// Verifica se il sondaggio è scaduto
  bool get isExpired =>
      expiryDate != null && DateTime.now().isAfter(expiryDate!);

  /// Percentuale di completamento (risposte / totale domande)
  double get completionRate =>
      totalQuestions > 0 ? responses / totalQuestions : 0.0;
}
