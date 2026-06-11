import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:note_sondage/feature/sondage/domain/entities/sondage_entity.dart';
import 'package:note_sondage/feature/sondage/infrastructure/data/hive_models/sondage_hive_model.dart';

class SondageLocalDataSource {
  static const String _boxNamePrefix = 'sondages_box_v2';

  String get _boxName {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null || userId.isEmpty) {
      return '${_boxNamePrefix}_anonymous';
    }
    return '${_boxNamePrefix}_$userId';
  }

  Future<Box<SondageHiveModel>> _openBox() async {
    if (Hive.isBoxOpen(_boxName)) {
      return Hive.box<SondageHiveModel>(_boxName);
    }
    return await Hive.openBox<SondageHiveModel>(_boxName);
  }

  Future<void> saveAll(List<SondageEntity> sondages) async {
    final box = await _openBox();
    await box.clear();
    final models = sondages.map(
      (e) => SondageHiveModel(
        id: e.id,
        name: e.name,
        focus: e.focus,
        status: e.status.name,
        responses: e.responses,
        totalQuestions: e.totalQuestions,
        createdDate: e.createdDate.toIso8601String(),
        expiryDate: e.expiryDate?.toIso8601String(),
        color: e.color.toARGB32(),
        createdByUserId: e.createdByUserId,
        teamId: e.teamId,
        description: e.description,
      ),
    );
    await box.addAll(models);
  }

  Future<List<SondageEntity>> getAll() async {
    final box = await _openBox();
    return box.values
        .map(
          (m) => SondageEntity(
            id: m.id,
            name: m.name,
            focus: m.focus,
            status: SondageStatus.fromString(m.status),
            responses: m.responses,
            totalVotes: m.responses,
            totalQuestions: m.totalQuestions,
            createdDate: DateTime.tryParse(m.createdDate) ?? DateTime.now(),
            expiryDate: m.expiryDate != null
                ? DateTime.tryParse(m.expiryDate!)
                : null,
            color: Color(m.color),
            createdByUserId: m.createdByUserId,
            teamId: m.teamId,
            description: m.description,
          ),
        )
        .toList();
  }

  Future<void> clearAll() async {
    final box = await _openBox();
    await box.clear();
  }
}
