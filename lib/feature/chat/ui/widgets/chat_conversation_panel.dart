import 'package:flutter/material.dart';
import 'package:note_sondage/feature/chat/domain/entities/chat_message_entity.dart';
import 'package:note_sondage/feature/chat/domain/entities/chat_message_reply_entity.dart';
import 'package:note_sondage/feature/chat/ui/widgets/chat_composer.dart';
import 'package:note_sondage/feature/chat/ui/widgets/chat_draft_attachment.dart';
import 'package:note_sondage/feature/chat/ui/widgets/chat_message_timeline.dart';
import 'package:note_sondage/theme/extensions/color_scheme/color_scheme.dart';

class ChatConversationPanel extends StatelessWidget {
  const ChatConversationPanel({
    super.key,
    required this.messages,
    required this.messageController,
    required this.scrollController,
    required this.loadingMessages,
    required this.refreshingMessages,
    required this.loadingOlderMessages,
    required this.hasMoreOlderMessages,
    required this.sending,
    required this.compact,
    required this.accentColor,
    required this.onPickImagePressed,
    required this.onPickDocumentPressed,
    required this.onClearAttachmentPressed,
    required this.onSendPressed,
    this.selectedAttachment,
    this.selectedTeamName,
    this.onSenderPressed,
    this.onMessagePressed,
    this.onMessageLongPressed,
    this.onReplyRequested,
    this.onDeleteRequested,
    this.replyTarget,
    this.onClearReplyPressed,
  });

  final List<ChatMessageEntity> messages;
  final TextEditingController messageController;
  final ScrollController scrollController;
  final bool loadingMessages;
  final bool refreshingMessages;
  final bool loadingOlderMessages;
  final bool hasMoreOlderMessages;
  final bool sending;
  final bool compact;
  final Color accentColor;
  final VoidCallback onPickImagePressed;
  final VoidCallback onPickDocumentPressed;
  final VoidCallback onClearAttachmentPressed;
  final VoidCallback onSendPressed;
  final ChatDraftAttachment? selectedAttachment;
  final String? selectedTeamName;
  final ValueChanged<ChatMessageEntity>? onSenderPressed;
  final ValueChanged<ChatMessageEntity>? onMessagePressed;
  final ValueChanged<ChatMessageEntity>? onMessageLongPressed;
  final ValueChanged<ChatMessageEntity>? onReplyRequested;
  final ValueChanged<ChatMessageEntity>? onDeleteRequested;
  final ChatMessageReplyEntity? replyTarget;
  final VoidCallback? onClearReplyPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.bgColorNew,
        //borderRadius: BorderRadius.circular(compact ? 24 : 30),
        /* border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.32),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],*/
      ),
      child: Column(
        children: [
          if (refreshingMessages) const LinearProgressIndicator(minHeight: 2),
          Expanded(
            child: loadingMessages
                ? const Center(child: CircularProgressIndicator())
                : ChatMessageTimeline(
                    messages: messages,
                    scrollController: scrollController,
                    compact: compact,
                    accentColor: accentColor,
                    selectedTeamName: selectedTeamName,
                    loadingOlderMessages: loadingOlderMessages,
                    hasMoreOlderMessages: hasMoreOlderMessages,
                    onSenderPressed: onSenderPressed,
                    onMessagePressed: onMessagePressed,
                    onMessageLongPressed: onMessageLongPressed,
                    onReplyRequested: onReplyRequested,
                    onDeleteRequested: onDeleteRequested,
                  ),
          ),
          const Divider(height: 1),
          ChatComposer(
            messageController: messageController,
            compact: compact,
            sending: sending,
            accentColor: accentColor,
            selectedAttachment: selectedAttachment,
            replyTarget: replyTarget,
            onPickImagePressed: onPickImagePressed,
            onPickDocumentPressed: onPickDocumentPressed,
            onClearAttachmentPressed: onClearAttachmentPressed,
            onClearReplyPressed: onClearReplyPressed,
            onSendPressed: onSendPressed,
          ),
        ],
      ),
    );
  }
}
