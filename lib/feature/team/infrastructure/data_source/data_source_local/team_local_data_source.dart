import 'package:hive/hive.dart';
import 'package:note_sondage/feature/team/domain/entities/team_entity.dart';
import 'package:note_sondage/feature/team/infrastructure/data/hive_models/team_hive_model.dart';

class TeamLocalDataSource {
  static const String _boxName = 'teams_box';

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
      ),
    );
    await box.addAll(models);
  }

  Future<List<TeamEntity>> getAll() async {
    final box = await _openBox();
    return box.values
        .map(
          (m) => TeamEntity(
            m.id,
            m.color,
            name: m.name,
            description: m.description,
            createdByUserId: m.createdByUserId,
            createdAt: DateTime.tryParse(m.createdAt),
          ),
        )
        .toList();
  }
}
