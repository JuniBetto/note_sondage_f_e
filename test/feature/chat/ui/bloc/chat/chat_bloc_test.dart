import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:note_sondage/feature/chat/domain/entities/chat_conversation_entity.dart';
import 'package:note_sondage/feature/chat/domain/entities/chat_direct_conversation_summary_entity.dart';
import 'package:note_sondage/feature/chat/domain/entities/chat_message_action_entity.dart';
import 'package:note_sondage/feature/chat/domain/entities/chat_message_entity.dart';
import 'package:note_sondage/feature/chat/domain/entities/chat_message_reaction_entity.dart';
import 'package:note_sondage/feature/chat/domain/entities/chat_team_conversation_summary_entity.dart';
import 'package:note_sondage/feature/chat/domain/repositories/chat_message_action_repository.dart';
import 'package:note_sondage/feature/chat/domain/repositories/chat_repository.dart';
import 'package:note_sondage/feature/chat/domain/use_case/chat_message_action_use_case.dart';
import 'package:note_sondage/feature/chat/domain/use_case/chat_use_case.dart';
import 'package:note_sondage/feature/chat/ui/bloc/chat/chat_bloc.dart';
import 'package:note_sondage/feature/chat/ui/widgets/chat_draft_attachment.dart';
import 'package:note_sondage/feature/chat/workflow/chat_message_event_workflow_controller.dart';
import 'package:note_sondage/feature/chat/workflow/chat_message_shift_workflow_controller.dart';
import 'package:note_sondage/feature/chat/workflow/chat_message_sondage_workflow_controller.dart';
import 'package:note_sondage/feature/chat/workflow/chat_message_suggestion_service.dart';
import 'package:note_sondage/feature/chat/workflow/chat_message_task_workflow_controller.dart';
import 'package:note_sondage/feature/event/domain/entities/event_create_request_entity.dart';
import 'package:note_sondage/feature/event/domain/entities/event_entity.dart';
import 'package:note_sondage/feature/event/domain/entities/event_reminder_anchor.dart';
import 'package:note_sondage/feature/event/domain/entities/event_update_request_entity.dart';
import 'package:note_sondage/feature/event/domain/repositories/event_repository.dart';
import 'package:note_sondage/feature/event/domain/use_case/event_use_case.dart';
import 'package:note_sondage/feature/shift/domain/entities/shift_assignment_create_request_entity.dart';
import 'package:note_sondage/feature/shift/domain/entities/shift_assignment_entity.dart';
import 'package:note_sondage/feature/shift/domain/entities/shift_auto_plan_entity.dart';
import 'package:note_sondage/feature/shift/domain/entities/shift_availability_sondage_draft_request_entity.dart';
import 'package:note_sondage/feature/shift/domain/entities/shift_profile_entity.dart';
import 'package:note_sondage/feature/shift/domain/entities/shift_replacement_candidate_entity.dart';
import 'package:note_sondage/feature/shift/domain/repositories/shift_repository.dart';
import 'package:note_sondage/feature/sondage/domain/entities/sondage_entity.dart';
import 'package:note_sondage/feature/task/domain/entities/task_create_request_entity.dart';
import 'package:note_sondage/feature/task/domain/entities/task_entity.dart';
import 'package:note_sondage/feature/task/domain/entities/task_reminder_anchor.dart';
import 'package:note_sondage/feature/task/domain/entities/task_status.dart';
import 'package:note_sondage/feature/task/domain/entities/task_update_request_entity.dart';
import 'package:note_sondage/feature/task/domain/repositories/task_repository.dart';
import 'package:note_sondage/feature/task/domain/use_case/task_use_case.dart';
import 'package:note_sondage/feature/team/domain/entities/planning_worker_type_entity.dart';
import 'package:note_sondage/feature/team/domain/entities/role_entity.dart';
import 'package:note_sondage/feature/team/domain/entities/team_entity.dart';
import 'package:note_sondage/feature/team/domain/entities/team_invitation_entity.dart';
import 'package:note_sondage/feature/team/domain/entities/team_member_clocking_alarm_override_entity.dart';
import 'package:note_sondage/feature/team/domain/entities/team_member_entity.dart';
import 'package:note_sondage/feature/team/domain/entities/team_member_planning_constraints_entity.dart';
import 'package:note_sondage/feature/team/domain/entities/user_status.dart';
import 'package:note_sondage/feature/team/domain/repositories/role_repository.dart';
import 'package:note_sondage/feature/team/domain/repositories/team_member_repository.dart';
import 'package:note_sondage/feature/team/domain/repositories/team_repository.dart';
import 'package:note_sondage/feature/team/domain/use_case/role/role_use_case.dart';
import 'package:note_sondage/feature/team/domain/use_case/team/team_use_case.dart';
import 'package:note_sondage/feature/team/domain/use_case/team_member/team_member_use_case.dart';

import '../../../../../support/team_fixtures.dart';

class _FakeTeamRepository implements TeamRepository {
  Future<List<TeamEntity>> Function()? getAllHandler;
  int getAllCalls = 0;

  @override
  Future<List<TeamEntity>> getAll() {
    getAllCalls++;
    return getAllHandler?.call() ?? Future.value(const <TeamEntity>[]);
  }

  @override
  Future<TeamEntity> create(TeamEntity team) => throw UnimplementedError();

  @override
  Future<TeamEntity> createByUser(TeamEntity team, String userId) =>
      throw UnimplementedError();

  @override
  Future<bool> delete(String id) => throw UnimplementedError();

  @override
  Future<List<TeamEntity>> getAllByUserId(String userId) =>
      throw UnimplementedError();

  @override
  Future<TeamEntity?> getById(String id) => throw UnimplementedError();

  @override
  Future<List<TeamEntity>> getLocalOnly() => throw UnimplementedError();

  @override
  Future<TeamUpdate> update(TeamUpdate team) => throw UnimplementedError();

  @override
  Future<List<PlanningWorkerTypeEntity>> updatePlanningWorkerTypes(
    String teamId,
    List<PlanningWorkerTypeEntity> workerTypes,
  ) => throw UnimplementedError();
}

class _FakeTeamMemberRepository implements TeamMemberRepository {
  final membersByTeamId = <String, List<TeamMemberEntity>>{};
  final errorForTeamId = <String, Object>{};
  final getAllByTeamIdCalls = <String>[];

  @override
  Future<List<TeamMemberEntity>> getAllByTeamId(String teamId) async {
    getAllByTeamIdCalls.add(teamId);
    final error = errorForTeamId[teamId];
    if (error != null) {
      throw error;
    }
    return membersByTeamId[teamId] ?? const <TeamMemberEntity>[];
  }

  @override
  Future<List<TeamMemberEntity>> getAll() => throw UnimplementedError();

  @override
  Future<TeamMemberEntity?> getById(String id) => throw UnimplementedError();

  @override
  Future<TeamMemberEntity> create(TeamMemberEntity member) =>
      throw UnimplementedError();

  @override
  Future<TeamMemberEntity> update(TeamMemberEntity member) =>
      throw UnimplementedError();

  @override
  Future<bool> delete(String id) => throw UnimplementedError();

  @override
  Future<bool> inviteMember(String teamId, String email, String roleId) =>
      throw UnimplementedError();

  @override
  Future<List<TeamInvitationEntity>> getPendingInvitations(String teamId) =>
      throw UnimplementedError();

  @override
  Future<void> cancelInvitation(String teamId, String invitationId) =>
      throw UnimplementedError();

  @override
  Future<TeamMemberEntity> updatePlanningConstraints({
    required String teamId,
    required String memberId,
    required TeamMemberPlanningConstraintsEntity constraints,
  }) => throw UnimplementedError();

  @override
  Future<TeamMemberEntity> updateClockingAlarmOverride({
    required String teamId,
    required String memberId,
    required TeamMemberClockingAlarmOverrideEntity override,
  }) => throw UnimplementedError();

  @override
  Future<TeamMemberEntity> uploadProfileImage({
    required String memberId,
    File? imageFile,
    Uint8List? imageBytes,
    String? fileName,
  }) => throw UnimplementedError();
}

class _FakeRoleRepository implements RoleRepository {
  final rolesByTeamId = <String, List<RoleEntity>>{};
  final errorForTeamId = <String, Object>{};
  final getAllRolesByTeamIdCalls = <String>[];

  @override
  Future<List<RoleEntity>> getAllRolesByTeamId(String teamId) async {
    getAllRolesByTeamIdCalls.add(teamId);
    final error = errorForTeamId[teamId];
    if (error != null) {
      throw error;
    }
    return rolesByTeamId[teamId] ?? const <RoleEntity>[];
  }

  @override
  Future<List<RoleEntity>> getAll() => throw UnimplementedError();

  @override
  Future<RoleEntity?> getRoleById(String id) => throw UnimplementedError();

  @override
  Future<RoleEntity> createRole(RoleEntity role) => throw UnimplementedError();

  @override
  Future<RoleEntity> updateRole(RoleEntity role) => throw UnimplementedError();

  @override
  Future<bool> deleteRole(String id) => throw UnimplementedError();
}

class _FakeChatRepository implements ChatRepository {
  ChatConversationEntity? cachedTeamConversation;
  ChatConversationEntity? cachedDirectConversation;
  List<ChatMessageEntity> cachedMessages = const <ChatMessageEntity>[];

  Future<ChatConversationEntity> Function(String teamId)?
  getOrCreateTeamConversationHandler;
  Future<ChatConversationEntity> Function(String teamId, String memberUserId)?
  getOrCreateDirectConversationHandler;
  Future<List<ChatMessageEntity>> Function({DateTime? before, int limit})?
  getMessagesHandler;
  Future<ChatMessageEntity> Function(String content, {String? replyToMessageId})?
  sendMessageHandler;
  Future<ChatMessageEntity> Function({
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

  final getMessagesCalls =
      <({String conversationId, DateTime? before, int limit})>[];
  final markConversationReadCalls = <String>[];

  @override
  ChatConversationEntity? getCachedTeamConversation(String teamId) =>
      cachedTeamConversation;

  @override
  ChatConversationEntity? getCachedDirectConversation(
    String teamId,
    String memberUserId,
  ) => cachedDirectConversation;

  @override
  List<ChatMessageEntity> getCachedMessages(String conversationId) =>
      cachedMessages;

  @override
  Future<ChatConversationEntity> getOrCreateTeamConversation(
    String teamId,
  ) => getOrCreateTeamConversationHandler!(teamId);

  @override
  Future<ChatConversationEntity> getOrCreateDirectConversation(
    String teamId,
    String memberUserId,
  ) => getOrCreateDirectConversationHandler!(teamId, memberUserId);

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
    return getMessagesHandler!(before: before, limit: limit);
  }

  @override
  Future<ChatMessageEntity> sendMessage(
    String conversationId,
    String content, {
    String? replyToMessageId,
  }) => sendMessageHandler!(content, replyToMessageId: replyToMessageId);

  @override
  Future<ChatMessageEntity> sendAttachmentMessage(
    String conversationId, {
    String? content,
    required List<int> bytes,
    required String fileName,
    required String contentType,
    String? replyToMessageId,
  }) => sendAttachmentMessageHandler!(
    content: content,
    bytes: bytes,
    fileName: fileName,
    contentType: contentType,
    replyToMessageId: replyToMessageId,
  );

  @override
  Future<ChatMessageEntity> toggleReaction(String messageId, String emoji) =>
      toggleReactionHandler!(messageId, emoji);

  @override
  Future<ChatMessageEntity> deleteMessage(String messageId) =>
      deleteMessageHandler!(messageId);

  @override
  Future<void> markConversationRead(String conversationId) async {
    markConversationReadCalls.add(conversationId);
  }

  @override
  ChatTeamConversationSummaryEntity? getCachedTeamSummary(String teamId) =>
      throw UnimplementedError();

  @override
  ChatDirectConversationSummaryEntity? getCachedDirectSummary(
    String teamId,
    String memberUserId,
  ) => throw UnimplementedError();

  @override
  Future<ChatTeamConversationSummaryEntity> getTeamConversationSummary(
    String teamId,
  ) => throw UnimplementedError();

  @override
  Future<ChatDirectConversationSummaryEntity> getDirectConversationSummary(
    String teamId,
    String memberUserId,
  ) => throw UnimplementedError();
}

class _FakeChatMessageActionRepository implements ChatMessageActionRepository {
  final resultByActionType = <ChatMessageActionType, ChatMessageActionDraftResult>{};
  final errorByActionType = <ChatMessageActionType, Object>{};
  final buildDraftCalls = <ChatMessageActionType>[];

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
    buildDraftCalls.add(actionType);
    final error = errorByActionType[actionType];
    if (error != null) {
      throw error;
    }
    return resultByActionType[actionType]!;
  }
}

class _ThrowingTaskRepository implements TaskRepository {
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
  @override
  Future<TaskEntity> updateMyReminder(
    String taskId,
    List<int> reminderOffsets,
    TaskReminderAnchor reminderAnchor,
  ) => throw UnimplementedError();
}

class _ThrowingShiftRepository implements ShiftRepository {
  @override
  Future<List<ShiftProfileEntity>> getProfiles() => throw UnimplementedError();
  @override
  Future<ShiftProfileEntity> createProfile({
    required String name,
    required TimeOfDay startTime,
    required TimeOfDay endTime,
    required bool overnight,
    required List<int> alarmOffsets,
    String? color,
    bool isPublic = false,
  }) => throw UnimplementedError();
  @override
  Future<ShiftProfileEntity> updateProfile(
    String profileId, {
    required String name,
    required TimeOfDay startTime,
    required TimeOfDay endTime,
    required bool overnight,
    required List<int> alarmOffsets,
    String? color,
    bool isPublic = false,
  }) => throw UnimplementedError();
  @override
  Future<void> deleteProfile(String profileId) => throw UnimplementedError();
  @override
  Future<void> hideSystemProfile(String profileId) =>
      throw UnimplementedError();
  @override
  Future<List<ShiftAssignmentEntity>> getAssignments({
    required DateTime from,
    required DateTime to,
    List<String>? visibleTeamIds,
    List<String>? visibleUserIds,
  }) => throw UnimplementedError();
  @override
  Future<ShiftAssignmentEntity> assign({
    required DateTime shiftDate,
    String? profileId,
    TimeOfDay? startTime,
    TimeOfDay? endTime,
    bool? overnight,
    String? note,
    List<int>? alarmOffsets,
    bool isPublic = false,
    String? teamId,
    String? teamShiftGroupId,
    String? targetUserId,
  }) => throw UnimplementedError();
  @override
  Future<List<ShiftAssignmentEntity>> assignBatch({
    required List<ShiftAssignmentCreateRequestEntity> requests,
  }) => throw UnimplementedError();
  @override
  Future<ShiftAssignmentEntity> updateAssignment(
    String assignmentId, {
    String? profileId,
    TimeOfDay? startTime,
    TimeOfDay? endTime,
    bool? overnight,
    String? note,
    List<int>? alarmOffsets,
    bool isPublic = false,
    String? teamId,
    String? teamShiftGroupId,
    String? targetUserId,
  }) => throw UnimplementedError();
  @override
  Future<void> deleteAssignment(String assignmentId) =>
      throw UnimplementedError();
  @override
  Future<void> requestAssignmentChange(
    String assignmentId, {
    String? profileId,
    TimeOfDay? startTime,
    TimeOfDay? endTime,
    bool? overnight,
    String? note,
    List<int>? alarmOffsets,
  }) => throw UnimplementedError();
  @override
  Future<void> requestAssignmentSwap(
    String assignmentId, {
    required String candidateUserId,
    String? note,
  }) => throw UnimplementedError();
  @override
  Future<ShiftReplacementCandidatesEntity> findReplacementCandidates(
    String assignmentId,
  ) => throw UnimplementedError();
  @override
  Future<void> offerReplacement(
    String assignmentId, {
    required String candidateFirebaseUid,
  }) => throw UnimplementedError();
  @override
  Future<SondageEntity> createAvailabilitySondageDraft(
    String assignmentId,
    ShiftAvailabilitySondageDraftRequestEntity request,
  ) => throw UnimplementedError();
  @override
  Future<ShiftAutoPlanResultEntity> autoPlan(
    ShiftAutoPlanRequestEntity request,
  ) => throw UnimplementedError();
  @override
  Future<ShiftAutoPlanPreviewEntity> previewAutoPlan(
    ShiftAutoPlanRequestEntity request,
  ) => throw UnimplementedError();
  @override
  Future<ShiftAutoPlanPreviewEntity> recalculateAutoPlanPreview(
    String snapshotToken,
    List<ShiftAutoPlanDraftAssignmentEntity> draftAssignments,
  ) => throw UnimplementedError();
  @override
  Future<ShiftAutoPlanResultEntity> confirmAutoPlan(String snapshotToken) =>
      throw UnimplementedError();
}

class _ThrowingEventRepository implements EventRepository {
  @override
  Future<EventEntity> createEvent(EventCreateRequestEntity request) =>
      throw UnimplementedError();
  @override
  Future<List<EventEntity>> getEventsByTeam(String? teamId) =>
      throw UnimplementedError();
  @override
  Future<List<EventEntity>> getArchivedEventsByTeam(String? teamId) =>
      throw UnimplementedError();
  @override
  Future<EventEntity> getEventById(String eventId) =>
      throw UnimplementedError();
  @override
  Future<EventEntity> updateEvent(
    String eventId,
    EventUpdateRequestEntity request,
  ) => throw UnimplementedError();
  @override
  Future<EventEntity> updateMyReminder(
    String eventId,
    List<int> reminderOffsets,
    EventReminderAnchor reminderAnchor,
  ) => throw UnimplementedError();
  @override
  Future<EventEntity> archiveEvent(String eventId) =>
      throw UnimplementedError();
  @override
  Future<EventEntity> unarchiveEvent(String eventId) =>
      throw UnimplementedError();
  @override
  Future<void> deleteEventPermanently(String eventId) =>
      throw UnimplementedError();
}

class _FakeHttpClientAdapter implements HttpClientAdapter {
  RequestOptions? lastRequest;
  String responseBody = '{}';

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    lastRequest = options;
    return ResponseBody.fromString(
      responseBody,
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

ChatConversationEntity _buildConversation({
  String id = 'conversation-1',
  String teamId = 'team-1',
  String type = 'TEAM',
  String? participantUserId,
  String? participantDisplayName,
  DateTime? lastMessageAt,
}) {
  return ChatConversationEntity(
    id: id,
    teamId: teamId,
    type: type,
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
    participantUserId: participantUserId,
    participantDisplayName: participantDisplayName,
    lastMessageAt: lastMessageAt,
  );
}

ChatMessageEntity _buildMessage({
  String id = 'message-1',
  String conversationId = 'conversation-1',
  bool mine = false,
  bool readByCurrentUser = true,
  DateTime? createdAt,
  String contentText = 'Ciao',
}) {
  return ChatMessageEntity(
    id: id,
    conversationId: conversationId,
    senderUserId: 'user-1',
    senderName: 'Mario Rossi',
    senderAvatarUrl: null,
    contentText: contentText,
    messageType: 'TEXT',
    attachmentPath: null,
    attachmentOriginalName: null,
    attachmentContentType: null,
    attachmentSizeBytes: null,
    replyTo: null,
    reactions: const <ChatMessageReactionEntity>[],
    deleted: false,
    deletedAt: null,
    createdAt: createdAt ?? DateTime(2026, 1, 1),
    readByCurrentUser: readByCurrentUser,
    mine: mine,
  );
}

void main() {
  late _FakeTeamRepository teamRepository;
  late _FakeTeamMemberRepository teamMemberRepository;
  late _FakeRoleRepository roleRepository;
  late _FakeChatRepository chatRepository;
  late _FakeChatMessageActionRepository actionRepository;
  late _FakeHttpClientAdapter suggestionAdapter;
  late ChatBloc bloc;

  setUp(() {
    teamRepository = _FakeTeamRepository();
    teamMemberRepository = _FakeTeamMemberRepository();
    roleRepository = _FakeRoleRepository();
    chatRepository = _FakeChatRepository();
    actionRepository = _FakeChatMessageActionRepository();
    suggestionAdapter = _FakeHttpClientAdapter();
    final actionUseCase = ChatMessageActionUseCase(actionRepository);
    final suggestionDio = Dio(BaseOptions(baseUrl: 'https://example.test'))
      ..httpClientAdapter = suggestionAdapter;
    bloc = ChatBloc(
      teamUseCase: TeamUseCase(teamRepository),
      teamMemberUseCase: TeamMemberUseCase(teamMemberRepository),
      roleUseCase: RoleUseCase(roleRepository),
      chatUseCase: ChatUseCase(chatRepository),
      sondageWorkflowController: ChatMessageSondageWorkflowController(
        draftService: actionUseCase,
      ),
      taskWorkflowController: ChatMessageTaskWorkflowController(
        draftService: actionUseCase,
        taskUseCase: TaskUseCase(_ThrowingTaskRepository()),
      ),
      shiftWorkflowController: ChatMessageShiftWorkflowController(
        draftService: actionUseCase,
        shiftRepository: _ThrowingShiftRepository(),
      ),
      eventWorkflowController: ChatMessageEventWorkflowController(
        draftService: actionUseCase,
        eventUseCase: EventUseCase(_ThrowingEventRepository()),
      ),
      suggestionService: ChatMessageSuggestionService(dio: suggestionDio),
    );
  });

  tearDown(() async => bloc.close());

  group('ChatBloc teams', () {
    test(
      'ChatTeamsRequested selects the first team when none is preferred',
      () async {
        final teams = [buildTeam(), buildTeam(id: 'team-2', name: 'Design')];
        teamRepository.getAllHandler = () async => teams;

        final emittedStates = <ChatState>[];
        final subscription = bloc.stream.listen(emittedStates.add);

        bloc.add(const ChatTeamsRequested());
        await pumpEventQueue();

        expect(emittedStates.first.loadingTeams, isTrue);
        final loaded = emittedStates.last;
        expect(loaded.loadingTeams, isFalse);
        expect(loaded.teams, teams);
        expect(loaded.selectedTeamId, 'team-1');

        await subscription.cancel();
      },
    );

    test(
      'ChatTeamsRequested honors an explicit preferredTeamId over the '
      'current selection',
      () async {
        final teams = [buildTeam(), buildTeam(id: 'team-2', name: 'Design')];
        teamRepository.getAllHandler = () async => teams;

        final emittedStates = <ChatState>[];
        final subscription = bloc.stream.listen(emittedStates.add);

        bloc.add(const ChatTeamsRequested(preferredTeamId: 'team-2'));
        await pumpEventQueue();

        expect(emittedStates.last.selectedTeamId, 'team-2');

        await subscription.cancel();
      },
    );

    test(
      'ChatTeamsRequested keeps the current selection when it is still '
      'valid and nothing is explicitly preferred',
      () async {
        teamRepository.getAllHandler = () async => [
          buildTeam(),
          buildTeam(id: 'team-2', name: 'Design'),
        ];
        bloc.add(const ChatTeamsRequested(preferredTeamId: 'team-2'));
        await pumpEventQueue();
        expect(bloc.state.selectedTeamId, 'team-2');

        bloc.add(const ChatTeamsRequested());
        await pumpEventQueue();

        expect(bloc.state.selectedTeamId, 'team-2');
      },
    );

    test('ChatTeamsRequested clears the selection when there are no teams', () async {
      teamRepository.getAllHandler = () async => const <TeamEntity>[];

      bloc.add(const ChatTeamsRequested());
      await pumpEventQueue();

      expect(bloc.state.teams, isEmpty);
      expect(bloc.state.selectedTeamId, isNull);
    });

    test(
      'ChatTeamsRequested surfaces a transient error and stops loading on '
      'failure',
      () async {
        teamRepository.getAllHandler = () =>
            Future<List<TeamEntity>>.error(Exception('backend down'));

        bloc.add(const ChatTeamsRequested());
        await pumpEventQueue();

        expect(bloc.state.loadingTeams, isFalse);
        expect(bloc.state.transient, isA<ChatErrorOccurred>());
      },
    );
  });

  group('ChatBloc team access context', () {
    test(
      'ChatTeamAccessContextRequested loads and caches members and roles',
      () async {
        teamMemberRepository.membersByTeamId['team-1'] = [
          TeamMemberEntity(
            userId: 'user-1',
            userEmail: 'mario@example.com',
            teamId: 'team-1',
            status: UserStatus.active,
            roleId: 'role-1',
          ),
        ];
        roleRepository.rolesByTeamId['team-1'] = [
          RoleEntity('role-1', teamId: 'team-1', name: 'Admin', permissions: const []),
        ];

        bloc.add(const ChatTeamAccessContextRequested('team-1'));
        await pumpEventQueue();

        expect(bloc.state.teamMembersByTeamId['team-1'], hasLength(1));
        expect(bloc.state.rolesByTeamId['team-1'], hasLength(1));
        expect(
          bloc.state.transient,
          isA<ChatTeamAccessContextReady>().having(
            (t) => t.teamId,
            'teamId',
            'team-1',
          ),
        );
      },
    );

    test(
      'ChatTeamAccessContextRequested does not refetch an already-cached team',
      () async {
        teamMemberRepository.membersByTeamId['team-1'] = const [];
        roleRepository.rolesByTeamId['team-1'] = const [];

        bloc.add(const ChatTeamAccessContextRequested('team-1'));
        await pumpEventQueue();
        bloc.add(const ChatTeamAccessContextRequested('team-1'));
        await pumpEventQueue();

        expect(teamMemberRepository.getAllByTeamIdCalls, ['team-1']);
        expect(roleRepository.getAllRolesByTeamIdCalls, ['team-1']);
        // Ready fires even on the fully-cached second dispatch, so a caller
        // awaiting it via bloc.stream.firstWhere never hangs.
        expect(
          bloc.state.transient,
          isA<ChatTeamAccessContextReady>().having(
            (t) => t.teamId,
            'teamId',
            'team-1',
          ),
        );
      },
    );

    test(
      'ChatTeamAccessContextRequested fired twice back-to-back for the same '
      'team only fetches once (sequential processing + cache check dedupe)',
      () async {
        bloc
          ..add(const ChatTeamAccessContextRequested('team-1'))
          ..add(const ChatTeamAccessContextRequested('team-1'));
        await pumpEventQueue();

        expect(teamMemberRepository.getAllByTeamIdCalls, ['team-1']);
        expect(roleRepository.getAllRolesByTeamIdCalls, ['team-1']);
      },
    );

    test(
      'ChatTeamAccessContextRequested silently swallows errors without '
      'crashing the bloc',
      () async {
        teamMemberRepository.errorForTeamId['team-1'] = Exception('boom');
        roleRepository.errorForTeamId['team-1'] = Exception('boom');

        bloc.add(const ChatTeamAccessContextRequested('team-1'));
        await pumpEventQueue();

        expect(bloc.state.teamMembersByTeamId.containsKey('team-1'), isFalse);
        expect(bloc.state.rolesByTeamId.containsKey('team-1'), isFalse);
        // Ready still fires on failure — a caller awaiting it must not hang
        // forever just because the fetch didn't succeed.
        expect(
          bloc.state.transient,
          isA<ChatTeamAccessContextReady>().having(
            (t) => t.teamId,
            'teamId',
            'team-1',
          ),
        );
      },
    );

    test('ChatTeamAccessContextRequested ignores a blank team id', () async {
      bloc.add(const ChatTeamAccessContextRequested('  '));
      await pumpEventQueue();

      expect(teamMemberRepository.getAllByTeamIdCalls, isEmpty);
      expect(roleRepository.getAllRolesByTeamIdCalls, isEmpty);
    });
  });

  group('ChatBloc conversation', () {
    test(
      'ChatConversationRequested renders the cache first, then reconciles '
      'with the server',
      () async {
        final cached = _buildConversation(lastMessageAt: DateTime(2026, 1, 1));
        final cachedMessages = [_buildMessage(id: 'cached-1')];
        chatRepository.cachedTeamConversation = cached;
        chatRepository.cachedMessages = cachedMessages;
        final fresh = _buildConversation();
        final freshMessages = [_buildMessage(id: 'fresh-1')];
        chatRepository.getOrCreateTeamConversationHandler =
            (_) async => fresh;
        chatRepository.getMessagesHandler =
            ({before, limit = 50}) async => freshMessages;

        final emittedStates = <ChatState>[];
        final subscription = bloc.stream.listen(emittedStates.add);

        bloc.add(const ChatConversationRequested('team-1'));
        await pumpEventQueue();

        expect(emittedStates.first.messages, cachedMessages);
        expect(emittedStates.first.transient, isA<ChatConversationOpened>());
        expect(emittedStates.last.messages, freshMessages);
        expect(emittedStates.last.loadingMessages, isFalse);
        expect(emittedStates.last.transient, isA<ChatConversationOpened>());

        await subscription.cancel();
      },
    );

    test(
      'ChatConversationRequested shows a loading state when nothing is '
      'cached',
      () async {
        chatRepository.getOrCreateTeamConversationHandler =
            (_) async => _buildConversation();
        chatRepository.getMessagesHandler =
            ({before, limit = 50}) async => const <ChatMessageEntity>[];

        final emittedStates = <ChatState>[];
        final subscription = bloc.stream.listen(emittedStates.add);

        bloc.add(const ChatConversationRequested('team-1'));
        await pumpEventQueue();

        expect(emittedStates.first.loadingMessages, isTrue);
        expect(emittedStates.first.refreshingMessages, isFalse);
        // Fires even on a cold, nothing-cached open: lets the widget clear a
        // *previous* conversation's messages from view right away.
        expect(emittedStates.first.transient, isA<ChatConversationOpened>());
        await subscription.cancel();
      },
    );

    test(
      'ChatConversationRequested with a memberUserId opens the direct '
      'conversation',
      () async {
        chatRepository.getOrCreateDirectConversationHandler =
            (_, _) async => _buildConversation(
              type: 'DIRECT',
              participantUserId: 'member-1',
              participantDisplayName: 'Anna',
            );
        chatRepository.getMessagesHandler =
            ({before, limit = 50}) async => const <ChatMessageEntity>[];

        bloc.add(
          const ChatConversationRequested('team-1', memberUserId: 'member-1'),
        );
        await pumpEventQueue();

        expect(bloc.state.selectedMemberUserId, 'member-1');
        expect(bloc.state.conversationDisplayName, 'Anna');
      },
    );

    test(
      'ChatConversationRequested also dispatches ChatTeamAccessContextRequested',
      () async {
        chatRepository.getOrCreateTeamConversationHandler =
            (_) async => _buildConversation();
        chatRepository.getMessagesHandler =
            ({before, limit = 50}) async => const <ChatMessageEntity>[];
        teamMemberRepository.membersByTeamId['team-1'] = const [];
        roleRepository.rolesByTeamId['team-1'] = const [];

        bloc.add(const ChatConversationRequested('team-1'));
        await pumpEventQueue();

        expect(teamMemberRepository.getAllByTeamIdCalls, ['team-1']);
      },
    );

    test('ChatConversationRequested surfaces a transient error on failure', () async {
      chatRepository.getOrCreateTeamConversationHandler =
          (_) => Future.error(Exception('down'));

      // ChatConversationRequested also fires-and-forgets a
      // ChatTeamAccessContextRequested, which races independently and may
      // emit its own ChatTeamAccessContextReady transient afterwards — so
      // assert the error was emitted at some point in the stream, the way a
      // real BlocListener would observe it, rather than on the final
      // settled state (which the other handler's later emit can reasonably
      // move on from).
      final emittedStates = <ChatState>[];
      final subscription = bloc.stream.listen(emittedStates.add);

      bloc.add(const ChatConversationRequested('team-1'));
      await pumpEventQueue();

      expect(bloc.state.loadingMessages, isFalse);
      expect(emittedStates.map((s) => s.transient), contains(isA<ChatErrorOccurred>()));

      await subscription.cancel();
    });
  });

  group('ChatBloc messages refresh', () {
    test('ChatMessagesRefreshRequested merges the latest page in', () async {
      chatRepository.getOrCreateTeamConversationHandler =
          (_) async => _buildConversation();
      chatRepository.getMessagesHandler =
          ({before, limit = 50}) async => [_buildMessage(id: 'initial')];
      bloc.add(const ChatConversationRequested('team-1'));
      await pumpEventQueue();

      chatRepository.getMessagesHandler = ({before, limit = 50}) async => [
        _buildMessage(id: 'initial', createdAt: DateTime(2026, 1, 1)),
        _buildMessage(id: 'new', createdAt: DateTime(2026, 1, 2)),
      ];
      bloc.add(const ChatMessagesRefreshRequested());
      await pumpEventQueue();

      expect(bloc.state.messages.map((m) => m.id), ['initial', 'new']);
      expect(bloc.state.refreshingMessages, isFalse);
      // Lets a caller (the widget's own _refreshMessages bridge) await
      // completion via bloc.stream.firstWhere(...) without depending on the
      // shared refreshingMessages flag, which conversation-loading also uses.
      expect(bloc.state.transient, isA<ChatMessagesRefreshed>());
    });

    test('ChatMessagesRefreshRequested is a no-op without an open conversation', () async {
      bloc.add(const ChatMessagesRefreshRequested());
      await pumpEventQueue();

      expect(bloc.state.messages, isEmpty);
    });

    test('ChatMessagesRefreshRequested fails silently (best effort)', () async {
      chatRepository.getOrCreateTeamConversationHandler =
          (_) async => _buildConversation();
      chatRepository.getMessagesHandler =
          ({before, limit = 50}) async => const <ChatMessageEntity>[];
      bloc.add(const ChatConversationRequested('team-1'));
      await pumpEventQueue();

      chatRepository.getMessagesHandler =
          ({before, limit = 50}) => Future.error(Exception('down'));
      bloc.add(const ChatMessagesRefreshRequested());
      await pumpEventQueue();

      expect(bloc.state.refreshingMessages, isFalse);
      // Best-effort: a failed background refresh must not surface an error
      // transient — but it still fires ChatMessagesRefreshed (on both
      // success and failure) so a caller awaiting completion never hangs.
      expect(bloc.state.transient, isA<ChatMessagesRefreshed>());
    });
  });

  group('ChatBloc older messages pagination', () {
    Future<void> openConversationWith(List<ChatMessageEntity> messages) async {
      chatRepository.getOrCreateTeamConversationHandler =
          (_) async => _buildConversation();
      chatRepository.getMessagesHandler =
          ({before, limit = 50}) async => messages;
      bloc.add(const ChatConversationRequested('team-1'));
      await pumpEventQueue();
    }

    // A full page (>= ChatBloc's internal initial-messages limit of 100) is
    // needed so the conversation-load handler sets hasMoreOlderMessages to
    // true — otherwise (e.g. opening with just 1 message) it correctly
    // concludes there's nothing more to paginate, and pagination requests
    // become no-ops, per the guard this group tests around.
    List<ChatMessageEntity> fullInitialPage({String latestId = 'current-1'}) {
      final padding = List<ChatMessageEntity>.generate(
        99,
        (i) => _buildMessage(
          id: 'pad-$i',
          createdAt: DateTime(2026, 1, 1).add(Duration(minutes: i)),
        ),
      );
      return [
        ...padding,
        _buildMessage(id: latestId, createdAt: DateTime(2026, 1, 5)),
      ];
    }

    test('ChatOlderMessagesRequested prepends unique older messages', () async {
      await openConversationWith(fullInitialPage());
      expect(bloc.state.hasMoreOlderMessages, isTrue);
      final oldestLoadedTimestamp = bloc.state.messages.first.createdAt;

      chatRepository.getMessagesHandler = ({before, limit = 50}) async => [
        _buildMessage(id: 'older-1', createdAt: DateTime(2025, 12, 30)),
        _buildMessage(id: 'older-2', createdAt: DateTime(2025, 12, 31)),
      ];

      bloc.add(const ChatOlderMessagesRequested());
      await pumpEventQueue();

      expect(
        bloc.state.messages.take(2).map((m) => m.id),
        ['older-1', 'older-2'],
      );
      expect(bloc.state.messages, hasLength(102));
      expect(bloc.state.messages.last.id, 'current-1');
      expect(chatRepository.getMessagesCalls.last.before, oldestLoadedTimestamp);
      expect(bloc.state.loadingOlderMessages, isFalse);
      expect(bloc.state.transient, isA<ChatOlderMessagesLoaded>());
    });

    test(
      'ChatOlderMessagesRequested fired twice back-to-back fetches two '
      'different pages rather than racing on the same one (sequential '
      'processing — same fix as ChatTeamAccessContextRequested)',
      () async {
        await openConversationWith(fullInitialPage());
        final firstCursor = bloc.state.messages.first.createdAt;
        // A full batch (>= 70) for both pages so hasMoreOlderMessages stays
        // true after the first fetch settles — otherwise the second
        // dispatch would legitimately no-op on "nothing more to paginate"
        // rather than exercising the race this test targets. Oldest-first
        // within each batch, matching what the bloc expects to prepend
        // as-is (it does not re-sort after merging older pages in).
        chatRepository.getMessagesHandler = ({before, limit = 50}) async {
          final isFirstPage = before == firstCursor;
          final pageStart = isFirstPage
              ? firstCursor.subtract(const Duration(minutes: 70))
              : firstCursor.subtract(const Duration(minutes: 140));
          return List<ChatMessageEntity>.generate(
            70,
            (i) => _buildMessage(
              id: '${isFirstPage ? 'page1' : 'page2'}-$i',
              createdAt: pageStart.add(Duration(minutes: i)),
            ),
          );
        };

        bloc
          ..add(const ChatOlderMessagesRequested())
          ..add(const ChatOlderMessagesRequested());
        await pumpEventQueue();

        // Had the two dispatches raced (both reading the stale `before`
        // cursor before either completed), both would have fetched "page1"
        // and "page2" messages would never appear. Sequential processing
        // guarantees the second dispatch sees the first dispatch's
        // already-updated cursor and fetches the next page instead.
        expect(bloc.state.messages.first.id, 'page2-0');
      },
    );

    test(
      'ChatOlderMessagesRequested dedupes messages already present '
      '(e.g. raced with a refresh)',
      () async {
        await openConversationWith(fullInitialPage());
        final oldestId = bloc.state.messages.first.id;
        chatRepository.getMessagesHandler = ({before, limit = 50}) async => [
          _buildMessage(id: 'older-1', createdAt: DateTime(2025, 12, 30)),
          bloc.state.messages.first, // already present, must not duplicate
        ];

        bloc.add(const ChatOlderMessagesRequested());
        await pumpEventQueue();

        expect(bloc.state.messages.first.id, 'older-1');
        expect(bloc.state.messages.where((m) => m.id == oldestId), hasLength(1));
        expect(bloc.state.messages, hasLength(101));
      },
    );

    test(
      'ChatOlderMessagesRequested stops pagination once nothing new comes '
      'back',
      () async {
        await openConversationWith(fullInitialPage());
        final messagesBeforePagination = bloc.state.messages;
        chatRepository.getMessagesHandler = ({before, limit = 50}) async =>
            // The server has nothing older than what's already loaded.
            <ChatMessageEntity>[bloc.state.messages.first];

        bloc.add(const ChatOlderMessagesRequested());
        await pumpEventQueue();

        expect(bloc.state.hasMoreOlderMessages, isFalse);
        expect(
          bloc.state.messages.map((m) => m.id),
          messagesBeforePagination.map((m) => m.id),
        );
      },
    );

    test('ChatOlderMessagesRequested is a no-op with an empty message list', () async {
      await openConversationWith(const <ChatMessageEntity>[]);

      bloc.add(const ChatOlderMessagesRequested());
      await pumpEventQueue();

      expect(chatRepository.getMessagesCalls, hasLength(1)); // only the initial load
    });

    test(
      'ChatOlderMessagesRequested is a no-op once hasMoreOlderMessages is '
      'false',
      () async {
        // A short first page (below the initial-load limit) already means
        // there's nothing more to paginate.
        await openConversationWith([
          _buildMessage(id: 'current-1', createdAt: DateTime(2026, 1, 5)),
        ]);
        expect(bloc.state.hasMoreOlderMessages, isFalse);
        final callsSoFar = chatRepository.getMessagesCalls.length;

        bloc.add(const ChatOlderMessagesRequested());
        await pumpEventQueue();

        expect(chatRepository.getMessagesCalls, hasLength(callsSoFar));
      },
    );
  });

  group('ChatBloc composer', () {
    test('ChatAttachmentSelected and ChatAttachmentCleared update state', () async {
      const attachment = ChatDraftAttachment(
        bytes: [1, 2, 3],
        fileName: 'photo.png',
        contentType: 'image/png',
        sizeBytes: 3,
      );
      bloc.add(const ChatAttachmentSelected(attachment));
      await pumpEventQueue();
      expect(bloc.state.selectedAttachment, same(attachment));

      bloc.add(const ChatAttachmentCleared());
      await pumpEventQueue();
      expect(bloc.state.selectedAttachment, isNull);
    });

    test('ChatReplyTargetSet and ChatReplyTargetCleared update state', () async {
      final message = _buildMessage();
      bloc.add(ChatReplyTargetSet(message));
      await pumpEventQueue();
      expect(bloc.state.replyTarget, same(message));

      bloc.add(const ChatReplyTargetCleared());
      await pumpEventQueue();
      expect(bloc.state.replyTarget, isNull);
    });

    test('ChatDraftRestored puts the attachment and reply target back', () async {
      const attachment = ChatDraftAttachment(
        bytes: [1],
        fileName: 'a.png',
        contentType: 'image/png',
        sizeBytes: 1,
      );
      final replyTarget = _buildMessage();

      bloc.add(
        ChatDraftRestored(attachment: attachment, replyTarget: replyTarget),
      );
      await pumpEventQueue();

      expect(bloc.state.selectedAttachment, same(attachment));
      expect(bloc.state.replyTarget, same(replyTarget));
    });
  });

  group('ChatBloc send message', () {
    Future<void> openConversation() async {
      chatRepository.getOrCreateTeamConversationHandler =
          (_) async => _buildConversation();
      chatRepository.getMessagesHandler =
          ({before, limit = 50}) async => const <ChatMessageEntity>[];
      bloc.add(const ChatConversationRequested('team-1'));
      await pumpEventQueue();
    }

    test(
      'ChatMessageSendRequested inserts an optimistic message, then '
      'reconciles it with the server response by id',
      () async {
        await openConversation();
        final serverMessage = _buildMessage(id: 'server-1');
        chatRepository.sendMessageHandler =
            (content, {replyToMessageId}) async => serverMessage;

        final emittedStates = <ChatState>[];
        final subscription = bloc.stream.listen(emittedStates.add);

        bloc.add(
          const ChatMessageSendRequested(
            content: 'Ciao',
            actorDisplayName: 'You',
          ),
        );
        await pumpEventQueue();

        final optimisticState = emittedStates.first;
        expect(optimisticState.messages, hasLength(1));
        expect(optimisticState.messages.single.id, startsWith('local-'));
        expect(optimisticState.messages.single.senderName, 'You');
        expect(optimisticState.sending, isTrue);
        // Fires on the optimistic insert too, not just the reconcile below —
        // the widget scrolls to the new message at both points.
        expect(optimisticState.transient, isA<ChatMessageSent>());

        final finalState = emittedStates.last;
        expect(finalState.messages, [serverMessage]);
        expect(finalState.sending, isFalse);
        expect(finalState.transient, isA<ChatMessageSent>());

        await subscription.cancel();
      },
    );

    test(
      'ChatMessageSendRequested clears the selected attachment and reply '
      'target optimistically',
      () async {
        await openConversation();
        chatRepository.sendMessageHandler =
            (content, {replyToMessageId}) async => _buildMessage();
        bloc.add(ChatAttachmentSelected(
          const ChatDraftAttachment(
            bytes: [1],
            fileName: 'a.png',
            contentType: 'image/png',
            sizeBytes: 1,
          ),
        ));
        bloc.add(ChatReplyTargetSet(_buildMessage(id: 'reply-target')));
        await pumpEventQueue();

        bloc.add(
          const ChatMessageSendRequested(
            content: 'Ciao',
            actorDisplayName: 'You',
          ),
        );
        await pumpEventQueue();

        expect(bloc.state.selectedAttachment, isNull);
        expect(bloc.state.replyTarget, isNull);
      },
    );

    test(
      'ChatMessageSendRequested removes the optimistic message and surfaces '
      'a restore payload on failure',
      () async {
        await openConversation();
        chatRepository.sendMessageHandler =
            (content, {replyToMessageId}) =>
                Future.error(Exception('network down'));
        const attachment = ChatDraftAttachment(
          bytes: [1],
          fileName: 'a.png',
          contentType: 'image/png',
          sizeBytes: 1,
        );
        final replyTarget = _buildMessage(id: 'reply-target');

        bloc.add(
          ChatMessageSendRequested(
            content: 'Ciao',
            actorDisplayName: 'You',
            attachment: attachment,
            replyTarget: replyTarget,
          ),
        );
        await pumpEventQueue();

        expect(bloc.state.messages, isEmpty);
        expect(bloc.state.sending, isFalse);
        final transient = bloc.state.transient;
        expect(transient, isA<ChatMessageSendFailed>());
        final failed = transient as ChatMessageSendFailed;
        expect(failed.content, 'Ciao');
        expect(failed.attachment, same(attachment));
        expect(failed.replyTarget?.id, 'reply-target');
        expect(failed.replyTarget?.contentText, replyTarget.contentText);
      },
    );

    test(
      'ChatMessageSendRequested sends the attachment variant when an '
      'attachment is present',
      () async {
        await openConversation();
        const attachment = ChatDraftAttachment(
          bytes: [1, 2],
          fileName: 'a.png',
          contentType: 'image/png',
          sizeBytes: 2,
        );
        ChatDraftAttachment? capturedAttachment;
        chatRepository.sendAttachmentMessageHandler =
            ({content, required bytes, required fileName, required contentType, replyToMessageId}) async {
          capturedAttachment = ChatDraftAttachment(
            bytes: bytes,
            fileName: fileName,
            contentType: contentType,
            sizeBytes: bytes.length,
          );
          return _buildMessage();
        };

        bloc.add(
          ChatMessageSendRequested(
            content: 'Guarda',
            actorDisplayName: 'You',
            attachment: attachment,
          ),
        );
        await pumpEventQueue();

        expect(capturedAttachment?.fileName, 'a.png');
        expect(chatRepository.sendMessageHandler, isNull);
      },
    );

    test(
      'ChatMessageSendRequested is a no-op without an open conversation',
      () async {
        bloc.add(
          const ChatMessageSendRequested(
            content: 'Ciao',
            actorDisplayName: 'You',
          ),
        );
        await pumpEventQueue();

        expect(bloc.state.messages, isEmpty);
      },
    );
  });

  group('ChatBloc reactions, delete and mark-read', () {
    Future<void> openConversationWithMessages(
      List<ChatMessageEntity> messages,
    ) async {
      chatRepository.getOrCreateTeamConversationHandler =
          (_) async => _buildConversation();
      chatRepository.getMessagesHandler =
          ({before, limit = 50}) async => messages;
      bloc.add(const ChatConversationRequested('team-1'));
      await pumpEventQueue();
    }

    test('ChatReactionToggled replaces the message with the server response', () async {
      await openConversationWithMessages([_buildMessage(id: 'msg-1')]);
      final updated = _buildMessage(id: 'msg-1', contentText: 'Ciao 👍');
      chatRepository.toggleReactionHandler = (_, _) async => updated;

      bloc.add(const ChatReactionToggled('msg-1', '👍'));
      await pumpEventQueue();

      expect(bloc.state.messages.single.contentText, 'Ciao 👍');
    });

    test('ChatReactionToggled surfaces an error on failure', () async {
      await openConversationWithMessages([_buildMessage(id: 'msg-1')]);
      chatRepository.toggleReactionHandler =
          (_, _) => Future.error(Exception('boom'));

      bloc.add(const ChatReactionToggled('msg-1', '👍'));
      await pumpEventQueue();

      expect(bloc.state.transient, isA<ChatErrorOccurred>());
    });

    test('ChatMessageDeleteConfirmed replaces the message with the tombstone', () async {
      await openConversationWithMessages([_buildMessage(id: 'msg-1')]);
      final deleted = ChatMessageEntity(
        id: 'msg-1',
        conversationId: 'conversation-1',
        senderUserId: 'user-1',
        senderName: 'Mario Rossi',
        senderAvatarUrl: null,
        contentText: '',
        messageType: 'TEXT',
        attachmentPath: null,
        attachmentOriginalName: null,
        attachmentContentType: null,
        attachmentSizeBytes: null,
        replyTo: null,
        reactions: const [],
        deleted: true,
        deletedAt: DateTime(2026, 1, 2),
        createdAt: DateTime(2026, 1, 1),
        readByCurrentUser: true,
        mine: false,
      );
      chatRepository.deleteMessageHandler = (_) async => deleted;

      bloc.add(const ChatMessageDeleteConfirmed('msg-1'));
      await pumpEventQueue();

      expect(bloc.state.messages.single.deleted, isTrue);
    });

    test(
      'ChatConversationMarkReadRequested marks non-mine unread messages read',
      () async {
        await openConversationWithMessages([
          _buildMessage(id: 'mine', mine: true, readByCurrentUser: false),
          _buildMessage(id: 'theirs', mine: false, readByCurrentUser: false),
        ]);

        bloc.add(const ChatConversationMarkReadRequested());
        await pumpEventQueue();

        expect(chatRepository.markConversationReadCalls, ['conversation-1']);
        final theirs = bloc.state.messages.firstWhere((m) => m.id == 'theirs');
        expect(theirs.readByCurrentUser, isTrue);
        final mine = bloc.state.messages.firstWhere((m) => m.id == 'mine');
        expect(mine.readByCurrentUser, isFalse); // untouched, mirrors the widget
        expect(bloc.state.markingConversationRead, isFalse);
      },
    );

    test(
      'ChatConversationMarkReadRequested is a no-op when nothing is unread',
      () async {
        await openConversationWithMessages([
          _buildMessage(id: 'mine', mine: true, readByCurrentUser: false),
          _buildMessage(id: 'theirs', mine: false, readByCurrentUser: true),
        ]);

        bloc.add(const ChatConversationMarkReadRequested());
        await pumpEventQueue();

        expect(chatRepository.markConversationReadCalls, isEmpty);
      },
    );
  });

  group('ChatBloc workflow AI preference', () {
    test('disabling the preference clears cached suggestions', () async {
      // ChatWorkflowSuggestionPrefetchRequested's guard requires the
      // selected team to have opted into workflow AI.
      teamRepository.getAllHandler = () async => [
        buildTeam(workflowAiEnabled: true),
      ];
      bloc.add(const ChatTeamsRequested());
      chatRepository.getOrCreateTeamConversationHandler =
          (_) async => _buildConversation();
      chatRepository.getMessagesHandler =
          ({before, limit = 50}) async => const <ChatMessageEntity>[];
      bloc.add(const ChatConversationRequested('team-1'));
      bloc.add(const ChatWorkflowAiPreferenceChanged(true));
      await pumpEventQueue();
      actionRepository.resultByActionType[ChatMessageActionType.createTask] =
          const ChatMessageActionDraftResult(
            messageActionType: 'create_task',
            resolutionStatus: 'ready',
            targetEntityType: 'task',
            warnings: [],
          );
      suggestionAdapter.responseBody =
          '{"resolutionStatus": "ok", "suggestions": [], "warnings": []}';
      bloc.add(
        ChatWorkflowSuggestionPrefetchRequested(
          message: _buildMessage(),
          locale: 'it',
        ),
      );
      await pumpEventQueue();
      expect(bloc.state.workflowSuggestionsByMessageId, isNotEmpty);

      bloc.add(const ChatWorkflowAiPreferenceChanged(false));
      await pumpEventQueue();

      expect(bloc.state.workflowAiAppEnabled, isFalse);
      expect(bloc.state.workflowSuggestionsByMessageId, isEmpty);
    });
  });

  group('ChatBloc draft-prepare handlers', () {
    Future<void> openConversation() async {
      chatRepository.getOrCreateTeamConversationHandler =
          (_) async => _buildConversation();
      chatRepository.getMessagesHandler =
          ({before, limit = 50}) async => const <ChatMessageEntity>[];
      bloc.add(const ChatConversationRequested('team-1'));
      await pumpEventQueue();
    }

    const readyResult = ChatMessageActionDraftResult(
      messageActionType: 'x',
      resolutionStatus: 'ready',
      targetEntityType: 'x',
      warnings: [],
    );

    test('ChatSondageDraftRequested emits ChatSondageDraftReady', () async {
      await openConversation();
      actionRepository.resultByActionType[ChatMessageActionType.createSondage] =
          readyResult;

      bloc.add(ChatSondageDraftRequested(message: _buildMessage(), locale: 'it'));
      await pumpEventQueue();

      expect(bloc.state.transient, isA<ChatSondageDraftReady>());
      expect(actionRepository.buildDraftCalls, [
        ChatMessageActionType.createSondage,
      ]);
    });

    test('ChatTaskDraftRequested emits ChatTaskDraftReady', () async {
      await openConversation();
      actionRepository.resultByActionType[ChatMessageActionType.createTask] =
          readyResult;

      bloc.add(ChatTaskDraftRequested(message: _buildMessage(), locale: 'it'));
      await pumpEventQueue();

      expect(bloc.state.transient, isA<ChatTaskDraftReady>());
    });

    test('ChatShiftDraftRequested emits ChatShiftDraftReady', () async {
      await openConversation();
      actionRepository.resultByActionType[ChatMessageActionType.createShift] =
          readyResult;

      bloc.add(ChatShiftDraftRequested(message: _buildMessage(), locale: 'it'));
      await pumpEventQueue();

      expect(bloc.state.transient, isA<ChatShiftDraftReady>());
    });

    test('ChatEventDraftRequested emits ChatEventDraftReady', () async {
      await openConversation();
      actionRepository.resultByActionType[ChatMessageActionType.createEvent] =
          readyResult;

      bloc.add(ChatEventDraftRequested(message: _buildMessage(), locale: 'it'));
      await pumpEventQueue();

      expect(bloc.state.transient, isA<ChatEventDraftReady>());
    });

    test('a draft-prepare failure surfaces a transient error', () async {
      await openConversation();
      actionRepository.errorByActionType[ChatMessageActionType.createTask] =
          Exception('boom');

      bloc.add(ChatTaskDraftRequested(message: _buildMessage(), locale: 'it'));
      await pumpEventQueue();

      expect(bloc.state.transient, isA<ChatErrorOccurred>());
    });

    test(
      'draft-prepare handlers are a no-op without an open conversation',
      () async {
        bloc.add(ChatTaskDraftRequested(message: _buildMessage(), locale: 'it'));
        await pumpEventQueue();

        expect(actionRepository.buildDraftCalls, isEmpty);
      },
    );
  });

  group('ChatBloc workflow suggestions', () {
    Future<void> openConversation() async {
      // ChatWorkflowSuggestionPrefetchRequested's guard requires the
      // selected team to have opted into workflow AI, so state.teams must
      // be populated (ChatConversationRequested alone doesn't touch it).
      teamRepository.getAllHandler = () async => [
        buildTeam(workflowAiEnabled: true),
      ];
      bloc.add(const ChatTeamsRequested());
      chatRepository.getOrCreateTeamConversationHandler =
          (_) async => _buildConversation();
      chatRepository.getMessagesHandler =
          ({before, limit = 50}) async => const <ChatMessageEntity>[];
      bloc.add(const ChatConversationRequested('team-1'));
      await pumpEventQueue();
    }

    test('ChatWorkflowSuggestionsRequested emits the ready result', () async {
      await openConversation();
      suggestionAdapter.responseBody =
          '{"resolutionStatus": "ok", "suggestions": [], "warnings": []}';

      bloc.add(
        ChatWorkflowSuggestionsRequested(message: _buildMessage(), locale: 'it'),
      );
      await pumpEventQueue();

      expect(bloc.state.transient, isA<ChatWorkflowSuggestionsReady>());
    });

    test('ChatWorkflowSuggestionsRequested surfaces an error on failure', () async {
      await openConversation();
      suggestionAdapter.responseBody = '[1,2,3]'; // not a JSON object

      bloc.add(
        ChatWorkflowSuggestionsRequested(message: _buildMessage(), locale: 'it'),
      );
      await pumpEventQueue();

      expect(bloc.state.transient, isA<ChatErrorOccurred>());
    });

    test(
      'ChatWorkflowSuggestionPrefetchRequested caches the result per message '
      'id and clears the loading flag',
      () async {
        await openConversation();
        bloc.add(const ChatWorkflowAiPreferenceChanged(true));
        suggestionAdapter.responseBody =
            '{"resolutionStatus": "ok", "suggestions": [], "warnings": []}';

        bloc.add(
          ChatWorkflowSuggestionPrefetchRequested(
            message: _buildMessage(id: 'msg-1'),
            locale: 'it',
          ),
        );
        await pumpEventQueue();

        expect(bloc.state.workflowSuggestionsByMessageId.containsKey('msg-1'), isTrue);
        expect(bloc.state.loadingWorkflowSuggestionMessageIds, isEmpty);
      },
    );

    test(
      'ChatWorkflowSuggestionPrefetchRequested falls back to an unsupported '
      'result on failure',
      () async {
        await openConversation();
        bloc.add(const ChatWorkflowAiPreferenceChanged(true));
        suggestionAdapter.responseBody = '[1,2,3]';

        bloc.add(
          ChatWorkflowSuggestionPrefetchRequested(
            message: _buildMessage(id: 'msg-1'),
            locale: 'it',
          ),
        );
        await pumpEventQueue();

        expect(
          bloc.state.workflowSuggestionsByMessageId['msg-1']?.isUnsupported,
          isTrue,
        );
        expect(bloc.state.loadingWorkflowSuggestionMessageIds, isEmpty);
      },
    );

    test(
      'ChatWorkflowSuggestionPrefetchRequested skips when AI is disabled',
      () async {
        await openConversation();

        bloc.add(
          ChatWorkflowSuggestionPrefetchRequested(
            message: _buildMessage(id: 'msg-1'),
            locale: 'it',
          ),
        );
        await pumpEventQueue();

        expect(bloc.state.workflowSuggestionsByMessageId, isEmpty);
      },
    );

    test(
      'ChatWorkflowSuggestionPrefetchRequested skips an already-cached '
      'message',
      () async {
        await openConversation();
        bloc.add(const ChatWorkflowAiPreferenceChanged(true));
        suggestionAdapter.responseBody =
            '{"resolutionStatus": "ok", "suggestions": [], "warnings": []}';
        bloc.add(
          ChatWorkflowSuggestionPrefetchRequested(
            message: _buildMessage(id: 'msg-1'),
            locale: 'it',
          ),
        );
        await pumpEventQueue();

        bloc.add(
          ChatWorkflowSuggestionPrefetchRequested(
            message: _buildMessage(id: 'msg-1'),
            locale: 'it',
          ),
        );
        await pumpEventQueue();

        expect(suggestionAdapter.lastRequest, isNotNull);
      },
    );
  });

  group('ChatBloc realtime', () {
    test('ChatRealtimeMessageEventReceived refreshes the open conversation', () async {
      chatRepository.getOrCreateTeamConversationHandler =
          (_) async => _buildConversation();
      chatRepository.getMessagesHandler =
          ({before, limit = 50}) async => const <ChatMessageEntity>[];
      bloc.add(const ChatConversationRequested('team-1'));
      await pumpEventQueue();

      chatRepository.getMessagesHandler =
          ({before, limit = 50}) async => [_buildMessage(id: 'new-1')];
      bloc.add(const ChatRealtimeMessageEventReceived());
      await pumpEventQueue();

      expect(bloc.state.messages.map((m) => m.id), ['new-1']);
    });
  });
}
