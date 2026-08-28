import 'package:flutter_test/flutter_test.dart';
import 'package:note_sondage/feature/clocking/domain/entities/clocking_record_entity.dart';
import 'package:note_sondage/feature/clocking/domain/repositories/clocking_repository.dart';
import 'package:note_sondage/feature/clocking/domain/use_case/clocking_use_case.dart';
import 'package:note_sondage/feature/clocking/infrastructure/data_source/data_source_local/clocking_local_data_source.dart';
import 'package:note_sondage/feature/clocking/ui/bloc/clocking_bloc.dart';

class _FakeClockingRepository implements ClockingRepository {
  Future<List<ClockingRecordEntity>> Function()? getAllHandler;
  Future<List<ClockingRecordEntity>> Function(String teamId)?
  getByTeamIdHandler;
  Future<ClockingRecordEntity> Function({
    String? teamId,
    String? note,
    DateTime? clockInAt,
  })?
  clockInHandler;

  int getAllCalls = 0;
  final getByTeamIdCalls = <String>[];
  int clockInCalls = 0;

  @override
  Future<List<ClockingRecordEntity>> getAll() {
    getAllCalls++;
    return getAllHandler?.call() ??
        Future.value(const <ClockingRecordEntity>[]);
  }

  @override
  Future<List<ClockingRecordEntity>> getByTeamId(String teamId) {
    getByTeamIdCalls.add(teamId);
    return getByTeamIdHandler?.call(teamId) ??
        Future.value(const <ClockingRecordEntity>[]);
  }

  @override
  Future<ClockingRecordEntity> clockIn({
    String? teamId,
    String? note,
    DateTime? clockInAt,
  }) {
    clockInCalls++;
    return clockInHandler?.call(
          teamId: teamId,
          note: note,
          clockInAt: clockInAt,
        ) ??
        Future<ClockingRecordEntity>.error(UnimplementedError());
  }

  @override
  Future<ClockingRecordEntity> clockOut({
    String? teamId,
    String? note,
    DateTime? clockOutAt,
  }) => throw UnimplementedError();

  @override
  Future<ClockingRecordEntity> startBreak({
    String? teamId,
    String? note,
    DateTime? actionAt,
  }) => throw UnimplementedError();

  @override
  Future<ClockingRecordEntity> stopBreak({
    String? teamId,
    String? note,
    DateTime? actionAt,
  }) => throw UnimplementedError();

  @override
  Future<List<ClockingRecordEntity>> getByDate(DateTime date) =>
      throw UnimplementedError();

  @override
  Future<List<ClockingRecordEntity>> getByUserId(String userId) =>
      throw UnimplementedError();

  @override
  Future<ClockingRecordEntity> markVacation({
    String? teamId,
    required DateTime date,
    String? targetUserId,
    String? note,
  }) => throw UnimplementedError();

  @override
  Future<ClockingRecordEntity> markPermission({
    String? teamId,
    required DateTime date,
    required String startTime,
    required String endTime,
    String? targetUserId,
    String? note,
  }) => throw UnimplementedError();

  @override
  Future<ClockingRecordEntity> markSick({
    String? teamId,
    required DateTime date,
    String? targetUserId,
    String? note,
  }) => throw UnimplementedError();

  @override
  Future<int> createManualClockingEntries({
    String? teamId,
    required List<DateTime> dates,
    required int clockInMinutes,
    required int clockOutMinutes,
    required int breakMinutes,
    String? note,
  }) => throw UnimplementedError();

  @override
  Future<void> requestTeamMemberClocking({
    required String teamId,
    required String targetUserId,
    required DateTime date,
    String? note,
    String? recordId,
  }) => throw UnimplementedError();

  @override
  Future<void> requestDecommit({
    required String teamId,
    required String targetUserId,
    required DateTime date,
    required String recordId,
    String? note,
  }) => throw UnimplementedError();

  @override
  Future<void> requestVacation({
    required String teamId,
    required DateTime date,
    String? note,
  }) => throw UnimplementedError();

  @override
  Future<void> requestPermission({
    required String teamId,
    required DateTime date,
    required String startTime,
    required String endTime,
    String? note,
  }) => throw UnimplementedError();

  @override
  Future<void> requestSick({
    required String teamId,
    required DateTime date,
    String? note,
  }) => throw UnimplementedError();

  @override
  Future<ClockingRecordEntity?> getById(String id) =>
      throw UnimplementedError();

  @override
  Future<bool> delete(String id) => throw UnimplementedError();

  @override
  Future<ClockingRecordEntity> updateTeamRecord({
    required String id,
    DateTime? clockInAt,
    DateTime? clockOutAt,
    int? totalBreakMinutes,
    String? note,
  }) => throw UnimplementedError();

  @override
  Future<ClockingRecordEntity> decommitTeamRecord(String id) =>
      throw UnimplementedError();

  @override
  Future<ClockingRecordEntity> commitTeamRecord(String id) =>
      throw UnimplementedError();
}

class _SpyClockingLocalDataSource extends ClockingLocalDataSource {
  List<ClockingRecordEntity> storedRecords = <ClockingRecordEntity>[];
  final savedSnapshots = <List<ClockingRecordEntity>>[];

  @override
  Future<List<ClockingRecordEntity>> getAll() async => storedRecords;

  @override
  Future<void> saveAll(List<ClockingRecordEntity> records) async {
    storedRecords = List<ClockingRecordEntity>.from(records);
    savedSnapshots.add(List<ClockingRecordEntity>.from(records));
  }
}

ClockingRecordEntity _buildRecord({
  required String id,
  required ClockingStatus status,
  String? teamId,
  DateTime? clockInTime,
}) {
  return ClockingRecordEntity(
    id: id,
    userId: 'user-1',
    userName: 'Mario Rossi',
    teamName: teamId == null ? '' : 'Operations',
    teamId: teamId,
    clockInTime: clockInTime,
    status: status,
    date: DateTime(2026, 7, 22),
    timeWorked: const Duration(hours: 2),
  );
}

void main() {
  late _FakeClockingRepository repository;
  late _SpyClockingLocalDataSource localDataSource;
  late ClockingBloc bloc;

  setUp(() {
    repository = _FakeClockingRepository();
    localDataSource = _SpyClockingLocalDataSource();
    bloc = ClockingBloc(
      clockingUseCase: ClockingUseCase(repository),
      clockingLocalDataSource: localDataSource,
    );
  });

  tearDown(() async {
    await bloc.close();
  });

  group('ClockingBloc', () {
    test(
      'LoadClockingRecordsEvent emits cached records first and then refreshed dashboard data',
      () async {
        final localRecord = _buildRecord(
          id: 'local-record',
          status: ClockingStatus.committed,
          clockInTime: DateTime(2026, 7, 21, 9, 0),
        );
        final remoteRecord = _buildRecord(
          id: 'remote-record',
          status: ClockingStatus.clockedIn,
          teamId: 'team-1',
          clockInTime: DateTime(2026, 7, 22, 8, 30),
        );
        final teamRecord = _buildRecord(
          id: 'team-record',
          status: ClockingStatus.clockedIn,
          teamId: 'team-1',
          clockInTime: DateTime(2026, 7, 22, 8, 30),
        );
        final emittedStates = <ClockingState>[];

        localDataSource.storedRecords = <ClockingRecordEntity>[localRecord];
        repository.getAllHandler = () async => <ClockingRecordEntity>[
          remoteRecord,
        ];
        repository.getByTeamIdHandler = (_) async => <ClockingRecordEntity>[
          teamRecord,
        ];
        final subscription = bloc.stream.listen(emittedStates.add);

        bloc.add(const LoadClockingRecordsEvent(teamId: 'team-1'));
        await pumpEventQueue(times: 30);

        expect(
          emittedStates.first,
          isA<ClockingRecordsLoaded>().having(
            (state) => state.myRecords.map((record) => record.id).toList(),
            'cached ids',
            <String>['local-record'],
          ),
        );
        expect(
          emittedStates.last,
          isA<ClockingRecordsLoaded>()
              .having(
                (state) => state.myRecords.map((record) => record.id).toList(),
                'refreshed personal ids',
                <String>['remote-record'],
              )
              .having(
                (state) =>
                    state.teamRecords.map((record) => record.id).toList(),
                'team ids',
                <String>['team-record'],
              )
              .having(
                (state) => state.selectedTeamId,
                'selected team',
                'team-1',
              ),
        );
        expect(repository.getAllCalls, 1);
        expect(repository.getByTeamIdCalls, <String>['team-1']);

        await subscription.cancel();
      },
    );

    test(
      'ClockInEvent emits in-progress, success and then refreshed loaded state',
      () async {
        final committedRecord = _buildRecord(
          id: 'clocking-1',
          status: ClockingStatus.clockedIn,
          teamId: 'team-1',
          clockInTime: DateTime(2026, 7, 22, 9, 0),
        );
        final emittedStates = <ClockingState>[];

        repository.getAllHandler = () async => <ClockingRecordEntity>[
          committedRecord,
        ];
        repository.getByTeamIdHandler = (_) async => <ClockingRecordEntity>[
          committedRecord,
        ];
        repository.clockInHandler = ({teamId, note, clockInAt}) async =>
            committedRecord;
        final subscription = bloc.stream.listen(emittedStates.add);

        bloc.add(
          const ClockInEvent(teamId: 'team-1', note: 'Arrivato in sede'),
        );
        await pumpEventQueue(times: 30);

        expect(emittedStates.first, isA<ClockingActionInProgress>());
        expect(
          emittedStates[1],
          isA<ClockingActionSuccess>()
              .having((state) => state.record.id, 'record id', 'clocking-1')
              .having(
                (state) => state.record.status,
                'status',
                ClockingStatus.clockedIn,
              ),
        );
        expect(
          emittedStates.last,
          isA<ClockingRecordsLoaded>().having(
            (state) => state.myRecords.map((record) => record.id).toList(),
            'loaded ids',
            <String>['clocking-1'],
          ),
        );
        expect(repository.clockInCalls, 1);
        expect(
          localDataSource.savedSnapshots.last
              .map((record) => record.id)
              .toList(),
          <String>['clocking-1'],
        );

        await subscription.cancel();
      },
    );
  });
}
