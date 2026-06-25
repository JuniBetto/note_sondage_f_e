import 'package:note_sondage/feature/notification/realtime/realtime_notification_model.dart';

class TeamRealtimeCoordinator {
  static const Set<String> _managedEventTypes = {
    'TEAM_UPDATED',
    'TEAM_MEMBER_INVITED',
    'TEAM_MEMBER_JOINED',
    'TEAM_MEMBER_ROLE_UPDATED',
    'TEAM_MEMBER_REMOVED',
    'TEAM_INVITATION_CANCELLED',
    'TEAM_INVITATION_REJECTED',
    'TEAM_ROLE_CREATED',
    'TEAM_ROLE_UPDATED',
    'TEAM_ROLE_DELETED',
  };

  static const Set<String> _memberRefreshEventTypes = {
    'TEAM_UPDATED',
    'TEAM_MEMBER_INVITED',
    'TEAM_MEMBER_JOINED',
    'TEAM_MEMBER_ROLE_UPDATED',
    'TEAM_MEMBER_REMOVED',
    'TEAM_INVITATION_CANCELLED',
    'TEAM_INVITATION_REJECTED',
  };

  static const Set<String> _invitationRefreshEventTypes = {
    'TEAM_UPDATED',
    'TEAM_MEMBER_INVITED',
    'TEAM_MEMBER_JOINED',
    'TEAM_INVITATION_CANCELLED',
    'TEAM_INVITATION_REJECTED',
  };

  final Map<String, int> _activeTeamContexts = {};

  void activateTeamContext(String teamId) {
    if (teamId.isEmpty) return;
    _activeTeamContexts.update(teamId, (count) => count + 1, ifAbsent: () => 1);
  }

  void deactivateTeamContext(String teamId) {
    if (teamId.isEmpty) return;
    final currentCount = _activeTeamContexts[teamId];
    if (currentCount == null) return;
    if (currentCount <= 1) {
      _activeTeamContexts.remove(teamId);
      return;
    }
    _activeTeamContexts[teamId] = currentCount - 1;
  }

  bool isManagedTeamNotification(RealtimeNotification notification) {
    return notification.sourceService == 'team-service' &&
        _managedEventTypes.contains(notification.eventType);
  }

  TeamRealtimeGlobalDecision resolveGlobalDecision(
    RealtimeNotification notification, {
    required String currentUserId,
  }) {
    if (!isManagedTeamNotification(notification)) {
      return TeamRealtimeGlobalDecision.none;
    }

    final teamId = notification.metadata['teamId'] ?? '';
    final isTeamCurrentlyOpen =
        teamId.isNotEmpty && (_activeTeamContexts[teamId] ?? 0) > 0;

    return TeamRealtimeGlobalDecision(
      refreshTeams: true,
      refreshDashboard: true,
      teamIdToRemoveFromCache:
          _shouldLeaveCurrentTeam(notification, currentUserId: currentUserId)
          ? teamId
          : null,
      showSnackBar: !isTeamCurrentlyOpen,
      snackBarMessage: !isTeamCurrentlyOpen
          ? _buildSnackBarMessage(notification, currentUserId: currentUserId)
          : null,
    );
  }

  TeamRealtimeScreenDecision resolveScreenDecision(
    RealtimeNotification notification, {
    required String teamId,
    required String currentUserId,
  }) {
    if (!isManagedTeamNotification(notification)) {
      return TeamRealtimeScreenDecision.none;
    }

    if (notification.metadata['teamId'] != teamId) {
      return TeamRealtimeScreenDecision.none;
    }

    final shouldLeaveCurrentTeam = _shouldLeaveCurrentTeam(
      notification,
      currentUserId: currentUserId,
    );

    return TeamRealtimeScreenDecision(
      refreshTeam: true,
      refreshMembers: _memberRefreshEventTypes.contains(notification.eventType),
      refreshInvitations: _invitationRefreshEventTypes.contains(
        notification.eventType,
      ),
      shouldLeaveCurrentTeam: shouldLeaveCurrentTeam,
    );
  }

  bool _shouldLeaveCurrentTeam(
    RealtimeNotification notification, {
    required String currentUserId,
  }) {
    if (notification.eventType == 'TEAM_UPDATED' &&
        notification.metadata['deleted'] == 'true') {
      return true;
    }

    if (notification.eventType == 'TEAM_MEMBER_REMOVED' &&
        currentUserId.isNotEmpty &&
        notification.metadata['removedUserId'] == currentUserId) {
      return true;
    }

    return false;
  }

  String? _buildSnackBarMessage(
    RealtimeNotification notification, {
    required String currentUserId,
  }) {
    if (_shouldLeaveCurrentTeam(notification, currentUserId: currentUserId)) {
      if (notification.eventType == 'TEAM_MEMBER_REMOVED') {
        return 'Sei stato rimosso da un team.';
      }
      if (notification.metadata['deleted'] == 'true') {
        final teamName = notification.metadata['teamName'];
        if (teamName != null && teamName.isNotEmpty) {
          return "Il team '$teamName' è stato eliminato.";
        }
        return "Un team è stato eliminato.";
      }
    }

    final title = notification.title.trim();
    final body = notification.body.trim();

    if (title.isNotEmpty && body.isNotEmpty && body != title) {
      return '$title: $body';
    }

    if (title.isNotEmpty) return title;
    if (body.isNotEmpty) return body;
    return null;
  }
}

class TeamRealtimeGlobalDecision {
  final bool refreshTeams;
  final bool refreshDashboard;
  final String? teamIdToRemoveFromCache;
  final bool showSnackBar;
  final String? snackBarMessage;

  const TeamRealtimeGlobalDecision({
    this.refreshTeams = false,
    this.refreshDashboard = false,
    this.teamIdToRemoveFromCache,
    this.showSnackBar = false,
    this.snackBarMessage,
  });

  static const none = TeamRealtimeGlobalDecision();

  bool get hasWork =>
      refreshTeams ||
      refreshDashboard ||
      showSnackBar ||
      snackBarMessage != null;
}

class TeamRealtimeScreenDecision {
  final bool refreshTeam;
  final bool refreshMembers;
  final bool refreshInvitations;
  final bool shouldLeaveCurrentTeam;

  const TeamRealtimeScreenDecision({
    this.refreshTeam = false,
    this.refreshMembers = false,
    this.refreshInvitations = false,
    this.shouldLeaveCurrentTeam = false,
  });

  static const none = TeamRealtimeScreenDecision();

  bool get needsReload => refreshTeam || refreshMembers || refreshInvitations;
}
