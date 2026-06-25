import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:note_sondage/core/config/routes.dart';
import 'package:note_sondage/core/utils/app_error_message_resolver.dart';
import 'package:note_sondage/feature/chat/domain/entities/chat_direct_conversation_summary_entity.dart';
import 'package:note_sondage/feature/chat/domain/entities/chat_team_conversation_summary_entity.dart';
import 'package:note_sondage/feature/chat/domain/use_case/chat_use_case.dart';
import 'package:note_sondage/feature/chat/ui/widgets/chat_direct_list_card.dart';
import 'package:note_sondage/feature/chat/ui/widgets/chat_team_list_card.dart';
import 'package:note_sondage/feature/chat/ui/widgets/chat_theme.dart';
import 'package:note_sondage/feature/team/domain/entities/team_entity.dart';
import 'package:note_sondage/feature/team/domain/entities/team_member_entity.dart';
import 'package:note_sondage/feature/team/domain/use_case/team/team_use_case.dart';
import 'package:note_sondage/feature/team/domain/use_case/team_member/team_member_use_case.dart';
import 'package:note_sondage/languages/l10n/app_localizations.dart';
import 'package:note_sondage/theme/extensions/color_scheme/color_scheme.dart';
import 'package:note_sondage/ui/widgets/app_snackbar.dart';

class ChatMobileTeamListPage extends StatefulWidget {
  const ChatMobileTeamListPage({super.key, this.initialTeamId});

  final String? initialTeamId;

  @override
  State<ChatMobileTeamListPage> createState() => _ChatMobileTeamListPageState();
}

class _ChatMobileTeamListPageState extends State<ChatMobileTeamListPage> {
  final TeamUseCase _teamUseCase = GetIt.instance<TeamUseCase>();
  final TeamMemberUseCase _teamMemberUseCase =
      GetIt.instance<TeamMemberUseCase>();
  final ChatUseCase _chatUseCase = GetIt.instance<ChatUseCase>();

  List<TeamEntity> _teams = const <TeamEntity>[];
  Map<String, ChatTeamConversationSummaryEntity> _summaryByTeamId =
      const <String, ChatTeamConversationSummaryEntity>{};
  List<_DirectChatEntry> _directEntries = const <_DirectChatEntry>[];
  bool _loading = true;
  bool _didHandleInitialTeam = false;

  @override
  void initState() {
    super.initState();
    unawaited(_loadTeams());
  }

  Future<void> _loadTeams() async {
    try {
      final teams = await _teamUseCase.getAllTeams();
      if (!mounted) {
        return;
      }
      setState(() {
        _teams = teams;
        _loading = false;
      });
      await _loadConversationData();
      _handleInitialTeamIfNeeded();
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _loading = false;
      });
      AppSnackBar.showError(
        context,
        AppErrorMessageResolver.resolve(
          error,
          fallback: AppLocalizations.of(context)!.chatLoadTeamsError,
        ),
      );
    }
  }

  void _handleInitialTeamIfNeeded() {
    if (_didHandleInitialTeam) {
      return;
    }
    final initialTeamId = widget.initialTeamId?.trim();
    if (initialTeamId == null || initialTeamId.isEmpty) {
      _didHandleInitialTeam = true;
      return;
    }
    if (!_teams.any((team) => team.id == initialTeamId)) {
      _didHandleInitialTeam = true;
      return;
    }
    _didHandleInitialTeam = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _openTeamConversation(initialTeamId);
    });
  }

  Future<void> _loadConversationData() async {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
    final nextSummaries = <String, ChatTeamConversationSummaryEntity>{};
    final nextDirectEntries = <_DirectChatEntry>[];
    final nextTeams = <TeamEntity>[];

    for (final team in _teams) {
      final teamId = team.id;
      if (teamId == null || teamId.isEmpty) {
        nextTeams.add(team);
        continue;
      }

      try {
        final summary = await _chatUseCase.getTeamConversationSummary(teamId);
        nextSummaries[teamId] = summary;
      } catch (_) {
        final cached = _chatUseCase.getCachedTeamSummary(teamId);
        if (cached != null) {
          nextSummaries[teamId] = cached;
        }
      }

      List<TeamMemberEntity> members = const <TeamMemberEntity>[];
      try {
        members = await _teamMemberUseCase.getAllMembersByTeamId(teamId);
      } catch (_) {
        members = const <TeamMemberEntity>[];
      }
      final resolvedMembers = members
          .where((member) => (member.userId?.trim().isNotEmpty ?? false))
          .toList();

      nextTeams.add(
        TeamEntity(
          team.id,
          team.color,
          team.pendingInvitations,
          name: team.name,
          description: team.description,
          createdByUserId: team.createdByUserId,
          clockingRequired: team.clockingRequired,
          clockingReminderTime: team.clockingReminderTime,
          clockingMissingAlertTime: team.clockingMissingAlertTime,
          clockingOpenAlertTime: team.clockingOpenAlertTime,
          memberCount: resolvedMembers.length,
          createdAt: team.createdAt,
        ),
      );

      for (final member in resolvedMembers) {
        final memberUserId = member.userId?.trim() ?? '';
        if (memberUserId.isEmpty || memberUserId == currentUserId) {
          continue;
        }
        ChatDirectConversationSummaryEntity? summary;
        try {
          summary = await _chatUseCase.getDirectConversationSummary(
            teamId,
            memberUserId,
          );
        } catch (_) {
          summary = _chatUseCase.getCachedDirectSummary(teamId, memberUserId);
        }
        if (summary == null || !_hasExistingDirectConversation(summary)) {
          continue;
        }
        nextDirectEntries.add(
          _DirectChatEntry(team: team, member: member, summary: summary),
        );
      }
    }

    nextDirectEntries.sort((left, right) {
      final rightTime =
          right.summary?.lastMessageAt ??
          DateTime.fromMillisecondsSinceEpoch(0);
      final leftTime =
          left.summary?.lastMessageAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final dateComparison = rightTime.compareTo(leftTime);
      if (dateComparison != 0) {
        return dateComparison;
      }
      return left.displayName.toLowerCase().compareTo(
        right.displayName.toLowerCase(),
      );
    });

    if (!mounted) {
      return;
    }
    setState(() {
      _teams = nextTeams;
      _summaryByTeamId = nextSummaries;
      _directEntries = nextDirectEntries;
    });
  }

  Future<void> _openTeamConversation(String teamId) async {
    final path = Uri(
      path: RouterPaths.sondageChatConversation,
      queryParameters: <String, String>{'teamId': teamId},
    ).toString();
    await context.push(path);
    if (!mounted) {
      return;
    }
    await _loadConversationData();
  }

  Future<void> _openDirectConversation(_DirectChatEntry entry) async {
    final teamId = entry.team.id;
    final memberUserId = entry.member.userId?.trim();
    if (teamId == null ||
        teamId.isEmpty ||
        memberUserId == null ||
        memberUserId.isEmpty) {
      return;
    }
    final path = Uri(
      path: RouterPaths.sondageChatConversation,
      queryParameters: <String, String>{
        'teamId': teamId,
        'memberUserId': memberUserId,
        'memberName': entry.displayName,
      },
    ).toString();
    await context.push(path);
    if (!mounted) {
      return;
    }
    await _loadConversationData();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context)!;
    final colorScheme = theme.colorScheme;

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_teams.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Text(
            loc.chatNoTeamsAvailable,
            style: theme.textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.bgColor,
        borderRadius: BorderRadius.circular(24),
      ),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(4, 2, 4, 18),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 6, 8, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  loc.chatChooseConversation,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  loc.chatListDescriptionMobile,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          _SectionLabel(title: loc.chatTeamChannels),
          const SizedBox(height: 10),
          for (final team in _teams) ...[
            if (team.id != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: ChatTeamListCard(
                  team: team,
                  compact: true,
                  summary: _summaryByTeamId[team.id!],
                  memberCountOverride: team.memberCount,
                  onTap: () => _openTeamConversation(team.id!),
                ),
              ),
          ],
          const SizedBox(height: 8),
          _SectionLabel(title: loc.chatDirectChats),
          const SizedBox(height: 10),
          if (_directEntries.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
              child: Text(
                loc.chatNoDirectContacts,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          for (final entry in _directEntries)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: ChatDirectListCard(
                compact: true,
                title: entry.displayName,
                teamName: entry.team.name,
                preview: entry.summary?.lastMessagePreview,
                avatarUrl:
                    entry.summary?.participantAvatarUrl ??
                    entry.member.imageUrl,
                unreadCount: entry.summary?.unreadCount ?? 0,
                accentColor: ChatThemeTokens.resolveTeamAccentColor(
                  entry.team.color,
                  theme.colorScheme.primary,
                ),
                onTap: () => _openDirectConversation(entry),
              ),
            ),
        ],
      ),
    );
  }
}

bool _hasExistingDirectConversation(
  ChatDirectConversationSummaryEntity summary,
) {
  final conversationId = summary.conversationId?.trim() ?? '';
  return conversationId.isNotEmpty;
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, right: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w800,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

class _DirectChatEntry {
  const _DirectChatEntry({
    required this.team,
    required this.member,
    required this.summary,
  });

  final TeamEntity team;
  final TeamMemberEntity member;
  final ChatDirectConversationSummaryEntity? summary;

  String get displayName {
    final name = summary?.participantDisplayName.trim() ?? '';
    if (name.isNotEmpty) {
      return name;
    }
    final initialName = member.initialName?.trim() ?? '';
    if (initialName.isNotEmpty) {
      return initialName;
    }
    return member.userEmail;
  }
}
