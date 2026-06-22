import 'package:flutter/material.dart';
import 'package:note_sondage/feature/chat/ui/web/chat_web_conversation_page.dart';
import 'package:note_sondage/feature/chat/ui/web/chat_web_team_list_page.dart';

class ChatWebPage extends StatelessWidget {
  const ChatWebPage({
    super.key,
    this.initialTeamId,
    this.initialMemberUserId,
    this.initialMemberName,
    this.focusLatestOnOpen = false,
  });

  final String? initialTeamId;
  final String? initialMemberUserId;
  final String? initialMemberName;
  final bool focusLatestOnOpen;

  @override
  Widget build(BuildContext context) {
    final teamId = initialTeamId?.trim();
    final memberUserId = initialMemberUserId?.trim();
    if (teamId == null || teamId.isEmpty) {
      return const ChatWebTeamListPage();
    }
    return ChatWebConversationPage(
      teamId: teamId,
      memberUserId: memberUserId,
      memberName: initialMemberName,
      focusLatestOnOpen: focusLatestOnOpen,
    );
  }
}
