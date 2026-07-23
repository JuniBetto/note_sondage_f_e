import 'package:flutter_test/flutter_test.dart';
import 'package:note_sondage/feature/home/domain/entities/dashboard_entity.dart';
import 'package:note_sondage/feature/home/domain/repositories/dashboard_repository.dart';
import 'package:note_sondage/feature/home/domain/use_case/dashboard_use_case.dart';
import 'package:note_sondage/feature/home/ui/bloc/dashboard_bloc.dart';

class _FakeDashboardRepository implements DashboardRepository {
  Future<DashboardStats> Function()? getStatsHandler;
  Future<List<RecentActivity>> Function()? getRecentActivitiesHandler;

  int getStatsCalls = 0;
  int getRecentActivitiesCalls = 0;

  @override
  Future<DashboardStats> getStats() {
    getStatsCalls++;
    return getStatsHandler?.call() ?? Future.value(const DashboardStats());
  }

  @override
  Future<List<RecentActivity>> getRecentActivities() {
    getRecentActivitiesCalls++;
    return getRecentActivitiesHandler?.call() ??
        Future.value(const <RecentActivity>[]);
  }
}

void main() {
  late _FakeDashboardRepository repository;
  late DashboardBloc bloc;

  setUp(() {
    repository = _FakeDashboardRepository();
    bloc = DashboardBloc(dashboardUseCase: DashboardUseCase(repository));
  });

  tearDown(() async {
    await bloc.close();
  });

  group('DashboardBloc', () {
    test('LoadDashboardEvent emits loading and then dashboard data', () async {
      final emittedStates = <DashboardState>[];
      const stats = DashboardStats(
        activeTeams: 3,
        totalMembers: 12,
        activeSurveys: 2,
        todayClocking: 9,
        todayShifts: 4,
        completedSurveys: 7,
        pendingInvitations: 1,
      );
      final activities = <RecentActivity>[
        RecentActivity(
          id: 'activity-1',
          title: 'Team created',
          subtitle: 'Operations',
          type: RecentActivityType.teamCreated,
          timestamp: DateTime(2026, 7, 22, 9, 0),
        ),
      ];

      repository.getStatsHandler = () async => stats;
      repository.getRecentActivitiesHandler = () async => activities;
      final subscription = bloc.stream.listen(emittedStates.add);

      bloc.add(LoadDashboardEvent());
      await pumpEventQueue(times: 20);

      expect(emittedStates.first, isA<DashboardLoading>());
      expect(
        emittedStates.last,
        isA<DashboardLoaded>()
            .having((state) => state.stats.activeTeams, 'active teams', 3)
            .having((state) => state.stats.totalMembers, 'members', 12)
            .having(
              (state) => state.activities.map((item) => item.id).toList(),
              'activity ids',
              <String>['activity-1'],
            ),
      );
      expect(repository.getStatsCalls, 1);
      expect(repository.getRecentActivitiesCalls, 1);

      await subscription.cancel();
    });

    test(
      'RefreshDashboardEvent emits refreshed data without loading state',
      () async {
        final emittedStates = <DashboardState>[];
        repository.getStatsHandler = () async =>
            const DashboardStats(activeTeams: 5, todayClocking: 11);
        repository.getRecentActivitiesHandler = () async => <RecentActivity>[
          RecentActivity(
            id: 'activity-2',
            title: 'Clock in',
            subtitle: 'Mario Rossi',
            type: RecentActivityType.clockIn,
            timestamp: DateTime(2026, 7, 22, 10, 30),
          ),
        ];
        final subscription = bloc.stream.listen(emittedStates.add);

        bloc.add(RefreshDashboardEvent());
        await pumpEventQueue(times: 20);

        expect(emittedStates, hasLength(1));
        expect(
          emittedStates.single,
          isA<DashboardLoaded>()
              .having((state) => state.stats.activeTeams, 'active teams', 5)
              .having((state) => state.stats.todayClocking, 'clocking', 11),
        );

        await subscription.cancel();
      },
    );

    test(
      'LoadDashboardEvent emits DashboardError when fetching stats fails',
      () async {
        final emittedStates = <DashboardState>[];

        repository.getStatsHandler = () =>
            Future<DashboardStats>.error(Exception('network down'));
        repository.getRecentActivitiesHandler = () async =>
            const <RecentActivity>[];
        final subscription = bloc.stream.listen(emittedStates.add);

        bloc.add(LoadDashboardEvent());
        await pumpEventQueue(times: 20);

        expect(emittedStates.first, isA<DashboardLoading>());
        expect(
          emittedStates.last,
          isA<DashboardError>().having(
            (state) => state.message,
            'error message',
            contains('network down'),
          ),
        );

        await subscription.cancel();
      },
    );
  });
}
