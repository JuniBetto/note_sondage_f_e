import 'package:note_sondage/feature/clocking/domain/entities/clocking_record_entity.dart';

abstract class ClockingRepository {
  /// Ottiene tutti i record di clocking
  Future<List<ClockingRecordEntity>> getAll();

  /// Ottiene i record di clocking per data
  Future<List<ClockingRecordEntity>> getByDate(DateTime date);

  /// Ottiene i record di clocking per utente
  Future<List<ClockingRecordEntity>> getByUserId(String userId);

  /// Ottiene i record di un team specifico
  Future<List<ClockingRecordEntity>> getByTeamId(String teamId);

  /// Effettua il clock-in
  Future<ClockingRecordEntity> clockIn(String userId);

  /// Effettua il clock-out
  Future<ClockingRecordEntity> clockOut(String userId);

  /// Ottiene un record per ID
  Future<ClockingRecordEntity?> getById(String id);

  /// Cancella un record
  Future<bool> delete(String id);
}
