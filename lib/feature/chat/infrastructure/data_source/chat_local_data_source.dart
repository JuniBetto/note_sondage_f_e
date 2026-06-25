import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:hive/hive.dart';
import 'package:note_sondage/feature/chat/domain/entities/chat_conversation_entity.dart';
import 'package:note_sondage/feature/chat/domain/entities/chat_direct_conversation_summary_entity.dart';
import 'package:note_sondage/feature/chat/domain/entities/chat_message_entity.dart';
import 'package:note_sondage/feature/chat/domain/entities/chat_message_reaction_entity.dart';
import 'package:note_sondage/feature/chat/domain/entities/chat_message_reply_entity.dart';
import 'package:note_sondage/feature/chat/domain/entities/chat_team_conversation_summary_entity.dart';

class ChatLocalDataSource {
  static const String _boxName = 'chat_cache_box';
  static const int _persistedMessagesLimit = 50;

  final Map<String, ChatConversationEntity> _conversationByTeamId =
      <String, ChatConversationEntity>{};
  final Map<String, ChatConversationEntity> _directConversationByKey =
      <String, ChatConversationEntity>{};
  final Map<String, List<ChatMessageEntity>> _messagesByConversationId =
      <String, List<ChatMessageEntity>>{};
  final Map<String, ChatTeamConversationSummaryEntity> _summaryByTeamId =
      <String, ChatTeamConversationSummaryEntity>{};
  final Map<String, ChatDirectConversationSummaryEntity> _directSummaryByKey =
      <String, ChatDirectConversationSummaryEntity>{};

  String? _hydratedScope;

  ChatConversationEntity? getConversationByTeamId(String teamId) {
    _ensureHydrated();
    return _conversationByTeamId[teamId];
  }

  ChatConversationEntity? getDirectConversation(
    String teamId,
    String memberUserId,
  ) {
    _ensureHydrated();
    return _directConversationByKey[_directKey(teamId, memberUserId)];
  }

  List<ChatMessageEntity> getMessages(String conversationId) {
    _ensureHydrated();
    return List<ChatMessageEntity>.unmodifiable(
      _messagesByConversationId[conversationId] ?? const <ChatMessageEntity>[],
    );
  }

  ChatTeamConversationSummaryEntity? getTeamSummary(String teamId) {
    _ensureHydrated();
    return _summaryByTeamId[teamId];
  }

  ChatDirectConversationSummaryEntity? getDirectSummary(
    String teamId,
    String memberUserId,
  ) {
    _ensureHydrated();
    return _directSummaryByKey[_directKey(teamId, memberUserId)];
  }

  Future<void> saveConversation(ChatConversationEntity conversation) async {
    _ensureHydrated();
    if (conversation.type.toUpperCase() == 'DIRECT' &&
        (conversation.participantUserId?.isNotEmpty ?? false)) {
      _directConversationByKey[_directKey(
            conversation.teamId,
            conversation.participantUserId!,
          )] =
          conversation;
    } else {
      _conversationByTeamId[conversation.teamId] = conversation;
    }
    await _persistConversations();
  }

  Future<void> saveSummary(ChatTeamConversationSummaryEntity summary) async {
    _ensureHydrated();
    _summaryByTeamId[summary.teamId] = summary;
    await _persistTeamSummaries();
  }

  Future<void> saveDirectSummary(
    ChatDirectConversationSummaryEntity summary,
  ) async {
    _ensureHydrated();
    _directSummaryByKey[_directKey(summary.teamId, summary.participantUserId)] =
        summary;
    await _persistDirectSummaries();
  }

  Future<void> saveMessages(
    String conversationId,
    List<ChatMessageEntity> messages,
  ) async {
    _ensureHydrated();
    final normalized = List<ChatMessageEntity>.of(messages)
      ..sort((left, right) => left.createdAt.compareTo(right.createdAt));
    _messagesByConversationId[conversationId] = normalized;
    await _persistMessages();
  }

  Future<void> upsertMessage(
    String conversationId,
    ChatMessageEntity message,
  ) async {
    _ensureHydrated();
    final current = List<ChatMessageEntity>.of(
      _messagesByConversationId[conversationId] ?? const <ChatMessageEntity>[],
    );
    final existingIndex = current.indexWhere((item) => item.id == message.id);

    if (existingIndex >= 0) {
      current[existingIndex] = message;
    } else {
      current.add(message);
    }

    current.sort((left, right) => left.createdAt.compareTo(right.createdAt));
    _messagesByConversationId[conversationId] = current;
    await _persistMessages();
  }

  void _ensureHydrated() {
    final scope = _scope();
    if (_hydratedScope == scope) {
      return;
    }

    _clearMemory();
    _hydratedScope = scope;

    if (!Hive.isBoxOpen(_boxName)) {
      return;
    }

    try {
      final box = Hive.box<String>(_boxName);
      _hydrateConversations(box.get(_conversationsKey(scope)));
      _hydrateDirectConversations(box.get(_directConversationsKey(scope)));
      _hydrateMessages(box.get(_messagesKey(scope)));
      _hydrateTeamSummaries(box.get(_teamSummariesKey(scope)));
      _hydrateDirectSummaries(box.get(_directSummariesKey(scope)));
    } catch (_) {
      _clearMemory();
    }
  }

  Future<Box<String>> _openBox() async {
    if (Hive.isBoxOpen(_boxName)) {
      return Hive.box<String>(_boxName);
    }
    return Hive.openBox<String>(_boxName);
  }

  Future<void> _persistConversations() async {
    final scope = _scope();
    final box = await _openBox();
    final payload = _conversationByTeamId.values
        .map(_conversationToMap)
        .toList(growable: false);
    await box.put(_conversationsKey(scope), jsonEncode(payload));
    final directPayload = _directConversationByKey.values
        .map(_conversationToMap)
        .toList(growable: false);
    await box.put(_directConversationsKey(scope), jsonEncode(directPayload));
  }

  Future<void> _persistTeamSummaries() async {
    final scope = _scope();
    final box = await _openBox();
    final payload = _summaryByTeamId.values
        .map(_teamSummaryToMap)
        .toList(growable: false);
    await box.put(_teamSummariesKey(scope), jsonEncode(payload));
  }

  Future<void> _persistDirectSummaries() async {
    final scope = _scope();
    final box = await _openBox();
    final payload = _directSummaryByKey.values
        .map(_directSummaryToMap)
        .toList(growable: false);
    await box.put(_directSummariesKey(scope), jsonEncode(payload));
  }

  Future<void> _persistMessages() async {
    final scope = _scope();
    final box = await _openBox();
    final payload = <String, dynamic>{
      for (final entry in _messagesByConversationId.entries)
        entry.key: _trimForPersistence(
          entry.value,
        ).map(_messageToMap).toList(growable: false),
    };
    await box.put(_messagesKey(scope), jsonEncode(payload));
  }

  List<ChatMessageEntity> _trimForPersistence(
    List<ChatMessageEntity> messages,
  ) {
    if (messages.length <= _persistedMessagesLimit) {
      return List<ChatMessageEntity>.of(messages);
    }
    return messages.sublist(messages.length - _persistedMessagesLimit);
  }

  void _hydrateConversations(String? raw) {
    final decoded = _decodeList(raw);
    for (final item in decoded) {
      final conversation = _conversationFromMap(item);
      _conversationByTeamId[conversation.teamId] = conversation;
    }
  }

  void _hydrateDirectConversations(String? raw) {
    final decoded = _decodeList(raw);
    for (final item in decoded) {
      final conversation = _conversationFromMap(item);
      final participantUserId = conversation.participantUserId;
      if (participantUserId == null || participantUserId.isEmpty) {
        continue;
      }
      _directConversationByKey[_directKey(
            conversation.teamId,
            participantUserId,
          )] =
          conversation;
    }
  }

  void _hydrateMessages(String? raw) {
    if (raw == null || raw.isEmpty) {
      return;
    }
    final decoded = jsonDecode(raw);
    if (decoded is! Map) {
      return;
    }
    for (final entry in decoded.entries) {
      final key = entry.key.toString();
      final value = entry.value;
      if (value is! List) {
        continue;
      }
      _messagesByConversationId[key] =
          value
              .whereType<Map>()
              .map((item) => _messageFromMap(_normalizeMap(item)))
              .toList()
            ..sort((left, right) => left.createdAt.compareTo(right.createdAt));
    }
  }

  void _hydrateTeamSummaries(String? raw) {
    final decoded = _decodeList(raw);
    for (final item in decoded) {
      final summary = _teamSummaryFromMap(item);
      _summaryByTeamId[summary.teamId] = summary;
    }
  }

  void _hydrateDirectSummaries(String? raw) {
    final decoded = _decodeList(raw);
    for (final item in decoded) {
      final summary = _directSummaryFromMap(item);
      _directSummaryByKey[_directKey(
            summary.teamId,
            summary.participantUserId,
          )] =
          summary;
    }
  }

  List<Map<String, dynamic>> _decodeList(String? raw) {
    if (raw == null || raw.isEmpty) {
      return const <Map<String, dynamic>>[];
    }
    final decoded = jsonDecode(raw);
    if (decoded is! List) {
      return const <Map<String, dynamic>>[];
    }
    return decoded.whereType<Map>().map(_normalizeMap).toList(growable: false);
  }

  Map<String, dynamic> _conversationToMap(ChatConversationEntity conversation) {
    return <String, dynamic>{
      'id': conversation.id,
      'teamId': conversation.teamId,
      'type': conversation.type,
      'createdAt': conversation.createdAt.toIso8601String(),
      'updatedAt': conversation.updatedAt.toIso8601String(),
      'participantUserId': conversation.participantUserId,
      'participantDisplayName': conversation.participantDisplayName,
      'participantAvatarUrl': conversation.participantAvatarUrl,
      'lastMessageAt': conversation.lastMessageAt?.toIso8601String(),
    };
  }

  ChatConversationEntity _conversationFromMap(Map<String, dynamic> map) {
    return ChatConversationEntity(
      id: map['id']?.toString() ?? '',
      teamId: map['teamId']?.toString() ?? '',
      type: map['type']?.toString() ?? 'TEAM',
      createdAt:
          DateTime.tryParse(map['createdAt']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      updatedAt:
          DateTime.tryParse(map['updatedAt']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      participantUserId: map['participantUserId']?.toString(),
      participantDisplayName: map['participantDisplayName']?.toString(),
      participantAvatarUrl: map['participantAvatarUrl']?.toString(),
      lastMessageAt: DateTime.tryParse(map['lastMessageAt']?.toString() ?? ''),
    );
  }

  Map<String, dynamic> _messageToMap(ChatMessageEntity message) {
    return <String, dynamic>{
      'id': message.id,
      'conversationId': message.conversationId,
      'senderUserId': message.senderUserId,
      'senderName': message.senderName,
      'senderAvatarUrl': message.senderAvatarUrl,
      'contentText': message.contentText,
      'messageType': message.messageType,
      'attachmentPath': message.attachmentPath,
      'attachmentOriginalName': message.attachmentOriginalName,
      'attachmentContentType': message.attachmentContentType,
      'attachmentSizeBytes': message.attachmentSizeBytes,
      'replyTo': message.replyTo == null ? null : _replyToMap(message.replyTo!),
      'reactions': message.reactions
          .map(_reactionToMap)
          .toList(growable: false),
      'deleted': message.deleted,
      'deletedAt': message.deletedAt?.toIso8601String(),
      'createdAt': message.createdAt.toIso8601String(),
      'readByCurrentUser': message.readByCurrentUser,
      'deliveredByOtherCount': message.deliveredByOtherCount,
      'readByOtherCount': message.readByOtherCount,
      'mine': message.mine,
    };
  }

  ChatMessageEntity _messageFromMap(Map<String, dynamic> map) {
    return ChatMessageEntity(
      id: map['id']?.toString() ?? '',
      conversationId: map['conversationId']?.toString() ?? '',
      senderUserId: map['senderUserId']?.toString() ?? '',
      senderName: map['senderName']?.toString() ?? '',
      senderAvatarUrl: map['senderAvatarUrl']?.toString(),
      contentText: map['contentText']?.toString() ?? '',
      messageType: map['messageType']?.toString() ?? 'TEXT',
      attachmentPath: map['attachmentPath']?.toString(),
      attachmentOriginalName: map['attachmentOriginalName']?.toString(),
      attachmentContentType: map['attachmentContentType']?.toString(),
      attachmentSizeBytes: (map['attachmentSizeBytes'] as num?)?.toInt(),
      replyTo: map['replyTo'] is Map
          ? _replyFromMap(_normalizeMap(map['replyTo'] as Map))
          : null,
      reactions: (map['reactions'] as List<dynamic>? ?? const <dynamic>[])
          .whereType<Map>()
          .map((item) => _reactionFromMap(_normalizeMap(item)))
          .toList(growable: false),
      deleted: map['deleted'] == true,
      deletedAt: DateTime.tryParse(map['deletedAt']?.toString() ?? ''),
      createdAt:
          DateTime.tryParse(map['createdAt']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      readByCurrentUser: map['readByCurrentUser'] == true,
      deliveredByOtherCount:
          (map['deliveredByOtherCount'] as num?)?.toInt() ?? 0,
      readByOtherCount: (map['readByOtherCount'] as num?)?.toInt() ?? 0,
      mine: map['mine'] == true,
    );
  }

  Map<String, dynamic> _replyToMap(ChatMessageReplyEntity reply) {
    return <String, dynamic>{
      'messageId': reply.messageId,
      'senderName': reply.senderName,
      'contentPreview': reply.contentPreview,
      'messageType': reply.messageType,
      'deleted': reply.deleted,
    };
  }

  ChatMessageReplyEntity _replyFromMap(Map<String, dynamic> map) {
    return ChatMessageReplyEntity(
      messageId: map['messageId']?.toString() ?? '',
      senderName: map['senderName']?.toString() ?? '',
      contentPreview: map['contentPreview']?.toString() ?? '',
      messageType: map['messageType']?.toString() ?? 'TEXT',
      deleted: map['deleted'] == true,
    );
  }

  Map<String, dynamic> _reactionToMap(ChatMessageReactionEntity reaction) {
    return <String, dynamic>{
      'emoji': reaction.emoji,
      'count': reaction.count,
      'mine': reaction.mine,
    };
  }

  ChatMessageReactionEntity _reactionFromMap(Map<String, dynamic> map) {
    return ChatMessageReactionEntity(
      emoji: map['emoji']?.toString() ?? '',
      count: (map['count'] as num?)?.toInt() ?? 0,
      mine: map['mine'] == true,
    );
  }

  Map<String, dynamic> _teamSummaryToMap(
    ChatTeamConversationSummaryEntity summary,
  ) {
    return <String, dynamic>{
      'teamId': summary.teamId,
      'conversationId': summary.conversationId,
      'unreadCount': summary.unreadCount,
      'lastMessagePreview': summary.lastMessagePreview,
      'lastMessageType': summary.lastMessageType,
      'lastMessageAt': summary.lastMessageAt?.toIso8601String(),
    };
  }

  ChatTeamConversationSummaryEntity _teamSummaryFromMap(
    Map<String, dynamic> map,
  ) {
    return ChatTeamConversationSummaryEntity(
      teamId: map['teamId']?.toString() ?? '',
      conversationId: map['conversationId']?.toString() ?? '',
      unreadCount: (map['unreadCount'] as num?)?.toInt() ?? 0,
      lastMessagePreview: map['lastMessagePreview']?.toString() ?? '',
      lastMessageType: map['lastMessageType']?.toString() ?? 'TEXT',
      lastMessageAt: DateTime.tryParse(map['lastMessageAt']?.toString() ?? ''),
    );
  }

  Map<String, dynamic> _directSummaryToMap(
    ChatDirectConversationSummaryEntity summary,
  ) {
    return <String, dynamic>{
      'teamId': summary.teamId,
      'conversationId': summary.conversationId,
      'participantUserId': summary.participantUserId,
      'participantDisplayName': summary.participantDisplayName,
      'participantAvatarUrl': summary.participantAvatarUrl,
      'unreadCount': summary.unreadCount,
      'lastMessagePreview': summary.lastMessagePreview,
      'lastMessageType': summary.lastMessageType,
      'lastMessageAt': summary.lastMessageAt?.toIso8601String(),
    };
  }

  ChatDirectConversationSummaryEntity _directSummaryFromMap(
    Map<String, dynamic> map,
  ) {
    return ChatDirectConversationSummaryEntity(
      teamId: map['teamId']?.toString() ?? '',
      conversationId: map['conversationId']?.toString(),
      participantUserId: map['participantUserId']?.toString() ?? '',
      participantDisplayName: map['participantDisplayName']?.toString() ?? '',
      participantAvatarUrl: map['participantAvatarUrl']?.toString(),
      unreadCount: (map['unreadCount'] as num?)?.toInt() ?? 0,
      lastMessagePreview: map['lastMessagePreview']?.toString() ?? '',
      lastMessageType: map['lastMessageType']?.toString() ?? 'TEXT',
      lastMessageAt: DateTime.tryParse(map['lastMessageAt']?.toString() ?? ''),
    );
  }

  Map<String, dynamic> _normalizeMap(Map<dynamic, dynamic> map) {
    return map.map((key, value) => MapEntry(key.toString(), value));
  }

  void _clearMemory() {
    _conversationByTeamId.clear();
    _directConversationByKey.clear();
    _messagesByConversationId.clear();
    _summaryByTeamId.clear();
    _directSummaryByKey.clear();
  }

  String _scope() {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null || userId.isEmpty) {
      return 'anonymous';
    }
    return userId;
  }

  String _conversationsKey(String scope) => 'conversations::$scope';
  String _directConversationsKey(String scope) =>
      'direct_conversations::$scope';
  String _messagesKey(String scope) => 'messages::$scope';
  String _teamSummariesKey(String scope) => 'team_summaries::$scope';
  String _directSummariesKey(String scope) => 'direct_summaries::$scope';

  String _directKey(String teamId, String memberUserId) =>
      '$teamId::$memberUserId';
}
