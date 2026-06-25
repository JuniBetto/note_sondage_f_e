import 'package:flutter/material.dart';
import 'package:note_sondage/feature/chat/domain/entities/chat_message_entity.dart';
import 'package:note_sondage/feature/chat/domain/entities/chat_message_reply_entity.dart';
import 'package:note_sondage/feature/chat/ui/widgets/chat_conversation_panel.dart';
import 'package:note_sondage/feature/chat/ui/widgets/chat_draft_attachment.dart';
import 'package:note_sondage/feature/chat/ui/widgets/chat_header_card.dart';
import 'package:note_sondage/feature/team/domain/entities/team_entity.dart';

class ChatMobileSection extends StatelessWidget {
  const ChatMobileSection({
    super.key,
    required this.headerDescription,
    required this.teams,
    required this.messages,
    required this.messageController,
    required this.scrollController,
    required this.loadingMessages,
    required this.refreshingMessages,
    required this.loadingOlderMessages,
    required this.hasMoreOlderMessages,
    required this.sending,
    required this.accentColor,
    required this.onPickImagePressed,
    required this.onPickDocumentPressed,
    required this.onClearAttachmentPressed,
    required this.onRefreshPressed,
    required this.onSendPressed,
    required this.onTeamChanged,
    this.onSenderPressed,
    this.onMessagePressed,
    this.onMessageLongPressed,
    this.onReplyRequested,
    this.onDeleteRequested,
    this.selectedAttachment,
    this.replyTarget,
    this.onClearReplyPressed,
    this.showTeamHeader = true,
    this.selectedTeamId,
    this.selectedTeamName,
  });

  final String headerDescription;
  final List<TeamEntity> teams;
  final List<ChatMessageEntity> messages;
  final TextEditingController messageController;
  final ScrollController scrollController;
  final bool loadingMessages;
  final bool refreshingMessages;
  final bool loadingOlderMessages;
  final bool hasMoreOlderMessages;
  final bool sending;
  final Color accentColor;
  final VoidCallback onPickImagePressed;
  final VoidCallback onPickDocumentPressed;
  final VoidCallback onClearAttachmentPressed;
  final VoidCallback onRefreshPressed;
  final VoidCallback onSendPressed;
  final ValueChanged<String> onTeamChanged;
  final ValueChanged<ChatMessageEntity>? onSenderPressed;
  final ValueChanged<ChatMessageEntity>? onMessagePressed;
  final ValueChanged<ChatMessageEntity>? onMessageLongPressed;
  final ValueChanged<ChatMessageEntity>? onReplyRequested;
  final ValueChanged<ChatMessageEntity>? onDeleteRequested;
  final ChatDraftAttachment? selectedAttachment;
  final ChatMessageReplyEntity? replyTarget;
  final VoidCallback? onClearReplyPressed;
  final bool showTeamHeader;
  final String? selectedTeamId;
  final String? selectedTeamName;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(0, 0, 0, showTeamHeader ? 12 : 0),
      child: Column(
        children: [
          if (showTeamHeader) ...[
            ChatHeaderCard(
              compact: true,
              isWide: false,
              headerDescription: headerDescription,
              selectedTeamId: selectedTeamId,
              teams: teams,
              onRefreshPressed: onRefreshPressed,
              onTeamChanged: onTeamChanged,
            ),
            const SizedBox(height: 12),
          ],
          Expanded(
            child: ChatConversationPanel(
              messages: messages,
              messageController: messageController,
              scrollController: scrollController,
              loadingMessages: loadingMessages,
              refreshingMessages: refreshingMessages,
              loadingOlderMessages: loadingOlderMessages,
              hasMoreOlderMessages: hasMoreOlderMessages,
              sending: sending,
              compact: true,
              accentColor: accentColor,
              selectedAttachment: selectedAttachment,
              selectedTeamName: selectedTeamName,
              onSenderPressed: onSenderPressed,
              onMessagePressed: onMessagePressed,
              onMessageLongPressed: onMessageLongPressed,
              onReplyRequested: onReplyRequested,
              onDeleteRequested: onDeleteRequested,
              replyTarget: replyTarget,
              onPickImagePressed: onPickImagePressed,
              onPickDocumentPressed: onPickDocumentPressed,
              onClearAttachmentPressed: onClearAttachmentPressed,
              onClearReplyPressed: onClearReplyPressed,
              onSendPressed: onSendPressed,
            ),
          ),
        ],
      ),
    );
  }
}
