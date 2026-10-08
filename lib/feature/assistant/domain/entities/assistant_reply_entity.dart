class AssistantReplyEntity {
  const AssistantReplyEntity({
    required this.conversationId,
    required this.reply,
    required this.executedTools,
  });

  final String conversationId;
  final String reply;

  /// Nomi degli strumenti eseguiti con successo dal server in questo turno
  /// (es. `create_team`): servono a capire quali pagine sono cambiate.
  final List<String> executedTools;
}
