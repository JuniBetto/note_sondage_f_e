class ChatDirectConversationSummaryEntity {
  const ChatDirectConversationSummaryEntity({
    required this.teamId,
    required this.participantUserId,
    required this.participantDisplayName,
    required this.participantAvatarUrl,
    required this.unreadCount,
    required this.lastMessagePreview,
    required this.lastMessageType,
    this.conversationId,
    this.lastMessageAt,
  });

  final String teamId;
  final String? conversationId;
  final String participantUserId;
  final String participantDisplayName;
  final String? participantAvatarUrl;
  final int unreadCount;
  final String lastMessagePreview;
  final String lastMessageType;
  final DateTime? lastMessageAt;
}
