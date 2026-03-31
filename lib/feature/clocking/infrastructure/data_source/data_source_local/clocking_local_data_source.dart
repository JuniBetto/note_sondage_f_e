import 'package:hive/hive.dart';
import 'package:note_sondage/feature/clocking/domain/entities/clocking_record_entity.dart';
import 'package:note_sondage/feature/clocking/infrastructure/data/hive_models/clocking_hive_model.dart';

class ClockingLocalDataSource {
  static const String _boxName = 'clocking_box';

  Future<Box<ClockingHiveModel>> _openBox() async {
    if (Hive.isBoxOpen(_boxName)) {
      return Hive.box<ClockingHiveModel>(_boxName);
    }
    return await Hive.openBox<ClockingHiveModel>(_boxName);
  }

  Future<void> saveAll(List<ClockingRecordEntity> records) async {
    final box = await _openBox();
    await box.clear();
    final models = records.map(
      (e) => ClockingHiveModel(
        id: e.id,
        userId: e.userId,
        userName: e.userName,
        teamName: e.teamName,
        teamId: e.teamId,
        clockInTime: e.clockInTime?.toIso8601String(),
        clockOutTime: e.clockOutTime?.toIso8601String(),
        timeWorkedMinutes: e.timeWorked?.inMinutes,
        status: e.status.name,
        date: e.date.toIso8601String(),
        note: e.note,
      ),
    );
    await box.addAll(models);
  }

  Future<List<ClockingRecordEntity>> getAll() async {
    final box = await _openBox();
    return box.values
        .map(
          (m) => ClockingRecordEntity(
            id: m.id,
            userId: m.userId,
            userName: m.userName,
            teamName: m.teamName,
            teamId: m.teamId,
            clockInTime: m.clockInTime != null
                ? DateTime.tryParse(m.clockInTime!)
                : null,
            clockOutTime: m.clockOutTime != null
                ? DateTime.tryParse(m.clockOutTime!)
                : null,
            timeWorked: m.timeWorkedMinutes != null
                ? Duration(minutes: m.timeWorkedMinutes!)
                : null,
            status: ClockingStatus.fromString(m.status),
            date: DateTime.tryParse(m.date) ?? DateTime.now(),
            note: m.note,
          ),
        )
        .toList();
  }
}
