class ChatDraftAttachment {
  const ChatDraftAttachment({
    required this.bytes,
    required this.fileName,
    required this.contentType,
    required this.sizeBytes,
  });

  final List<int> bytes;
  final String fileName;
  final String contentType;
  final int sizeBytes;

  bool get isImage => contentType.toLowerCase().startsWith('image/');
}
