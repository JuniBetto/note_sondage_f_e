import 'package:hive/hive.dart';
import 'package:note_sondage/feature/team/domain/entities/permission_entity.dart';
import 'package:note_sondage/feature/team/infrastructure/data/hive_models/permission_hive_model.dart';

class PermissionLocalDataSource {
  static const String _boxName = 'permissions_box';

  Future<Box<PermissionHiveModel>> _openBox() async {
    if (Hive.isBoxOpen(_boxName)) {
      return Hive.box<PermissionHiveModel>(_boxName);
    }
    return await Hive.openBox<PermissionHiveModel>(_boxName);
  }

  /// Salva la lista nel box Hive (sovrascrive tutto).
  Future<void> saveAll(List<PermissionEntity> permissions) async {
    final box = await _openBox();
    await box.clear();
    final models = permissions.map(
      (e) => PermissionHiveModel(
        id: e.id ?? '',
        code: e.code,
        description: e.description,
      ),
    );
    await box.addAll(models);
  }

  /// Legge tutti i permessi dal box Hive.
  Future<List<PermissionEntity>> getAll() async {
    final box = await _openBox();
    return box.values
        .map(
          (m) => PermissionEntity(
            id: m.id,
            code: m.code,
            description: m.description,
          ),
        )
        .toList();
  }
}
