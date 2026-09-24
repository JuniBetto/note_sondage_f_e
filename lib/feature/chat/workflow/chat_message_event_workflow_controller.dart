import 'package:flutter/material.dart';
import 'package:note_sondage/feature/chat/domain/entities/chat_conversation_entity.dart';
import 'package:note_sondage/feature/chat/domain/entities/chat_message_action_entity.dart';
import 'package:note_sondage/feature/chat/domain/entities/chat_message_entity.dart';
import 'package:note_sondage/feature/chat/domain/use_case/chat_message_action_use_case.dart';
import 'package:note_sondage/feature/event/domain/entities/event_create_request_entity.dart';
import 'package:note_sondage/feature/event/domain/entities/event_entity.dart';
import 'package:note_sondage/feature/event/domain/use_case/event_use_case.dart';
import 'package:note_sondage/feature/event/ui/widgets/event_editor_dialog.dart';
import 'package:note_sondage/feature/team/domain/entities/team_entity.dart';
import 'package:note_sondage/feature/team/domain/entities/team_member_entity.dart';
import 'package:uuid/uuid.dart';

class ChatMessageEventWorkflowController {
  ChatMessageEventWorkflowController({
    required ChatMessageActionUseCase draftService,
    required EventUseCase eventUseCase,
  }) : _draftService = draftService,
       _eventUseCase = eventUseCase;

  final ChatMessageActionUseCase _draftService;
  final EventUseCase _eventUseCase;

  Future<ChatMessageActionDraftResult> prepareDraft({
    required ChatConversationEntity conversation,
    required ChatMessageEntity message,
    required String teamId,
    required String locale,
    String? memberUserId,
    String? memberDisplayName,
  }) {
    return _draftService.buildDraft(
      actionType: ChatMessageActionType.createEvent,
      conversationId: conversation.id,
      messageId: message.id,
      teamId: teamId,
      locale: locale,
      selectedMessageText: message.contentText,
      memberUserId: memberUserId,
      memberDisplayName: memberDisplayName,
    );
  }

  EventEntity buildPreviewEntity(
    ChatMessageActionEventDraft draft, {
    required String fallbackTeamId,
    required String actorUserId,
    required String actorDisplayName,
  }) {
    final now = DateTime.now();
    final normalizedTeamId = draft.teamId?.trim();
    return EventEntity(
      id: const Uuid().v4(),
      teamId: normalizedTeamId != null && normalizedTeamId.isNotEmpty
          ? normalizedTeamId
          : fallbackTeamId,
      title: draft.title,
      description: draft.description,
      startsAt: draft.startsAt,
      endsAt: draft.endsAt,
      allDay: draft.allDay,
      location: draft.location,
      participantUserIds: draft.participantUserIds,
      participantDisplayNames: draft.participantDisplayNames,
      createdByUserId: actorUserId,
      createdByDisplayName: actorDisplayName,
      workflowMetadata: draft.workflowMetadata,
      createdAt: now,
      updatedAt: now,
    );
  }

  List<TeamMemberforView> buildTeamMembersForView(
    Iterable<TeamMemberEntity> members,
  ) {
    return members
        .map((member) => TeamMemberforView(teamMember: member))
        .toList(growable: false);
  }

  Future<EventEditorResult?> openEventEditor({
    required BuildContext context,
    required String? initialTeamId,
    required EventEntity initialEvent,
    required List<TeamMemberforView> teamMembers,
  }) {
    return showEventEditorDialog(
      context,
      initialTeamId: initialTeamId,
      initialEvent: initialEvent,
      teamMembers: teamMembers,
    );
  }

  Future<EventEntity> createEvent(EventCreateRequestEntity request) {
    return _eventUseCase.createEvent(request);
  }
}
