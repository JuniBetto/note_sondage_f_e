import 'package:flutter_test/flutter_test.dart';
import 'package:note_sondage/feature/chat/domain/entities/chat_conversation_entity.dart';
import 'package:note_sondage/feature/chat/domain/entities/chat_message_entity.dart';
import 'package:note_sondage/feature/chat/domain/entities/chat_message_reaction_entity.dart';
import 'package:note_sondage/feature/chat/workflow/chat_message_action_draft_service.dart';
import 'package:note_sondage/feature/chat/workflow/chat_message_task_workflow_controller.dart';
import 'package:note_sondage/feature/task/domain/entities/task_create_request_entity.dart';
import 'package:note_sondage/feature/task/domain/entities/task_entity.dart';
import 'package:note_sondage/feature/task/domain/entities/task_status.dart';
import 'package:note_sondage/feature/task/domain/entities/task_update_request_entity.dart';
import 'package:note_sondage/feature/task/domain/repositories/task_repository.dart';
import 'package:note_sondage/feature/task/domain/use_case/task_use_case.dart';
import 'package:note_sondage/feature/team/domain/entities/team_entity.dart';
import 'package:note_sondage/feature/team/domain/entities/team_member_entity.dart';
import 'package:note_sondage/feature/team/domain/entities/user_status.dart';

class _FakeChatMessageActionDraftService extends ChatMessageActionDraftService {
  _FakeChatMessageActionDraftService({required this.result});

  final ChatMessageActionDraftResult result;

  ChatMessageActionType? capturedActionType;
  String? capturedConversationId;
  String? capturedMessageId;
  String? capturedTeamId;
  String? capturedLocale;
  String? capturedSelectedMessageText;
  String? capturedMemberUserId;
  String? capturedMemberDisplayName;

  @override
  Future<ChatMessageActionDraftResult> buildDraft({
    required ChatMessageActionType actionType,
    required String conversationId,
    required String messageId,
    required String teamId,
    required String locale,
    String? selectedMessageText,
    String? memberUserId,
    String? memberDisplayName,
  }) async {
    capturedActionType = actionType;
    capturedConversationId = conversationId;
    capturedMessageId = messageId;
    capturedTeamId = teamId;
    capturedLocale = locale;
    capturedSelectedMessageText = selectedMessageText;
    capturedMemberUserId = memberUserId;
    capturedMemberDisplayName = memberDisplayName;
    return result;
  }
}

class _FakeTaskRepository implements TaskRepository {
  @override
  Future<TaskEntity> archiveTask(String taskId) => throw UnimplementedError();

  @override
  Future<TaskEntity> createTask(TaskCreateRequestEntity request) =>
      throw UnimplementedError();

  @override
  Future<void> deleteTaskPermanently(String taskId) =>
      throw UnimplementedError();

  @override
  Future<TaskEntity> getTaskById(String taskId) => throw UnimplementedError();

  @override
  Future<List<TaskEntity>> getTasksByTeam(String teamId) =>
      throw UnimplementedError();

  @override
  Future<List<TaskEntity>> getArchivedTasksByTeam(String teamId) =>
      throw UnimplementedError();

  @override
  Future<List<TaskEntity>> getLocalOnly() => throw UnimplementedError();

  @override
  Future<List<TaskEntity>> getMyArchivedTasks(String currentUserId) =>
      throw UnimplementedError();

  @override
  Future<List<TaskEntity>> getMyTasks(String currentUserId) =>
      throw UnimplementedError();

  @override
  Future<TaskEntity> unarchiveTask(String taskId) => throw UnimplementedError();

  @override
  Future<TaskEntity> updateTask(
    String taskId,
    TaskUpdateRequestEntity request,
  ) => throw UnimplementedError();

  @override
  Future<TaskEntity> updateTaskStatus(String taskId, TaskStatus status) =>
      throw UnimplementedError();
}

void main() {
  late _FakeChatMessageActionDraftService draftService;
  late ChatMessageTaskWorkflowController controller;

  setUp(() {
    draftService = _FakeChatMessageActionDraftService(
      result: const ChatMessageActionDraftResult(
        messageActionType: 'create_task',
        resolutionStatus: 'ready',
        targetEntityType: 'task',
        warnings: <ChatMessageActionWarning>[],
        taskDraft: TaskCreateRequestEntity(
          teamId: 'team-1',
          title: 'Prepare weekly rota',
        ),
      ),
    );
    controller = ChatMessageTaskWorkflowController(
      draftService: draftService,
      taskUseCase: TaskUseCase(_FakeTaskRepository()),
    );
  });

  group('ChatMessageTaskWorkflowController', () {
    test('prepareDraft delegates create-task draft generation', () async {
      final conversation = ChatConversationEntity(
        id: 'conv-1',
        teamId: 'team-1',
        type: 'TEAM',
        createdAt: DateTime(2026, 8, 21),
        updatedAt: DateTime(2026, 8, 21),
      );
      final message = ChatMessageEntity(
        id: 'msg-9',
        conversationId: 'conv-1',
        senderUserId: 'user-1',
        senderName: 'Arthur',
        senderAvatarUrl: null,
        contentText: 'Serve un task per il turno di lunedi',
        messageType: 'TEXT',
        attachmentPath: null,
        attachmentOriginalName: null,
        attachmentContentType: null,
        attachmentSizeBytes: null,
        replyTo: null,
        reactions: <ChatMessageReactionEntity>[],
        deleted: false,
        deletedAt: null,
        createdAt: DateTime(2026, 8, 21),
        readByCurrentUser: true,
        mine: false,
      );

      final result = await controller.prepareDraft(
        conversation: conversation,
        message: message,
        teamId: 'team-1',
        locale: 'it',
        memberUserId: 'user-2',
        memberDisplayName: 'Mario',
      );

      expect(result, same(draftService.result));
      expect(draftService.capturedActionType, ChatMessageActionType.createTask);
      expect(draftService.capturedConversationId, 'conv-1');
      expect(draftService.capturedMessageId, 'msg-9');
      expect(draftService.capturedTeamId, 'team-1');
      expect(draftService.capturedLocale, 'it');
      expect(
        draftService.capturedSelectedMessageText,
        'Serve un task per il turno di lunedi',
      );
      expect(draftService.capturedMemberUserId, 'user-2');
      expect(draftService.capturedMemberDisplayName, 'Mario');
    });

    test('resolveAvailableTeams keeps only the selected team', () {
      final teams = <TeamEntity>[
        TeamEntity(
          'team-1',
          null,
          null,
          name: 'Sala',
          description: 'Sala principale',
          createdByUserId: 'owner-1',
        ),
        TeamEntity(
          'team-2',
          null,
          null,
          name: 'Cucina',
          description: 'Back office',
          createdByUserId: 'owner-1',
        ),
      ];

      final result = controller.resolveAvailableTeams(
        teams: teams,
        teamId: 'team-2',
      );

      expect(result, hasLength(1));
      expect(result.single.id, 'team-2');
      expect(result.single.name, 'Cucina');
    });

    test('buildAssigneeOptions keeps only active members with a user id', () {
      final members = <TeamMemberEntity>[
        TeamMemberEntity(
          userId: 'user-1',
          userEmail: 'mario@example.com',
          teamId: 'team-1',
          status: UserStatus.active,
          roleId: 'role-1',
          initialName: 'Mario',
        ),
        TeamMemberEntity(
          userId: 'user-2',
          userEmail: 'anna@example.com',
          teamId: 'team-1',
          status: UserStatus.active,
          roleId: 'role-1',
        ),
        TeamMemberEntity(
          userId: null,
          userEmail: 'invited@example.com',
          teamId: 'team-1',
          status: UserStatus.active,
          roleId: 'role-1',
        ),
        TeamMemberEntity(
          userId: 'user-3',
          userEmail: 'suspended@example.com',
          teamId: 'team-1',
          status: UserStatus.deactivated,
          roleId: 'role-1',
        ),
      ];

      final result = controller.buildAssigneeOptions(members);

      expect(result, hasLength(2));
      expect(result.first.userId, 'user-1');
      expect(result.first.label, 'Mario');
      expect(result.first.secondaryLabel, 'mario@example.com');
      expect(result.last.userId, 'user-2');
      expect(result.last.label, 'anna@example.com');
      expect(result.last.secondaryLabel, 'anna@example.com');
    });
  });
}
