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
  Future<ClockingRecordEntity> clockIn({required String teamId, String? note});

  /// Effettua il clock-out
  Future<ClockingRecordEntity> clockOut({String? teamId, String? note});

  /// Avvia una pausa sulla timbratura attiva
  Future<ClockingRecordEntity> startBreak({String? teamId, String? note});

  /// Termina una pausa sulla timbratura attiva
  Future<ClockingRecordEntity> stopBreak({String? teamId, String? note});

  /// Ottiene un record per ID
  Future<ClockingRecordEntity?> getById(String id);

  /// Cancella un record
  Future<bool> delete(String id);

  /// Aggiorna una timbratura del team gia decommittata
  Future<ClockingRecordEntity> updateTeamRecord({
    required String id,
    DateTime? clockInAt,
    DateTime? clockOutAt,
    int? totalBreakMinutes,
    String? note,
  });

  /// Decommitta una timbratura del team
  Future<ClockingRecordEntity> decommitTeamRecord(String id);

  /// Commita nuovamente una timbratura del team
  Future<ClockingRecordEntity> commitTeamRecord(String id);
}
