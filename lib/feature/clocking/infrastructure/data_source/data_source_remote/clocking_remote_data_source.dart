import 'package:note_sondage/feature/clocking/domain/entities/clocking_record_entity.dart';
import 'package:note_sondage/feature/clocking/infrastructure/data_source/data_source_local/clocking_local_data_source.dart';

/// Remote data source per Clocking.
///
/// Attualmente restituisce dati fittizi (mock) perché le API non sono
/// ancora pronte. Quando il backend sarà disponibile, basterà decommentare
/// le chiamate Dio e rimuovere i dati di test.
class ClockingRemoteDataSource {
  final ClockingLocalDataSource localDataSource;

  ClockingRemoteDataSource(this.localDataSource);

  // ────────────────────────────────────────────────────────────
  //  MOCK DATA — Da rimuovere quando le API saranno pronte
  // ────────────────────────────────────────────────────────────

  static final DateTime _today = DateTime.now();

  static final List<ClockingRecordEntity> _mockRecords = [
    ClockingRecordEntity(
      id: 'clock-001',
      userId: 'user-001',
      userName: 'Marco Rossi',
      teamName: 'Developer',
      teamId: 'team-001',
      clockInTime: DateTime(_today.year, _today.month, _today.day, 9, 0),
      clockOutTime: DateTime(_today.year, _today.month, _today.day, 17, 0),
      timeWorked: const Duration(hours: 8),
      status: ClockingStatus.clockedOut,
      date: _today,
    ),
    ClockingRecordEntity(
      id: 'clock-002',
      userId: 'user-002',
      userName: 'Laura Bianchi',
      teamName: 'Developer',
      teamId: 'team-001',
      clockInTime: DateTime(_today.year, _today.month, _today.day, 9, 12),
      clockOutTime: DateTime(_today.year, _today.month, _today.day, 17, 30),
      timeWorked: const Duration(hours: 8, minutes: 18),
      status: ClockingStatus.clockedOut,
      date: _today,
    ),
    ClockingRecordEntity(
      id: 'clock-003',
      userId: 'user-003',
      userName: 'Giuseppe Verdi',
      teamName: 'Manager',
      teamId: 'team-002',
      clockInTime: DateTime(_today.year, _today.month, _today.day, 8, 45),
      clockOutTime: DateTime(_today.year, _today.month, _today.day, 18, 0),
      timeWorked: const Duration(hours: 9, minutes: 15),
      status: ClockingStatus.clockedOut,
      date: _today,
    ),
    ClockingRecordEntity(
      id: 'clock-004',
      userId: 'user-004',
      userName: 'Sofia Ferrari',
      teamName: 'Commercial',
      teamId: 'team-003',
      clockInTime: DateTime(_today.year, _today.month, _today.day, 9, 30),
      clockOutTime: null,
      timeWorked: null,
      status: ClockingStatus.clockedIn,
      date: _today,
      note: 'Working from home',
    ),
    ClockingRecordEntity(
      id: 'clock-005',
      userId: 'user-005',
      userName: 'Andrea Colombo',
      teamName: 'Developer',
      teamId: 'team-001',
      clockInTime: DateTime(_today.year, _today.month, _today.day, 9, 5),
      clockOutTime: DateTime(_today.year, _today.month, _today.day, 17, 15),
      timeWorked: const Duration(hours: 8, minutes: 10),
      status: ClockingStatus.clockedOut,
      date: _today,
    ),
    ClockingRecordEntity(
      id: 'clock-006',
      userId: 'user-006',
      userName: 'Elena Romano',
      teamName: 'Manager',
      teamId: 'team-002',
      clockInTime: DateTime(_today.year, _today.month, _today.day, 8, 30),
      clockOutTime: DateTime(_today.year, _today.month, _today.day, 16, 45),
      timeWorked: const Duration(hours: 8, minutes: 15),
      status: ClockingStatus.clockedOut,
      date: _today,
    ),
    ClockingRecordEntity(
      id: 'clock-007',
      userId: 'user-007',
      userName: 'Luca Moretti',
      teamName: 'Developer',
      teamId: 'team-001',
      clockInTime: DateTime(_today.year, _today.month, _today.day, 10, 0),
      clockOutTime: null,
      timeWorked: null,
      status: ClockingStatus.clockedIn,
      date: _today,
      note: 'Late start — doctor appointment',
    ),
    ClockingRecordEntity(
      id: 'clock-008',
      userId: 'user-008',
      userName: 'Chiara Ricci',
      teamName: 'Mobile',
      teamId: 'team-004',
      clockInTime: DateTime(_today.year, _today.month, _today.day, 9, 0),
      clockOutTime: DateTime(_today.year, _today.month, _today.day, 17, 0),
      timeWorked: const Duration(hours: 8),
      status: ClockingStatus.clockedOut,
      date: _today,
    ),
    ClockingRecordEntity(
      id: 'clock-009',
      userId: 'user-009',
      userName: 'Matteo Conti',
      teamName: 'Mobile',
      teamId: 'team-004',
      clockInTime: DateTime(_today.year, _today.month, _today.day, 9, 15),
      clockOutTime: null,
      timeWorked: null,
      status: ClockingStatus.clockedIn,
      date: _today,
    ),
    ClockingRecordEntity(
      id: 'clock-010',
      userId: 'user-010',
      userName: 'Francesca Gallo',
      teamName: 'Commercial',
      teamId: 'team-003',
      clockInTime: null,
      clockOutTime: null,
      timeWorked: null,
      status: ClockingStatus.absent,
      date: _today,
      note: 'Sick leave',
    ),
  ];

  // ────────────────────────────────────────────────────────────
  //  API METHODS — Attualmente usano dati mock
  // ────────────────────────────────────────────────────────────

  Future<List<ClockingRecordEntity>> getAll() async {
    // TODO: Sostituire con chiamata API reale
    // final response = await DioClient().dio.get('/clocking/all');
    // final data = response.data as List;
    // final records = data.map((e) => ClockingMapper.fromJson(e)).toList();
    // await localDataSource.saveAll(records);
    // return records;

    await Future.delayed(const Duration(milliseconds: 300));
    await localDataSource.saveAll(_mockRecords);
    return List.from(_mockRecords);
  }

  Future<List<ClockingRecordEntity>> getByDate(DateTime date) async {
    // TODO: Sostituire con chiamata API reale

    await Future.delayed(const Duration(milliseconds: 200));
    return _mockRecords
        .where(
          (r) =>
              r.date.year == date.year &&
              r.date.month == date.month &&
              r.date.day == date.day,
        )
        .toList();
  }

  Future<List<ClockingRecordEntity>> getByUserId(String userId) async {
    // TODO: Sostituire con chiamata API reale

    await Future.delayed(const Duration(milliseconds: 200));
    return _mockRecords.where((r) => r.userId == userId).toList();
  }

  Future<List<ClockingRecordEntity>> getByTeamId(String teamId) async {
    // TODO: Sostituire con chiamata API reale

    await Future.delayed(const Duration(milliseconds: 200));
    return _mockRecords.where((r) => r.teamId == teamId).toList();
  }

  Future<ClockingRecordEntity?> getById(String id) async {
    // TODO: Sostituire con chiamata API reale

    await Future.delayed(const Duration(milliseconds: 150));
    try {
      return _mockRecords.firstWhere((r) => r.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<ClockingRecordEntity> clockIn(String userId) async {
    // TODO: Sostituire con chiamata API reale
    // final response = await DioClient().dio.post('/clocking/clock-in/$userId');
    // return ClockingMapper.fromJson(response.data);

    await Future.delayed(const Duration(milliseconds: 300));
    final now = DateTime.now();
    return ClockingRecordEntity(
      id: 'clock-new-${now.millisecondsSinceEpoch}',
      userId: userId,
      userName: 'Current User',
      teamName: 'Developer',
      clockInTime: now,
      status: ClockingStatus.clockedIn,
      date: now,
    );
  }

  Future<ClockingRecordEntity> clockOut(String userId) async {
    // TODO: Sostituire con chiamata API reale
    // final response = await DioClient().dio.post('/clocking/clock-out/$userId');
    // return ClockingMapper.fromJson(response.data);

    await Future.delayed(const Duration(milliseconds: 300));
    final now = DateTime.now();
    return ClockingRecordEntity(
      id: 'clock-out-${now.millisecondsSinceEpoch}',
      userId: userId,
      userName: 'Current User',
      teamName: 'Developer',
      clockInTime: DateTime(now.year, now.month, now.day, 9, 0),
      clockOutTime: now,
      timeWorked: now.difference(DateTime(now.year, now.month, now.day, 9, 0)),
      status: ClockingStatus.clockedOut,
      date: now,
    );
  }

  Future<void> delete(String id) async {
    // TODO: Sostituire con chiamata API reale
    await Future.delayed(const Duration(milliseconds: 200));
  }
}
