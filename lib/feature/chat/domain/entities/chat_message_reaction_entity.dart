class ChatMessageReactionEntity {
  const ChatMessageReactionEntity({
    required this.emoji,
    required this.count,
    required this.mine,
  });

  final String emoji;
  final int count;
  final bool mine;
}
