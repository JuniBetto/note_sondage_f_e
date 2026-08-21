import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:hive/hive.dart';
import 'package:note_sondage/feature/team/domain/entities/planning_worker_type_entity.dart';
import 'package:note_sondage/feature/team/domain/entities/team_entity.dart';
import 'package:note_sondage/feature/team/infrastructure/data/team_mapper.dart';
import 'package:note_sondage/feature/team/infrastructure/data/hive_models/team_hive_model.dart';

class TeamLocalDataSource {
  static const String _boxNamePrefix = 'teams_box';

  String get _boxName {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null || userId.isEmpty) {
      return '${_boxNamePrefix}_anonymous';
    }
    return '${_boxNamePrefix}_$userId';
  }

  Future<Box<TeamHiveModel>> _openBox() async {
    if (Hive.isBoxOpen(_boxName)) {
      return Hive.box<TeamHiveModel>(_boxName);
    }
    return await Hive.openBox<TeamHiveModel>(_boxName);
  }

  Future<void> saveAll(List<TeamEntity> teams) async {
    final box = await _openBox();
    await box.clear();
    final models = teams.map(
      (e) => TeamHiveModel(
        id: e.id,
        name: e.name,
        description: e.description,
        createdByUserId: e.createdByUserId,
        createdAt: e.createdAt.toIso8601String(),
        color: e.color,
        clockingRequired: e.clockingRequired,
        clockingRequiredStartDate: e.clockingRequiredStartDate,
        clockingRequiredEndDate: e.clockingRequiredEndDate,
        clockingReminderTime: e.clockingReminderTime,
        clockingMissingAlertTime: e.clockingMissingAlertTime,
        clockingOpenAlertTime: e.clockingOpenAlertTime,
        workflowAiEnabled: e.workflowAiEnabled,
        planningWorkerTypesJson: jsonEncode(
          e.planningWorkerTypes
              .map(TeamMapper.planningWorkerTypeToJson)
              .toList(),
        ),
      ),
    );
    await box.addAll(models);
  }

  Future<void> clearAll() async {
    final box = await _openBox();
    await box.clear();
  }

  Future<List<TeamEntity>> getAll() async {
    final box = await _openBox();
    return box.values.map((m) {
      final planningWorkerTypes = (() {
        try {
          return (jsonDecode(m.planningWorkerTypesJson ?? '[]')
                  as List<dynamic>)
              .whereType<Map>()
              .map(
                (item) => TeamMapper.planningWorkerTypeFromJson(
                  item.map((key, value) => MapEntry(key.toString(), value)),
                ),
              )
              .toList();
        } catch (_) {
          return <PlanningWorkerTypeEntity>[];
        }
      })();
      return TeamEntity(
        m.id,
        m.color,
        null,
        name: m.name,
        description: m.description,
        createdByUserId: m.createdByUserId,
        clockingRequired: m.clockingRequired,
        clockingRequiredStartDate: m.clockingRequiredStartDate,
        clockingRequiredEndDate: m.clockingRequiredEndDate,
        clockingReminderTime: m.clockingReminderTime,
        clockingMissingAlertTime: m.clockingMissingAlertTime,
        clockingOpenAlertTime: m.clockingOpenAlertTime,
        workflowAiEnabled: m.workflowAiEnabled,
        planningWorkerTypes: planningWorkerTypes.isEmpty
            ? PlanningWorkerTypeEntity.builtIns
            : planningWorkerTypes,
        createdAt: DateTime.tryParse(m.createdAt),
      );
    }).toList();
  }
}
