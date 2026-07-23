import 'package:flutter_test/flutter_test.dart';
import 'package:note_sondage/feature/clocking/domain/entities/clocking_record_entity.dart';
import 'package:note_sondage/feature/clocking/domain/repositories/clocking_repository.dart';
import 'package:note_sondage/feature/clocking/domain/use_case/clocking_use_case.dart';

class _FakeClockingRepository implements ClockingRepository {
  Future<int> Function({
    String? teamId,
    required List<DateTime> dates,
    required int clockInMinutes,
    required int clockOutMinutes,
    required int breakMinutes,
    String? note,
  })?
  createManualClockingEntriesHandler;

  int createManualClockingEntriesCalls = 0;
  List<DateTime> lastDates = const <DateTime>[];

  @override
  Future<int> createManualClockingEntries({
    String? teamId,
    required List<DateTime> dates,
    required int clockInMinutes,
    required int clockOutMinutes,
    required int breakMinutes,
    String? note,
  }) {
    createManualClockingEntriesCalls++;
    lastDates = List<DateTime>.from(dates);
    return createManualClockingEntriesHandler?.call(
          teamId: teamId,
          dates: dates,
          clockInMinutes: clockInMinutes,
          clockOutMinutes: clockOutMinutes,
          breakMinutes: breakMinutes,
          note: note,
        ) ??
        Future<int>.value(dates.length);
  }

  @override
  Future<ClockingRecordEntity> clockIn({
    String? teamId,
    String? note,
    DateTime? clockInAt,
  }) => throw UnimplementedError();

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
  Future<List<ClockingRecordEntity>> getAll() => throw UnimplementedError();

  @override
  Future<List<ClockingRecordEntity>> getByDate(DateTime date) =>
      throw UnimplementedError();

  @override
  Future<ClockingRecordEntity?> getById(String id) =>
      throw UnimplementedError();

  @override
  Future<List<ClockingRecordEntity>> getByTeamId(String teamId) =>
      throw UnimplementedError();

  @override
  Future<List<ClockingRecordEntity>> getByUserId(String userId) =>
      throw UnimplementedError();

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
  Future<ClockingRecordEntity> markVacation({
    String? teamId,
    required DateTime date,
    String? targetUserId,
    String? note,
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
  Future<void> requestPermission({
    required String teamId,
    required DateTime date,
    required String startTime,
    required String endTime,
    String? note,
  }) => throw UnimplementedError();

  @override
  Future<void> requestTeamMemberClocking({
    required String teamId,
    required String targetUserId,
    required DateTime date,
    String? note,
  }) => throw UnimplementedError();

  @override
  Future<void> requestVacation({
    required String teamId,
    required DateTime date,
    String? note,
  }) => throw UnimplementedError();

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

  @override
  Future<bool> delete(String id) => throw UnimplementedError();
}

void main() {
  late _FakeClockingRepository repository;
  late ClockingUseCase useCase;

  setUp(() {
    repository = _FakeClockingRepository();
    useCase = ClockingUseCase(repository);
  });

  group('ClockingUseCase.createManualClockingEntries', () {
    test('rejects an empty date selection', () async {
      await expectLater(
        () => useCase.createManualClockingEntries(
          dates: const <DateTime>[],
          clockInMinutes: 9 * 60,
          clockOutMinutes: 17 * 60,
          breakMinutes: 30,
        ),
        throwsA(
          isA<Exception>().having(
            (error) => error.toString(),
            'message',
            contains('Select at least one day'),
          ),
        ),
      );
      expect(repository.createManualClockingEntriesCalls, 0);
    });

    test('rejects a clock-out time before or equal to clock-in', () async {
      await expectLater(
        () => useCase.createManualClockingEntries(
          dates: <DateTime>[DateTime(2026, 7, 20)],
          clockInMinutes: 17 * 60,
          clockOutMinutes: 17 * 60,
          breakMinutes: 0,
        ),
        throwsA(
          isA<Exception>().having(
            (error) => error.toString(),
            'message',
            contains('Clock-out time must be after clock-in time'),
          ),
        ),
      );
      expect(repository.createManualClockingEntriesCalls, 0);
    });

    test(
      'rejects break durations that are not shorter than the shift',
      () async {
        await expectLater(
          () => useCase.createManualClockingEntries(
            dates: <DateTime>[DateTime(2026, 7, 20)],
            clockInMinutes: 9 * 60,
            clockOutMinutes: 17 * 60,
            breakMinutes: 8 * 60,
          ),
          throwsA(
            isA<Exception>().having(
              (error) => error.toString(),
              'message',
              contains('Break time must be shorter than the shift duration'),
            ),
          ),
        );
        expect(repository.createManualClockingEntriesCalls, 0);
      },
    );

    test('rejects manual clocking entries for today', () async {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      await expectLater(
        () => useCase.createManualClockingEntries(
          dates: <DateTime>[today],
          clockInMinutes: 9 * 60,
          clockOutMinutes: 17 * 60,
          breakMinutes: 30,
        ),
        throwsA(
          isA<Exception>().having(
            (error) => error.toString(),
            'message',
            contains('only available for days different from today'),
          ),
        ),
      );
      expect(repository.createManualClockingEntriesCalls, 0);
    });

    test(
      'normalizes duplicate dates and forwards them sorted to the repository',
      () async {
        final result = await useCase.createManualClockingEntries(
          teamId: 'team-1',
          dates: <DateTime>[
            DateTime(2026, 7, 21, 9, 15),
            DateTime(2026, 7, 19, 18, 45),
            DateTime(2026, 7, 21, 7, 00),
          ],
          clockInMinutes: 9 * 60,
          clockOutMinutes: 17 * 60,
          breakMinutes: 45,
          note: 'manual import',
        );

        expect(result, 2);
        expect(repository.createManualClockingEntriesCalls, 1);
        expect(
          repository.lastDates.map((date) => date.toIso8601String()).toList(),
          <String>[
            DateTime(2026, 7, 19).toIso8601String(),
            DateTime(2026, 7, 21).toIso8601String(),
          ],
        );
      },
    );
  });
}
