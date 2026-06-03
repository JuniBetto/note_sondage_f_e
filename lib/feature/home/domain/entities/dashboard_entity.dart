/// Entità per le statistiche della dashboard
class DashboardStats {
  final int activeTeams;
  final int totalMembers;
  final int activeSurveys;
  final int todayClocking;
  final int todayShifts;
  final int completedSurveys;
  final int pendingInvitations;

  const DashboardStats({
    this.activeTeams = 0,
    this.totalMembers = 0,
    this.activeSurveys = 0,
    this.todayClocking = 0,
    this.todayShifts = 0,
    this.completedSurveys = 0,
    this.pendingInvitations = 0,
  });

  DashboardStats copyWith({
    int? activeTeams,
    int? totalMembers,
    int? activeSurveys,
    int? todayClocking,
    int? todayShifts,
    int? completedSurveys,
    int? pendingInvitations,
  }) {
    return DashboardStats(
      activeTeams: activeTeams ?? this.activeTeams,
      totalMembers: totalMembers ?? this.totalMembers,
      activeSurveys: activeSurveys ?? this.activeSurveys,
      todayClocking: todayClocking ?? this.todayClocking,
      todayShifts: todayShifts ?? this.todayShifts,
      completedSurveys: completedSurveys ?? this.completedSurveys,
      pendingInvitations: pendingInvitations ?? this.pendingInvitations,
    );
  }
}

/// Entità per un'attività recente nella dashboard
class RecentActivity {
  final String id;
  final String title;
  final String subtitle;
  final RecentActivityType type;
  final DateTime timestamp;

  const RecentActivity({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.type,
    required this.timestamp,
  });
}

enum RecentActivityType {
  teamCreated,
  memberJoined,
  sondageCreated,
  sondageCompleted,
  clockIn,
  clockOut,
  shiftAssigned,
}
