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
import 'package:note_sondage/feature/chat/domain/entities/chat_team_conversation_summary_entity.dart';
import 'package:note_sondage/feature/chat/domain/use_case/chat_use_case.dart';
import 'package:note_sondage/feature/chat/ui/controllers/chat_list_controller.dart';
import 'package:note_sondage/feature/chat/ui/widgets/chat_direct_list_card.dart';
import 'package:note_sondage/feature/chat/ui/widgets/chat_team_list_card.dart';
import 'package:note_sondage/feature/chat/ui/widgets/chat_theme.dart';
import 'package:note_sondage/feature/team/domain/entities/team_entity.dart';
import 'package:note_sondage/feature/team/domain/use_case/team/team_use_case.dart';
import 'package:note_sondage/feature/team/domain/use_case/team_member/team_member_use_case.dart';
import 'package:note_sondage/feature/team/ui/bloc/team/team_bloc.dart';
import 'package:note_sondage/languages/l10n/app_localizations.dart';
import 'package:note_sondage/core/tutorial/debug_showcase.dart';
import 'package:note_sondage/ui/bloc/navigation_bloc/navigation_bloc.dart';
import 'package:note_sondage/ui/widgets/app_snackbar.dart';
import 'package:note_sondage/ui/widgets/scroll_overflow_hint.dart';

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

  static final _sessionCache = ChatListSessionCache();
  late final ChatListController _list;
  StreamSubscription<User?>? _authSubscription;
  List<TeamEntity> get _teams => _list.teams;
  Map<String, ChatTeamConversationSummaryEntity> get _summaryByTeamId =>
      _list.summaries;
  List<ChatDirectListEntry> get _directEntries => _list.directEntries;
  bool get _loading => _list.loading;
  bool _tutorialScheduled = false;

  @override
  void initState() {
    super.initState();
    _list = ChatListController(
      teamUseCase: _teamUseCase,
      memberUseCase: _teamMemberUseCase,
      chatUseCase: _chatUseCase,
      currentUserId: () => FirebaseAuth.instance.currentUser?.uid,
      sessionCache: _sessionCache,
    )..addListener(_onListChanged);
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen((user) {
      if (mounted && user?.uid != _list.userId) unawaited(_loadTeams());
    });
    unawaited(_loadTeams());
  }

  @override
  void dispose() {
    unawaited(_authSubscription?.cancel());
    _list.dispose();
    AppTutorialController.unregisterTutorial('web-chat-list');
    AppTutorialController.unregisterTutorial('web-main-$_chatNavIndex');
    super.dispose();
  }

  void _onListChanged() {
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _loadTeams() async {
    try {
      await _list.load();
    } catch (error) {
      if (!mounted) return;
      AppSnackBar.showError(
        context,
        AppErrorMessageResolver.resolve(
          error,
          fallback: AppLocalizations.of(context)!.chatLoadTeamsError,
        ),
      );
    }
  }

  void _openTeamConversation(String teamId) {
    final path = Uri(
      path: RouterPaths.chat,
      queryParameters: <String, String>{'teamId': teamId},
    ).toString();
    context.go(path);
  }

  void _openDirectConversation(ChatDirectListEntry entry) {
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
    final id = teamId.trim();
    if (id.isNotEmpty) _list.removeTeam(id);
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

                  return ScrollOverflowHint(
                    child: SingleChildScrollView(
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
                                          key: ValueKey(team.id),
                                          width: cardWidth,
                                          child: ChatTeamListCard(
                                            team: team,
                                            compact: false,
                                            summary: _summaryByTeamId[team.id!],
                                            memberCountOverride:
                                                team.memberCount,
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
                                          key: ValueKey((
                                            entry.team.id,
                                            entry.member.userId?.trim(),
                                          )),
                                          width: cardWidth,
                                          child: ChatDirectListCard(
                                            compact: false,
                                            title: entry.displayName,
                                            teamName: entry.team.name,
                                            preview: entry
                                                .summary
                                                .lastMessagePreview,
                                            avatarUrl:
                                                entry
                                                    .summary
                                                    .participantAvatarUrl ??
                                                entry.member.imageUrl,
                                            unreadCount:
                                                entry.summary.unreadCount,
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
    return AppLocalizations.of(context)!.tutorialChatOverviewTitle;
  }

  String _introDescription(BuildContext context) {
    return AppLocalizations.of(context)!.tutorialChatOverviewWebDescription;
  }

  String _teamChannelsTitle(BuildContext context) {
    return AppLocalizations.of(context)!.tutorialChatTeamChannelsTitle;
  }

  String _teamChannelsDescription(BuildContext context) {
    return AppLocalizations.of(context)!.tutorialChatTeamChannelsWebDescription;
  }

  String _directChatsTitle(BuildContext context) {
    return AppLocalizations.of(context)!.tutorialChatDirectChatsTitle;
  }

  String _directChatsDescription(BuildContext context) {
    return AppLocalizations.of(context)!.tutorialChatDirectChatsWebDescription;
  }
}
