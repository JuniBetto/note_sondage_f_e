part of 'chat_bloc.dart';

abstract class ChatEvent extends Equatable {
  const ChatEvent();

  @override
  List<Object?> get props => [];
}

/// Fetches the user's teams and resolves which one should be selected.
///
/// [preferredTeamId], when provided (e.g. from a deep link), wins over the
/// bloc's current selection if it still exists in the fetched team list.
class ChatTeamsRequested extends ChatEvent {
  const ChatTeamsRequested({this.preferredTeamId});

  final String? preferredTeamId;

  @override
  List<Object?> get props => [preferredTeamId];
}

/// Loads (and caches for the session) the member list and role list for
/// [teamId], used to resolve permissions in the chat header and in the
/// smart-action workflows. A no-op if already cached.
class ChatTeamAccessContextRequested extends ChatEvent {
  const ChatTeamAccessContextRequested(this.teamId);

  final String teamId;

  @override
  List<Object?> get props => [teamId];
}

/// Opens (or creates) the team or direct conversation for [teamId] —
/// direct when [memberUserId] is non-blank, team otherwise. Renders any
/// cached conversation/messages instantly, then reconciles with the server.
class ChatConversationRequested extends ChatEvent {
  const ChatConversationRequested(this.teamId, {this.memberUserId});

  final String teamId;
  final String? memberUserId;

  @override
  List<Object?> get props => [teamId, memberUserId];
}

/// Re-fetches the latest page of messages for the open conversation and
/// merges it with what's already loaded (used after a realtime notification
/// or a manual refresh).
class ChatMessagesRefreshRequested extends ChatEvent {
  const ChatMessagesRefreshRequested();
}

/// Loads the next older batch of messages for the open conversation
/// (infinite-scroll pagination).
class ChatOlderMessagesRequested extends ChatEvent {
  const ChatOlderMessagesRequested();
}

/// Sends [content] (and/or [attachment]) as a new message, replying to
/// [replyTarget] if set. Inserts an optimistic local message immediately;
/// [actorDisplayName] is the label to show as its sender until the server
/// responds (the bloc has no `BuildContext` to localize "You" itself).
class ChatMessageSendRequested extends ChatEvent {
  const ChatMessageSendRequested({
    required this.content,
    required this.actorDisplayName,
    this.attachment,
    this.replyTarget,
  });

  final String content;
  final String actorDisplayName;
  final ChatDraftAttachment? attachment;
  final ChatMessageEntity? replyTarget;

  @override
  List<Object?> get props => [content, actorDisplayName, attachment, replyTarget];
}

class ChatAttachmentSelected extends ChatEvent {
  const ChatAttachmentSelected(this.attachment);

  final ChatDraftAttachment attachment;

  @override
  List<Object?> get props => [attachment];
}

class ChatAttachmentCleared extends ChatEvent {
  const ChatAttachmentCleared();
}

class ChatReplyTargetSet extends ChatEvent {
  const ChatReplyTargetSet(this.message);

  final ChatMessageEntity message;

  @override
  List<Object?> get props => [message];
}

class ChatReplyTargetCleared extends ChatEvent {
  const ChatReplyTargetCleared();
}

/// Restores a draft attachment/reply-target after a failed send — dispatched
/// by the widget, which alone knows (via its `TextEditingController`)
/// whether the user has already started composing something else.
class ChatDraftRestored extends ChatEvent {
  const ChatDraftRestored({this.attachment, this.replyTarget});

  final ChatDraftAttachment? attachment;
  final ChatMessageEntity? replyTarget;

  @override
  List<Object?> get props => [attachment, replyTarget];
}

class ChatReactionToggled extends ChatEvent {
  const ChatReactionToggled(this.messageId, this.emoji);

  final String messageId;
  final String emoji;

  @override
  List<Object?> get props => [messageId, emoji];
}

/// Dispatched after the widget's own confirmation dialog returns true.
class ChatMessageDeleteConfirmed extends ChatEvent {
  const ChatMessageDeleteConfirmed(this.messageId);

  final String messageId;

  @override
  List<Object?> get props => [messageId];
}

/// Marks the open conversation read, if it actually has unread messages.
/// The "is the latest portion of the list visible" gate is a live-scroll
/// concern and stays in the widget, which decides whether to dispatch this.
class ChatConversationMarkReadRequested extends ChatEvent {
  const ChatConversationMarkReadRequested();
}

/// Fed by the widget's subscription to the external `WorkflowAiPreferencesCubit`.
class ChatWorkflowAiPreferenceChanged extends ChatEvent {
  const ChatWorkflowAiPreferenceChanged(this.enabled);

  final bool enabled;

  @override
  List<Object?> get props => [enabled];
}

class ChatSondageDraftRequested extends ChatEvent {
  const ChatSondageDraftRequested({required this.message, required this.locale});

  final ChatMessageEntity message;
  final String locale;

  @override
  List<Object?> get props => [message, locale];
}

class ChatTaskDraftRequested extends ChatEvent {
  const ChatTaskDraftRequested({required this.message, required this.locale});

  final ChatMessageEntity message;
  final String locale;

  @override
  List<Object?> get props => [message, locale];
}

class ChatShiftDraftRequested extends ChatEvent {
  const ChatShiftDraftRequested({required this.message, required this.locale});

  final ChatMessageEntity message;
  final String locale;

  @override
  List<Object?> get props => [message, locale];
}

class ChatEventDraftRequested extends ChatEvent {
  const ChatEventDraftRequested({required this.message, required this.locale});

  final ChatMessageEntity message;
  final String locale;

  @override
  List<Object?> get props => [message, locale];
}

class ChatWorkflowSuggestionsRequested extends ChatEvent {
  const ChatWorkflowSuggestionsRequested({
    required this.message,
    required this.locale,
  });

  final ChatMessageEntity message;
  final String locale;

  @override
  List<Object?> get props => [message, locale];
}

/// Auto-fetches AI suggestions for a message's footer chip, per-message
/// deduped via `state.loadingWorkflowSuggestionMessageIds`.
class ChatWorkflowSuggestionPrefetchRequested extends ChatEvent {
  const ChatWorkflowSuggestionPrefetchRequested({
    required this.message,
    required this.locale,
  });

  final ChatMessageEntity message;
  final String locale;

  @override
  List<Object?> get props => [message, locale];
}

/// Drops a message's cached AI suggestion result so the next
/// [ChatWorkflowSuggestionPrefetchRequested] for it re-fetches instead of
/// short-circuiting on the dedupe guard — backs the footer chip's "Refresh
/// AI" action.
class ChatWorkflowSuggestionCleared extends ChatEvent {
  const ChatWorkflowSuggestionCleared(this.messageId);

  final String messageId;

  @override
  List<Object?> get props => [messageId];
}

class _ChatTeamsLoadedEvent extends ChatEvent {
  const _ChatTeamsLoadedEvent({required this.teams, this.selectedTeamId});

  final List<TeamEntity> teams;
  final String? selectedTeamId;

  @override
  List<Object?> get props => [teams, selectedTeamId];
}

class _ChatTeamsLoadFailedEvent extends ChatEvent {
  const _ChatTeamsLoadFailedEvent(this.error);

  final Object error;

  @override
  List<Object?> get props => [error];
}
