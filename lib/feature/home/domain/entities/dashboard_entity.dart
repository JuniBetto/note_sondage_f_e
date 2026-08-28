/// Entità per le statistiche della dashboard
class DashboardStats {
  final int activeTeams;
  final int totalMembers;
  final int activeSurveys;
  final int todayClocking;
  final int todayShifts;
  final int completedSurveys;
  final int pendingInvitations;
  final int myOpenTasks;
  final int unreadChatMessages;
  final int myEvents;

  const DashboardStats({
    this.activeTeams = 0,
    this.totalMembers = 0,
    this.activeSurveys = 0,
    this.todayClocking = 0,
    this.todayShifts = 0,
    this.completedSurveys = 0,
    this.pendingInvitations = 0,
    this.myOpenTasks = 0,
    this.unreadChatMessages = 0,
    this.myEvents = 0,
  });

  DashboardStats copyWith({
    int? activeTeams,
    int? totalMembers,
    int? activeSurveys,
    int? todayClocking,
    int? todayShifts,
    int? completedSurveys,
    int? pendingInvitations,
    int? myOpenTasks,
    int? unreadChatMessages,
    int? myEvents,
  }) {
    return DashboardStats(
      activeTeams: activeTeams ?? this.activeTeams,
      totalMembers: totalMembers ?? this.totalMembers,
      activeSurveys: activeSurveys ?? this.activeSurveys,
      todayClocking: todayClocking ?? this.todayClocking,
      todayShifts: todayShifts ?? this.todayShifts,
      completedSurveys: completedSurveys ?? this.completedSurveys,
      pendingInvitations: pendingInvitations ?? this.pendingInvitations,
      myOpenTasks: myOpenTasks ?? this.myOpenTasks,
      unreadChatMessages: unreadChatMessages ?? this.unreadChatMessages,
      myEvents: myEvents ?? this.myEvents,
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
  taskAssigned,
  chatMessage,
}
