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
  Future<ClockingRecordEntity> clockIn({
    String? teamId,
    String? note,
    DateTime? clockInAt,
  });

  /// Effettua il clock-out
  Future<ClockingRecordEntity> clockOut({
    String? teamId,
    String? note,
    DateTime? clockOutAt,
  });

  /// Avvia una pausa sulla timbratura attiva
  Future<ClockingRecordEntity> startBreak({
    String? teamId,
    String? note,
    DateTime? actionAt,
  });

  /// Termina una pausa sulla timbratura attiva
  Future<ClockingRecordEntity> stopBreak({
    String? teamId,
    String? note,
    DateTime? actionAt,
  });

  /// Segna una giornata come ferie per l'utente corrente o per un membro del team
  Future<ClockingRecordEntity> markVacation({
    String? teamId,
    required DateTime date,
    String? targetUserId,
    String? note,
  });

  Future<ClockingRecordEntity> markPermission({
    String? teamId,
    required DateTime date,
    required String startTime,
    required String endTime,
    String? targetUserId,
    String? note,
  });

  /// Crea una o piu timbrature storiche normali per i giorni selezionati
  Future<int> createManualClockingEntries({
    String? teamId,
    required List<DateTime> dates,
    required int clockInMinutes,
    required int clockOutMinutes,
    required int breakMinutes,
    String? note,
  });

  /// Invia una richiesta di timbratura a un membro del team
  Future<void> requestTeamMemberClocking({
    required String teamId,
    required String targetUserId,
    required DateTime date,
    String? note,
  });

  Future<void> requestDecommit({
    required String teamId,
    required String targetUserId,
    required DateTime date,
    required String recordId,
    String? note,
  });

  Future<void> requestVacation({
    required String teamId,
    required DateTime date,
    String? note,
  });

  Future<void> requestPermission({
    required String teamId,
    required DateTime date,
    required String startTime,
    required String endTime,
    String? note,
  });

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
