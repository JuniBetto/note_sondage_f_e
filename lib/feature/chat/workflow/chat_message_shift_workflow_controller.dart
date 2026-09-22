import 'package:flutter/material.dart';
import 'package:note_sondage/feature/chat/domain/entities/chat_conversation_entity.dart';
import 'package:note_sondage/feature/chat/domain/entities/chat_message_action_entity.dart';
import 'package:note_sondage/feature/chat/domain/entities/chat_message_entity.dart';
import 'package:note_sondage/feature/chat/domain/use_case/chat_message_action_use_case.dart';
import 'package:note_sondage/feature/shift/domain/entities/shift_assignment_create_request_entity.dart';
import 'package:note_sondage/feature/shift/domain/entities/shift_profile_entity.dart';
import 'package:note_sondage/feature/shift/domain/repositories/shift_repository.dart';
import 'package:note_sondage/feature/shift/ui/widgets/shift_day_dialog.dart';
import 'package:note_sondage/feature/team/domain/entities/team_entity.dart';
import 'package:uuid/uuid.dart';

class ChatMessageShiftWorkflowController {
  ChatMessageShiftWorkflowController({
    required ChatMessageActionUseCase draftService,
    required ShiftRepository shiftRepository,
  }) : _draftService = draftService,
       _shiftRepository = shiftRepository;

  final ChatMessageActionUseCase _draftService;
  final ShiftRepository _shiftRepository;

  Future<ChatMessageActionDraftResult> prepareDraft({
    required ChatConversationEntity conversation,
    required ChatMessageEntity message,
    required String teamId,
    required String locale,
    String? memberUserId,
    String? memberDisplayName,
  }) {
    return _draftService.buildDraft(
      actionType: ChatMessageActionType.createShift,
      conversationId: conversation.id,
      messageId: message.id,
      teamId: teamId,
      locale: locale,
      selectedMessageText: message.contentText,
      memberUserId: memberUserId,
      memberDisplayName: memberDisplayName,
    );
  }

  List<TeamEntityForView> resolveOwnerTeams({
    required List<TeamEntity> teams,
    String? preferredTeamId,
  }) {
    return teams
        .where((team) => team.id != null)
        .where(
          (team) => preferredTeamId == null || team.id == preferredTeamId,
        )
        .map((team) => TeamEntityForView(team: team, members: const []))
        .toList(growable: false);
  }

  Future<List<ShiftProfileEntity>> loadProfiles() {
    return _shiftRepository.getProfiles();
  }

  Future<ShiftDayDialogResult?> openShiftDayDialog({
    required BuildContext context,
    required DateTime date,
    required List<ShiftProfileEntity> profiles,
    required List<TeamEntity> allTeams,
    required ShiftAssignmentCreateRequestEntity initialDraft,
    required String initialTeamId,
    required List<TeamEntityForView> ownerTeams,
  }) {
    return showShiftDayDialog(
      context: context,
      date: date,
      profiles: profiles,
      allTeams: allTeams,
      initialDraft: initialDraft,
      initialTeamId: initialTeamId,
      canManagePublicShifts: true,
      ownerTeams: ownerTeams,
    );
  }

  List<ShiftAssignmentCreateRequestEntity> buildRequestsFromDialog({
    required DateTime fallbackDate,
    required ShiftDayDialogResult result,
  }) {
    final scheduledDates = result.scheduledDates.isEmpty
        ? <DateTime>[fallbackDate]
        : result.scheduledDates;
    final targetUserIds = result.targetUserIds.isEmpty
        ? const <String?>[null]
        : result.targetUserIds.cast<String?>();
    final uuid = const Uuid();
    final requests = <ShiftAssignmentCreateRequestEntity>[];

    for (final scheduledDate in scheduledDates) {
      if (result.memberAssignmentPlans.isNotEmpty) {
        for (final plan in result.memberAssignmentPlans) {
          requests.add(
            ShiftAssignmentCreateRequestEntity(
              shiftDate: scheduledDate,
              profileId: plan.profileId ?? result.profileId,
              startTime: plan.profileId == null ? result.startTime : null,
              endTime: plan.profileId == null ? result.endTime : null,
              overnight: plan.profileId == null ? result.overnight : null,
              note: result.note,
              alarmOffsets: plan.profileId == null
                  ? result.alarmOffsets
                  : null,
              isPublic: result.isPublic,
              teamId: result.isPublic ? result.teamId : null,
              teamShiftGroupId: result.isPublic ? uuid.v4() : null,
              targetUserId: plan.targetUserId,
            ),
          );
        }
        continue;
      }

      final sharedGroupId = result.isPublic ? uuid.v4() : null;
      for (final targetUserId in targetUserIds) {
        requests.add(
          ShiftAssignmentCreateRequestEntity(
            shiftDate: scheduledDate,
            profileId: result.profileId,
            startTime: result.startTime,
            endTime: result.endTime,
            overnight: result.overnight,
            note: result.note,
            alarmOffsets: result.alarmOffsets,
            isPublic: result.isPublic,
            teamId: result.isPublic ? result.teamId : null,
            teamShiftGroupId: sharedGroupId,
            targetUserId: targetUserId,
          ),
        );
      }
    }

    return requests;
  }

  Future<void> submit(List<ShiftAssignmentCreateRequestEntity> requests) async {
    if (requests.length == 1) {
      final request = requests.single;
      await _shiftRepository.assign(
        shiftDate: request.shiftDate,
        profileId: request.profileId,
        startTime: request.startTime,
        endTime: request.endTime,
        overnight: request.overnight,
        note: request.note,
        alarmOffsets: request.alarmOffsets,
        isPublic: request.isPublic,
        teamId: request.teamId,
        teamShiftGroupId: request.teamShiftGroupId,
        targetUserId: request.targetUserId,
      );
      return;
    }
    await _shiftRepository.assignBatch(requests: requests);
  }
}
