import 'package:flutter_test/flutter_test.dart';
import 'package:note_sondage/feature/chat/domain/entities/blocked_user_entity.dart';
import 'package:note_sondage/feature/chat/domain/entities/chat_conversation_entity.dart';
import 'package:note_sondage/feature/chat/domain/entities/chat_direct_conversation_summary_entity.dart';
import 'package:note_sondage/feature/chat/domain/entities/chat_message_entity.dart';
import 'package:note_sondage/feature/chat/domain/entities/chat_message_report_reason.dart';
import 'package:note_sondage/feature/chat/domain/entities/chat_team_conversation_summary_entity.dart';
import 'package:note_sondage/feature/chat/domain/repositories/chat_repository.dart';
import 'package:note_sondage/feature/chat/domain/use_case/chat_use_case.dart';
import 'package:note_sondage/feature/chat/ui/cubit/blocked_users_cubit.dart';

/// Only `getBlockedUsers`/`unblockUser` are ever called by
/// [BlockedUsersCubit] — everything else throws, since it's never reached.
class _FakeChatRepository implements ChatRepository {
  Future<List<BlockedUserEntity>> Function()? getBlockedUsersHandler;
  Future<void> Function(String blockedUserId)? unblockUserHandler;
  final unblockUserCalls = <String>[];

  @override
  Future<List<BlockedUserEntity>> getBlockedUsers() => getBlockedUsersHandler!();

  @override
  Future<void> unblockUser(String blockedUserId) {
    unblockUserCalls.add(blockedUserId);
    return unblockUserHandler?.call(blockedUserId) ?? Future<void>.value();
  }

  @override
  Future<BlockedUserEntity> blockSender(String messageId) =>
      throw UnimplementedError();

  @override
  ChatConversationEntity? getCachedDirectConversation(
    String teamId,
    String memberUserId,
  ) => throw UnimplementedError();

  @override
  ChatDirectConversationSummaryEntity? getCachedDirectSummary(
    String teamId,
    String memberUserId,
  ) => throw UnimplementedError();

  @override
  List<ChatMessageEntity> getCachedMessages(String conversationId) =>
      throw UnimplementedError();

  @override
  ChatConversationEntity? getCachedTeamConversation(String teamId) =>
      throw UnimplementedError();

  @override
  ChatTeamConversationSummaryEntity? getCachedTeamSummary(String teamId) =>
      throw UnimplementedError();

  @override
  Future<ChatMessageEntity> deleteMessage(String messageId) =>
      throw UnimplementedError();

  @override
  Future<ChatDirectConversationSummaryEntity> getDirectConversationSummary(
    String teamId,
    String memberUserId,
  ) => throw UnimplementedError();

  @override
  Future<List<ChatMessageEntity>> getMessages(
    String conversationId, {
    DateTime? before,
    int limit = 50,
  }) => throw UnimplementedError();

  @override
  Future<ChatConversationEntity> getOrCreateDirectConversation(
    String teamId,
    String memberUserId,
  ) => throw UnimplementedError();

  @override
  Future<ChatConversationEntity> getOrCreateTeamConversation(String teamId) =>
      throw UnimplementedError();

  @override
  Future<ChatTeamConversationSummaryEntity> getTeamConversationSummary(
    String teamId,
  ) => throw UnimplementedError();

  @override
  Future<void> markConversationRead(String conversationId) =>
      throw UnimplementedError();

  @override
  Future<void> reportMessage(
    String messageId, {
    required ChatMessageReportReason reason,
    String? comment,
  }) => throw UnimplementedError();

  @override
  Future<ChatMessageEntity> sendAttachmentMessage(
    String conversationId, {
    String? content,
    required List<int> bytes,
    required String fileName,
    required String contentType,
    String? replyToMessageId,
  }) => throw UnimplementedError();

  @override
  Future<ChatMessageEntity> sendMessage(
    String conversationId,
    String content, {
    String? replyToMessageId,
  }) => throw UnimplementedError();

  @override
  Future<ChatMessageEntity> toggleReaction(String messageId, String emoji) =>
      throw UnimplementedError();
}

void main() {
  late _FakeChatRepository repository;
  late BlockedUsersCubit cubit;

  setUp(() {
    repository = _FakeChatRepository();
    cubit = BlockedUsersCubit(ChatUseCase(repository));
  });

  tearDown(() => cubit.close());

  group('BlockedUsersCubit load', () {
    test('populates blockedUsers on success', () async {
      final blockedUsers = [
        BlockedUserEntity(
          userId: 'user-2',
          displayName: 'User Two',
          blockedAt: DateTime(2026, 1, 1),
        ),
      ];
      repository.getBlockedUsersHandler = () async => blockedUsers;

      await cubit.load();

      expect(cubit.state.status, BlockedUsersStatus.loaded);
      expect(cubit.state.blockedUsers, same(blockedUsers));
      expect(cubit.state.errorMessage, isNull);
    });

    test('surfaces an error message on failure', () async {
      repository.getBlockedUsersHandler = () => Future.error(Exception('boom'));

      await cubit.load();

      expect(cubit.state.status, BlockedUsersStatus.error);
      expect(cubit.state.errorMessage, contains('boom'));
    });

    test('is a no-op while already loading', () async {
      var callCount = 0;
      repository.getBlockedUsersHandler = () async {
        callCount++;
        return const <BlockedUserEntity>[];
      };

      final first = cubit.load();
      final second = cubit.load();
      await Future.wait([first, second]);

      expect(callCount, 1);
    });
  });

  group('BlockedUsersCubit unblock', () {
    test('optimistically removes the user and calls the repository', () async {
      final userTwo = BlockedUserEntity(
        userId: 'user-2',
        displayName: 'User Two',
        blockedAt: DateTime(2026, 1, 1),
      );
      final userThree = BlockedUserEntity(
        userId: 'user-3',
        displayName: 'User Three',
        blockedAt: DateTime(2026, 1, 1),
      );
      repository.getBlockedUsersHandler = () async => [userTwo, userThree];
      await cubit.load();

      await cubit.unblock('user-2');

      expect(cubit.state.blockedUsers, [userThree]);
      expect(repository.unblockUserCalls, ['user-2']);
    });

    test('rolls back and surfaces an error when the repository call fails', () async {
      final userTwo = BlockedUserEntity(
        userId: 'user-2',
        displayName: 'User Two',
        blockedAt: DateTime(2026, 1, 1),
      );
      repository.getBlockedUsersHandler = () async => [userTwo];
      await cubit.load();
      repository.unblockUserHandler = (_) => Future.error(Exception('boom'));

      await cubit.unblock('user-2');

      expect(cubit.state.blockedUsers, [userTwo]);
      expect(cubit.state.errorMessage, contains('boom'));
    });
  });
}
