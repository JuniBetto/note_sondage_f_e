import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:note_sondage/feature/chat/domain/entities/chat_conversation_entity.dart';
import 'package:note_sondage/feature/chat/domain/entities/chat_message_action_entity.dart';
import 'package:note_sondage/feature/chat/domain/entities/chat_message_entity.dart';
import 'package:note_sondage/feature/chat/domain/entities/chat_message_reaction_entity.dart';
import 'package:note_sondage/feature/chat/domain/repositories/chat_message_action_repository.dart';
import 'package:note_sondage/feature/chat/domain/use_case/chat_message_action_use_case.dart';
import 'package:note_sondage/feature/chat/workflow/chat_message_shift_workflow_controller.dart';
import 'package:note_sondage/feature/shift/domain/entities/shift_assignment_create_request_entity.dart';
import 'package:note_sondage/feature/shift/domain/entities/shift_assignment_entity.dart';
import 'package:note_sondage/feature/shift/domain/entities/shift_auto_plan_entity.dart';
import 'package:note_sondage/feature/shift/domain/entities/shift_availability_sondage_draft_request_entity.dart';
import 'package:note_sondage/feature/shift/domain/entities/shift_profile_entity.dart';
import 'package:note_sondage/feature/shift/domain/entities/shift_replacement_candidate_entity.dart';
import 'package:note_sondage/feature/shift/domain/repositories/shift_repository.dart';
import 'package:note_sondage/feature/shift/ui/widgets/shift_day_dialog.dart';
import 'package:note_sondage/feature/sondage/domain/entities/sondage_entity.dart';
import 'package:note_sondage/feature/team/domain/entities/team_entity.dart';

class _UnreachableChatMessageActionRepository
    implements ChatMessageActionRepository {
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
  }) => throw UnimplementedError();
}

class _FakeChatMessageActionUseCase extends ChatMessageActionUseCase {
  _FakeChatMessageActionUseCase({required this.result})
    : super(_UnreachableChatMessageActionRepository());

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

class _FakeShiftRepository implements ShiftRepository {
  List<ShiftProfileEntity> profiles = const <ShiftProfileEntity>[];

  final assignCalls = <ShiftAssignmentCreateRequestEntity>[];
  final assignBatchCalls = <List<ShiftAssignmentCreateRequestEntity>>[];

  @override
  Future<List<ShiftProfileEntity>> getProfiles() async => profiles;

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
  }) async {
    assignCalls.add(
      ShiftAssignmentCreateRequestEntity(
        shiftDate: shiftDate,
        profileId: profileId,
        startTime: startTime,
        endTime: endTime,
        overnight: overnight,
        note: note,
        alarmOffsets: alarmOffsets,
        isPublic: isPublic,
        teamId: teamId,
        teamShiftGroupId: teamShiftGroupId,
        targetUserId: targetUserId,
      ),
    );
    return _buildAssignment(shiftDate);
  }

  @override
  Future<List<ShiftAssignmentEntity>> assignBatch({
    required List<ShiftAssignmentCreateRequestEntity> requests,
  }) async {
    assignBatchCalls.add(requests);
    return requests.map((r) => _buildAssignment(r.shiftDate)).toList();
  }

  ShiftAssignmentEntity _buildAssignment(DateTime shiftDate) {
    return ShiftAssignmentEntity(
      id: 'assignment-1',
      userId: 'user-1',
      userName: 'Mario Rossi',
      shiftDate: shiftDate,
      teamId: null,
      teamShiftGroupId: null,
      profileId: null,
      profileName: 'Personale',
      profileColor: '#00AAFF',
      startTime: const TimeOfDay(hour: 8, minute: 0),
      endTime: const TimeOfDay(hour: 12, minute: 0),
      overnight: false,
      note: null,
      alarmOffsets: const <int>[],
      isPublic: false,
      memberEditUnlocked: false,
      memberChangeRequestPending: false,
    );
  }

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

void main() {
  late _FakeChatMessageActionUseCase draftService;
  late _FakeShiftRepository shiftRepository;
  late ChatMessageShiftWorkflowController controller;

  setUp(() {
    draftService = _FakeChatMessageActionUseCase(
      result: ChatMessageActionDraftResult(
        messageActionType: 'create_shift',
        resolutionStatus: 'ready',
        targetEntityType: 'shift',
        warnings: const <ChatMessageActionWarning>[],
        shiftDraft: ShiftAssignmentCreateRequestEntity(
          shiftDate: DateTime(2026, 8, 30),
        ),
      ),
    );
    shiftRepository = _FakeShiftRepository();
    controller = ChatMessageShiftWorkflowController(
      draftService: draftService,
      shiftRepository: shiftRepository,
    );
  });

  group('ChatMessageShiftWorkflowController', () {
    test('prepareDraft delegates create-shift draft generation', () async {
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
        contentText: '30/08 09:00-16:00',
        messageType: 'TEXT',
        attachmentPath: null,
        attachmentOriginalName: null,
        attachmentContentType: null,
        attachmentSizeBytes: null,
        replyTo: null,
        reactions: const <ChatMessageReactionEntity>[],
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
      expect(
        draftService.capturedActionType,
        ChatMessageActionType.createShift,
      );
      expect(draftService.capturedConversationId, 'conv-1');
      expect(draftService.capturedMessageId, 'msg-9');
      expect(draftService.capturedTeamId, 'team-1');
      expect(draftService.capturedSelectedMessageText, '30/08 09:00-16:00');
    });

    test('resolveOwnerTeams keeps only the preferred team', () {
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

      final result = controller.resolveOwnerTeams(
        teams: teams,
        preferredTeamId: 'team-2',
      );

      expect(result, hasLength(1));
      expect(result.single.team.id, 'team-2');
    });

    test('resolveOwnerTeams keeps every team when no preference is given', () {
      final teams = <TeamEntity>[
        TeamEntity(
          'team-1',
          null,
          null,
          name: 'Sala',
          description: '',
          createdByUserId: 'owner-1',
        ),
        TeamEntity(
          'team-2',
          null,
          null,
          name: 'Cucina',
          description: '',
          createdByUserId: 'owner-1',
        ),
      ];

      final result = controller.resolveOwnerTeams(teams: teams);

      expect(result, hasLength(2));
    });

    test('loadProfiles delegates to the shift repository', () async {
      shiftRepository.profiles = const [
        ShiftProfileEntity(
          id: 'profile-1',
          name: 'Mattina',
          startTime: TimeOfDay(hour: 8, minute: 0),
          endTime: TimeOfDay(hour: 12, minute: 0),
          overnight: false,
          isSystem: false,
          alarmOffsets: <int>[],
        ),
      ];

      final result = await controller.loadProfiles();

      expect(result, same(shiftRepository.profiles));
    });

    test(
      'buildRequestsFromDialog expands one request per target user when '
      'no member assignment plans are given',
      () {
        final result = controller.buildRequestsFromDialog(
          fallbackDate: DateTime(2026, 8, 30),
          result: const ShiftDayDialogResult(
            profileId: 'profile-1',
            startTime: TimeOfDay(hour: 9, minute: 0),
            endTime: TimeOfDay(hour: 16, minute: 0),
            overnight: false,
            alarmOffsets: <int>[15],
            targetUserIds: ['user-1', 'user-2'],
          ),
        );

        expect(result, hasLength(2));
        expect(result[0].targetUserId, 'user-1');
        expect(result[1].targetUserId, 'user-2');
        expect(result[0].shiftDate, DateTime(2026, 8, 30));
        expect(result[0].profileId, 'profile-1');
      },
    );

    test(
      'buildRequestsFromDialog prefers member assignment plans when present',
      () {
        final result = controller.buildRequestsFromDialog(
          fallbackDate: DateTime(2026, 8, 30),
          result: const ShiftDayDialogResult(
            startTime: TimeOfDay(hour: 9, minute: 0),
            endTime: TimeOfDay(hour: 16, minute: 0),
            overnight: false,
            alarmOffsets: <int>[],
            targetUserIds: ['user-ignored'],
            memberAssignmentPlans: [
              ShiftMemberAssignmentPlan(
                targetUserId: 'user-1',
                profileId: 'profile-9',
              ),
            ],
          ),
        );

        expect(result, hasLength(1));
        expect(result.single.targetUserId, 'user-1');
        expect(result.single.profileId, 'profile-9');
        expect(result.single.startTime, isNull);
      },
    );

    test(
      'buildRequestsFromDialog falls back to the given date when no '
      'scheduled dates are selected',
      () {
        final result = controller.buildRequestsFromDialog(
          fallbackDate: DateTime(2026, 9, 1),
          result: const ShiftDayDialogResult(
            startTime: TimeOfDay(hour: 9, minute: 0),
            endTime: TimeOfDay(hour: 16, minute: 0),
            overnight: false,
            alarmOffsets: <int>[],
          ),
        );

        expect(result, hasLength(1));
        expect(result.single.shiftDate, DateTime(2026, 9, 1));
        expect(result.single.targetUserId, isNull);
      },
    );

    test('submit assigns a single request directly', () async {
      final requests = [
        ShiftAssignmentCreateRequestEntity(
          shiftDate: DateTime(2026, 8, 30),
          profileId: 'profile-1',
          targetUserId: 'user-1',
        ),
      ];

      await controller.submit(requests);

      expect(shiftRepository.assignCalls, hasLength(1));
      expect(shiftRepository.assignCalls.single.targetUserId, 'user-1');
      expect(shiftRepository.assignBatchCalls, isEmpty);
    });

    test('submit batches multiple requests', () async {
      final requests = [
        ShiftAssignmentCreateRequestEntity(
          shiftDate: DateTime(2026, 8, 30),
          targetUserId: 'user-1',
        ),
        ShiftAssignmentCreateRequestEntity(
          shiftDate: DateTime(2026, 8, 30),
          targetUserId: 'user-2',
        ),
      ];

      await controller.submit(requests);

      expect(shiftRepository.assignCalls, isEmpty);
      expect(shiftRepository.assignBatchCalls, [requests]);
    });
  });
}
