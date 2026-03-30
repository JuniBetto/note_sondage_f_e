import 'package:hive/hive.dart';
import 'package:note_sondage/feature/team/domain/entities/role_entity.dart';
import 'package:note_sondage/feature/team/infrastructure/data/hive_models/role_hive_model.dart';

class RoleLocalDataSource {
  static const String _boxName = 'roles_box';

  Future<Box<RoleHiveModel>> _openBox() async {
    if (Hive.isBoxOpen(_boxName)) {
      return Hive.box<RoleHiveModel>(_boxName);
    }
    return await Hive.openBox<RoleHiveModel>(_boxName);
  }

  Future<void> saveAll(List<RoleEntity> roles) async {
    final box = await _openBox();
    await box.clear();
    final models = roles.map(
      (e) => RoleHiveModel(
        id: e.id,
        teamId: e.teamId,
        name: e.name,
        permissions: e.permissions,
        description: e.description,
      ),
    );
    await box.addAll(models);
  }

  Future<List<RoleEntity>> getAll() async {
    final box = await _openBox();
    return box.values
        .map(
          (m) => RoleEntity(
            m.id,
            teamId: m.teamId,
            name: m.name,
            permissions: m.permissions,
            description: m.description,
          ),
        )
        .toList();
  }

  /// Legge i ruoli filtrati per teamId.
  Future<List<RoleEntity>> getAllByTeamId(String teamId) async {
    final all = await getAll();
    return all.where((r) => r.teamId == teamId).toList();
  }
}
