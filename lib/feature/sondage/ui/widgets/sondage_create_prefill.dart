class SondageCreatePrefill {
  const SondageCreatePrefill({
    required this.question,
    required this.options,
    this.description,
    this.teamId,
    this.allowMultipleResponses = false,
    this.expiryDate,
    this.contextType,
    this.contextId,
    this.sourceType,
    this.sourceId,
    this.sourceMessageId,
  });

  final String question;
  final String? description;
  final String? teamId;
  final List<String> options;
  final bool allowMultipleResponses;
  final DateTime? expiryDate;
  final String? contextType;
  final String? contextId;
  final String? sourceType;
  final String? sourceId;
  final String? sourceMessageId;
}
