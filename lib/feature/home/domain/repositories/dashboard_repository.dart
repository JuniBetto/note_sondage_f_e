import 'package:note_sondage/feature/home/domain/entities/dashboard_entity.dart';

abstract class DashboardRepository {
  Future<DashboardStats> getStats();
  Future<List<RecentActivity>> getRecentActivities();
}
