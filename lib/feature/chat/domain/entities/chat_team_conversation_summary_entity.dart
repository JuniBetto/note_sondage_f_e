class ChatTeamConversationSummaryEntity {
  const ChatTeamConversationSummaryEntity({
    required this.teamId,
    required this.conversationId,
    required this.unreadCount,
    required this.lastMessagePreview,
    required this.lastMessageType,
    required this.lastMessageAt,
  });

  final String teamId;
  final String conversationId;
  final int unreadCount;
  final String lastMessagePreview;
  final String lastMessageType;
  final DateTime? lastMessageAt;

  bool get hasUnread => unreadCount > 0;
}
