import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:note_sondage/core/config/routes.dart';
import 'package:note_sondage/core/tutorial/app_tutorial_controller.dart';
import 'package:note_sondage/feature/auth/ui/bloc/auth_bloc.dart';
import 'package:note_sondage/feature/chat/ui/widgets/chat_back_button.dart';
import 'package:note_sondage/feature/chat/ui/widgets/team_chat_screen.dart';
import 'package:note_sondage/feature/team/ui/bloc/team/team_bloc.dart';
import 'package:note_sondage/core/tutorial/debug_showcase.dart';
import 'package:note_sondage/languages/l10n/app_localizations.dart';
import 'package:note_sondage/theme/extensions/color_scheme/color_scheme.dart';

class ChatWebConversationPage extends StatefulWidget {
  const ChatWebConversationPage({
    super.key,
    required this.teamId,
    this.memberUserId,
    this.memberName,
    this.focusLatestOnOpen = false,
  });

  final String teamId;
  final String? memberUserId;
  final String? memberName;
  final bool focusLatestOnOpen;

  @override
  State<ChatWebConversationPage> createState() =>
      _ChatWebConversationPageState();
}

class _ChatWebConversationPageState extends State<ChatWebConversationPage> {
  final GlobalKey _headerKey = GlobalKey();
  final GlobalKey _timelineKey = GlobalKey();
  final GlobalKey _composerKey = GlobalKey();
  String? _conversationTitle;
  bool _tutorialScheduled = false;
  bool _tutorialContentReady = false;

  @override
  void dispose() {
    AppTutorialController.unregisterTutorial('web-chat-conversation');
    AppTutorialController.unregisterTutorial('web-main-6');
    super.dispose();
  }

  void _handleBack() {
    context.go(RouterPaths.chat);
  }

  void _handleTeamDeleted(String teamId) {
    if (teamId.trim() != widget.teamId.trim()) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _handleBack();
    });
  }

  void _handleConversationTitleChanged(String? title) {
    final normalizedTitle = title?.trim();
    if (_conversationTitle == normalizedTitle) {
      return;
    }
    setState(() {
      _conversationTitle = normalizedTitle;
    });
  }

  String _resolveTitle(AppLocalizations loc) {
    final routeTitle = widget.memberName?.trim();
    final resolvedTitle = _conversationTitle?.trim();
    if (resolvedTitle != null && resolvedTitle.isNotEmpty) {
      return resolvedTitle;
    }
    if (routeTitle != null && routeTitle.isNotEmpty) {
      return routeTitle;
    }
    return loc.chatTitle;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context)!;
    final colorScheme = theme.colorScheme;
    final hasDirectTarget = widget.memberName?.trim().isNotEmpty == true;
    if (_tutorialContentReady) {
      _registerTutorials(context);
    }

    return BlocListener<TeamBloc, TeamState>(
      listener: (context, state) {
        if (state is TeamDeleted) {
          _handleTeamDeleted(state.teamId);
        }
      },
      child: DecoratedBox(
        decoration: BoxDecoration(color: colorScheme.bgColor),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildShowcase(
                showcaseKey: _headerKey,
                title: _headerTitle(context),
                description: _headerDescription(context),
                child: Row(
                  children: [
                    ChatBackButton(onPressed: _handleBack),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _resolveTitle(loc),
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                hasDirectTarget
                    ? loc.chatReturnToChatList
                    : loc.chatReturnToTeamList,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 14),
              Expanded(
                child: TeamChatScreen(
                  initialTeamId: widget.teamId,
                  initialMemberUserId: widget.memberUserId,
                  focusLatestOnOpen: widget.focusLatestOnOpen,
                  layout: ChatScreenLayout.web,
                  showTeamHeader: false,
                  onConversationTitleChanged: _handleConversationTitleChanged,
                  onContentReady: _handleContentReady,
                  timelineShowcaseKey: _timelineKey,
                  timelineShowcaseTitle: _timelineTitle(context),
                  timelineShowcaseDescription: _timelineDescription(context),
                  composerShowcaseKey: _composerKey,
                  composerShowcaseTitle: _composerTitle(context),
                  composerShowcaseDescription: _composerDescription(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _registerTutorials(BuildContext context) {
    AppTutorialController.registerTargets(
      tutorialId: 'web-chat-conversation',
      keys: <GlobalKey>[_headerKey, _timelineKey, _composerKey],
    );
    AppTutorialController.registerReplayAction(
      tutorialId: 'web-chat-conversation',
      action: () => AppTutorialController.replay(
        context: context,
        keys: <GlobalKey>[_headerKey, _timelineKey, _composerKey],
      ),
    );
    AppTutorialController.registerReplayAction(
      tutorialId: 'web-main-6',
      action: () => AppTutorialController.replayRegistered(
        context: context,
        tutorialId: 'web-chat-conversation',
      ),
    );
  }

  void _handleContentReady() {
    if (!_tutorialContentReady && mounted) {
      setState(() {
        _tutorialContentReady = true;
      });
    }
    _scheduleTutorial();
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
      await AppTutorialController.showIfNeeded(
        context: context,
        tutorialId: 'web-chat-conversation',
        userId: context.read<AuthBloc>().state.user.uid,
        keys: <GlobalKey>[_headerKey, _timelineKey, _composerKey],
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

  String _headerTitle(BuildContext context) {
    if (_isItalian(context)) {
      return 'Intestazione chat';
    }
    return 'Chat header';
  }

  String _headerDescription(BuildContext context) {
    if (_isItalian(context)) {
      return 'Qui vedi la conversazione aperta e puoi tornare velocemente all\'elenco chat.';
    }
    return 'This header shows the open conversation and lets you quickly return to the chat list.';
  }

  String _timelineTitle(BuildContext context) {
    if (_isItalian(context)) {
      return 'Timeline messaggi';
    }
    return 'Message timeline';
  }

  String _timelineDescription(BuildContext context) {
    if (_isItalian(context)) {
      return 'Qui scorri i messaggi della conversazione, controlli reazioni e apri eventuali allegati.';
    }
    return 'Scroll through the conversation here, review reactions, and open any shared attachments.';
  }

  String _composerTitle(BuildContext context) {
    if (_isItalian(context)) {
      return 'Composer';
    }
    return 'Composer';
  }

  String _composerDescription(BuildContext context) {
    if (_isItalian(context)) {
      return 'Da questa area puoi scrivere, allegare documenti o immagini e inviare un nuovo messaggio.';
    }
    return 'From this area you can type, attach documents or images, and send a new message.';
  }

  bool _isItalian(BuildContext context) {
    return Localizations.localeOf(context).languageCode == 'it';
  }
}
