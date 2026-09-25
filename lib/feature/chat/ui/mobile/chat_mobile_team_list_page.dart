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
import 'package:note_sondage/feature/chat/ui/widgets/chat_slide_transition.dart';
import 'package:note_sondage/feature/chat/ui/widgets/chat_team_list_card.dart';
import 'package:note_sondage/feature/chat/ui/widgets/chat_theme.dart';
import 'package:note_sondage/feature/team/domain/entities/team_entity.dart';
import 'package:note_sondage/feature/team/domain/use_case/team/team_use_case.dart';
import 'package:note_sondage/feature/team/domain/use_case/team_member/team_member_use_case.dart';
import 'package:note_sondage/feature/team/ui/bloc/team/team_bloc.dart';
import 'package:note_sondage/languages/l10n/app_localizations.dart';
import 'package:note_sondage/core/tutorial/debug_showcase.dart';
import 'package:note_sondage/theme/extensions/color_scheme/color_scheme.dart';
import 'package:note_sondage/ui/widgets/app_snackbar.dart';
import 'package:note_sondage/ui/widgets/navigation_bar.dart';
import 'package:note_sondage/ui/widgets/scroll_overflow_hint.dart';

class ChatMobileTeamListPage extends StatefulWidget {
  const ChatMobileTeamListPage({
    super.key,
    this.initialTeamId,
    this.isActive = false,
    this.isTabTransitioning = false,
  });

  final String? initialTeamId;
  final bool isActive;

  /// True while the parent tab controller is still animating between tabs.
  ///
  /// The chat sub-tab is built eagerly (it's part of a plain [TabBarView]
  /// `children` list), so [isActive] can flip to true before the swipe
  /// settles. Starting the tutorial while still transitioning races with
  /// the tab-change listener that dismisses any active showcase, so the
  /// tutorial gets marked as "seen" moments after being killed and never
  /// shows again. We wait until the transition ends before auto-starting.
  final bool isTabTransitioning;

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

  static final _sessionCache = ChatListSessionCache();
  late final ChatListController _list;
  StreamSubscription<User?>? _authSubscription;
  List<TeamEntity> get _teams => _list.teams;
  Map<String, ChatTeamConversationSummaryEntity> get _summaryByTeamId =>
      _list.summaries;
  List<ChatDirectListEntry> get _directEntries => _list.directEntries;
  bool get _loading => _list.loading;
  bool _didHandleInitialTeam = false;
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
    AppTutorialController.unregisterTutorial('mobile-chat-list');
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant ChatMobileTeamListPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _scheduleTutorial();
    }
  }

  void _onListChanged() {
    if (!mounted) return;
    setState(() {});
    if (_teams.any((team) => team.id == widget.initialTeamId?.trim())) {
      _handleInitialTeamIfNeeded();
    }
  }

  Future<void> _loadTeams() async {
    try {
      await _list.load();
      if (mounted) _handleInitialTeamIfNeeded();
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

  Future<void> _loadConversationData() => _list.refreshDetails();

  Future<void> _openTeamConversation(String teamId) async {
    final path = Uri(
      path: RouterPaths.sondageChatConversation,
      queryParameters: <String, String>{'teamId': teamId},
    ).toString();
    await context.push(path, extra: chatSlideRouteExtra);
    if (!mounted) {
      return;
    }
    await _loadConversationData();
  }

  Future<void> _openDirectConversation(ChatDirectListEntry entry) async {
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
    await context.push(path, extra: chatSlideRouteExtra);
    if (!mounted) {
      return;
    }
    await _loadConversationData();
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
        child: ScrollOverflowHint(
          child: ListView(
            // The shell Scaffold uses extendBody: true for the floating nav
            // bar's frosted look, so without this the last card (and this
            // widget's own "more below" hint) end up rendered underneath it.
            padding: EdgeInsets.fromLTRB(
              4,
              2,
              4,
              18 + mobileNavBarBottomInset(context),
            ),
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
                          key: ValueKey(team.id),
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
                        key: ValueKey((
                          entry.team.id,
                          entry.member.userId?.trim(),
                        )),
                        padding: const EdgeInsets.only(bottom: 12),
                        child: ChatDirectListCard(
                          compact: true,
                          title: entry.displayName,
                          teamName: entry.team.name,
                          preview: entry.summary.lastMessagePreview,
                          avatarUrl:
                              entry.summary.participantAvatarUrl ??
                              entry.member.imageUrl,
                          unreadCount: entry.summary.unreadCount,
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
      ),
    );
  }

  void _scheduleTutorial() {
    final initialTeamId = widget.initialTeamId?.trim();
    if (_tutorialScheduled ||
        !widget.isActive ||
        widget.isTabTransitioning ||
        (initialTeamId != null && initialTeamId.isNotEmpty)) {
      return;
    }
    _tutorialScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted || !widget.isActive || widget.isTabTransitioning) {
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

    return appShowcase(
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
    return AppLocalizations.of(context)!.tutorialChatOverviewMobileDescription;
  }

  String _teamChannelsTitle(BuildContext context) {
    return AppLocalizations.of(context)!.tutorialChatTeamChannelsTitle;
  }

  String _teamChannelsDescription(BuildContext context) {
    return AppLocalizations.of(
      context,
    )!.tutorialChatTeamChannelsMobileDescription;
  }

  String _directChatsTitle(BuildContext context) {
    return AppLocalizations.of(context)!.tutorialChatDirectChatsTitle;
  }

  String _directChatsDescription(BuildContext context) {
    return AppLocalizations.of(
      context,
    )!.tutorialChatDirectChatsMobileDescription;
  }
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
