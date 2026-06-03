import 'package:note_sondage/feature/home/domain/entities/dashboard_entity.dart';
import 'package:note_sondage/feature/home/domain/repositories/dashboard_repository.dart';

class DashboardUseCase {
  final DashboardRepository repository;
  DashboardUseCase(this.repository);

  Future<DashboardStats> getStats() async {
    try {
      return await repository.getStats();
    } catch (e) {
      throw Exception('Failed to fetch dashboard stats: $e');
    }
  }

  Future<List<RecentActivity>> getRecentActivities() async {
    try {
      return await repository.getRecentActivities();
    } catch (e) {
      throw Exception('Failed to fetch recent activities: $e');
    }
  }
}
