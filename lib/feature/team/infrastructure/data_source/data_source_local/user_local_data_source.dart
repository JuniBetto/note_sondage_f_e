import 'package:hive/hive.dart';
import 'package:note_sondage/feature/team/domain/entities/user_entity.dart';
import 'package:note_sondage/feature/team/infrastructure/data/hive_models/user_hive_model.dart';

class UserLocalDataSource {
  static const String _boxName = 'users_box';

  Future<Box<UserHiveModel>> _openBox() async {
    if (Hive.isBoxOpen(_boxName)) {
      return Hive.box<UserHiveModel>(_boxName);
    }
    return await Hive.openBox<UserHiveModel>(_boxName);
  }

  Future<void> saveAll(List<UserEntity> users) async {
    final box = await _openBox();
    await box.clear();
    final models = users.map(
      (e) => UserHiveModel(
        id: e.id,
        fullName: e.fullName,
        email: e.email,
        createdAt: e.createdAt.toIso8601String(),
      ),
    );
    await box.addAll(models);
  }

  Future<List<UserEntity>> getAll() async {
    final box = await _openBox();
    return box.values
        .map(
          (m) => UserEntity(
            m.id,
            fullName: m.fullName,
            email: m.email,
            createdAt: DateTime.tryParse(m.createdAt),
          ),
        )
        .toList();
  }
}
