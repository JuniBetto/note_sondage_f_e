import 'package:flutter/material.dart';
import 'package:note_sondage/feature/chat/domain/entities/chat_message_entity.dart';
import 'package:note_sondage/feature/chat/domain/entities/chat_conversation_entity.dart';
import 'package:note_sondage/feature/chat/domain/entities/chat_message_action_entity.dart';
import 'package:note_sondage/feature/chat/domain/use_case/chat_message_action_use_case.dart';
import 'package:note_sondage/feature/task/domain/entities/task_create_request_entity.dart';
import 'package:note_sondage/feature/task/domain/entities/task_entity.dart';
import 'package:note_sondage/feature/task/domain/use_case/task_use_case.dart';
import 'package:note_sondage/feature/task/ui/task_editor_sheet.dart';
import 'package:note_sondage/feature/team/domain/entities/team_entity.dart';
import 'package:note_sondage/feature/team/domain/entities/team_member_entity.dart';
import 'package:note_sondage/feature/team/domain/entities/user_status.dart';

typedef ChatTaskWorkflowTeamMemberLoader =
    Future<List<TeamMemberEntity>> Function(String teamId);

class ChatMessageTaskWorkflowController {
  ChatMessageTaskWorkflowController({
    required ChatMessageActionUseCase draftService,
    required TaskUseCase taskUseCase,
  }) : _draftService = draftService,
       _taskUseCase = taskUseCase;

  final ChatMessageActionUseCase _draftService;
  final TaskUseCase _taskUseCase;

  Future<ChatMessageActionDraftResult> prepareDraft({
    required ChatConversationEntity conversation,
    required ChatMessageEntity message,
    required String teamId,
    required String locale,
    String? memberUserId,
    String? memberDisplayName,
  }) {
    return _draftService.buildDraft(
      actionType: ChatMessageActionType.createTask,
      conversationId: conversation.id,
      messageId: message.id,
      teamId: teamId,
      locale: locale,
      selectedMessageText: message.contentText,
      memberUserId: memberUserId,
      memberDisplayName: memberDisplayName,
    );
  }

  List<TeamEntity> resolveAvailableTeams({
    required List<TeamEntity> teams,
    required String teamId,
  }) {
    return teams
        .where((team) => team.id?.trim() == teamId)
        .toList(growable: false);
  }

  List<TaskAssigneeOption> buildAssigneeOptions(
    Iterable<TeamMemberEntity> members,
  ) {
    return members
        .where(
          (member) =>
              member.userId?.trim().isNotEmpty == true &&
              member.status == UserStatus.active,
        )
        .map(
          (member) => TaskAssigneeOption(
            userId: member.userId!.trim(),
            label: member.initialName?.trim().isNotEmpty == true
                ? member.initialName!.trim()
                : member.userEmail.trim(),
            secondaryLabel: member.userEmail,
          ),
        )
        .toList(growable: false);
  }

  Future<TaskEntity?> openTaskEditor({
    required BuildContext context,
    required List<TeamEntity> teams,
    required String teamId,
    required ChatTaskWorkflowTeamMemberLoader loadMembers,
    required String actorUserId,
    required String actorDisplayName,
    required TaskCreateRequestEntity initialDraft,
    bool lockTeamSelection = true,
  }) {
    return showTaskEditorSheet(
      context: context,
      availableTeams: resolveAvailableTeams(teams: teams, teamId: teamId),
      loadAssignees: (selectedTeamId) async {
        final members = await loadMembers(selectedTeamId);
        return buildAssigneeOptions(members);
      },
      onCreate: _taskUseCase.createTask,
      onUpdate: (task, request) => _taskUseCase.updateTask(task.id, request),
      actorUserId: actorUserId,
      actorDisplayName: actorDisplayName,
      initialDraft: initialDraft.copyWith(teamId: teamId),
      lockTeamSelection: lockTeamSelection,
    );
  }
}
