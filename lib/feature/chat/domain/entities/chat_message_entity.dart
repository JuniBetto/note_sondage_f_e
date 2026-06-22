import 'package:note_sondage/feature/chat/domain/entities/chat_message_reaction_entity.dart';
import 'package:note_sondage/feature/chat/domain/entities/chat_message_reply_entity.dart';

class ChatMessageEntity {
  const ChatMessageEntity({
    required this.id,
    required this.conversationId,
    required this.senderUserId,
    required this.senderName,
    required this.senderAvatarUrl,
    required this.contentText,
    required this.messageType,
    required this.attachmentPath,
    required this.attachmentOriginalName,
    required this.attachmentContentType,
    required this.attachmentSizeBytes,
    required this.replyTo,
    required this.reactions,
    required this.deleted,
    required this.deletedAt,
    required this.createdAt,
    required this.readByCurrentUser,
    this.deliveredByOtherCount = 0,
    this.readByOtherCount = 0,
    required this.mine,
  });

  final String id;
  final String conversationId;
  final String senderUserId;
  final String senderName;
  final String? senderAvatarUrl;
  final String contentText;
  final String messageType;
  final String? attachmentPath;
  final String? attachmentOriginalName;
  final String? attachmentContentType;
  final int? attachmentSizeBytes;
  final ChatMessageReplyEntity? replyTo;
  final List<ChatMessageReactionEntity> reactions;
  final bool deleted;
  final DateTime? deletedAt;
  final DateTime createdAt;
  final bool readByCurrentUser;
  final int deliveredByOtherCount;
  final int readByOtherCount;
  final bool mine;

  bool get hasAttachment =>
      attachmentPath != null && attachmentPath!.isNotEmpty;

  bool get hasTextContent => contentText.trim().isNotEmpty;

  bool get isImageAttachment =>
      messageType.toUpperCase() == 'IMAGE' && hasAttachment;

  bool get isFileAttachment =>
      messageType.toUpperCase() == 'FILE' && hasAttachment;

  bool get isDeliveredToOthers => deliveredByOtherCount > 0;

  bool get isReadByOthers => readByOtherCount > 0;

  bool get hasReply => replyTo != null;
}
