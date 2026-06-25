class ChatMessageReplyEntity {
  const ChatMessageReplyEntity({
    required this.messageId,
    required this.senderName,
    required this.contentPreview,
    required this.messageType,
    required this.deleted,
  });

  final String messageId;
  final String senderName;
  final String contentPreview;
  final String messageType;
  final bool deleted;
}
