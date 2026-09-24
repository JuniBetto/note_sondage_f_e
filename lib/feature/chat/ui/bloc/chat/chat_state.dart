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
///
/// Every instance carries a unique [_token] baked into [props], so equality
/// is by occurrence, not by payload — two errors with the identical message
/// (or two "ready" signals for the same id), fired back to back, must still
/// count as two distinct changes to a `previous.transient != current.transient`
/// check, not as "nothing changed". Subclasses only need to declare their
/// own payload fields; they don't need to (and shouldn't) override [props].
abstract class ChatTransient extends Equatable {
  ChatTransient();

  final Object _token = Object();

  @override
  List<Object?> get props => [_token];
}

class ChatErrorOccurred extends ChatTransient {
  ChatErrorOccurred(this.message);

  final String message;
}

/// Fired once a [ChatTeamAccessContextRequested] for [teamId] has settled —
/// successfully or not (fetch failures are swallowed, matching the widget
/// method this replaces). Lets a caller `await` completion via
/// `bloc.stream.firstWhere(...)` without the risk of hanging forever on a
/// failed fetch the way waiting on cache population directly would.
class ChatTeamAccessContextReady extends ChatTransient {
  ChatTeamAccessContextReady(this.teamId);

  final String teamId;
}

/// A conversation (team or direct) was just rendered — from cache, from the
/// server, or empty while waiting on either. The widget reacts by clearing
/// stale messages from view, scrolling to the bottom / focusing the latest
/// message, which needs a live `ScrollController`.
class ChatConversationOpened extends ChatTransient {
  ChatConversationOpened();
}

/// A [ChatMessagesRefreshRequested] (or the realtime-triggered equivalent)
/// settled — successfully or not (best-effort, matching the widget method
/// this replaces).
class ChatMessagesRefreshed extends ChatTransient {
  ChatMessagesRefreshed();
}

/// A [ChatOlderMessagesRequested] settled — successfully, with nothing new,
/// or on failure. The widget compares its message count before/after to
/// decide whether to run its scroll-position-preserving jump, so this fires
/// in every case rather than only on an actual prepend.
class ChatOlderMessagesLoaded extends ChatTransient {
  ChatOlderMessagesLoaded();
}

/// A [ChatMessageSendRequested] failed. Carries everything the widget needs
/// to show the error and decide whether to restore the draft — that
/// decision reads the *live* `TextEditingController` text, which only the
/// widget has, so the bloc can't make it itself.
class ChatMessageSendFailed extends ChatTransient {
  ChatMessageSendFailed({
    required this.message,
    required this.content,
    required this.attachment,
    required this.replyTarget,
  });

  final String message;
  final String content;
  final ChatDraftAttachment? attachment;
  final ChatMessageEntity? replyTarget;
}

/// A [ChatMessageSendRequested] made progress — the optimistic message was
/// inserted, or it was reconciled with the server's response. Fires on both
/// so the widget's "scroll to the new message" reaction runs at each step,
/// matching the widget method this replaces (it scrolls after the
/// optimistic insert AND after the reconcile, but not on failure — that
/// path only fires [ChatMessageSendFailed]).
class ChatMessageSent extends ChatTransient {
  ChatMessageSent();
}

/// A [ChatReactionToggled] succeeded — the widget syncs `messages` from
/// this state. Failures only carry [ChatErrorOccurred], matching the widget
/// method this replaces (no dedicated failure signal, just a snackbar).
class ChatReactionUpdated extends ChatTransient {
  ChatReactionUpdated();
}

/// A [ChatMessageDeleteConfirmed] succeeded — same shape as
/// [ChatReactionUpdated].
class ChatMessageDeleted extends ChatTransient {
  ChatMessageDeleted();
}

/// A [ChatConversationMarkReadRequested] succeeded. Failures are silent
/// (best-effort, matching the widget method this replaces), so this only
/// fires on the success path.
class ChatConversationMarkReadCompleted extends ChatTransient {
  ChatConversationMarkReadCompleted();
}

/// A [ChatMessageSenderBlocked] succeeded — carries the blocked user so the
/// widget can show a confirmation naming them. Failures only carry
/// [ChatErrorOccurred].
class ChatSenderBlocked extends ChatTransient {
  ChatSenderBlocked(this.blockedUser);

  final BlockedUserEntity blockedUser;
}

/// A [ChatMessageReported] succeeded. Failures only carry [ChatErrorOccurred].
class ChatMessageReportSubmitted extends ChatTransient {
  ChatMessageReportSubmitted();
}

class ChatSondageDraftReady extends ChatTransient {
  ChatSondageDraftReady(this.result);

  final ChatMessageActionDraftResult result;
}

class ChatTaskDraftReady extends ChatTransient {
  ChatTaskDraftReady(this.result);

  final ChatMessageActionDraftResult result;
}

class ChatShiftDraftReady extends ChatTransient {
  ChatShiftDraftReady(this.result);

  final ChatMessageActionDraftResult result;
}

class ChatEventDraftReady extends ChatTransient {
  ChatEventDraftReady(this.result);

  final ChatMessageActionDraftResult result;
}

class ChatWorkflowSuggestionsReady extends ChatTransient {
  ChatWorkflowSuggestionsReady(this.result);

  final DetectWorkflowSuggestionResult result;
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
