import 'package:note_sondage/feature/chat/domain/entities/chat_conversation_entity.dart';
import 'package:note_sondage/feature/chat/domain/entities/chat_direct_conversation_summary_entity.dart';
import 'package:note_sondage/feature/chat/domain/entities/chat_message_entity.dart';
import 'package:note_sondage/feature/chat/domain/entities/chat_message_reaction_entity.dart';
import 'package:note_sondage/feature/chat/domain/entities/chat_message_reply_entity.dart';
import 'package:note_sondage/feature/chat/domain/entities/chat_team_conversation_summary_entity.dart';

class ChatMapper {
  const ChatMapper._();

  static ChatConversationEntity conversationFromJson(
    Map<String, dynamic> json,
  ) {
    return ChatConversationEntity(
      id: json['id']?.toString() ?? '',
      teamId: json['teamId']?.toString() ?? '',
      type: json['type']?.toString() ?? 'TEAM',
      participantUserId: json['participantUserId']?.toString(),
      participantDisplayName: json['participantDisplayName']?.toString(),
      participantAvatarUrl: json['participantAvatarUrl']?.toString(),
      createdAt:
          DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
      updatedAt:
          DateTime.tryParse(json['updatedAt']?.toString() ?? '') ??
          DateTime.now(),
      lastMessageAt: DateTime.tryParse(json['lastMessageAt']?.toString() ?? ''),
    );
  }

  static ChatMessageEntity messageFromJson(Map<String, dynamic> json) {
    return ChatMessageEntity(
      id: json['id']?.toString() ?? '',
      conversationId: json['conversationId']?.toString() ?? '',
      senderUserId: json['senderUserId']?.toString() ?? '',
      senderName: json['senderName']?.toString() ?? '',
      senderAvatarUrl: json['senderAvatarUrl']?.toString(),
      contentText: json['contentText']?.toString() ?? '',
      messageType: json['messageType']?.toString() ?? 'TEXT',
      attachmentPath: json['attachmentPath']?.toString(),
      attachmentOriginalName: json['attachmentOriginalName']?.toString(),
      attachmentContentType: json['attachmentContentType']?.toString(),
      attachmentSizeBytes: _toInt(json['attachmentSizeBytes']),
      replyTo: replyFromJson(json['replyTo']),
      reactions: reactionsFromJson(json['reactions']),
      deleted: json['deleted'] == true,
      deletedAt: DateTime.tryParse(json['deletedAt']?.toString() ?? ''),
      createdAt:
          DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
      readByCurrentUser: json['readByCurrentUser'] == true,
      deliveredByOtherCount: _toInt(json['deliveredByOtherCount']) ?? 0,
      readByOtherCount: _toInt(json['readByOtherCount']) ?? 0,
      mine: json['mine'] == true,
    );
  }

  static ChatMessageReplyEntity? replyFromJson(dynamic json) {
    if (json is! Map<String, dynamic>) {
      return null;
    }
    return ChatMessageReplyEntity(
      messageId: json['messageId']?.toString() ?? '',
      senderName: json['senderName']?.toString() ?? '',
      contentPreview: json['contentPreview']?.toString() ?? '',
      messageType: json['messageType']?.toString() ?? 'TEXT',
      deleted: json['deleted'] == true,
    );
  }

  static List<ChatMessageReactionEntity> reactionsFromJson(dynamic json) {
    final items = json as List<dynamic>? ?? const <dynamic>[];
    return items.whereType<Map<String, dynamic>>().map((item) {
      return ChatMessageReactionEntity(
        emoji: item['emoji']?.toString() ?? '',
        count: _toInt(item['count']) ?? 0,
        mine: item['mine'] == true,
      );
    }).toList();
  }

  static ChatTeamConversationSummaryEntity summaryFromJson(
    Map<String, dynamic> json,
  ) {
    return ChatTeamConversationSummaryEntity(
      teamId: json['teamId']?.toString() ?? '',
      conversationId: json['conversationId']?.toString() ?? '',
      unreadCount: _toInt(json['unreadCount']) ?? 0,
      lastMessagePreview: json['lastMessagePreview']?.toString() ?? '',
      lastMessageType: json['lastMessageType']?.toString() ?? 'TEXT',
      lastMessageAt: DateTime.tryParse(json['lastMessageAt']?.toString() ?? ''),
    );
  }

  static ChatDirectConversationSummaryEntity directSummaryFromJson(
    Map<String, dynamic> json,
  ) {
    return ChatDirectConversationSummaryEntity(
      teamId: json['teamId']?.toString() ?? '',
      conversationId: json['conversationId']?.toString(),
      participantUserId: json['participantUserId']?.toString() ?? '',
      participantDisplayName: json['participantDisplayName']?.toString() ?? '',
      participantAvatarUrl: json['participantAvatarUrl']?.toString(),
      unreadCount: _toInt(json['unreadCount']) ?? 0,
      lastMessagePreview: json['lastMessagePreview']?.toString() ?? '',
      lastMessageType: json['lastMessageType']?.toString() ?? 'TEXT',
      lastMessageAt: DateTime.tryParse(json['lastMessageAt']?.toString() ?? ''),
    );
  }

  static int? _toInt(Object? value) {
    if (value is int) {
      return value;
    }
    return int.tryParse(value?.toString() ?? '');
  }
}
