import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:note_sondage/feature/home/domain/entities/dashboard_entity.dart';
import 'package:note_sondage/feature/home/domain/use_case/dashboard_use_case.dart';

part 'dashboard_event.dart';
part 'dashboard_state.dart';

class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  final DashboardUseCase dashboardUseCase;

  DashboardBloc({required this.dashboardUseCase}) : super(DashboardInitial()) {
    on<LoadDashboardEvent>(_onLoadDashboard);
    on<RefreshDashboardEvent>(_onRefreshDashboard);
  }

  Future<void> _onLoadDashboard(
    LoadDashboardEvent event,
    Emitter<DashboardState> emit,
  ) async {
    emit(DashboardLoading());
    try {
      final results = await Future.wait([
        dashboardUseCase.getStats(),
        dashboardUseCase.getRecentActivities(),
      ]);
      final stats = results[0] as DashboardStats;
      final activities = results[1] as List<RecentActivity>;
      emit(DashboardLoaded(stats: stats, activities: activities));
    } catch (e) {
      emit(DashboardError(e.toString()));
    }
  }

  Future<void> _onRefreshDashboard(
    RefreshDashboardEvent event,
    Emitter<DashboardState> emit,
  ) async {
    try {
      final results = await Future.wait([
        dashboardUseCase.getStats(),
        dashboardUseCase.getRecentActivities(),
      ]);
      final stats = results[0] as DashboardStats;
      final activities = results[1] as List<RecentActivity>;
      emit(DashboardLoaded(stats: stats, activities: activities));
    } catch (e) {
      emit(DashboardError(e.toString()));
    }
  }
}
