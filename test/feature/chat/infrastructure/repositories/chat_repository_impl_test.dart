import 'package:flutter_test/flutter_test.dart';
import 'package:note_sondage/feature/chat/domain/entities/chat_conversation_entity.dart';
import 'package:note_sondage/feature/chat/domain/entities/chat_direct_conversation_summary_entity.dart';
import 'package:note_sondage/feature/chat/domain/entities/chat_message_entity.dart';
import 'package:note_sondage/feature/chat/domain/entities/chat_team_conversation_summary_entity.dart';
import 'package:note_sondage/feature/chat/infrastructure/data_source/chat_local_data_source.dart';
import 'package:note_sondage/feature/chat/infrastructure/data_source/chat_remote_data_source.dart';
import 'package:note_sondage/feature/chat/infrastructure/repositories/chat_repository_impl.dart';

class _FakeChatLocalDataSource extends ChatLocalDataSource {
  ChatConversationEntity? teamConversation;
  ChatConversationEntity? directConversation;
  List<ChatMessageEntity> messages = const <ChatMessageEntity>[];
  ChatTeamConversationSummaryEntity? teamSummary;
  ChatDirectConversationSummaryEntity? directSummary;

  final savedConversations = <ChatConversationEntity>[];
  final savedTeamSummaries = <ChatTeamConversationSummaryEntity>[];
  final savedDirectSummaries = <ChatDirectConversationSummaryEntity>[];
  final savedMessagesCalls =
      <({String conversationId, List<ChatMessageEntity> messages})>[];
  final upsertMessageCalls =
      <({String conversationId, ChatMessageEntity message})>[];

  @override
  ChatConversationEntity? getConversationByTeamId(String teamId) =>
      teamConversation;

  @override
  ChatConversationEntity? getDirectConversation(
    String teamId,
    String memberUserId,
  ) => directConversation;

  @override
  List<ChatMessageEntity> getMessages(String conversationId) => messages;

  @override
  ChatTeamConversationSummaryEntity? getTeamSummary(String teamId) =>
      teamSummary;

  @override
  ChatDirectConversationSummaryEntity? getDirectSummary(
    String teamId,
    String memberUserId,
  ) => directSummary;

  @override
  Future<void> saveConversation(ChatConversationEntity conversation) async {
    savedConversations.add(conversation);
  }

  @override
  Future<void> saveSummary(ChatTeamConversationSummaryEntity summary) async {
    savedTeamSummaries.add(summary);
  }

  @override
  Future<void> saveDirectSummary(
    ChatDirectConversationSummaryEntity summary,
  ) async {
    savedDirectSummaries.add(summary);
  }

  @override
  Future<void> saveMessages(
    String conversationId,
    List<ChatMessageEntity> messages,
  ) async {
    savedMessagesCalls.add((conversationId: conversationId, messages: messages));
  }

  @override
  Future<void> upsertMessage(
    String conversationId,
    ChatMessageEntity message,
  ) async {
    upsertMessageCalls.add((conversationId: conversationId, message: message));
  }
}

class _FakeChatRemoteDataSource extends ChatRemoteDataSource {
  ChatConversationEntity? teamConversationResult;
  ChatConversationEntity? directConversationResult;
  ChatTeamConversationSummaryEntity? teamSummaryResult;
  ChatDirectConversationSummaryEntity? directSummaryResult;
  List<ChatMessageEntity> messagesResult = const <ChatMessageEntity>[];
  ChatMessageEntity? sendMessageResult;
  ChatMessageEntity? sendAttachmentMessageResult;
  ChatMessageEntity? toggleReactionResult;
  ChatMessageEntity? deleteMessageResult;

  final getMessagesCalls =
      <({String conversationId, DateTime? before, int limit})>[];
  final markConversationReadCalls = <String>[];

  @override
  Future<ChatConversationEntity> getOrCreateTeamConversation(
    String teamId,
  ) async => teamConversationResult!;

  @override
  Future<ChatConversationEntity> getOrCreateDirectConversation(
    String teamId,
    String memberUserId,
  ) async => directConversationResult!;

  @override
  Future<ChatTeamConversationSummaryEntity> getTeamConversationSummary(
    String teamId,
  ) async => teamSummaryResult!;

  @override
  Future<ChatDirectConversationSummaryEntity> getDirectConversationSummary(
    String teamId,
    String memberUserId,
  ) async => directSummaryResult!;

  @override
  Future<List<ChatMessageEntity>> getMessages(
    String conversationId, {
    DateTime? before,
    int limit = 50,
  }) async {
    getMessagesCalls.add((
      conversationId: conversationId,
      before: before,
      limit: limit,
    ));
    return messagesResult;
  }

  @override
  Future<ChatMessageEntity> sendMessage(
    String conversationId,
    String content, {
    String? replyToMessageId,
  }) async => sendMessageResult!;

  @override
  Future<ChatMessageEntity> sendAttachmentMessage(
    String conversationId, {
    String? content,
    required List<int> bytes,
    required String fileName,
    required String contentType,
    String? replyToMessageId,
  }) async => sendAttachmentMessageResult!;

  @override
  Future<ChatMessageEntity> toggleReaction(
    String messageId,
    String emoji,
  ) async => toggleReactionResult!;

  @override
  Future<ChatMessageEntity> deleteMessage(String messageId) async =>
      deleteMessageResult!;

  @override
  Future<void> markConversationRead(String conversationId) async {
    markConversationReadCalls.add(conversationId);
  }
}

ChatConversationEntity _buildConversation({
  String teamId = 'team-1',
  String type = 'TEAM',
  String? participantUserId,
}) {
  return ChatConversationEntity(
    id: 'conversation-1',
    teamId: teamId,
    type: type,
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
    participantUserId: participantUserId,
  );
}

ChatDirectConversationSummaryEntity _buildDirectSummary({
  String teamId = 'team-1',
  required String participantUserId,
}) {
  return ChatDirectConversationSummaryEntity(
    teamId: teamId,
    participantUserId: participantUserId,
    participantDisplayName: 'Mario Rossi',
    participantAvatarUrl: null,
    unreadCount: 0,
    lastMessagePreview: '',
    lastMessageType: 'TEXT',
  );
}

ChatMessageEntity _buildMessage({
  String id = 'message-1',
  String conversationId = 'conversation-1',
}) {
  return ChatMessageEntity(
    id: id,
    conversationId: conversationId,
    senderUserId: 'user-1',
    senderName: 'Mario Rossi',
    senderAvatarUrl: null,
    contentText: 'Ciao',
    messageType: 'TEXT',
    attachmentPath: null,
    attachmentOriginalName: null,
    attachmentContentType: null,
    attachmentSizeBytes: null,
    replyTo: null,
    reactions: const [],
    deleted: false,
    deletedAt: null,
    createdAt: DateTime(2026, 1, 1),
    readByCurrentUser: true,
    mine: true,
  );
}

void main() {
  late _FakeChatLocalDataSource local;
  late _FakeChatRemoteDataSource remote;
  late ChatRepositoryImpl repository;

  setUp(() {
    local = _FakeChatLocalDataSource();
    remote = _FakeChatRemoteDataSource();
    repository = ChatRepositoryImpl(local, remote);
  });

  group('ChatRepositoryImpl team conversation', () {
    test(
      'getOrCreateTeamConversation caches the remote conversation locally',
      () async {
        final conversation = _buildConversation();
        remote.teamConversationResult = conversation;

        final result = await repository.getOrCreateTeamConversation('team-1');

        expect(result, same(conversation));
        expect(local.savedConversations, [conversation]);
      },
    );

    test(
      'getTeamConversationSummary caches the remote summary locally',
      () async {
        const summary = ChatTeamConversationSummaryEntity(
          teamId: 'team-1',
          conversationId: 'conversation-1',
          unreadCount: 3,
          lastMessagePreview: 'Ciao',
          lastMessageType: 'TEXT',
          lastMessageAt: null,
        );
        remote.teamSummaryResult = summary;

        final result = await repository.getTeamConversationSummary('team-1');

        expect(result, same(summary));
        expect(local.savedTeamSummaries, [summary]);
      },
    );
  });

  group('ChatRepositoryImpl direct conversation participant guard', () {
    test(
      'getOrCreateDirectConversation caches when the participant matches',
      () async {
        final conversation = _buildConversation(
          type: 'DIRECT',
          participantUserId: 'member-1',
        );
        remote.directConversationResult = conversation;

        final result = await repository.getOrCreateDirectConversation(
          'team-1',
          'member-1',
        );

        expect(result, same(conversation));
        expect(local.savedConversations, [conversation]);
      },
    );

    test(
      'getOrCreateDirectConversation throws and skips caching on participant mismatch',
      () async {
        remote.directConversationResult = _buildConversation(
          type: 'DIRECT',
          participantUserId: 'someone-else',
        );

        await expectLater(
          repository.getOrCreateDirectConversation('team-1', 'member-1'),
          throwsA(isA<StateError>()),
        );
        expect(local.savedConversations, isEmpty);
      },
    );

    test(
      'getOrCreateDirectConversation throws when the participant id is missing',
      () async {
        remote.directConversationResult = _buildConversation(type: 'DIRECT');

        await expectLater(
          repository.getOrCreateDirectConversation('team-1', 'member-1'),
          throwsA(isA<StateError>()),
        );
        expect(local.savedConversations, isEmpty);
      },
    );

    test(
      'getDirectConversationSummary caches when the participant matches',
      () async {
        final summary = _buildDirectSummary(participantUserId: 'member-1');
        remote.directSummaryResult = summary;

        final result = await repository.getDirectConversationSummary(
          'team-1',
          'member-1',
        );

        expect(result, same(summary));
        expect(local.savedDirectSummaries, [summary]);
      },
    );

    test(
      'getDirectConversationSummary throws and skips caching on participant mismatch',
      () async {
        remote.directSummaryResult = _buildDirectSummary(
          participantUserId: 'someone-else',
        );

        await expectLater(
          repository.getDirectConversationSummary('team-1', 'member-1'),
          throwsA(isA<StateError>()),
        );
        expect(local.savedDirectSummaries, isEmpty);
      },
    );
  });

  group('ChatRepositoryImpl message pagination cache', () {
    test('getMessages caches the first page when before is null', () async {
      final messages = [_buildMessage()];
      remote.messagesResult = messages;

      final result = await repository.getMessages('conversation-1');

      expect(result, same(messages));
      expect(local.savedMessagesCalls, [
        (conversationId: 'conversation-1', messages: messages),
      ]);
    });

    test(
      'getMessages does NOT cache older pages when before is provided',
      () async {
        final messages = [_buildMessage(id: 'message-0')];
        remote.messagesResult = messages;

        final result = await repository.getMessages(
          'conversation-1',
          before: DateTime(2026, 1, 1),
        );

        expect(result, same(messages));
        expect(local.savedMessagesCalls, isEmpty);
      },
    );

    test('getMessages forwards before and limit to the remote source', () async {
      final before = DateTime(2026, 1, 1);

      await repository.getMessages('conversation-1', before: before, limit: 20);

      expect(remote.getMessagesCalls, [
        (conversationId: 'conversation-1', before: before, limit: 20),
      ]);
    });
  });

  group('ChatRepositoryImpl message writes', () {
    test('sendMessage upserts the returned message under its conversation', () async {
      final message = _buildMessage();
      remote.sendMessageResult = message;

      final result = await repository.sendMessage('conversation-1', 'Ciao');

      expect(result, same(message));
      expect(local.upsertMessageCalls, [
        (conversationId: 'conversation-1', message: message),
      ]);
    });

    test(
      'sendAttachmentMessage upserts the returned message under its conversation',
      () async {
        final message = _buildMessage();
        remote.sendAttachmentMessageResult = message;

        final result = await repository.sendAttachmentMessage(
          'conversation-1',
          bytes: const [1, 2, 3],
          fileName: 'photo.png',
          contentType: 'image/png',
        );

        expect(result, same(message));
        expect(local.upsertMessageCalls, [
          (conversationId: 'conversation-1', message: message),
        ]);
      },
    );

    test(
      'toggleReaction upserts using the conversationId from the remote response, '
      'not the caller-supplied messageId',
      () async {
        final message = _buildMessage(
          id: 'message-9',
          conversationId: 'conversation-9',
        );
        remote.toggleReactionResult = message;

        final result = await repository.toggleReaction('message-9', '👍');

        expect(result, same(message));
        expect(local.upsertMessageCalls, [
          (conversationId: 'conversation-9', message: message),
        ]);
      },
    );

    test(
      'deleteMessage upserts the tombstoned message under its conversation',
      () async {
        final message = _buildMessage(conversationId: 'conversation-9');
        remote.deleteMessageResult = message;

        final result = await repository.deleteMessage('message-1');

        expect(result, same(message));
        expect(local.upsertMessageCalls, [
          (conversationId: 'conversation-9', message: message),
        ]);
      },
    );

    test('markConversationRead delegates to remote without touching cache', () async {
      await repository.markConversationRead('conversation-1');

      expect(remote.markConversationReadCalls, ['conversation-1']);
      expect(local.upsertMessageCalls, isEmpty);
      expect(local.savedMessagesCalls, isEmpty);
    });
  });

  group('ChatRepositoryImpl cached reads', () {
    test('getCachedTeamConversation delegates to local by teamId', () {
      final conversation = _buildConversation();
      local.teamConversation = conversation;

      final result = repository.getCachedTeamConversation('team-1');

      expect(result, same(conversation));
    });

    test('getCachedDirectConversation delegates to local', () {
      final conversation = _buildConversation(
        type: 'DIRECT',
        participantUserId: 'member-1',
      );
      local.directConversation = conversation;

      final result = repository.getCachedDirectConversation(
        'team-1',
        'member-1',
      );

      expect(result, same(conversation));
    });

    test('getCachedMessages returns whatever local currently holds', () {
      final messages = [_buildMessage()];
      local.messages = messages;

      final result = repository.getCachedMessages('conversation-1');

      expect(result, same(messages));
    });

    test('getCachedTeamSummary delegates to local', () {
      const summary = ChatTeamConversationSummaryEntity(
        teamId: 'team-1',
        conversationId: 'conversation-1',
        unreadCount: 1,
        lastMessagePreview: 'Ciao',
        lastMessageType: 'TEXT',
        lastMessageAt: null,
      );
      local.teamSummary = summary;

      final result = repository.getCachedTeamSummary('team-1');

      expect(result, same(summary));
    });

    test('getCachedDirectSummary delegates to local', () {
      final summary = _buildDirectSummary(participantUserId: 'member-1');
      local.directSummary = summary;

      final result = repository.getCachedDirectSummary('team-1', 'member-1');

      expect(result, same(summary));
    });
  });
}
