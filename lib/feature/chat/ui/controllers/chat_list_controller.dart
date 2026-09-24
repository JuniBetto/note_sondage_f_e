import 'dart:async';
import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:note_sondage/feature/chat/domain/entities/chat_direct_conversation_summary_entity.dart';
import 'package:note_sondage/feature/chat/domain/entities/chat_team_conversation_summary_entity.dart';
import 'package:note_sondage/feature/chat/domain/use_case/chat_use_case.dart';
import 'package:note_sondage/feature/team/domain/entities/team_entity.dart';
import 'package:note_sondage/feature/team/domain/entities/team_member_entity.dart';
import 'package:note_sondage/feature/team/domain/use_case/team/team_use_case.dart';
import 'package:note_sondage/feature/team/domain/use_case/team_member/team_member_use_case.dart';

class ChatDirectListEntry {
  const ChatDirectListEntry({
    required this.team,
    required this.member,
    required this.summary,
  });
  final TeamEntity team;
  final TeamMemberEntity member;
  final ChatDirectConversationSummaryEntity summary;

  String get displayName {
    final name = summary.participantDisplayName.trim();
    if (name.isNotEmpty) return name;
    final initialName = member.initialName?.trim() ?? '';
    return initialName.isNotEmpty ? initialName : member.userEmail;
  }
}

/// Only the latest account's session is retained. Persistent summaries still
/// come from the account-scoped chat repository.
class ChatListSessionCache {
  String? _userId;
  List<TeamEntity>? _teams;
  Map<String, List<TeamMemberEntity>> _members = {};
}

class ChatListController extends ChangeNotifier {
  ChatListController({
    required this.teamUseCase,
    required this.memberUseCase,
    required this.chatUseCase,
    required this.currentUserId,
    required this.sessionCache,
  }) : userId = currentUserId() {
    if (sessionCache._userId == userId && sessionCache._teams != null) {
      teams = List.of(sessionCache._teams!);
      _members.addAll(sessionCache._members);
      loading = false;
      _seedSummaries();
      _publish();
    }
  }

  final TeamUseCase teamUseCase;
  final TeamMemberUseCase memberUseCase;
  final ChatUseCase chatUseCase;
  final String? Function() currentUserId;
  final ChatListSessionCache sessionCache;
  final _requests = _RequestPool(6);
  String? userId;
  List<TeamEntity> teams = const [];
  Map<String, ChatTeamConversationSummaryEntity> summaries = const {};
  List<ChatDirectListEntry> directEntries = const [];
  bool loading = true;
  final Map<String, List<TeamMemberEntity>> _members = {};
  final Map<(String, String), ChatDirectConversationSummaryEntity> _direct = {};
  final Set<String> _deletedTeams = {};
  int _generation = 0;
  int _teamGeneration = 0;
  bool _disposed = false;

  bool _current(int generation) =>
      !_disposed && generation == _generation && userId == currentUserId();

  bool _currentTeam(int generation, String id) =>
      _current(generation) && !_deletedTeams.contains(id);

  Future<void> load() async {
    ++_generation;
    final teamGeneration = ++_teamGeneration;
    bool currentLoad() =>
        !_disposed &&
        teamGeneration == _teamGeneration &&
        userId == currentUserId();
    if (userId != currentUserId()) {
      userId = currentUserId();
      teams = const [];
      summaries = const {};
      directEntries = const [];
      _members.clear();
      _direct.clear();
      _deletedTeams.clear();
      loading = true;
      sessionCache._teams = null;
      sessionCache._members = {};
      sessionCache._userId = userId;
      notifyListeners();
    }
    var remoteFinished = false;
    // Local teams and the remote request start together. A late disk read must
    // never replace an already received server list.
    unawaited(() async {
      try {
        final cached = await teamUseCase.getLocalTeams();
        if (currentLoad() &&
            !remoteFinished &&
            teams.isEmpty &&
            cached.isNotEmpty) {
          _replaceTeams(cached);
        }
      } catch (_) {
        /* Cache is best effort. */
      }
    }());
    try {
      final fresh = await _requests.run(
        () async => currentLoad() ? await teamUseCase.getAllTeams() : null,
      );
      remoteFinished = true;
      if (!currentLoad() || fresh == null) return;
      _replaceTeams(fresh);
      await _loadDetails(++_generation);
    } catch (_) {
      remoteFinished = true;
      if (!currentLoad()) return;
      loading = false;
      _publish();
      rethrow;
    }
  }

  Future<void> refreshDetails() => _loadDetails(++_generation);

  void removeTeam(String id) {
    _deletedTeams.add(id);
    teams = teams.where((team) => team.id != id).toList();
    _members.remove(id);
    summaries = Map.of(summaries)..remove(id);
    _direct.removeWhere((key, _) => key.$1 == id);
    _publish();
  }

  void _replaceTeams(List<TeamEntity> fresh) {
    teams = fresh.where((team) => !_deletedTeams.contains(team.id)).toList();
    final ids = teams.map((team) => team.id).toSet();
    _members.removeWhere((id, _) => !ids.contains(id));
    _direct.removeWhere((key, _) => !ids.contains(key.$1));
    summaries = Map.of(summaries)..removeWhere((id, _) => !ids.contains(id));
    loading = false;
    _seedSummaries();
    _publish();
  }

  void _seedSummaries() {
    for (final team in teams) {
      final id = team.id;
      if (id == null || id.isEmpty) continue;
      final cached = chatUseCase.getCachedTeamSummary(id);
      if (cached != null && cached.teamId == id) {
        summaries = {...summaries, id: cached};
      }
      for (final member in _members[id] ?? <TeamMemberEntity>[]) {
        final uid = member.userId?.trim() ?? '';
        if (uid.isEmpty || uid == userId) continue;
        final cached = chatUseCase.getCachedDirectSummary(id, uid);
        if (cached != null) _acceptDirect(id, uid, cached);
      }
    }
  }

  void _acceptDirect(
    String id,
    String uid,
    ChatDirectConversationSummaryEntity summary,
  ) {
    if (summary.teamId == id &&
        summary.participantUserId.trim() == uid &&
        (summary.conversationId?.trim().isNotEmpty ?? false)) {
      _direct[(id, uid)] = summary;
    } else {
      _direct.remove((id, uid));
    }
  }

  Future<void> _loadDetails(int generation) async {
    if (!_current(generation)) return;
    _seedSummaries();
    _publish();
    await Future.wait([
      for (final team in List<TeamEntity>.of(teams))
        if (team.id != null && team.id!.isNotEmpty) ...[
          _loadSummary(team.id!, generation),
          _loadMembers(team.id!, generation),
        ],
    ]);
  }

  Future<void> _loadSummary(String id, int generation) async {
    try {
      final summary = await _requests.run(
        () async => _currentTeam(generation, id)
            ? await chatUseCase.getTeamConversationSummary(id)
            : null,
      );
      if (!_currentTeam(generation, id) ||
          summary == null ||
          summary.teamId != id) {
        return;
      }
      summaries = {...summaries, id: summary};
      _publish();
    } catch (_) {
      /* Keep the cached summary; other rows continue. */
    }
  }

  Future<void> _loadMembers(String id, int generation) async {
    try {
      final members = await _requests.run(
        () async => _currentTeam(generation, id)
            ? await memberUseCase.getAllMembersByTeamId(id)
            : null,
      );
      if (!_currentTeam(generation, id) || members == null) return;
      // Preserve the previous count/entries on failure; only a successful empty
      // response is authoritative. Deduplicate direct-summary requests by UID.
      final resolved = <String, TeamMemberEntity>{
        for (final member in members)
          if (member.userId?.trim().isNotEmpty ?? false)
            member.userId!.trim(): member,
      };
      _members[id] = resolved.values.toList();
      _direct.removeWhere(
        (key, _) => key.$1 == id && !resolved.containsKey(key.$2),
      );
      for (final uid in resolved.keys.where((uid) => uid != userId)) {
        final cached = chatUseCase.getCachedDirectSummary(id, uid);
        if (cached != null) _acceptDirect(id, uid, cached);
      }
      _publish();
      await Future.wait([
        for (final uid in resolved.keys.where((uid) => uid != userId))
          _loadDirect(id, uid, generation),
      ]);
    } catch (_) {
      /* Preserve known members and allow other teams to load. */
    }
  }

  Future<void> _loadDirect(String id, String uid, int generation) async {
    try {
      final summary = await _requests.run(
        () async => _currentTeam(generation, id)
            ? await chatUseCase.getDirectConversationSummary(id, uid)
            : null,
      );
      if (!_currentTeam(generation, id) || summary == null) return;
      _acceptDirect(id, uid, summary);
      _publish();
    } catch (_) {
      /* Keep any cached direct summary. */
    }
  }

  void _publish() {
    if (_disposed || userId != currentUserId()) return;
    final epoch = DateTime.fromMillisecondsSinceEpoch(0);
    teams = List.unmodifiable(
      teams.map((team) {
        final members = _members[team.id];
        if (members == null) return team;
        return TeamEntity(
          team.id,
          team.color,
          team.pendingInvitations,
          name: team.name,
          description: team.description,
          createdByUserId: team.createdByUserId,
          createdAt: team.createdAt,
          memberCount: members.length,
          clockingRequired: team.clockingRequired,
          clockingRequiredStartDate: team.clockingRequiredStartDate,
          clockingRequiredEndDate: team.clockingRequiredEndDate,
          clockingReminderTime: team.clockingReminderTime,
          clockingMissingAlertTime: team.clockingMissingAlertTime,
          clockingOpenAlertTime: team.clockingOpenAlertTime,
          workflowAiEnabled: team.workflowAiEnabled,
          planningWorkerTypes: team.planningWorkerTypes,
        );
      }).toList()..sort((a, b) {
        final date = (summaries[b.id]?.lastMessageAt ?? epoch).compareTo(
          summaries[a.id]?.lastMessageAt ?? epoch,
        );
        return date != 0
            ? date
            : a.name.toLowerCase().compareTo(b.name.toLowerCase());
      }),
    );
    directEntries = List.unmodifiable(
      [
        for (final team in teams)
          for (final member in _members[team.id] ?? <TeamMemberEntity>[])
            if (_direct[(team.id, member.userId?.trim())] case final summary?)
              if (member.userId?.trim() != userId)
                ChatDirectListEntry(
                  team: team,
                  member: member,
                  summary: summary,
                ),
      ]..sort((a, b) {
        final date = (b.summary.lastMessageAt ?? epoch).compareTo(
          a.summary.lastMessageAt ?? epoch,
        );
        return date != 0
            ? date
            : a.displayName.toLowerCase().compareTo(
                b.displayName.toLowerCase(),
              );
      }),
    );
    sessionCache._userId = userId;
    sessionCache._teams = teams;
    sessionCache._members = Map.of(_members);
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _generation++;
    super.dispose();
  }
}

/// The same pool spans refresh generations, so overlapping refreshes cannot
/// multiply the request limit. Jobs check their generation before using HTTP.
class _RequestPool {
  _RequestPool(this.limit);
  final int limit;
  final _queue = Queue<Future<void> Function()>();
  int _active = 0;

  Future<T> run<T>(Future<T> Function() operation) {
    final result = Completer<T>();
    _queue.add(() async {
      try {
        result.complete(await operation());
      } catch (error, stack) {
        result.completeError(error, stack);
      } finally {
        _active--;
        _pump();
      }
    });
    _pump();
    return result.future;
  }

  void _pump() {
    while (_active < limit && _queue.isNotEmpty) {
      _active++;
      unawaited(_queue.removeFirst()());
    }
  }
}
