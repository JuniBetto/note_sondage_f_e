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

class ChatMobileConversationPage extends StatefulWidget {
  const ChatMobileConversationPage({
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
  State<ChatMobileConversationPage> createState() =>
      _ChatMobileConversationPageState();
}

class _ChatMobileConversationPageState
    extends State<ChatMobileConversationPage> {
  final GlobalKey _headerKey = GlobalKey();
  final GlobalKey _timelineKey = GlobalKey();
  final GlobalKey _composerKey = GlobalKey();
  String? _conversationTitle;
  bool _tutorialScheduled = false;

  void _handleBack() {
    if (context.canPop()) {
      context.pop();
      return;
    }
    context.go(RouterPaths.sondageChat);
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context)!;
    final colorScheme = theme.colorScheme;

    AppTutorialController.registerTargets(
      tutorialId: 'mobile-chat-conversation',
      keys: <GlobalKey>[_headerKey, _timelineKey, _composerKey],
    );
    AppTutorialController.registerReplayAction(
      tutorialId: 'mobile-chat-conversation',
      action: () => AppTutorialController.replay(
        context: context,
        keys: <GlobalKey>[_headerKey, _timelineKey, _composerKey],
      ),
    );

    return BlocListener<TeamBloc, TeamState>(
      listener: (context, state) {
        if (state is TeamDeleted) {
          _handleTeamDeleted(state.teamId);
        }
      },
      child: Scaffold(
        backgroundColor: colorScheme.bgColor,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: ChatBackButton(onPressed: _handleBack),
          centerTitle: true,
          title: _buildShowcase(
            showcaseKey: _headerKey,
            title: _headerTitle(context),
            description: _headerDescription(context),
            child: Text(
              _resolveTitle(loc),
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          actions: [
            IconButton(
              tooltip: loc.reviewTutorial,
              onPressed: () => AppTutorialController.replayRegistered(
                context: context,
                tutorialId: 'mobile-chat-conversation',
              ),
              icon: const Icon(Icons.help_outline_rounded),
            ),
          ],
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: TeamChatScreen(
              initialTeamId: widget.teamId,
              initialMemberUserId: widget.memberUserId,
              focusLatestOnOpen: widget.focusLatestOnOpen,
              layout: ChatScreenLayout.mobile,
              showTeamHeader: false,
              onConversationTitleChanged: _handleConversationTitleChanged,
              onContentReady: _scheduleTutorial,
              timelineShowcaseKey: _timelineKey,
              timelineShowcaseTitle: _timelineTitle(context),
              timelineShowcaseDescription: _timelineDescription(context),
              composerShowcaseKey: _composerKey,
              composerShowcaseTitle: _composerTitle(context),
              composerShowcaseDescription: _composerDescription(context),
            ),
          ),
        ),
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
      await AppTutorialController.showIfNeeded(
        context: context,
        tutorialId: 'mobile-chat-conversation',
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
      return 'Qui vedi quale conversazione stai leggendo e puoi tornare rapidamente alla lista chat.';
    }
    return 'Here you can confirm which conversation is open and quickly return to the chat list.';
  }

  String _timelineTitle(BuildContext context) {
    if (_isItalian(context)) {
      return 'Messaggi';
    }
    return 'Messages';
  }

  String _timelineDescription(BuildContext context) {
    if (_isItalian(context)) {
      return 'In questa area scorri i messaggi, le reazioni e gli allegati della conversazione in ordine cronologico.';
    }
    return 'Scroll through messages, reactions, and attachments in chronological order in this area.';
  }

  String _composerTitle(BuildContext context) {
    if (_isItalian(context)) {
      return 'Scrivi un messaggio';
    }
    return 'Write a message';
  }

  String _composerDescription(BuildContext context) {
    if (_isItalian(context)) {
      return 'Usa questo composer per scrivere, allegare file o immagini e inviare rapidamente un nuovo messaggio.';
    }
    return 'Use this composer to type, attach files or images, and quickly send a new message.';
  }

  bool _isItalian(BuildContext context) {
    return Localizations.localeOf(context).languageCode == 'it';
  }
}
