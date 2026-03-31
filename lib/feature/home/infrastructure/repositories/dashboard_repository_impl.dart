import 'package:note_sondage/feature/home/domain/entities/dashboard_entity.dart';
import 'package:note_sondage/feature/home/domain/repositories/dashboard_repository.dart';

/// Implementazione mock del DashboardRepository.
/// Restituisce dati fittizi — sostituire con chiamate API reali.
class DashboardRepositoryImpl implements DashboardRepository {
  @override
  Future<DashboardStats> getStats() async {
    // TODO: Sostituire con chiamata API reale
    await Future.delayed(const Duration(milliseconds: 300));
    return const DashboardStats(
      activeTeams: 4,
      totalMembers: 24,
      activeSurveys: 7,
      todayClocking: 18,
      completedSurveys: 3,
      pendingInvitations: 2,
    );
  }

  @override
  Future<List<RecentActivity>> getRecentActivities() async {
    // TODO: Sostituire con chiamata API reale
    await Future.delayed(const Duration(milliseconds: 300));
    final now = DateTime.now();
    return [
      RecentActivity(
        id: 'act-001',
        title: 'Marco Rossi clocked in',
        subtitle: 'Developer team — 09:00',
        type: RecentActivityType.clockIn,
        timestamp: now.subtract(const Duration(minutes: 30)),
      ),
      RecentActivity(
        id: 'act-002',
        title: 'New survey created',
        subtitle: 'Employee Satisfaction Survey 2026',
        type: RecentActivityType.sondageCreated,
        timestamp: now.subtract(const Duration(hours: 1)),
      ),
      RecentActivity(
        id: 'act-003',
        title: 'Laura Bianchi joined Developer',
        subtitle: 'Accepted team invitation',
        type: RecentActivityType.memberJoined,
        timestamp: now.subtract(const Duration(hours: 2)),
      ),
      RecentActivity(
        id: 'act-004',
        title: 'Product Feedback Q1 completed',
        subtitle: '128 responses collected',
        type: RecentActivityType.sondageCompleted,
        timestamp: now.subtract(const Duration(hours: 3)),
      ),
      RecentActivity(
        id: 'act-005',
        title: 'Mobile team created',
        subtitle: 'Created by Giuseppe Verdi',
        type: RecentActivityType.teamCreated,
        timestamp: now.subtract(const Duration(hours: 5)),
      ),
    ];
  }
}
