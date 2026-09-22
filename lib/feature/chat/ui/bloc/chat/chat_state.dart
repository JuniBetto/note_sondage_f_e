part of 'chat_bloc.dart';

/// Sentinel used by [ChatState.copyWith] to distinguish "leave unchanged"
/// from "explicitly set to null" for nullable fields.
const _unset = Object();

/// A one-shot signal (error, success, "draft ready") riding alongside
/// [ChatState]. `copyWith` preserves it by default (like every other field)
/// — deliberately unlike `NotificationCenterState.errorMessage`, which
/// resets on every update. Chat has many independent handlers whose emits
/// can interleave (e.g. `ChatTeamAccessContextRequested` firing in the
/// background while a conversation loads); if an unrelated emit reset
/// `transient` to null, it could wipe a pending signal before any
/// `BlocListener` ever saw it. Listeners should react via
/// `listenWhen: (prev, curr) => curr.transient != prev.transient`, which
/// still fires exactly once per new signal even though the value now lingers
/// in state afterwards.
abstract class ChatTransient extends Equatable {
  const ChatTransient();

  @override
  List<Object?> get props => [];
}

class ChatErrorOccurred extends ChatTransient {
  const ChatErrorOccurred(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

/// A fresh conversation (team or direct) finished loading — either from
/// cache or from the server. The widget reacts by scrolling to the bottom
/// / focusing the latest message, which needs a live `ScrollController`.
class ChatConversationOpened extends ChatTransient {
  const ChatConversationOpened();
}

/// A [ChatMessageSendRequested] failed. Carries everything the widget needs
/// to show the error and decide whether to restore the draft — that
/// decision reads the *live* `TextEditingController` text, which only the
/// widget has, so the bloc can't make it itself.
class ChatMessageSendFailed extends ChatTransient {
  const ChatMessageSendFailed({
    required this.message,
    required this.content,
    required this.attachment,
    required this.replyTarget,
  });

  final String message;
  final String content;
  final ChatDraftAttachment? attachment;
  final ChatMessageEntity? replyTarget;

  @override
  List<Object?> get props => [message, content, attachment, replyTarget];
}

class ChatSondageDraftReady extends ChatTransient {
  const ChatSondageDraftReady(this.result);

  final ChatMessageActionDraftResult result;

  @override
  List<Object?> get props => [result];
}

class ChatTaskDraftReady extends ChatTransient {
  const ChatTaskDraftReady(this.result);

  final ChatMessageActionDraftResult result;

  @override
  List<Object?> get props => [result];
}

class ChatShiftDraftReady extends ChatTransient {
  const ChatShiftDraftReady(this.result);

  final ChatMessageActionDraftResult result;

  @override
  List<Object?> get props => [result];
}

class ChatEventDraftReady extends ChatTransient {
  const ChatEventDraftReady(this.result);

  final ChatMessageActionDraftResult result;

  @override
  List<Object?> get props => [result];
}

class ChatWorkflowSuggestionsReady extends ChatTransient {
  const ChatWorkflowSuggestionsReady(this.result);

  final DetectWorkflowSuggestionResult result;

  @override
  List<Object?> get props => [result];
}

class ChatState extends Equatable {
  const ChatState({
    this.teams = const <TeamEntity>[],
    this.loadingTeams = false,
    this.selectedTeamId,
    this.teamMembersByTeamId = const <String, List<TeamMemberEntity>>{},
    this.rolesByTeamId = const <String, List<RoleEntity>>{},
    this.selectedMemberUserId,
    this.conversation,
    this.conversationDisplayName,
    this.messages = const <ChatMessageEntity>[],
    this.loadingMessages = false,
    this.refreshingMessages = false,
    this.loadingOlderMessages = false,
    this.hasMoreOlderMessages = true,
    this.selectedAttachment,
    this.replyTarget,
    this.pendingSendCount = 0,
    this.markingConversationRead = false,
    this.workflowSuggestionsByMessageId =
        const <String, DetectWorkflowSuggestionResult>{},
    this.loadingWorkflowSuggestionMessageIds = const <String>{},
    this.workflowAiAppEnabled = false,
    this.transient,
  });

  final List<TeamEntity> teams;
  final bool loadingTeams;
  final String? selectedTeamId;
  final Map<String, List<TeamMemberEntity>> teamMembersByTeamId;
  final Map<String, List<RoleEntity>> rolesByTeamId;

  final String? selectedMemberUserId;
  final ChatConversationEntity? conversation;
  final String? conversationDisplayName;

  final List<ChatMessageEntity> messages;
  final bool loadingMessages;
  final bool refreshingMessages;
  final bool loadingOlderMessages;
  final bool hasMoreOlderMessages;

  final ChatDraftAttachment? selectedAttachment;
  final ChatMessageEntity? replyTarget;
  final int pendingSendCount;

  final bool markingConversationRead;

  final Map<String, DetectWorkflowSuggestionResult>
  workflowSuggestionsByMessageId;
  final Set<String> loadingWorkflowSuggestionMessageIds;
  final bool workflowAiAppEnabled;

  final ChatTransient? transient;

  bool get sending => pendingSendCount > 0;

  ChatState copyWith({
    List<TeamEntity>? teams,
    bool? loadingTeams,
    Object? selectedTeamId = _unset,
    Map<String, List<TeamMemberEntity>>? teamMembersByTeamId,
    Map<String, List<RoleEntity>>? rolesByTeamId,
    Object? selectedMemberUserId = _unset,
    Object? conversation = _unset,
    Object? conversationDisplayName = _unset,
    List<ChatMessageEntity>? messages,
    bool? loadingMessages,
    bool? refreshingMessages,
    bool? loadingOlderMessages,
    bool? hasMoreOlderMessages,
    Object? selectedAttachment = _unset,
    Object? replyTarget = _unset,
    int? pendingSendCount,
    bool? markingConversationRead,
    Map<String, DetectWorkflowSuggestionResult>?
    workflowSuggestionsByMessageId,
    Set<String>? loadingWorkflowSuggestionMessageIds,
    bool? workflowAiAppEnabled,
    Object? transient = _unset,
  }) {
    return ChatState(
      teams: teams ?? this.teams,
      loadingTeams: loadingTeams ?? this.loadingTeams,
      selectedTeamId: identical(selectedTeamId, _unset)
          ? this.selectedTeamId
          : selectedTeamId as String?,
      teamMembersByTeamId: teamMembersByTeamId ?? this.teamMembersByTeamId,
      rolesByTeamId: rolesByTeamId ?? this.rolesByTeamId,
      selectedMemberUserId: identical(selectedMemberUserId, _unset)
          ? this.selectedMemberUserId
          : selectedMemberUserId as String?,
      conversation: identical(conversation, _unset)
          ? this.conversation
          : conversation as ChatConversationEntity?,
      conversationDisplayName: identical(conversationDisplayName, _unset)
          ? this.conversationDisplayName
          : conversationDisplayName as String?,
      messages: messages ?? this.messages,
      loadingMessages: loadingMessages ?? this.loadingMessages,
      refreshingMessages: refreshingMessages ?? this.refreshingMessages,
      loadingOlderMessages: loadingOlderMessages ?? this.loadingOlderMessages,
      hasMoreOlderMessages: hasMoreOlderMessages ?? this.hasMoreOlderMessages,
      selectedAttachment: identical(selectedAttachment, _unset)
          ? this.selectedAttachment
          : selectedAttachment as ChatDraftAttachment?,
      replyTarget: identical(replyTarget, _unset)
          ? this.replyTarget
          : replyTarget as ChatMessageEntity?,
      pendingSendCount: pendingSendCount ?? this.pendingSendCount,
      markingConversationRead:
          markingConversationRead ?? this.markingConversationRead,
      workflowSuggestionsByMessageId:
          workflowSuggestionsByMessageId ?? this.workflowSuggestionsByMessageId,
      loadingWorkflowSuggestionMessageIds:
          loadingWorkflowSuggestionMessageIds ??
          this.loadingWorkflowSuggestionMessageIds,
      workflowAiAppEnabled: workflowAiAppEnabled ?? this.workflowAiAppEnabled,
      transient: identical(transient, _unset)
          ? this.transient
          : transient as ChatTransient?,
    );
  }

  @override
  List<Object?> get props => [
    teams,
    loadingTeams,
    selectedTeamId,
    teamMembersByTeamId,
    rolesByTeamId,
    selectedMemberUserId,
    conversation,
    conversationDisplayName,
    messages,
    loadingMessages,
    refreshingMessages,
    loadingOlderMessages,
    hasMoreOlderMessages,
    selectedAttachment,
    replyTarget,
    pendingSendCount,
    markingConversationRead,
    workflowSuggestionsByMessageId,
    loadingWorkflowSuggestionMessageIds,
    workflowAiAppEnabled,
    transient,
  ];
}
