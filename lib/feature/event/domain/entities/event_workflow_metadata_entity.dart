class EventWorkflowMetadataEntity {
  const EventWorkflowMetadataEntity({
    this.contextType,
    this.contextId,
    this.sourceType,
    this.sourceId,
    this.sourceMessageId,
  });

  final String? contextType;
  final String? contextId;
  final String? sourceType;
  final String? sourceId;
  final String? sourceMessageId;
}
