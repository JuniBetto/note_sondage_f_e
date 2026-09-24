import 'dart:async';
import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:note_sondage/feature/chat/domain/entities/chat_conversation_entity.dart';
import 'package:note_sondage/feature/chat/domain/entities/chat_direct_conversation_summary_entity.dart';
import 'package:note_sondage/feature/chat/domain/entities/chat_message_entity.dart';
import 'package:note_sondage/feature/chat/domain/entities/chat_message_reaction_entity.dart';
import 'package:note_sondage/feature/chat/domain/entities/chat_message_reply_entity.dart';
import 'package:note_sondage/feature/chat/domain/entities/chat_team_conversation_summary_entity.dart';

class ChatLocalDataSource {
  ChatLocalDataSource({HiveInterface? hive}) : _hive = hive ?? Hive;

  final HiveInterface _hive;
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
  bool _metadataHydrated = false;
  Map<String, dynamic>? _legacyMessages;
  bool _legacyMessagesLoaded = false;
  final Set<String> _migratingScopes = <String>{};
  Future<void> _cacheWrites = Future<void>.value();
  // Account-qualified snapshots remain readable across account switches until
  // successfully persisted. Failed writes retain the latest snapshot in memory.
  final Map<String, Object> _pendingCacheValues = <String, Object>{};

  String get cacheScope => _scope();

  /// Waits for writes already queued at the time of this call to settle.
  /// Errors are delivered to the individual save futures, not rethrown here.
  Future<void> flushPendingWrites() => _cacheWrites;

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
    _ensureMessagesHydrated(conversationId);
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
    await _persistMessages(conversationId, normalized);
  }

  Future<void> upsertMessage(
    String conversationId,
    ChatMessageEntity message,
  ) async {
    _ensureHydrated();
    if (!_ensureMessagesHydrated(conversationId)) {
      // Hive isn't open yet, so memory can't tell us what is already stored.
      // Publishing a one-message list (or writing it) would hide or replace
      // the persisted history: merge into the stored messages when the write
      // runs instead, and leave memory unset so the next read hydrates it.
      await _persistMessageUpsert(conversationId, message);
      return;
    }
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
    await _persistMessages(conversationId, current);
  }

  void _ensureHydrated() {
    final scope = _scope();
    if (_hydratedScope != scope) {
      _clearMemory();
      _hydratedScope = scope;
    }
    if (_metadataHydrated || !_hive.isBoxOpen(_boxName)) {
      return;
    }

    _metadataHydrated = true;
    try {
      final box = _hive.box<String>(_boxName);
      _hydrateConversations(_readCacheValue(box, _conversationsKey(scope)));
      _hydrateDirectConversations(
        _readCacheValue(box, _directConversationsKey(scope)),
      );
      _hydrateTeamSummaries(_readCacheValue(box, _teamSummariesKey(scope)));
      _hydrateDirectSummaries(_readCacheValue(box, _directSummariesKey(scope)));
    } catch (_) {
      _conversationByTeamId.clear();
      _directConversationByKey.clear();
      _summaryByTeamId.clear();
      _directSummaryByKey.clear();
    }
  }

  Future<Box<String>> _openBox() async {
    if (_hive.isBoxOpen(_boxName)) {
      return _hive.box<String>(_boxName);
    }
    return _hive.openBox<String>(_boxName);
  }

  Object? _readCacheValue(Box<String> box, String key) =>
      _pendingCacheValues[key] ?? box.get(key);

  Future<void> _writeCacheValue(
    Box<String> box,
    String key,
    Object payload,
  ) async {
    // Coalescing: if a newer snapshot for this key was queued meanwhile, its own
    // queue entry writes it, so encoding and writing this stale one is wasted
    // work (a burst of N summary saves would otherwise rewrite the whole list
    // N times). This save's future then completes without touching the disk.
    if (!identical(_pendingCacheValues[key], payload)) {
      return;
    }
    // Encoding and disk I/O run from the event queue, after the caller can use
    // the server response. Snapshots are detached before they are queued.
    await box.put(key, jsonEncode(payload));
    if (identical(_pendingCacheValues[key], payload)) {
      _pendingCacheValues.remove(key);
    }
  }

  Future<void> _persistValues(Map<String, Object> values) {
    _pendingCacheValues.addAll(values);
    return _enqueueCacheWrite(() async {
      final box = await _openBox();
      for (final entry in values.entries) {
        await _writeCacheValue(box, entry.key, entry.value);
      }
    });
  }

  Future<void> _persistConversations() {
    final scope = _scope();
    return _persistValues({
      _conversationsKey(scope): _conversationByTeamId.values
          .map(_conversationToMap)
          .toList(growable: false),
      _directConversationsKey(scope): _directConversationByKey.values
          .map(_conversationToMap)
          .toList(growable: false),
    });
  }

  Future<void> _persistTeamSummaries() {
    final scope = _scope();
    return _persistValues({
      _teamSummariesKey(scope): _summaryByTeamId.values
          .map(_teamSummaryToMap)
          .toList(growable: false),
    });
  }

  Future<void> _persistDirectSummaries() {
    final scope = _scope();
    return _persistValues({
      _directSummariesKey(scope): _directSummaryByKey.values
          .map(_directSummaryToMap)
          .toList(growable: false),
    });
  }

  Future<void> _persistMessages(
    String conversationId,
    List<ChatMessageEntity> messages,
  ) {
    final scope = _scope();
    final key = _conversationMessagesKey(scope, conversationId);
    // Copy maps (including reply/reaction data) now; JSON encoding is deferred.
    final payload = _trimForPersistence(
      messages,
    ).map(_messageToMap).toList(growable: false);
    _pendingCacheValues[key] = payload;
    return _enqueueCacheWrite(() async {
      final box = await _openBox();
      await _writeCacheValue(box, key, payload);
      try {
        await _migrateLegacyMessages(box, scope);
      } catch (error) {
        // Keep a successful fresh save even if unrelated legacy data is broken.
        debugPrint('Chat cache migration failed: ${error.runtimeType}');
      }
    });
  }

  Future<void> _persistMessageUpsert(
    String conversationId,
    ChatMessageEntity message,
  ) {
    final scope = _scope();
    final key = _conversationMessagesKey(scope, conversationId);
    final incoming = _messageToMap(message);
    return _enqueueCacheWrite(() async {
      final box = await _openBox();
      final merged = _mergeIntoStoredMessages(
        box,
        scope,
        conversationId,
        key,
        incoming,
      );
      await box.put(key, jsonEncode(merged));
      try {
        await _migrateLegacyMessages(box, scope);
      } catch (error) {
        debugPrint('Chat cache migration failed: ${error.runtimeType}');
      }
    });
  }

  List<Map<String, dynamic>> _mergeIntoStoredMessages(
    Box<String> box,
    String scope,
    String conversationId,
    String key,
    Map<String, dynamic> incoming,
  ) {
    var stored = <Map<String, dynamic>>[];
    try {
      final raw = _readCacheValue(box, key);
      final Object? value;
      if (raw != null) {
        value = raw is String ? jsonDecode(raw) : raw;
      } else {
        final legacyRaw = box.get(_messagesKey(scope));
        final legacy = legacyRaw == null ? null : jsonDecode(legacyRaw);
        value = legacy is Map ? legacy[conversationId] : null;
      }
      if (value is List && value.every((item) => item is Map)) {
        stored = value.cast<Map>().map(_normalizeMap).toList();
      }
    } catch (_) {
      // Unreadable stored history is treated as a miss, like a damaged read.
    }
    final index = stored.indexWhere((item) => item['id'] == incoming['id']);
    if (index >= 0) {
      stored[index] = incoming;
    } else {
      stored.add(incoming);
    }
    DateTime createdAt(Map<String, dynamic> item) =>
        DateTime.tryParse(item['createdAt']?.toString() ?? '') ??
        DateTime.fromMillisecondsSinceEpoch(0);
    stored.sort((left, right) => createdAt(left).compareTo(createdAt(right)));
    return stored.length <= _persistedMessagesLimit
        ? stored
        : stored.sublist(stored.length - _persistedMessagesLimit);
  }

  Future<void> _enqueueCacheWrite(Future<void> Function() operation) {
    final result = _cacheWrites.then((_) => Future<void>(operation));
    // A failed write must not poison subsequent writes or migration retries.
    _cacheWrites = result.then<void>(
      (_) {},
      onError: (Object _, StackTrace __) {},
    );
    return result;
  }

  /// Completes any legacy migration for the current account. Normal saves also
  /// await migration; cache reads schedule it without waiting for disk I/O.
  Future<void> migrateLegacyMessages() {
    final scope = _scope();
    return _enqueueCacheWrite(() async {
      final box = await _openBox();
      await _migrateLegacyMessages(box, scope);
    });
  }

  void _scheduleLegacyMigration(String scope) {
    if (!_migratingScopes.add(scope)) {
      return;
    }
    final migration = _enqueueCacheWrite(() async {
      final box = await _openBox();
      await _migrateLegacyMessages(box, scope);
    });
    unawaited(
      migration.then<void>(
        (_) {
          _migratingScopes.remove(scope);
        },
        onError: (Object error, StackTrace stackTrace) {
          _migratingScopes.remove(scope);
          // The legacy blob is retained so a future read/save can retry safely.
          debugPrint('Chat cache migration failed: ${error.runtimeType}');
        },
      ),
    );
  }

  Future<void> _migrateLegacyMessages(Box<String> box, String scope) async {
    final legacyKey = _messagesKey(scope);
    final raw = box.get(legacyKey);
    if (raw == null) {
      return;
    }
    final decoded = jsonDecode(raw);
    if (decoded is! Map) {
      throw const FormatException('Invalid legacy chat cache');
    }
    final payloads = <String, String>{};
    for (final entry in decoded.entries) {
      final key = _conversationMessagesKey(scope, entry.key.toString());
      // Includes an authoritative empty list; never resurrect older messages.
      if (box.containsKey(key)) {
        continue;
      }
      final value = entry.value;
      if (value is! List || value.any((item) => item is! Map)) {
        throw const FormatException('Invalid legacy messages');
      }
      // Preserve the original fields instead of expanding every legacy message
      // with nullable defaults (or dropping fields unknown to this version).
      final messages =
          value.cast<Map>().map((item) {
              final payload = _normalizeMap(item);
              return (
                payload: payload,
                createdAt: _messageFromMap(payload).createdAt,
              );
            }).toList()
            ..sort((left, right) => left.createdAt.compareTo(right.createdAt));
      final recent = messages.length <= _persistedMessagesLimit
          ? messages
          : messages.sublist(messages.length - _persistedMessagesLimit);
      payloads[key] = jsonEncode(
        recent.map((message) => message.payload).toList(),
      );
    }
    if (payloads.isNotEmpty) {
      await box.putAll(payloads);
    }
    await box.flush();
    // If copying/flushing fails or the process exits, the original survives.
    await box.delete(legacyKey);
    if (_hydratedScope == scope) {
      _legacyMessages = null;
      _legacyMessagesLoaded = true;
    }
    // Deleting a large blob only appends a tombstone in Hive. Compact once so
    // subsequent app starts do not read both the old and the new history.
    try {
      await box.compact();
    } catch (error) {
      // New entries are already durable; compaction is only a space optimization.
      debugPrint('Chat cache compaction failed: ${error.runtimeType}');
    }
  }

  /// Returns whether memory now holds this conversation's messages: false only
  /// while Hive is not open, when nothing can be said about the stored history.
  bool _ensureMessagesHydrated(String conversationId) {
    if (_messagesByConversationId.containsKey(conversationId)) {
      return true;
    }
    if (!_hive.isBoxOpen(_boxName)) {
      return false;
    }
    final scope = _hydratedScope!;
    final box = _hive.box<String>(_boxName);
    try {
      if (box.containsKey(_messagesKey(scope))) {
        _scheduleLegacyMigration(scope);
      }
      final raw = _readCacheValue(
        box,
        _conversationMessagesKey(scope, conversationId),
      );
      Object? value;
      if (raw != null) {
        value = raw is String ? jsonDecode(raw) : raw;
      } else {
        if (!_legacyMessagesLoaded) {
          final legacyRaw = box.get(_messagesKey(scope));
          if (legacyRaw != null) {
            final decoded = jsonDecode(legacyRaw);
            if (decoded is Map) {
              _legacyMessages = _normalizeMap(decoded);
            }
          }
          _legacyMessagesLoaded = true;
        }
        value = _legacyMessages?[conversationId];
      }
      _messagesByConversationId[conversationId] = value == null
          ? <ChatMessageEntity>[]
          : _messagesFromValue(value);
    } catch (_) {
      // A damaged chat must not hide metadata or other conversations.
      _messagesByConversationId[conversationId] = <ChatMessageEntity>[];
    }
    return true;
  }

  List<ChatMessageEntity> _messagesFromValue(Object? value) {
    if (value is! List || value.any((item) => item is! Map)) {
      throw const FormatException('Invalid cached messages');
    }
    return value
        .cast<Map>()
        .map((item) => _messageFromMap(_normalizeMap(item)))
        .toList()
      ..sort((left, right) => left.createdAt.compareTo(right.createdAt));
  }

  List<ChatMessageEntity> _trimForPersistence(
    List<ChatMessageEntity> messages,
  ) {
    if (messages.length <= _persistedMessagesLimit) {
      return List<ChatMessageEntity>.of(messages);
    }
    return messages.sublist(messages.length - _persistedMessagesLimit);
  }

  void _hydrateConversations(Object? raw) {
    final decoded = _decodeList(raw);
    for (final item in decoded) {
      final conversation = _conversationFromMap(item);
      _conversationByTeamId[conversation.teamId] = conversation;
    }
  }

  void _hydrateDirectConversations(Object? raw) {
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

  void _hydrateTeamSummaries(Object? raw) {
    final decoded = _decodeList(raw);
    for (final item in decoded) {
      final summary = _teamSummaryFromMap(item);
      _summaryByTeamId[summary.teamId] = summary;
    }
  }

  void _hydrateDirectSummaries(Object? raw) {
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

  List<Map<String, dynamic>> _decodeList(Object? raw) {
    if (raw == null || raw == '') {
      return const <Map<String, dynamic>>[];
    }
    final decoded = raw is String ? jsonDecode(raw) : raw;
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
    _metadataHydrated = false;
    _legacyMessages = null;
    _legacyMessagesLoaded = false;
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
  String _conversationMessagesKey(String scope, String conversationId) =>
      'messages_v2::${Uri.encodeComponent(scope)}::${Uri.encodeComponent(conversationId)}';
  String _teamSummariesKey(String scope) => 'team_summaries::$scope';
  String _directSummariesKey(String scope) => 'direct_summaries::$scope';

  String _directKey(String teamId, String memberUserId) =>
      '$teamId::$memberUserId';
}
