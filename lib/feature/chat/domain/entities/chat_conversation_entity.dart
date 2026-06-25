class ChatConversationEntity {
  const ChatConversationEntity({
    required this.id,
    required this.teamId,
    required this.type,
    required this.createdAt,
    required this.updatedAt,
    this.participantUserId,
    this.participantDisplayName,
    this.participantAvatarUrl,
    this.lastMessageAt,
  });

  final String id;
  final String teamId;
  final String type;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? participantUserId;
  final String? participantDisplayName;
  final String? participantAvatarUrl;
  final DateTime? lastMessageAt;
}
