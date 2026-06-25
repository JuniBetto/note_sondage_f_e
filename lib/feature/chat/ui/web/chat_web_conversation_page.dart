import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:note_sondage/core/config/routes.dart';
import 'package:note_sondage/feature/chat/ui/widgets/chat_back_button.dart';
import 'package:note_sondage/feature/chat/ui/widgets/team_chat_screen.dart';
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
  String? _conversationTitle;

  void _handleBack() {
    context.go(RouterPaths.chat);
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

    return DecoratedBox(
      decoration: BoxDecoration(color: colorScheme.bgColor),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
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
              ),
            ),
          ],
        ),
      ),
    );
  }
}
