import 'dart:async';

// chat_bloc.dart
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:note_sondage/core/utils/app_error_message_resolver.dart';
import 'package:note_sondage/feature/chat/domain/entities/chat_conversation_entity.dart';
import 'package:note_sondage/feature/chat/domain/entities/chat_message_action_entity.dart';
import 'package:note_sondage/feature/chat/domain/entities/chat_message_entity.dart';
import 'package:note_sondage/feature/chat/domain/entities/chat_message_reply_entity.dart';
import 'package:note_sondage/feature/chat/domain/use_case/chat_use_case.dart';
import 'package:note_sondage/feature/chat/ui/widgets/chat_draft_attachment.dart';
import 'package:note_sondage/feature/chat/workflow/chat_message_event_workflow_controller.dart';
import 'package:note_sondage/feature/chat/workflow/chat_message_shift_workflow_controller.dart';
import 'package:note_sondage/feature/chat/workflow/chat_message_sondage_workflow_controller.dart';
import 'package:note_sondage/feature/chat/workflow/chat_message_suggestion_models.dart';
import 'package:note_sondage/feature/chat/workflow/chat_message_suggestion_service.dart';
import 'package:note_sondage/feature/chat/workflow/chat_message_task_workflow_controller.dart';
import 'package:note_sondage/feature/team/domain/entities/role_entity.dart';
import 'package:note_sondage/feature/team/domain/entities/team_entity.dart';
import 'package:note_sondage/feature/team/domain/entities/team_member_entity.dart';
import 'package:note_sondage/feature/team/domain/use_case/role/role_use_case.dart';
import 'package:note_sondage/feature/team/domain/use_case/team/team_use_case.dart';
import 'package:note_sondage/feature/team/domain/use_case/team_member/team_member_use_case.dart';

part 'chat_event.dart';
part 'chat_state.dart';

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  ChatBloc({
    required this.teamUseCase,
    required this.teamMemberUseCase,
    required this.roleUseCase,
    required this.chatUseCase,
    required this.sondageWorkflowController,
    required this.taskWorkflowController,
    required this.shiftWorkflowController,
    required this.eventWorkflowController,
    required this.suggestionService,
  }) : super(const ChatState()) {
    on<ChatTeamsRequested>(_onTeamsRequested);
    on<_ChatTeamsLoadedEvent>(_onTeamsLoaded);
    on<_ChatTeamsLoadFailedEvent>(_onTeamsLoadFailed);
    // `sequential` (not the framework's default `concurrent` transformer):
    // guarantees one ChatTeamAccessContextRequested fully resolves (and
    // populates the cache) before the next one for the same team is
    // processed, so the "already cached" check below is enough to dedupe
    // — no separate in-flight guard needed, unlike the widget method this
    // replaces (which could have genuinely overlapping invocations).
    on<ChatTeamAccessContextRequested>(
      _onTeamAccessContextRequested,
      transformer: (events, mapper) => events.asyncExpand(mapper),
    );
    on<ChatConversationRequested>(_onConversationRequested);
    on<ChatMessagesRefreshRequested>(
      (event, emit) => _refreshMessages(emit),
    );
    on<ChatOlderMessagesRequested>(_onOlderMessagesRequested);
    on<ChatMessageSendRequested>(_onMessageSendRequested);
    on<ChatAttachmentSelected>(_onAttachmentSelected);
    on<ChatAttachmentCleared>(_onAttachmentCleared);
    on<ChatReplyTargetSet>(_onReplyTargetSet);
    on<ChatReplyTargetCleared>(_onReplyTargetCleared);
    on<ChatDraftRestored>(_onDraftRestored);
    on<ChatReactionToggled>(_onReactionToggled);
    on<ChatMessageDeleteConfirmed>(_onMessageDeleteConfirmed);
    on<ChatConversationMarkReadRequested>(_onConversationMarkReadRequested);
    on<ChatWorkflowAiPreferenceChanged>(_onWorkflowAiPreferenceChanged);
    on<ChatSondageDraftRequested>(_onSondageDraftRequested);
    on<ChatTaskDraftRequested>(_onTaskDraftRequested);
    on<ChatShiftDraftRequested>(_onShiftDraftRequested);
    on<ChatEventDraftRequested>(_onEventDraftRequested);
    on<ChatWorkflowSuggestionsRequested>(_onWorkflowSuggestionsRequested);
    on<ChatWorkflowSuggestionPrefetchRequested>(
      _onWorkflowSuggestionPrefetchRequested,
    );
    on<ChatRealtimeMessageEventReceived>(
      (event, emit) => _refreshMessages(emit),
    );
  }

  static const int _initialMessagesLimit = 100;
  static const int _olderMessagesBatchSize = 70;

  final TeamUseCase teamUseCase;
  final TeamMemberUseCase teamMemberUseCase;
  final RoleUseCase roleUseCase;
  final ChatUseCase chatUseCase;
  final ChatMessageSondageWorkflowController sondageWorkflowController;
  final ChatMessageTaskWorkflowController taskWorkflowController;
  final ChatMessageShiftWorkflowController shiftWorkflowController;
  final ChatMessageEventWorkflowController eventWorkflowController;
  final ChatMessageSuggestionService suggestionService;

  Future<void> _onTeamsRequested(
    ChatTeamsRequested event,
    Emitter<ChatState> emit,
  ) async {
    emit(state.copyWith(loadingTeams: true));
    try {
      final teams = await teamUseCase.getAllTeams();
      final nextTeamId = _resolveNextTeamId(teams, event.preferredTeamId);
      if (!isClosed) {
        add(_ChatTeamsLoadedEvent(teams: teams, selectedTeamId: nextTeamId));
      }
    } catch (error) {
      if (!isClosed) {
        add(_ChatTeamsLoadFailedEvent(error));
      }
    }
  }

  String? _resolveNextTeamId(List<TeamEntity> teams, String? preferredTeamId) {
    final effectivePreferred = preferredTeamId ?? state.selectedTeamId;
    if (effectivePreferred != null &&
        teams.any((team) => team.id == effectivePreferred)) {
      return effectivePreferred;
    }
    return teams.isNotEmpty ? teams.first.id : null;
  }

  void _onTeamsLoaded(_ChatTeamsLoadedEvent event, Emitter<ChatState> emit) {
    emit(
      state.copyWith(
        teams: event.teams,
        loadingTeams: false,
        selectedTeamId: event.selectedTeamId,
      ),
    );
  }

  void _onTeamsLoadFailed(
    _ChatTeamsLoadFailedEvent event,
    Emitter<ChatState> emit,
  ) {
    emit(
      state.copyWith(
        loadingTeams: false,
        transient: ChatErrorOccurred(
          AppErrorMessageResolver.resolve(
            event.error,
            fallback: 'We could not load your teams. Please try again.',
          ),
        ),
      ),
    );
  }

  Future<void> _onTeamAccessContextRequested(
    ChatTeamAccessContextRequested event,
    Emitter<ChatState> emit,
  ) async {
    final teamId = event.teamId.trim();
    if (teamId.isEmpty) {
      return;
    }

    final futures = <Future<void>>[];

    if (!state.teamMembersByTeamId.containsKey(teamId)) {
      futures.add(
        teamMemberUseCase
            .getAllMembersByTeamId(teamId)
            .then((members) {
              emit(
                state.copyWith(
                  teamMembersByTeamId: {
                    ...state.teamMembersByTeamId,
                    teamId: members,
                  },
                ),
              );
            })
            .catchError((_) {}),
      );
    }

    if (!state.rolesByTeamId.containsKey(teamId)) {
      futures.add(
        roleUseCase
            .getAllRolesByTeamId(teamId)
            .then((roles) {
              emit(
                state.copyWith(
                  rolesByTeamId: {...state.rolesByTeamId, teamId: roles},
                ),
              );
            })
            .catchError((_) {}),
      );
    }

    if (futures.isNotEmpty) {
      await Future.wait(futures);
    }
    emit(state.copyWith(transient: ChatTeamAccessContextReady(teamId)));
  }

  Future<void> _onConversationRequested(
    ChatConversationRequested event,
    Emitter<ChatState> emit,
  ) async {
    // Fire-and-forget, exactly like the widget method this replaces.
    add(ChatTeamAccessContextRequested(event.teamId));

    final memberUserId = event.memberUserId?.trim();
    final isDirect = memberUserId != null && memberUserId.isNotEmpty;

    final cachedConversation = isDirect
        ? chatUseCase.getCachedDirectConversation(event.teamId, memberUserId)
        : chatUseCase.getCachedTeamConversation(event.teamId);
    final cachedMessages = cachedConversation == null
        ? const <ChatMessageEntity>[]
        : chatUseCase.getCachedMessages(cachedConversation.id);
    final hasReliableCachedEmptyState =
        cachedConversation != null && cachedConversation.lastMessageAt == null;
    final canRenderCache =
        cachedMessages.isNotEmpty || hasReliableCachedEmptyState;

    emit(
      state.copyWith(
        selectedTeamId: event.teamId,
        selectedMemberUserId: memberUserId,
        conversation: cachedConversation,
        conversationDisplayName:
            cachedConversation?.participantDisplayName ??
            _teamName(event.teamId),
        messages: canRenderCache ? cachedMessages : const <ChatMessageEntity>[],
        loadingMessages: !canRenderCache,
        refreshingMessages: canRenderCache,
        loadingOlderMessages: false,
        hasMoreOlderMessages: cachedMessages.length >= _initialMessagesLimit,
        // Fires even with nothing cached: the widget uses this to clear a
        // *previous* conversation's messages from view immediately on
        // switch, not just once fresh data arrives.
        transient: ChatConversationOpened(),
      ),
    );

    try {
      final conversation = isDirect
          ? await chatUseCase.getOrCreateDirectConversation(
              event.teamId,
              memberUserId,
            )
          : await chatUseCase.getOrCreateTeamConversation(event.teamId);
      final messages = await chatUseCase.getMessages(
        conversation.id,
        limit: _initialMessagesLimit,
      );
      emit(
        state.copyWith(
          conversation: conversation,
          conversationDisplayName:
              conversation.participantDisplayName ?? _teamName(event.teamId),
          messages: messages,
          loadingMessages: false,
          refreshingMessages: false,
          hasMoreOlderMessages: messages.length >= _initialMessagesLimit,
          transient: ChatConversationOpened(),
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          loadingMessages: false,
          refreshingMessages: false,
          transient: ChatErrorOccurred(
            AppErrorMessageResolver.resolve(
              error,
              fallback: 'We could not load this conversation. Please try again.',
            ),
          ),
        ),
      );
    }
  }

  String? _teamName(String teamId) {
    for (final team in state.teams) {
      if (team.id == teamId) {
        return team.name;
      }
    }
    return null;
  }

  Future<void> _refreshMessages(Emitter<ChatState> emit) async {
    final conversation = state.conversation;
    if (conversation == null) {
      return;
    }

    emit(state.copyWith(refreshingMessages: true));
    try {
      final messages = await chatUseCase.getMessages(
        conversation.id,
        limit: _initialMessagesLimit,
      );
      final merged = _mergeRecentMessages(
        currentMessages: state.messages,
        latestMessages: messages,
      );
      emit(
        state.copyWith(
          messages: merged,
          refreshingMessages: false,
          hasMoreOlderMessages: messages.length >= _initialMessagesLimit,
          transient: ChatMessagesRefreshed(),
        ),
      );
    } catch (_) {
      // Best-effort refresh, e.g. triggered by a realtime notification.
      emit(
        state.copyWith(
          refreshingMessages: false,
          transient: ChatMessagesRefreshed(),
        ),
      );
    }
  }

  List<ChatMessageEntity> _mergeRecentMessages({
    required List<ChatMessageEntity> currentMessages,
    required List<ChatMessageEntity> latestMessages,
  }) {
    if (latestMessages.isEmpty) {
      return currentMessages;
    }

    final latestIds = latestMessages.map((message) => message.id).toSet();
    final firstLatestTimestamp = latestMessages.first.createdAt;
    final preservedOlderMessages = currentMessages
        .where(
          (message) =>
              !message.isPendingLocal &&
              message.createdAt.isBefore(firstLatestTimestamp) &&
              !latestIds.contains(message.id),
        )
        .toList();
    final pendingLocalMessages = currentMessages
        .where(
          (message) =>
              message.isPendingLocal && !latestIds.contains(message.id),
        )
        .toList();

    final merged = <ChatMessageEntity>[
      ...preservedOlderMessages,
      ...latestMessages,
      ...pendingLocalMessages,
    ]..sort((left, right) => left.createdAt.compareTo(right.createdAt));

    return merged;
  }

  Future<void> _onOlderMessagesRequested(
    ChatOlderMessagesRequested event,
    Emitter<ChatState> emit,
  ) async {
    final conversation = state.conversation;
    if (conversation == null ||
        state.loadingMessages ||
        state.loadingOlderMessages ||
        !state.hasMoreOlderMessages ||
        state.messages.isEmpty) {
      return;
    }

    final before = state.messages.first.createdAt;
    emit(state.copyWith(loadingOlderMessages: true));

    try {
      final olderMessages = await chatUseCase.getMessages(
        conversation.id,
        before: before,
        limit: _olderMessagesBatchSize,
      );

      final existingIds = state.messages.map((message) => message.id).toSet();
      final uniqueOlderMessages = olderMessages
          .where((message) => !existingIds.contains(message.id))
          .toList();

      if (uniqueOlderMessages.isEmpty) {
        emit(
          state.copyWith(loadingOlderMessages: false, hasMoreOlderMessages: false),
        );
        return;
      }

      emit(
        state.copyWith(
          messages: <ChatMessageEntity>[
            ...uniqueOlderMessages,
            ...state.messages,
          ],
          loadingOlderMessages: false,
          hasMoreOlderMessages:
              olderMessages.length >= _olderMessagesBatchSize,
        ),
      );
    } catch (_) {
      emit(state.copyWith(loadingOlderMessages: false));
    }
  }

  Future<void> _onMessageSendRequested(
    ChatMessageSendRequested event,
    Emitter<ChatState> emit,
  ) async {
    final conversation = state.conversation;
    if (conversation == null ||
        (event.content.isEmpty && event.attachment == null)) {
      return;
    }

    final temporaryMessage = _buildOptimisticMessage(
      conversationId: conversation.id,
      content: event.content,
      attachment: event.attachment,
      replyTo: event.replyTarget,
      actorDisplayName: event.actorDisplayName,
    );

    emit(
      state.copyWith(
        pendingSendCount: state.pendingSendCount + 1,
        selectedAttachment: null,
        replyTarget: null,
        messages: <ChatMessageEntity>[...state.messages, temporaryMessage],
      ),
    );

    try {
      final message = event.attachment == null
          ? await chatUseCase.sendMessage(
              conversation.id,
              event.content,
              replyToMessageId: temporaryMessage.replyTo?.messageId,
            )
          : await chatUseCase.sendAttachmentMessage(
              conversation.id,
              content: event.content,
              bytes: event.attachment!.bytes,
              fileName: event.attachment!.fileName,
              contentType: event.attachment!.contentType,
              replyToMessageId: temporaryMessage.replyTo?.messageId,
            );
      emit(
        state.copyWith(
          messages: state.messages
              .map((item) => item.id == temporaryMessage.id ? message : item)
              .toList(),
          pendingSendCount: state.pendingSendCount > 0
              ? state.pendingSendCount - 1
              : 0,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          messages: state.messages
              .where((item) => item.id != temporaryMessage.id)
              .toList(),
          pendingSendCount: state.pendingSendCount > 0
              ? state.pendingSendCount - 1
              : 0,
          transient: ChatMessageSendFailed(
            message: AppErrorMessageResolver.resolve(
              error,
              fallback: 'We could not send this message. Please try again.',
            ),
            content: event.content,
            attachment: event.attachment,
            replyTarget: _restoredReplyTarget(temporaryMessage, conversation.id),
          ),
        ),
      );
    }
  }

  ChatMessageEntity _buildOptimisticMessage({
    required String conversationId,
    required String content,
    required ChatDraftAttachment? attachment,
    required ChatMessageEntity? replyTo,
    required String actorDisplayName,
  }) {
    return ChatMessageEntity(
      id: 'local-${DateTime.now().microsecondsSinceEpoch}',
      conversationId: conversationId,
      senderUserId: 'local-user',
      senderName: actorDisplayName,
      senderAvatarUrl: null,
      contentText: content,
      messageType: attachment == null
          ? 'TEXT'
          : (attachment.isImage ? 'IMAGE' : 'FILE'),
      attachmentPath: null,
      attachmentOriginalName: attachment?.fileName,
      attachmentContentType: attachment?.contentType,
      attachmentSizeBytes: attachment?.sizeBytes,
      replyTo: replyTo == null
          ? null
          : ChatMessageReplyEntity(
              messageId: replyTo.id,
              senderName: replyTo.senderName,
              contentPreview: replyTo.contentText,
              messageType: replyTo.messageType,
              deleted: replyTo.deleted,
            ),
      reactions: const [],
      deleted: false,
      deletedAt: null,
      createdAt: DateTime.now(),
      readByCurrentUser: true,
      deliveredByOtherCount: 0,
      readByOtherCount: 0,
      mine: true,
    );
  }

  ChatMessageEntity? _restoredReplyTarget(
    ChatMessageEntity temporaryMessage,
    String conversationId,
  ) {
    final replyTo = temporaryMessage.replyTo;
    if (replyTo == null) {
      return null;
    }
    return ChatMessageEntity(
      id: replyTo.messageId,
      conversationId: conversationId,
      senderUserId: '',
      senderName: replyTo.senderName,
      senderAvatarUrl: null,
      contentText: replyTo.contentPreview,
      messageType: replyTo.messageType,
      attachmentPath: null,
      attachmentOriginalName: null,
      attachmentContentType: null,
      attachmentSizeBytes: null,
      replyTo: null,
      reactions: const [],
      deleted: replyTo.deleted,
      deletedAt: null,
      createdAt: DateTime.now(),
      readByCurrentUser: true,
      deliveredByOtherCount: 0,
      readByOtherCount: 0,
      mine: false,
    );
  }

  void _onAttachmentSelected(
    ChatAttachmentSelected event,
    Emitter<ChatState> emit,
  ) {
    emit(state.copyWith(selectedAttachment: event.attachment));
  }

  void _onAttachmentCleared(
    ChatAttachmentCleared event,
    Emitter<ChatState> emit,
  ) {
    if (state.selectedAttachment == null) {
      return;
    }
    emit(state.copyWith(selectedAttachment: null));
  }

  void _onReplyTargetSet(ChatReplyTargetSet event, Emitter<ChatState> emit) {
    emit(state.copyWith(replyTarget: event.message));
  }

  void _onReplyTargetCleared(
    ChatReplyTargetCleared event,
    Emitter<ChatState> emit,
  ) {
    emit(state.copyWith(replyTarget: null));
  }

  void _onDraftRestored(ChatDraftRestored event, Emitter<ChatState> emit) {
    emit(
      state.copyWith(
        selectedAttachment: event.attachment,
        replyTarget: event.replyTarget,
      ),
    );
  }

  Future<void> _onReactionToggled(
    ChatReactionToggled event,
    Emitter<ChatState> emit,
  ) async {
    try {
      final updated = await chatUseCase.toggleReaction(
        event.messageId,
        event.emoji,
      );
      emit(
        state.copyWith(
          messages: state.messages
              .map((item) => item.id == updated.id ? updated : item)
              .toList(),
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          transient: ChatErrorOccurred(
            AppErrorMessageResolver.resolve(
              error,
              fallback: 'We could not update this reaction. Please try again.',
            ),
          ),
        ),
      );
    }
  }

  Future<void> _onMessageDeleteConfirmed(
    ChatMessageDeleteConfirmed event,
    Emitter<ChatState> emit,
  ) async {
    try {
      final updated = await chatUseCase.deleteMessage(event.messageId);
      emit(
        state.copyWith(
          messages: state.messages
              .map((item) => item.id == updated.id ? updated : item)
              .toList(),
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          transient: ChatErrorOccurred(
            AppErrorMessageResolver.resolve(
              error,
              fallback: 'We could not delete this message. Please try again.',
            ),
          ),
        ),
      );
    }
  }

  Future<void> _onConversationMarkReadRequested(
    ChatConversationMarkReadRequested event,
    Emitter<ChatState> emit,
  ) async {
    final conversation = state.conversation;
    if (conversation == null || state.markingConversationRead) {
      return;
    }
    if (!state.messages.any(
      (message) => !message.mine && !message.readByCurrentUser,
    )) {
      return;
    }

    emit(state.copyWith(markingConversationRead: true));
    try {
      await chatUseCase.markConversationRead(conversation.id);
      emit(
        state.copyWith(
          markingConversationRead: false,
          messages: state.messages
              .map(
                (message) => message.mine
                    ? message
                    : ChatMessageEntity(
                        id: message.id,
                        conversationId: message.conversationId,
                        senderUserId: message.senderUserId,
                        senderName: message.senderName,
                        senderAvatarUrl: message.senderAvatarUrl,
                        contentText: message.contentText,
                        messageType: message.messageType,
                        attachmentPath: message.attachmentPath,
                        attachmentOriginalName: message.attachmentOriginalName,
                        attachmentContentType: message.attachmentContentType,
                        attachmentSizeBytes: message.attachmentSizeBytes,
                        replyTo: message.replyTo,
                        reactions: message.reactions,
                        deleted: message.deleted,
                        deletedAt: message.deletedAt,
                        createdAt: message.createdAt,
                        readByCurrentUser: true,
                        deliveredByOtherCount: message.deliveredByOtherCount,
                        readByOtherCount: message.readByOtherCount,
                        mine: message.mine,
                      ),
              )
              .toList(),
        ),
      );
    } catch (_) {
      // Best effort.
      emit(state.copyWith(markingConversationRead: false));
    }
  }

  void _onWorkflowAiPreferenceChanged(
    ChatWorkflowAiPreferenceChanged event,
    Emitter<ChatState> emit,
  ) {
    emit(
      state.copyWith(
        workflowAiAppEnabled: event.enabled,
        workflowSuggestionsByMessageId: event.enabled
            ? state.workflowSuggestionsByMessageId
            : const <String, DetectWorkflowSuggestionResult>{},
        loadingWorkflowSuggestionMessageIds: event.enabled
            ? state.loadingWorkflowSuggestionMessageIds
            : const <String>{},
      ),
    );
  }

  Future<void> _onSondageDraftRequested(
    ChatSondageDraftRequested event,
    Emitter<ChatState> emit,
  ) async {
    final conversation = state.conversation;
    final teamId = state.selectedTeamId;
    if (conversation == null || teamId == null || teamId.isEmpty) {
      return;
    }
    try {
      final result = await sondageWorkflowController.prepareDraft(
        conversation: conversation,
        message: event.message,
        teamId: teamId,
        locale: event.locale,
        memberUserId: state.selectedMemberUserId,
        memberDisplayName: state.conversationDisplayName,
      );
      emit(state.copyWith(transient: ChatSondageDraftReady(result)));
    } catch (error) {
      emit(
        state.copyWith(
          transient: ChatErrorOccurred(
            AppErrorMessageResolver.resolve(
              error,
              fallback: 'Failed to prepare the survey draft.',
            ),
          ),
        ),
      );
    }
  }

  Future<void> _onTaskDraftRequested(
    ChatTaskDraftRequested event,
    Emitter<ChatState> emit,
  ) async {
    final conversation = state.conversation;
    final teamId = state.selectedTeamId;
    if (conversation == null || teamId == null || teamId.isEmpty) {
      return;
    }
    try {
      final result = await taskWorkflowController.prepareDraft(
        conversation: conversation,
        message: event.message,
        teamId: teamId,
        locale: event.locale,
        memberUserId: state.selectedMemberUserId,
        memberDisplayName: state.conversationDisplayName,
      );
      emit(state.copyWith(transient: ChatTaskDraftReady(result)));
    } catch (error) {
      emit(
        state.copyWith(
          transient: ChatErrorOccurred(
            AppErrorMessageResolver.resolve(
              error,
              fallback: 'Failed to prepare the task draft.',
            ),
          ),
        ),
      );
    }
  }

  Future<void> _onShiftDraftRequested(
    ChatShiftDraftRequested event,
    Emitter<ChatState> emit,
  ) async {
    final conversation = state.conversation;
    final teamId = state.selectedTeamId;
    if (conversation == null || teamId == null || teamId.isEmpty) {
      return;
    }
    try {
      final result = await shiftWorkflowController.prepareDraft(
        conversation: conversation,
        message: event.message,
        teamId: teamId,
        locale: event.locale,
        memberUserId: state.selectedMemberUserId,
        memberDisplayName: state.conversationDisplayName,
      );
      emit(state.copyWith(transient: ChatShiftDraftReady(result)));
    } catch (error) {
      emit(
        state.copyWith(
          transient: ChatErrorOccurred(
            AppErrorMessageResolver.resolve(
              error,
              fallback: 'Failed to prepare or create the shift.',
            ),
          ),
        ),
      );
    }
  }

  Future<void> _onEventDraftRequested(
    ChatEventDraftRequested event,
    Emitter<ChatState> emit,
  ) async {
    final conversation = state.conversation;
    final teamId = state.selectedTeamId;
    if (conversation == null || teamId == null || teamId.isEmpty) {
      return;
    }
    try {
      final result = await eventWorkflowController.prepareDraft(
        conversation: conversation,
        message: event.message,
        teamId: teamId,
        locale: event.locale,
        memberUserId: state.selectedMemberUserId,
        memberDisplayName: state.conversationDisplayName,
      );
      emit(state.copyWith(transient: ChatEventDraftReady(result)));
    } catch (error) {
      emit(
        state.copyWith(
          transient: ChatErrorOccurred(
            AppErrorMessageResolver.resolve(
              error,
              fallback: 'Failed to prepare or create the event.',
            ),
          ),
        ),
      );
    }
  }

  Future<void> _onWorkflowSuggestionsRequested(
    ChatWorkflowSuggestionsRequested event,
    Emitter<ChatState> emit,
  ) async {
    final conversation = state.conversation;
    final teamId = state.selectedTeamId;
    if (conversation == null || teamId == null || teamId.isEmpty) {
      return;
    }
    try {
      final result = await suggestionService.detectWorkflowSuggestionFromMessage(
        conversationId: conversation.id,
        messageId: event.message.id,
        teamId: teamId,
        locale: event.locale,
        allowedActionTypes: const <ChatMessageActionType>[
          ChatMessageActionType.createTask,
          ChatMessageActionType.createEvent,
          ChatMessageActionType.createSondage,
          ChatMessageActionType.createShift,
        ],
        selectedMessageText: event.message.contentText,
        memberUserId: state.selectedMemberUserId,
        memberDisplayName: state.conversationDisplayName,
      );
      emit(state.copyWith(transient: ChatWorkflowSuggestionsReady(result)));
    } catch (error) {
      emit(
        state.copyWith(
          transient: ChatErrorOccurred(
            AppErrorMessageResolver.resolve(
              error,
              fallback: 'Failed to detect AI suggestions.',
            ),
          ),
        ),
      );
    }
  }

  Future<void> _onWorkflowSuggestionPrefetchRequested(
    ChatWorkflowSuggestionPrefetchRequested event,
    Emitter<ChatState> emit,
  ) async {
    final conversation = state.conversation;
    final teamId = state.selectedTeamId;
    final messageId = event.message.id;
    if (conversation == null || teamId == null || teamId.isEmpty) {
      return;
    }
    if (!state.workflowAiAppEnabled) {
      return;
    }
    if (state.loadingWorkflowSuggestionMessageIds.contains(messageId) ||
        state.workflowSuggestionsByMessageId.containsKey(messageId)) {
      return;
    }

    emit(
      state.copyWith(
        loadingWorkflowSuggestionMessageIds: {
          ...state.loadingWorkflowSuggestionMessageIds,
          messageId,
        },
      ),
    );

    try {
      final result = await suggestionService.detectWorkflowSuggestionFromMessage(
        conversationId: conversation.id,
        messageId: messageId,
        teamId: teamId,
        locale: event.locale,
        allowedActionTypes: const <ChatMessageActionType>[
          ChatMessageActionType.createTask,
          ChatMessageActionType.createEvent,
          ChatMessageActionType.createSondage,
          ChatMessageActionType.createShift,
        ],
        selectedMessageText: event.message.contentText,
        memberUserId: state.selectedMemberUserId,
        memberDisplayName: state.conversationDisplayName,
      );
      emit(
        state.copyWith(
          workflowSuggestionsByMessageId: {
            ...state.workflowSuggestionsByMessageId,
            messageId: result,
          },
          loadingWorkflowSuggestionMessageIds: {
            ...state.loadingWorkflowSuggestionMessageIds,
          }..remove(messageId),
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          workflowSuggestionsByMessageId: {
            ...state.workflowSuggestionsByMessageId,
            messageId: const DetectWorkflowSuggestionResult(
              resolutionStatus: 'unsupported',
              suggestions: <WorkflowSuggestionItem>[],
              warnings: <ChatMessageActionWarning>[],
            ),
          },
          loadingWorkflowSuggestionMessageIds: {
            ...state.loadingWorkflowSuggestionMessageIds,
          }..remove(messageId),
        ),
      );
    }
  }
}
