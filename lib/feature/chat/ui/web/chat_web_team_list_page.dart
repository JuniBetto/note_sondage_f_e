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
import 'package:note_sondage/ui/bloc/navigation_bloc/navigation_bloc.dart';
import 'package:note_sondage/ui/widgets/app_snackbar.dart';

class ChatWebTeamListPage extends StatefulWidget {
  const ChatWebTeamListPage({super.key});

  @override
  State<ChatWebTeamListPage> createState() => _ChatWebTeamListPageState();
}

class _ChatWebTeamListPageState extends State<ChatWebTeamListPage> {
  // Deve restare allineato all'indice della Chat nell'IndexedStack di
  // MainWeb (vedi _pathToNavIndex in routes.dart e main_web.dart).
  static const int _chatNavIndex = 7;
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
  bool _tutorialScheduled = false;

  @override
  void initState() {
    super.initState();
    unawaited(_loadTeams());
  }

  @override
  void dispose() {
    AppTutorialController.unregisterTutorial('web-chat-list');
    AppTutorialController.unregisterTutorial('web-main-$_chatNavIndex');
    super.dispose();
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

  void _openTeamConversation(String teamId) {
    final path = Uri(
      path: RouterPaths.chat,
      queryParameters: <String, String>{'teamId': teamId},
    ).toString();
    context.go(path);
  }

  void _openDirectConversation(_DirectChatEntry entry) {
    final teamId = entry.team.id;
    final memberUserId = entry.member.userId?.trim();
    if (teamId == null ||
        teamId.isEmpty ||
        memberUserId == null ||
        memberUserId.isEmpty) {
      return;
    }
    final path = Uri(
      path: RouterPaths.chat,
      queryParameters: <String, String>{
        'teamId': teamId,
        'memberUserId': memberUserId,
        'memberName': entry.displayName,
      },
    ).toString();
    context.go(path);
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

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_teams.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            loc.chatNoTeamsAvailable,
            style: theme.textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final isChatTabActive =
        context.watch<NavigationBloc>().state == _chatNavIndex;
    _registerTutorials(context);
    if (isChatTabActive) {
      _scheduleTutorial();
    }

    return BlocListener<TeamBloc, TeamState>(
      listener: (context, state) {
        if (state is TeamDeleted) {
          _handleTeamDeleted(state.teamId);
        }
      },
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildShowcase(
              showcaseKey: _introKey,
              title: _introTitle(context),
              description: _introDescription(context),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    loc.chatChooseConversation,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    loc.chatListDescriptionWeb,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final cardWidth = constraints.maxWidth < 1120 ? 320.0 : 360.0;

                  return SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildShowcase(
                          showcaseKey: _teamChannelsKey,
                          title: _teamChannelsTitle(context),
                          description: _teamChannelsDescription(context),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                loc.chatTeamChannels,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Wrap(
                                spacing: 16,
                                runSpacing: 16,
                                children: [
                                  for (final team in _teams)
                                    if (team.id != null)
                                      SizedBox(
                                        width: cardWidth,
                                        child: ChatTeamListCard(
                                          team: team,
                                          compact: false,
                                          summary: _summaryByTeamId[team.id!],
                                          memberCountOverride: team.memberCount,
                                          onTap: () =>
                                              _openTeamConversation(team.id!),
                                        ),
                                      ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 28),
                        _buildShowcase(
                          showcaseKey: _directChatsKey,
                          title: _directChatsTitle(context),
                          description: _directChatsDescription(context),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                loc.chatDirectChats,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 16),
                              if (_directEntries.isEmpty)
                                Text(
                                  loc.chatNoDirectContacts,
                                  style: theme.textTheme.bodyLarge?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                )
                              else
                                Wrap(
                                  spacing: 16,
                                  runSpacing: 16,
                                  children: [
                                    for (final entry in _directEntries)
                                      SizedBox(
                                        width: cardWidth,
                                        child: ChatDirectListCard(
                                          compact: false,
                                          title: entry.displayName,
                                          teamName: entry.team.name,
                                          preview:
                                              entry.summary?.lastMessagePreview,
                                          avatarUrl:
                                              entry
                                                  .summary
                                                  ?.participantAvatarUrl ??
                                              entry.member.imageUrl,
                                          unreadCount:
                                              entry.summary?.unreadCount ?? 0,
                                          accentColor:
                                              ChatThemeTokens.resolveTeamAccentColor(
                                                entry.team.color,
                                                theme.colorScheme.primary,
                                              ),
                                          onTap: () =>
                                              _openDirectConversation(entry),
                                        ),
                                      ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _registerTutorials(BuildContext context) {
    AppTutorialController.registerTargets(
      tutorialId: 'web-chat-list',
      keys: <GlobalKey>[_introKey, _teamChannelsKey, _directChatsKey],
    );
    AppTutorialController.registerReplayAction(
      tutorialId: 'web-chat-list',
      action: () => AppTutorialController.replay(
        context: context,
        keys: <GlobalKey>[_introKey, _teamChannelsKey, _directChatsKey],
      ),
    );
    AppTutorialController.registerReplayAction(
      tutorialId: 'web-main-$_chatNavIndex',
      action: () => AppTutorialController.replayRegistered(
        context: context,
        tutorialId: 'web-chat-list',
      ),
    );
  }

  void _scheduleTutorial() {
    if (_tutorialScheduled) {
      return;
    }
    _tutorialScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) {
        return;
      }
      await WidgetsBinding.instance.endOfFrame;
      if (!mounted) {
        return;
      }
      // La Chat vive dentro l'IndexedStack di MainWeb ed è quindi montata
      // anche quando un'altra scheda è quella visibile: senza questo
      // controllo il tutorial partirebbe (e verrebbe segnato come "visto")
      // mentre l'utente sta ancora guardando un'altra pagina.
      if (context.read<NavigationBloc>().state != _chatNavIndex) {
        _tutorialScheduled = false;
        return;
      }
      await AppTutorialController.showIfNeeded(
        context: context,
        tutorialId: 'web-chat-list',
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
      return 'Da qui puoi scegliere una conversazione del team o riaprire una chat diretta già esistente.';
    }
    return 'Start here to choose a team conversation or reopen an existing direct chat.';
  }

  String _teamChannelsTitle(BuildContext context) {
    if (_isItalian(context)) {
      return 'Canali del team';
    }
    return 'Team channels';
  }

  String _teamChannelsDescription(BuildContext context) {
    if (_isItalian(context)) {
      return 'Queste card mostrano i canali condivisi dei team con riepilogo e accesso rapido alla conversazione.';
    }
    return 'These cards show your shared team channels with a summary and quick access to each conversation.';
  }

  String _directChatsTitle(BuildContext context) {
    if (_isItalian(context)) {
      return 'Chat dirette';
    }
    return 'Direct chats';
  }

  String _directChatsDescription(BuildContext context) {
    if (_isItalian(context)) {
      return 'Qui trovi le conversazioni private già avviate con altri membri del team.';
    }
    return 'Here you can reopen private conversations already started with other team members.';
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
