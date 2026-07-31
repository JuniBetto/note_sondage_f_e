import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:note_sondage/core/config/routes.dart';
import 'package:note_sondage/core/tutorial/app_tutorial_controller.dart';
import 'package:note_sondage/core/utils/app_error_message_resolver.dart';
import 'package:note_sondage/feature/auth/ui/bloc/auth_bloc.dart';
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
import 'package:note_sondage/feature/team/ui/bloc/team/team_bloc.dart';
import 'package:note_sondage/languages/l10n/app_localizations.dart';
import 'package:note_sondage/core/tutorial/debug_showcase.dart';
import 'package:note_sondage/theme/extensions/color_scheme/color_scheme.dart';
import 'package:note_sondage/ui/widgets/app_snackbar.dart';

class ChatMobileTeamListPage extends StatefulWidget {
  const ChatMobileTeamListPage({
    super.key,
    this.initialTeamId,
    this.isActive = false,
  });

  final String? initialTeamId;
  final bool isActive;

  @override
  State<ChatMobileTeamListPage> createState() => _ChatMobileTeamListPageState();
}

class _ChatMobileTeamListPageState extends State<ChatMobileTeamListPage> {
  final GlobalKey _introKey = GlobalKey();
  final GlobalKey _teamChannelsKey = GlobalKey();
  final GlobalKey _directChatsKey = GlobalKey();
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
  bool _tutorialScheduled = false;

  @override
  void initState() {
    super.initState();
    unawaited(_loadTeams());
  }

  @override
  void didUpdateWidget(covariant ChatMobileTeamListPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _scheduleTutorial();
    }
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
          clockingRequiredStartDate: team.clockingRequiredStartDate,
          clockingRequiredEndDate: team.clockingRequiredEndDate,
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
        if (summary == null ||
            !_matchesRequestedDirectParticipant(summary, memberUserId) ||
            !_hasExistingDirectConversation(summary)) {
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

  void _handleTeamDeleted(String teamId) {
    final normalizedTeamId = teamId.trim();
    if (normalizedTeamId.isEmpty) {
      return;
    }
    final nextTeams = _teams
        .where((team) => team.id?.trim() != normalizedTeamId)
        .toList();
    final nextDirectEntries = _directEntries
        .where((entry) => entry.team.id?.trim() != normalizedTeamId)
        .toList();
    final hadSummary = _summaryByTeamId.containsKey(normalizedTeamId);
    if (nextTeams.length == _teams.length &&
        nextDirectEntries.length == _directEntries.length &&
        !hadSummary) {
      return;
    }
    final nextSummaries = Map<String, ChatTeamConversationSummaryEntity>.from(
      _summaryByTeamId,
    )..remove(normalizedTeamId);
    setState(() {
      _teams = nextTeams;
      _summaryByTeamId = nextSummaries;
      _directEntries = nextDirectEntries;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context)!;
    final colorScheme = theme.colorScheme;

    AppTutorialController.registerTargets(
      tutorialId: 'mobile-chat-list',
      keys: <GlobalKey>[_introKey, _teamChannelsKey, _directChatsKey],
    );
    AppTutorialController.registerReplayAction(
      tutorialId: 'mobile-chat-list',
      action: () => AppTutorialController.replay(
        context: context,
        keys: <GlobalKey>[_introKey, _teamChannelsKey, _directChatsKey],
      ),
    );

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

    if (widget.isActive) {
      _scheduleTutorial();
    }

    return BlocListener<TeamBloc, TeamState>(
      listener: (context, state) {
        if (state is TeamDeleted) {
          _handleTeamDeleted(state.teamId);
        }
      },
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colorScheme.bgColor,
          borderRadius: BorderRadius.circular(24),
        ),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(4, 2, 4, 18),
          children: [
            _buildShowcase(
              showcaseKey: _introKey,
              title: _introTitle(context),
              description: _introDescription(context),
              child: Padding(
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
            ),
            _buildShowcase(
              showcaseKey: _teamChannelsKey,
              title: _teamChannelsTitle(context),
              description: _teamChannelsDescription(context),
              child: Column(
                children: [
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
                ],
              ),
            ),
            const SizedBox(height: 8),
            _buildShowcase(
              showcaseKey: _directChatsKey,
              title: _directChatsTitle(context),
              description: _directChatsDescription(context),
              child: Column(
                children: [
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
            ),
          ],
        ),
      ),
    );
  }

  void _scheduleTutorial() {
    final initialTeamId = widget.initialTeamId?.trim();
    if (_tutorialScheduled ||
        !widget.isActive ||
        (initialTeamId != null && initialTeamId.isNotEmpty)) {
      return;
    }
    _tutorialScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted || !widget.isActive) {
        return;
      }
      await AppTutorialController.showIfNeeded(
        context: context,
        tutorialId: 'mobile-chat-list',
        userId: context.read<AuthBloc>().state.user.uid,
        keys: <GlobalKey>[_introKey, _teamChannelsKey, _directChatsKey],
      );
    });
  }

  Widget _buildShowcase({
    required GlobalKey showcaseKey,
    required String title,
    required String description,
    required Widget child,
  }) {
    if (isInspectorSelectionActive) {
      return child;
    }

    return Showcase(
      key: showcaseKey,
      title: title,
      description: description,
      child: child,
    );
  }

  String _introTitle(BuildContext context) {
    if (_isItalian(context)) {
      return 'Panoramica chat';
    }
    return 'Chat overview';
  }

  String _introDescription(BuildContext context) {
    if (_isItalian(context)) {
      return 'Da qui scegli rapidamente quale conversazione aprire tra canali del team e chat dirette.';
    }
    return 'Start here to quickly choose which conversation to open between team channels and direct chats.';
  }

  String _teamChannelsTitle(BuildContext context) {
    if (_isItalian(context)) {
      return 'Canali del team';
    }
    return 'Team channels';
  }

  String _teamChannelsDescription(BuildContext context) {
    if (_isItalian(context)) {
      return 'Questa sezione raccoglie le conversazioni condivise dei tuoi team con stato e messaggi recenti.';
    }
    return 'This section gathers your shared team conversations with status and recent message previews.';
  }

  String _directChatsTitle(BuildContext context) {
    if (_isItalian(context)) {
      return 'Chat dirette';
    }
    return 'Direct chats';
  }

  String _directChatsDescription(BuildContext context) {
    if (_isItalian(context)) {
      return 'Qui trovi le conversazioni private già avviate con i membri dei tuoi team.';
    }
    return 'Here you can reopen private conversations already started with members of your teams.';
  }

  bool _isItalian(BuildContext context) {
    return Localizations.localeOf(context).languageCode == 'it';
  }
}

bool _hasExistingDirectConversation(
  ChatDirectConversationSummaryEntity summary,
) {
  final conversationId = summary.conversationId?.trim() ?? '';
  return conversationId.isNotEmpty;
}

bool _matchesRequestedDirectParticipant(
  ChatDirectConversationSummaryEntity summary,
  String memberUserId,
) {
  return summary.participantUserId.trim() == memberUserId.trim();
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
