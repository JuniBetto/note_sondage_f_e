import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:note_sondage/feature/chat/domain/entities/blocked_user_entity.dart';
import 'package:note_sondage/feature/chat/domain/entities/chat_conversation_entity.dart';
import 'package:note_sondage/feature/chat/domain/entities/chat_direct_conversation_summary_entity.dart';
import 'package:note_sondage/feature/chat/domain/entities/chat_message_entity.dart';
import 'package:note_sondage/feature/chat/domain/entities/chat_message_report_reason.dart';
import 'package:note_sondage/feature/chat/domain/entities/chat_team_conversation_summary_entity.dart';
import 'package:note_sondage/feature/chat/infrastructure/data_source/chat_local_data_source.dart';
import 'package:note_sondage/feature/chat/infrastructure/data_source/chat_remote_data_source.dart';
import 'package:note_sondage/feature/chat/infrastructure/repositories/chat_repository_impl.dart';

class _FakeChatLocalDataSource extends ChatLocalDataSource {
  String scope = 'user-a';
  Future<void> Function()? writeHandler;

  @override
  String get cacheScope => scope;

  int get writeCount =>
      savedConversations.length +
      savedTeamSummaries.length +
      savedDirectSummaries.length +
      savedMessagesCalls.length +
      upsertMessageCalls.length;
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
    await writeHandler?.call();
  }

  @override
  Future<void> saveSummary(ChatTeamConversationSummaryEntity summary) async {
    savedTeamSummaries.add(summary);
    await writeHandler?.call();
  }

  @override
  Future<void> saveDirectSummary(
    ChatDirectConversationSummaryEntity summary,
  ) async {
    savedDirectSummaries.add(summary);
    await writeHandler?.call();
  }

  @override
  Future<void> saveMessages(
    String conversationId,
    List<ChatMessageEntity> messages,
  ) async {
    savedMessagesCalls.add((
      conversationId: conversationId,
      messages: messages,
    ));
    await writeHandler?.call();
  }

  @override
  Future<void> upsertMessage(
    String conversationId,
    ChatMessageEntity message,
  ) async {
    upsertMessageCalls.add((conversationId: conversationId, message: message));
    await writeHandler?.call();
  }
}

class _SynchronouslyFailingCache extends _FakeChatLocalDataSource {
  @override
  Future<void> saveMessages(
    String conversationId,
    List<ChatMessageEntity> messages,
  ) {
    throw StateError('synchronous cache failure');
  }
}

class _FakeChatRemoteDataSource extends ChatRemoteDataSource {
  Future<void> Function()? requestHandler;
  ChatConversationEntity? teamConversationResult;
  ChatConversationEntity? directConversationResult;
  ChatTeamConversationSummaryEntity? teamSummaryResult;
  ChatDirectConversationSummaryEntity? directSummaryResult;
  List<ChatMessageEntity> messagesResult = const <ChatMessageEntity>[];
  ChatMessageEntity? sendMessageResult;
  ChatMessageEntity? sendAttachmentMessageResult;
  ChatMessageEntity? toggleReactionResult;
  ChatMessageEntity? deleteMessageResult;
  BlockedUserEntity? blockSenderResult;
  List<BlockedUserEntity> getBlockedUsersResult = const <BlockedUserEntity>[];

  final getMessagesCalls =
      <({String conversationId, DateTime? before, int limit})>[];
  final markConversationReadCalls = <String>[];
  final blockSenderCalls = <String>[];
  final unblockUserCalls = <String>[];
  final reportMessageCalls =
      <({String messageId, ChatMessageReportReason reason, String? comment})>[];

  @override
  Future<ChatConversationEntity> getOrCreateTeamConversation(
    String teamId,
  ) async {
    await requestHandler?.call();
    return teamConversationResult!;
  }

  @override
  Future<ChatConversationEntity> getOrCreateDirectConversation(
    String teamId,
    String memberUserId,
  ) async {
    await requestHandler?.call();
    return directConversationResult!;
  }

  @override
  Future<ChatTeamConversationSummaryEntity> getTeamConversationSummary(
    String teamId,
  ) async {
    await requestHandler?.call();
    return teamSummaryResult!;
  }

  @override
  Future<ChatDirectConversationSummaryEntity> getDirectConversationSummary(
    String teamId,
    String memberUserId,
  ) async {
    await requestHandler?.call();
    return directSummaryResult!;
  }

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
    await requestHandler?.call();
    return messagesResult;
  }

  @override
  Future<ChatMessageEntity> sendMessage(
    String conversationId,
    String content, {
    String? replyToMessageId,
  }) async {
    await requestHandler?.call();
    return sendMessageResult!;
  }

  @override
  Future<ChatMessageEntity> sendAttachmentMessage(
    String conversationId, {
    String? content,
    required List<int> bytes,
    required String fileName,
    required String contentType,
    String? replyToMessageId,
  }) async {
    await requestHandler?.call();
    return sendAttachmentMessageResult!;
  }

  @override
  Future<ChatMessageEntity> toggleReaction(
    String messageId,
    String emoji,
  ) async {
    await requestHandler?.call();
    return toggleReactionResult!;
  }

  @override
  Future<ChatMessageEntity> deleteMessage(String messageId) async {
    await requestHandler?.call();
    return deleteMessageResult!;
  }

  @override
  Future<void> markConversationRead(String conversationId) async {
    markConversationReadCalls.add(conversationId);
  }

  @override
  Future<BlockedUserEntity> blockSender(String messageId) async {
    blockSenderCalls.add(messageId);
    return blockSenderResult!;
  }

  @override
  Future<void> unblockUser(String blockedUserId) async {
    unblockUserCalls.add(blockedUserId);
  }

  @override
  Future<List<BlockedUserEntity>> getBlockedUsers() async =>
      getBlockedUsersResult;

  @override
  Future<void> reportMessage(
    String messageId, {
    required ChatMessageReportReason reason,
    String? comment,
  }) async {
    reportMessageCalls.add((
      messageId: messageId,
      reason: reason,
      comment: comment,
    ));
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

  group('background cache writes', () {
    setUp(() {
      remote.teamConversationResult = _buildConversation();
      remote.directConversationResult = _buildConversation(
        type: 'DIRECT',
        participantUserId: 'member-1',
      );
      remote.teamSummaryResult = const ChatTeamConversationSummaryEntity(
        teamId: 'team-1',
        conversationId: 'conversation-1',
        unreadCount: 1,
        lastMessagePreview: 'Hello',
        lastMessageType: 'TEXT',
        lastMessageAt: null,
      );
      remote.directSummaryResult = _buildDirectSummary(
        participantUserId: 'member-1',
      );
      remote.messagesResult = [_buildMessage()];
      remote.sendMessageResult = _buildMessage();
      remote.sendAttachmentMessageResult = _buildMessage();
      remote.toggleReactionResult = _buildMessage();
      remote.deleteMessageResult = _buildMessage();
    });

    test(
      'a synchronous cache failure also preserves the server result',
      () async {
        repository = ChatRepositoryImpl(_SynchronouslyFailingCache(), remote);
        expect(
          await repository.getMessages('conversation-1'),
          same(remote.messagesResult),
        );
      },
    );

    final operations = <String, Future<Object?> Function()>{
      'team conversation': () =>
          repository.getOrCreateTeamConversation('team-1'),
      'direct conversation': () =>
          repository.getOrCreateDirectConversation('team-1', 'member-1'),
      'team summary': () => repository.getTeamConversationSummary('team-1'),
      'direct summary': () =>
          repository.getDirectConversationSummary('team-1', 'member-1'),
      'messages': () => repository.getMessages('conversation-1'),
      'send text': () => repository.sendMessage('conversation-1', 'Hello'),
      'send attachment': () => repository.sendAttachmentMessage(
        'conversation-1',
        bytes: [1],
        fileName: 'test.pdf',
        contentType: 'application/pdf',
      ),
      'reaction': () => repository.toggleReaction('message-1', '👍'),
      'delete': () => repository.deleteMessage('message-1'),
    };
    final expected = <String, Object? Function()>{
      'team conversation': () => remote.teamConversationResult,
      'direct conversation': () => remote.directConversationResult,
      'team summary': () => remote.teamSummaryResult,
      'direct summary': () => remote.directSummaryResult,
      'messages': () => remote.messagesResult,
      'send text': () => remote.sendMessageResult,
      'send attachment': () => remote.sendAttachmentMessageResult,
      'reaction': () => remote.toggleReactionResult,
      'delete': () => remote.deleteMessageResult,
    };

    for (final entry in operations.entries) {
      test(
        '${entry.key} returns the server result while cache persistence is blocked',
        () async {
          final disk = Completer<void>();
          addTearDown(() {
            if (!disk.isCompleted) disk.complete();
          });
          local.writeHandler = () => disk.future;
          var completed = false;
          final request = entry.value().then((value) {
            completed = true;
            return value;
          });
          await pumpEventQueue();
          expect(completed, isTrue);
          expect(disk.isCompleted, isFalse);
          expect(local.writeCount, 1);
          expect(await request, same(expected[entry.key]!()));
          disk.complete();
        },
      );

      test('${entry.key} keeps server success when persistence fails', () async {
        local.writeHandler = () =>
            Future<void>.error(StateError('disk failure'));
        expect(await entry.value(), same(expected[entry.key]!()));
        await pumpEventQueue(); // Unhandled asynchronous errors fail the test.
        expect(local.writeCount, 1);
      });

      for (final nextScope in ['user-b', 'anonymous']) {
        test(
          '${entry.key} skips cache for a late response after switching to $nextScope',
          () async {
            final network = Completer<void>();
            addTearDown(() {
              if (!network.isCompleted) network.complete();
            });
            remote.requestHandler = () => network.future;
            final request = entry.value();
            local.scope = nextScope;
            network.complete();
            expect(await request, same(expected[entry.key]!()));
            expect(local.writeCount, 0);
          },
        );
      }

      test(
        '${entry.key} still propagates network failures and does not write cache',
        () async {
          remote.requestHandler = () =>
              Future<void>.error(StateError('network failure'));
          await expectLater(entry.value(), throwsStateError);
          expect(local.writeCount, 0);
        },
      );
    }
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

    test(
      'getMessages forwards before and limit to the remote source',
      () async {
        final before = DateTime(2026, 1, 1);

        await repository.getMessages(
          'conversation-1',
          before: before,
          limit: 20,
        );

        expect(remote.getMessagesCalls, [
          (conversationId: 'conversation-1', before: before, limit: 20),
        ]);
      },
    );
  });

  group('ChatRepositoryImpl message writes', () {
    test(
      'sendMessage upserts the returned message under its conversation',
      () async {
        final message = _buildMessage();
        remote.sendMessageResult = message;

        final result = await repository.sendMessage('conversation-1', 'Ciao');

        expect(result, same(message));
        expect(local.upsertMessageCalls, [
          (conversationId: 'conversation-1', message: message),
        ]);
      },
    );

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

    test(
      'markConversationRead delegates to remote without touching cache',
      () async {
        await repository.markConversationRead('conversation-1');

        expect(remote.markConversationReadCalls, ['conversation-1']);
        expect(local.upsertMessageCalls, isEmpty);
        expect(local.savedMessagesCalls, isEmpty);
      },
    );
  });

  group('ChatRepositoryImpl moderation', () {
    test('blockSender delegates to remote without touching cache', () async {
      final blockedUser = BlockedUserEntity(
        userId: 'user-2',
        displayName: 'User Two',
        blockedAt: DateTime(2026, 1, 1),
      );
      remote.blockSenderResult = blockedUser;

      final result = await repository.blockSender('message-1');

      expect(result, same(blockedUser));
      expect(remote.blockSenderCalls, ['message-1']);
    });

    test('unblockUser delegates to remote', () async {
      await repository.unblockUser('user-2');

      expect(remote.unblockUserCalls, ['user-2']);
    });

    test('getBlockedUsers delegates to remote', () async {
      final blockedUsers = [
        BlockedUserEntity(
          userId: 'user-2',
          displayName: 'User Two',
          blockedAt: DateTime(2026, 1, 1),
        ),
      ];
      remote.getBlockedUsersResult = blockedUsers;

      final result = await repository.getBlockedUsers();

      expect(result, same(blockedUsers));
    });

    test('reportMessage delegates messageId, reason and comment', () async {
      await repository.reportMessage(
        'message-1',
        reason: ChatMessageReportReason.spam,
        comment: 'looks like spam',
      );

      expect(remote.reportMessageCalls, [
        (
          messageId: 'message-1',
          reason: ChatMessageReportReason.spam,
          comment: 'looks like spam',
        ),
      ]);
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
