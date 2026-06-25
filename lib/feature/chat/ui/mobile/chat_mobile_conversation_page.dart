import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:note_sondage/core/config/routes.dart';
import 'package:note_sondage/feature/chat/ui/widgets/chat_back_button.dart';
import 'package:note_sondage/feature/chat/ui/widgets/team_chat_screen.dart';
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
  String? _conversationTitle;

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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context)!;
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: ChatBackButton(onPressed: _handleBack),
        centerTitle: true,
        title: Text(
          _resolveTitle(loc),
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
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
          ),
        ),
      ),
    );
  }
}
