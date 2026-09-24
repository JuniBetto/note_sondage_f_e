import 'package:flutter_test/flutter_test.dart';
import 'package:note_sondage/feature/chat/domain/entities/blocked_user_entity.dart';
import 'package:note_sondage/feature/chat/domain/entities/chat_conversation_entity.dart';
import 'package:note_sondage/feature/chat/domain/entities/chat_direct_conversation_summary_entity.dart';
import 'package:note_sondage/feature/chat/domain/entities/chat_message_entity.dart';
import 'package:note_sondage/feature/chat/domain/entities/chat_message_report_reason.dart';
import 'package:note_sondage/feature/chat/domain/entities/chat_team_conversation_summary_entity.dart';
import 'package:note_sondage/feature/chat/domain/repositories/chat_repository.dart';
import 'package:note_sondage/feature/chat/domain/use_case/chat_use_case.dart';

class _FakeChatRepository implements ChatRepository {
  ChatConversationEntity? cachedTeamConversation;
  ChatConversationEntity? cachedDirectConversation;
  List<ChatMessageEntity> cachedMessages = const <ChatMessageEntity>[];
  ChatTeamConversationSummaryEntity? cachedTeamSummary;
  ChatDirectConversationSummaryEntity? cachedDirectSummary;

  Future<ChatConversationEntity> Function(String teamId)?
  getOrCreateTeamConversationHandler;
  Future<ChatConversationEntity> Function(String teamId, String memberUserId)?
  getOrCreateDirectConversationHandler;
  Future<ChatTeamConversationSummaryEntity> Function(String teamId)?
  getTeamConversationSummaryHandler;
  Future<ChatDirectConversationSummaryEntity> Function(
    String teamId,
    String memberUserId,
  )?
  getDirectConversationSummaryHandler;
  Future<List<ChatMessageEntity>> Function(
    String conversationId, {
    DateTime? before,
    int limit,
  })?
  getMessagesHandler;
  Future<ChatMessageEntity> Function(
    String conversationId,
    String content, {
    String? replyToMessageId,
  })?
  sendMessageHandler;
  Future<ChatMessageEntity> Function(
    String conversationId, {
    String? content,
    required List<int> bytes,
    required String fileName,
    required String contentType,
    String? replyToMessageId,
  })?
  sendAttachmentMessageHandler;
  Future<ChatMessageEntity> Function(String messageId, String emoji)?
  toggleReactionHandler;
  Future<ChatMessageEntity> Function(String messageId)? deleteMessageHandler;
  Future<void> Function(String conversationId)? markConversationReadHandler;
  Future<BlockedUserEntity> Function(String messageId)? blockSenderHandler;
  Future<void> Function(String blockedUserId)? unblockUserHandler;
  Future<List<BlockedUserEntity>> Function()? getBlockedUsersHandler;
  Future<void> Function(
    String messageId, {
    required ChatMessageReportReason reason,
    String? comment,
  })?
  reportMessageHandler;

  final getCachedTeamConversationCalls = <String>[];
  final getCachedDirectConversationCalls = <(String, String)>[];
  final getCachedMessagesCalls = <String>[];
  final getCachedTeamSummaryCalls = <String>[];
  final getCachedDirectSummaryCalls = <(String, String)>[];
  final getOrCreateTeamConversationCalls = <String>[];
  final getOrCreateDirectConversationCalls = <(String, String)>[];
  final getTeamConversationSummaryCalls = <String>[];
  final getDirectConversationSummaryCalls = <(String, String)>[];
  final getMessagesCalls = <({String conversationId, DateTime? before, int limit})>[];
  final sendMessageCalls =
      <({String conversationId, String content, String? replyToMessageId})>[];
  final sendAttachmentMessageCalls =
      <({
        String conversationId,
        String? content,
        List<int> bytes,
        String fileName,
        String contentType,
        String? replyToMessageId,
      })>[];
  final toggleReactionCalls = <(String, String)>[];
  final deleteMessageCalls = <String>[];
  final markConversationReadCalls = <String>[];
  final blockSenderCalls = <String>[];
  final unblockUserCalls = <String>[];
  int getBlockedUsersCallCount = 0;
  final reportMessageCalls =
      <({String messageId, ChatMessageReportReason reason, String? comment})>[];

  @override
  ChatConversationEntity? getCachedTeamConversation(String teamId) {
    getCachedTeamConversationCalls.add(teamId);
    return cachedTeamConversation;
  }

  @override
  ChatConversationEntity? getCachedDirectConversation(
    String teamId,
    String memberUserId,
  ) {
    getCachedDirectConversationCalls.add((teamId, memberUserId));
    return cachedDirectConversation;
  }

  @override
  List<ChatMessageEntity> getCachedMessages(String conversationId) {
    getCachedMessagesCalls.add(conversationId);
    return cachedMessages;
  }

  @override
  ChatTeamConversationSummaryEntity? getCachedTeamSummary(String teamId) {
    getCachedTeamSummaryCalls.add(teamId);
    return cachedTeamSummary;
  }

  @override
  ChatDirectConversationSummaryEntity? getCachedDirectSummary(
    String teamId,
    String memberUserId,
  ) {
    getCachedDirectSummaryCalls.add((teamId, memberUserId));
    return cachedDirectSummary;
  }

  @override
  Future<ChatConversationEntity> getOrCreateTeamConversation(String teamId) {
    getOrCreateTeamConversationCalls.add(teamId);
    return getOrCreateTeamConversationHandler!(teamId);
  }

  @override
  Future<ChatConversationEntity> getOrCreateDirectConversation(
    String teamId,
    String memberUserId,
  ) {
    getOrCreateDirectConversationCalls.add((teamId, memberUserId));
    return getOrCreateDirectConversationHandler!(teamId, memberUserId);
  }

  @override
  Future<ChatTeamConversationSummaryEntity> getTeamConversationSummary(
    String teamId,
  ) {
    getTeamConversationSummaryCalls.add(teamId);
    return getTeamConversationSummaryHandler!(teamId);
  }

  @override
  Future<ChatDirectConversationSummaryEntity> getDirectConversationSummary(
    String teamId,
    String memberUserId,
  ) {
    getDirectConversationSummaryCalls.add((teamId, memberUserId));
    return getDirectConversationSummaryHandler!(teamId, memberUserId);
  }

  @override
  Future<List<ChatMessageEntity>> getMessages(
    String conversationId, {
    DateTime? before,
    int limit = 50,
  }) {
    getMessagesCalls.add((
      conversationId: conversationId,
      before: before,
      limit: limit,
    ));
    return getMessagesHandler!(conversationId, before: before, limit: limit);
  }

  @override
  Future<ChatMessageEntity> sendMessage(
    String conversationId,
    String content, {
    String? replyToMessageId,
  }) {
    sendMessageCalls.add((
      conversationId: conversationId,
      content: content,
      replyToMessageId: replyToMessageId,
    ));
    return sendMessageHandler!(
      conversationId,
      content,
      replyToMessageId: replyToMessageId,
    );
  }

  @override
  Future<ChatMessageEntity> sendAttachmentMessage(
    String conversationId, {
    String? content,
    required List<int> bytes,
    required String fileName,
    required String contentType,
    String? replyToMessageId,
  }) {
    sendAttachmentMessageCalls.add((
      conversationId: conversationId,
      content: content,
      bytes: bytes,
      fileName: fileName,
      contentType: contentType,
      replyToMessageId: replyToMessageId,
    ));
    return sendAttachmentMessageHandler!(
      conversationId,
      content: content,
      bytes: bytes,
      fileName: fileName,
      contentType: contentType,
      replyToMessageId: replyToMessageId,
    );
  }

  @override
  Future<ChatMessageEntity> toggleReaction(String messageId, String emoji) {
    toggleReactionCalls.add((messageId, emoji));
    return toggleReactionHandler!(messageId, emoji);
  }

  @override
  Future<ChatMessageEntity> deleteMessage(String messageId) {
    deleteMessageCalls.add(messageId);
    return deleteMessageHandler!(messageId);
  }

  @override
  Future<void> markConversationRead(String conversationId) {
    markConversationReadCalls.add(conversationId);
    return markConversationReadHandler?.call(conversationId) ??
        Future<void>.value();
  }

  @override
  Future<BlockedUserEntity> blockSender(String messageId) {
    blockSenderCalls.add(messageId);
    return blockSenderHandler!(messageId);
  }

  @override
  Future<void> unblockUser(String blockedUserId) {
    unblockUserCalls.add(blockedUserId);
    return unblockUserHandler?.call(blockedUserId) ?? Future<void>.value();
  }

  @override
  Future<List<BlockedUserEntity>> getBlockedUsers() {
    getBlockedUsersCallCount++;
    return getBlockedUsersHandler!();
  }

  @override
  Future<void> reportMessage(
    String messageId, {
    required ChatMessageReportReason reason,
    String? comment,
  }) {
    reportMessageCalls.add((messageId: messageId, reason: reason, comment: comment));
    return reportMessageHandler?.call(messageId, reason: reason, comment: comment) ??
        Future<void>.value();
  }
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

ChatConversationEntity _buildConversation({String teamId = 'team-1'}) {
  return ChatConversationEntity(
    id: 'conversation-1',
    teamId: teamId,
    type: 'TEAM',
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
  );
}

void main() {
  late _FakeChatRepository repository;
  late ChatUseCase useCase;

  setUp(() {
    repository = _FakeChatRepository();
    useCase = ChatUseCase(repository);
  });

  group('ChatUseCase cached reads', () {
    test('getCachedTeamConversation delegates to repository', () {
      final conversation = _buildConversation();
      repository.cachedTeamConversation = conversation;

      final result = useCase.getCachedTeamConversation('team-1');

      expect(result, same(conversation));
      expect(repository.getCachedTeamConversationCalls, ['team-1']);
    });

    test('getCachedDirectConversation delegates teamId and memberUserId', () {
      useCase.getCachedDirectConversation('team-1', 'member-1');

      expect(repository.getCachedDirectConversationCalls, [
        ('team-1', 'member-1'),
      ]);
    });

    test('getCachedMessages delegates to repository', () {
      final messages = [_buildMessage()];
      repository.cachedMessages = messages;

      final result = useCase.getCachedMessages('conversation-1');

      expect(result, same(messages));
      expect(repository.getCachedMessagesCalls, ['conversation-1']);
    });

    test('getCachedTeamSummary delegates to repository', () {
      useCase.getCachedTeamSummary('team-1');

      expect(repository.getCachedTeamSummaryCalls, ['team-1']);
    });

    test('getCachedDirectSummary delegates teamId and memberUserId', () {
      useCase.getCachedDirectSummary('team-1', 'member-1');

      expect(repository.getCachedDirectSummaryCalls, [
        ('team-1', 'member-1'),
      ]);
    });
  });

  group('ChatUseCase remote fetches', () {
    test('getOrCreateTeamConversation delegates and returns result', () async {
      final conversation = _buildConversation();
      repository.getOrCreateTeamConversationHandler = (_) async => conversation;

      final result = await useCase.getOrCreateTeamConversation('team-1');

      expect(result, same(conversation));
      expect(repository.getOrCreateTeamConversationCalls, ['team-1']);
    });

    test('getOrCreateDirectConversation delegates teamId and memberUserId', () async {
      final conversation = _buildConversation();
      repository.getOrCreateDirectConversationHandler =
          (_, _) async => conversation;

      final result = await useCase.getOrCreateDirectConversation(
        'team-1',
        'member-1',
      );

      expect(result, same(conversation));
      expect(repository.getOrCreateDirectConversationCalls, [
        ('team-1', 'member-1'),
      ]);
    });

    test('getMessages defaults limit to 50 and forwards before', () async {
      final messages = [_buildMessage()];
      repository.getMessagesHandler = (_, {before, limit = 50}) async => messages;
      final before = DateTime(2026, 1, 1);

      final result = await useCase.getMessages('conversation-1', before: before);

      expect(result, same(messages));
      expect(repository.getMessagesCalls, [
        (conversationId: 'conversation-1', before: before, limit: 50),
      ]);
    });

    test('getMessages forwards an explicit limit', () async {
      repository.getMessagesHandler = (_, {before, limit = 50}) async => const [];

      await useCase.getMessages('conversation-1', limit: 20);

      expect(repository.getMessagesCalls.single.limit, 20);
    });
  });

  group('ChatUseCase writes', () {
    test('sendMessage forwards content and replyToMessageId', () async {
      final message = _buildMessage();
      repository.sendMessageHandler = (_, _, {replyToMessageId}) async => message;

      final result = await useCase.sendMessage(
        'conversation-1',
        'Ciao',
        replyToMessageId: 'message-0',
      );

      expect(result, same(message));
      expect(repository.sendMessageCalls, [
        (
          conversationId: 'conversation-1',
          content: 'Ciao',
          replyToMessageId: 'message-0',
        ),
      ]);
    });

    test('sendAttachmentMessage forwards attachment metadata', () async {
      final message = _buildMessage();
      repository.sendAttachmentMessageHandler =
          (
            _, {
            content,
            required bytes,
            required fileName,
            required contentType,
            replyToMessageId,
          }) async => message;
      final bytes = <int>[1, 2, 3];

      final result = await useCase.sendAttachmentMessage(
        'conversation-1',
        content: 'Guarda',
        bytes: bytes,
        fileName: 'photo.png',
        contentType: 'image/png',
      );

      expect(result, same(message));
      expect(repository.sendAttachmentMessageCalls, [
        (
          conversationId: 'conversation-1',
          content: 'Guarda',
          bytes: bytes,
          fileName: 'photo.png',
          contentType: 'image/png',
          replyToMessageId: null,
        ),
      ]);
    });

    test('toggleReaction delegates messageId and emoji', () async {
      final message = _buildMessage();
      repository.toggleReactionHandler = (_, _) async => message;

      final result = await useCase.toggleReaction('message-1', '👍');

      expect(result, same(message));
      expect(repository.toggleReactionCalls, [('message-1', '👍')]);
    });

    test('deleteMessage delegates messageId', () async {
      final message = _buildMessage();
      repository.deleteMessageHandler = (_) async => message;

      final result = await useCase.deleteMessage('message-1');

      expect(result, same(message));
      expect(repository.deleteMessageCalls, ['message-1']);
    });

    test('markConversationRead delegates conversationId', () async {
      await useCase.markConversationRead('conversation-1');

      expect(repository.markConversationReadCalls, ['conversation-1']);
    });
  });

  group('ChatUseCase moderation', () {
    test('blockSender delegates messageId', () async {
      final blockedUser = BlockedUserEntity(
        userId: 'user-2',
        displayName: 'User Two',
        blockedAt: DateTime(2026, 1, 1),
      );
      repository.blockSenderHandler = (_) async => blockedUser;

      final result = await useCase.blockSender('message-1');

      expect(result, same(blockedUser));
      expect(repository.blockSenderCalls, ['message-1']);
    });

    test('unblockUser delegates blockedUserId', () async {
      await useCase.unblockUser('user-2');

      expect(repository.unblockUserCalls, ['user-2']);
    });

    test('getBlockedUsers delegates to repository', () async {
      final blockedUsers = [
        BlockedUserEntity(
          userId: 'user-2',
          displayName: 'User Two',
          blockedAt: DateTime(2026, 1, 1),
        ),
      ];
      repository.getBlockedUsersHandler = () async => blockedUsers;

      final result = await useCase.getBlockedUsers();

      expect(result, same(blockedUsers));
      expect(repository.getBlockedUsersCallCount, 1);
    });

    test('reportMessage delegates messageId, reason and comment', () async {
      await useCase.reportMessage(
        'message-1',
        reason: ChatMessageReportReason.spam,
        comment: 'looks like spam',
      );

      expect(repository.reportMessageCalls, [
        (
          messageId: 'message-1',
          reason: ChatMessageReportReason.spam,
          comment: 'looks like spam',
        ),
      ]);
    });
  });
}
