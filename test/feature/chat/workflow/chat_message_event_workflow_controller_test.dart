import 'package:flutter_test/flutter_test.dart';
import 'package:note_sondage/feature/chat/domain/entities/chat_conversation_entity.dart';
import 'package:note_sondage/feature/chat/domain/entities/chat_message_action_entity.dart';
import 'package:note_sondage/feature/chat/domain/entities/chat_message_entity.dart';
import 'package:note_sondage/feature/chat/domain/entities/chat_message_reaction_entity.dart';
import 'package:note_sondage/feature/chat/domain/repositories/chat_message_action_repository.dart';
import 'package:note_sondage/feature/chat/domain/use_case/chat_message_action_use_case.dart';
import 'package:note_sondage/feature/chat/workflow/chat_message_event_workflow_controller.dart';
import 'package:note_sondage/feature/event/domain/entities/event_create_request_entity.dart';
import 'package:note_sondage/feature/event/domain/entities/event_entity.dart';
import 'package:note_sondage/feature/event/domain/entities/event_reminder_anchor.dart';
import 'package:note_sondage/feature/event/domain/entities/event_update_request_entity.dart';
import 'package:note_sondage/feature/event/domain/entities/event_workflow_metadata_entity.dart';
import 'package:note_sondage/feature/event/domain/repositories/event_repository.dart';
import 'package:note_sondage/feature/event/domain/use_case/event_use_case.dart';
import 'package:note_sondage/feature/team/domain/entities/team_member_entity.dart';
import 'package:note_sondage/feature/team/domain/entities/user_status.dart';

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
  String? capturedSelectedMessageText;

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
    capturedSelectedMessageText = selectedMessageText;
    return result;
  }
}

class _FakeEventRepository implements EventRepository {
  final createEventCalls = <EventCreateRequestEntity>[];
  EventEntity? createEventResult;

  @override
  Future<EventEntity> createEvent(EventCreateRequestEntity request) async {
    createEventCalls.add(request);
    return createEventResult!;
  }

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

void main() {
  late _FakeChatMessageActionUseCase draftService;
  late _FakeEventRepository eventRepository;
  late ChatMessageEventWorkflowController controller;

  setUp(() {
    draftService = _FakeChatMessageActionUseCase(
      result: ChatMessageActionDraftResult(
        messageActionType: 'create_event',
        resolutionStatus: 'ready',
        targetEntityType: 'event',
        warnings: const <ChatMessageActionWarning>[],
        eventDraft: ChatMessageActionEventDraft(
          title: 'Riunione settimanale',
          startsAt: DateTime(2026, 8, 25, 14, 30),
          workflowMetadata: const EventWorkflowMetadataEntity(
            sourceType: 'CHAT_MESSAGE',
            sourceId: 'conv-1',
            sourceMessageId: 'msg-9',
          ),
        ),
      ),
    );
    eventRepository = _FakeEventRepository();
    controller = ChatMessageEventWorkflowController(
      draftService: draftService,
      eventUseCase: EventUseCase(eventRepository),
    );
  });

  group('ChatMessageEventWorkflowController', () {
    test('prepareDraft delegates create-event draft generation', () async {
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
        contentText: 'riunione 25/08 alle 14:30',
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
      );

      expect(result, same(draftService.result));
      expect(
        draftService.capturedActionType,
        ChatMessageActionType.createEvent,
      );
      expect(draftService.capturedConversationId, 'conv-1');
      expect(draftService.capturedMessageId, 'msg-9');
      expect(draftService.capturedSelectedMessageText, 'riunione 25/08 alle 14:30');
    });

    test(
      'buildPreviewEntity uses the draft team id when present',
      () {
        final draft = ChatMessageActionEventDraft(
          teamId: 'draft-team',
          title: 'Standup',
          startsAt: DateTime(2026, 8, 25, 9),
          workflowMetadata: const EventWorkflowMetadataEntity(),
        );

        final preview = controller.buildPreviewEntity(
          draft,
          fallbackTeamId: 'fallback-team',
          actorUserId: 'user-1',
          actorDisplayName: 'Mario',
        );

        expect(preview.teamId, 'draft-team');
        expect(preview.title, 'Standup');
        expect(preview.createdByUserId, 'user-1');
        expect(preview.createdByDisplayName, 'Mario');
      },
    );

    test(
      'buildPreviewEntity falls back to the given team id when the draft '
      'has none',
      () {
        final draft = ChatMessageActionEventDraft(
          title: 'Standup',
          startsAt: DateTime(2026, 8, 25, 9),
          workflowMetadata: const EventWorkflowMetadataEntity(),
        );

        final preview = controller.buildPreviewEntity(
          draft,
          fallbackTeamId: 'fallback-team',
          actorUserId: 'user-1',
          actorDisplayName: 'Mario',
        );

        expect(preview.teamId, 'fallback-team');
      },
    );

    test('buildTeamMembersForView maps every member', () {
      final members = [
        TeamMemberEntity(
          userId: 'user-1',
          userEmail: 'mario@example.com',
          teamId: 'team-1',
          status: UserStatus.active,
          roleId: 'role-1',
        ),
      ];

      final result = controller.buildTeamMembersForView(members);

      expect(result, hasLength(1));
      expect(result.single.teamMember.userId, 'user-1');
    });

    test('createEvent delegates to the event use case', () async {
      final expected = EventEntity(
        id: 'event-1',
        title: 'Riunione settimanale',
        startsAt: DateTime(2026, 8, 25, 14, 30),
        allDay: false,
        createdByUserId: 'user-1',
        createdAt: DateTime(2026, 8, 21),
        updatedAt: DateTime(2026, 8, 21),
      );
      eventRepository.createEventResult = expected;
      final request = EventCreateRequestEntity(
        title: 'Riunione settimanale',
        startsAt: DateTime(2026, 8, 25, 14, 30),
        createdByUserId: 'user-1',
      );

      final result = await controller.createEvent(request);

      expect(result, same(expected));
      expect(eventRepository.createEventCalls, [request]);
    });
  });
}
