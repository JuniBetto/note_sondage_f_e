import 'dart:async';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:note_sondage/core/config/runtime_config.dart';
import 'package:note_sondage/core/config/routes.dart';
import 'package:note_sondage/core/network/setup_dio.dart';
import 'package:note_sondage/core/utils/app_error_message_resolver.dart';
import 'package:note_sondage/core/utils/file_download_bridge.dart';
import 'package:note_sondage/feature/ai/preferences/workflow_ai_preferences_cubit.dart';
import 'package:note_sondage/feature/auth/ui/bloc/auth_bloc.dart';
import 'package:note_sondage/feature/chat/domain/entities/chat_conversation_entity.dart';
import 'package:note_sondage/feature/chat/domain/entities/chat_message_action_entity.dart';
import 'package:note_sondage/feature/chat/domain/entities/chat_message_entity.dart';
import 'package:note_sondage/feature/chat/domain/entities/chat_message_reply_entity.dart';
import 'package:note_sondage/feature/chat/ui/bloc/chat/chat_bloc.dart';
import 'package:note_sondage/feature/chat/ui/mobile/chat_mobile_section.dart';
import 'package:note_sondage/feature/chat/ui/widgets/chat_direct_action_dialog.dart';
import 'package:note_sondage/feature/chat/ui/widgets/chat_image_viewer_dialog.dart';
import 'package:note_sondage/feature/chat/ui/web/chat_web_layout.dart';
import 'package:note_sondage/feature/chat/ui/widgets/chat_draft_attachment.dart';
import 'package:note_sondage/feature/chat/ui/widgets/chat_theme.dart';
import 'package:note_sondage/feature/chat/workflow/chat_message_event_workflow_controller.dart';
import 'package:note_sondage/feature/chat/workflow/chat_message_shift_workflow_controller.dart';
import 'package:note_sondage/feature/chat/workflow/chat_message_sondage_workflow_controller.dart';
import 'package:note_sondage/feature/chat/workflow/chat_message_suggestion_models.dart';
import 'package:note_sondage/feature/chat/workflow/chat_message_suggestion_service.dart';
import 'package:note_sondage/feature/chat/workflow/chat_message_task_workflow_controller.dart';
import 'package:note_sondage/feature/event/domain/entities/event_create_request_entity.dart';
import 'package:note_sondage/feature/notification/realtime/realtime_notification_model.dart';
import 'package:note_sondage/feature/notification/realtime/realtime_notification_service.dart';
import 'package:note_sondage/feature/team/domain/entities/role_entity.dart';
import 'package:note_sondage/feature/team/domain/entities/team_entity.dart';
import 'package:note_sondage/feature/team/domain/entities/team_member_entity.dart';
import 'package:note_sondage/languages/l10n/app_localizations.dart';
import 'package:note_sondage/ui/widgets/app_snackbar.dart';

enum ChatScreenLayout { mobile, web }

class TeamChatScreen extends StatefulWidget {
  const TeamChatScreen({
    super.key,
    this.initialTeamId,
    this.initialMemberUserId,
    this.focusLatestOnOpen = false,
    this.layout = ChatScreenLayout.web,
    this.showTeamHeader = true,
    this.onConversationTitleChanged,
    this.onContentReady,
    this.timelineShowcaseKey,
    this.timelineShowcaseTitle,
    this.timelineShowcaseDescription,
    this.composerShowcaseKey,
    this.composerShowcaseTitle,
    this.composerShowcaseDescription,
  });

  final String? initialTeamId;
  final String? initialMemberUserId;
  final bool focusLatestOnOpen;
  final ChatScreenLayout layout;
  final bool showTeamHeader;
  final ValueChanged<String?>? onConversationTitleChanged;
  final VoidCallback? onContentReady;
  final GlobalKey? timelineShowcaseKey;
  final String? timelineShowcaseTitle;
  final String? timelineShowcaseDescription;
  final GlobalKey? composerShowcaseKey;
  final String? composerShowcaseTitle;
  final String? composerShowcaseDescription;

  @override
  State<TeamChatScreen> createState() => _TeamChatScreenState();
}

class _TeamChatScreenState extends State<TeamChatScreen> {
  static const double _olderMessagesLoadThreshold = 180;
  static const double _readVisibilityThreshold = 72;

  final ChatBloc _chatBloc = GetIt.instance<ChatBloc>();
  final ChatMessageSondageWorkflowController _sondageWorkflowController =
      GetIt.instance<ChatMessageSondageWorkflowController>();
  final ChatMessageSuggestionService _messageSuggestionService =
      GetIt.instance<ChatMessageSuggestionService>();
  final ChatMessageTaskWorkflowController _taskWorkflowController =
      GetIt.instance<ChatMessageTaskWorkflowController>();
  final ChatMessageShiftWorkflowController _shiftWorkflowController =
      GetIt.instance<ChatMessageShiftWorkflowController>();
  final ChatMessageEventWorkflowController _eventWorkflowController =
      GetIt.instance<ChatMessageEventWorkflowController>();
  final RealtimeNotificationService _realtimeService =
      GetIt.instance<RealtimeNotificationService>();
  final WorkflowAiPreferencesCubit _workflowAiPreferencesCubit =
      GetIt.instance<WorkflowAiPreferencesCubit>();
  final ImagePicker _imagePicker = ImagePicker();
  final FileDownloadBridge _fileDownloadBridge = createFileDownloadBridge();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  StreamSubscription<RealtimeNotification>? _realtimeSubscription;
  StreamSubscription<WorkflowAiPreferencesState>? _workflowAiSubscription;
  StreamSubscription<ChatState>? _chatBlocSubscription;
  ChatState? _previousChatBlocState;
  bool _pendingTeamsRefreshFeedback = false;

  List<ChatMessageEntity> _messages = const <ChatMessageEntity>[];
  final Map<String, DetectWorkflowSuggestionResult>
  _workflowSuggestionsByMessageId = {};
  final Set<String> _loadingWorkflowSuggestionMessageIds = <String>{};
  ChatConversationEntity? _conversation;
  String? _selectedTeamId;
  String? _selectedMemberUserId;
  String? _conversationDisplayName;
  bool _loadingMessages = false;
  bool _refreshingMessages = false;
  bool _skipNextTeamsConversationLoad = false;
  bool _loadingOlderMessages = false;
  bool _hasMoreOlderMessages = true;
  bool _pendingForceLatestFocus = false;
  bool _workflowAiAppEnabled = false;
  bool _didNotifyContentReady = false;

  // Sourced from ChatBloc — only ever written by _loadTeams (teams,
  // loadingTeams), _ensureTeamAccessContextLoaded (the two maps), the
  // composer/send handlers below (selectedAttachment, replyTarget,
  // pendingSendCount), or _markConversationRead (markingConversationRead) —
  // none of which have any other, not-yet-migrated writer, so they can be
  // plain getters with no local mutable copy. _selectedTeamId stays a local
  // field (see _loadTeams and _loadConversation) since it's also written by
  // the not-yet-migrated conversation-loading flow.
  List<TeamEntity> get _teams => _chatBloc.state.teams;
  bool get _loadingTeams => _chatBloc.state.loadingTeams;
  Map<String, List<TeamMemberEntity>> get _teamMembersByTeamId =>
      _chatBloc.state.teamMembersByTeamId;
  Map<String, List<RoleEntity>> get _rolesByTeamId =>
      _chatBloc.state.rolesByTeamId;
  ChatDraftAttachment? get _selectedAttachment =>
      _chatBloc.state.selectedAttachment;
  ChatMessageEntity? get _replyTarget => _chatBloc.state.replyTarget;
  int get _pendingSendCount => _chatBloc.state.pendingSendCount;
  bool get _sending => _pendingSendCount > 0;
  bool get _markingConversationRead => _chatBloc.state.markingConversationRead;

  String get _currentUid => GetIt.instance<AuthBloc>().state.user.uid.trim();
  String get _currentEmail =>
      GetIt.instance<AuthBloc>().state.user.email.trim().toLowerCase();
  String get _actorDisplayName {
    final user = GetIt.instance<AuthBloc>().state.user;
    final candidate = user.displayName?.trim();
    if (candidate != null && candidate.isNotEmpty) {
      return candidate;
    }
    return user.email.trim();
  }

  TeamEntity? get _selectedTeam {
    for (final team in _teams) {
      if (team.id == _selectedTeamId) {
        return team;
      }
    }
    return null;
  }

  ChatMessageReplyEntity? get _replyPreviewTarget {
    final replyTarget = _replyTarget;
    if (replyTarget == null) {
      return null;
    }
    return ChatMessageReplyEntity(
      messageId: replyTarget.id,
      senderName: replyTarget.senderName,
      contentPreview: replyTarget.contentText,
      messageType: replyTarget.messageType,
      deleted: replyTarget.deleted,
    );
  }

  String _headerDescription(AppLocalizations loc) {
    final isDirect = _selectedMemberUserId?.isNotEmpty == true;
    final label = isDirect
        ? _conversationDisplayName?.trim()
        : _selectedTeam?.name.trim();
    if (label == null || label.isEmpty) {
      return loc.chatChooseTeamHeader;
    }
    if (isDirect) {
      return loc.chatHeaderDirectDescription(label);
    }
    return loc.chatHeaderTeamDescription(label);
  }

  String? _resolvedConversationTitle() {
    final isDirect = _selectedMemberUserId?.isNotEmpty == true;
    final teamName = _selectedTeam?.name.trim();
    final rawTitle = isDirect
        ? _conversationDisplayName?.trim()
        : (teamName?.isNotEmpty ?? false)
        ? teamName
        : _conversationDisplayName?.trim();
    if (rawTitle == null || rawTitle.isEmpty) {
      return null;
    }
    return rawTitle;
  }

  void _notifyConversationTitleChanged() {
    final callback = widget.onConversationTitleChanged;
    if (callback == null) {
      return;
    }

    final resolvedTitle = _resolvedConversationTitle();
    if (SchedulerBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        callback(resolvedTitle);
      });
      return;
    }

    callback(resolvedTitle);
  }

  @override
  void initState() {
    super.initState();
    _pendingForceLatestFocus = widget.focusLatestOnOpen;
    _workflowAiAppEnabled = _workflowAiPreferencesCubit.state.appAiEnabled;
    _scrollController.addListener(_handleScroll);
    _realtimeSubscription = _realtimeService.stream.listen(
      _handleRealtimeNotification,
    );
    _previousChatBlocState = _chatBloc.state;
    _chatBlocSubscription = _chatBloc.stream.listen(_handleChatBlocState);
    _workflowAiSubscription = _workflowAiPreferencesCubit.stream.listen((
      state,
    ) {
      if (!mounted || _workflowAiAppEnabled == state.appAiEnabled) {
        return;
      }
      setState(() {
        _workflowAiAppEnabled = state.appAiEnabled;
        if (!_workflowAiAppEnabled) {
          _workflowSuggestionsByMessageId.clear();
          _loadingWorkflowSuggestionMessageIds.clear();
        }
      });
    });
    unawaited(_workflowAiPreferencesCubit.loadPreferences());
    final initialTeamId = widget.initialTeamId;
    if (initialTeamId != null && initialTeamId.isNotEmpty) {
      // The tapped card already tells us which conversation to open, so load
      // it immediately instead of waiting on the full team list round-trip.
      _selectedTeamId = initialTeamId;
      _skipNextTeamsConversationLoad = true;
      _loadConversation(initialTeamId, memberUserId: widget.initialMemberUserId);
    }
    _loadTeams();
  }

  @override
  void dispose() {
    _realtimeSubscription?.cancel();
    _workflowAiSubscription?.cancel();
    _chatBlocSubscription?.cancel();
    _scrollController.removeListener(_handleScroll);
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant TeamChatScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.focusLatestOnOpen && !oldWidget.focusLatestOnOpen) {
      _pendingForceLatestFocus = true;
      if (_conversation != null) {
        unawaited(_refreshMessages());
      }
    }
    final nextTeamId = widget.initialTeamId;
    final nextMemberUserId = widget.initialMemberUserId?.trim();
    final memberChanged =
        nextMemberUserId != (oldWidget.initialMemberUserId?.trim());
    if (nextTeamId == null ||
        nextTeamId.isEmpty ||
        (nextTeamId == oldWidget.initialTeamId && !memberChanged) ||
        (nextTeamId == _selectedTeamId &&
            nextMemberUserId == _selectedMemberUserId)) {
      return;
    }
    if (_teams.any((team) => team.id == nextTeamId)) {
      _loadConversation(nextTeamId, memberUserId: nextMemberUserId);
      return;
    }
    _loadTeams();
  }

  void _loadTeams({bool showFeedback = false}) {
    if (showFeedback) {
      _pendingTeamsRefreshFeedback = true;
    }
    _chatBloc.add(ChatTeamsRequested(preferredTeamId: widget.initialTeamId));
  }

  /// Reacts to every [ChatBloc] emission. Most fields this screen reads are
  /// now plain getters over `_chatBloc.state`. `loadingMessages`/
  /// `refreshingMessages`/`loadingOlderMessages` are blanket-mirrored on
  /// every emission below — safe because nothing else still writes them
  /// locally. `_conversation`/`_messages`/`_conversationDisplayName`/
  /// `_selectedMemberUserId`/`_hasMoreOlderMessages` are NOT
  /// blanket-mirrored: send, reactions, delete and mark-read (not yet
  /// migrated) still mutate them directly, and syncing on every unrelated
  /// emission would clobber those local-only mutations with the bloc's own,
  /// unaware, copy. They're only synced in response to the specific
  /// transients that mean "the bloc's copy is authoritative right now"
  /// (`ChatConversationOpened`, `ChatMessagesRefreshed`,
  /// `ChatOlderMessagesLoaded`).
  void _handleChatBlocState(ChatState next) {
    final previous = _previousChatBlocState;
    _previousChatBlocState = next;
    if (!mounted) {
      return;
    }

    setState(() {
      _loadingMessages = next.loadingMessages;
      _refreshingMessages = next.refreshingMessages;
      _loadingOlderMessages = next.loadingOlderMessages;
    });

    final justFinishedLoadingTeams =
        (previous?.loadingTeams ?? true) && !next.loadingTeams;
    final transientChanged = next.transient != previous?.transient;
    final freshTransient = transientChanged ? next.transient : null;

    if (freshTransient is ChatErrorOccurred) {
      _pendingTeamsRefreshFeedback = false;
      AppSnackBar.showError(context, freshTransient.message);
    }

    if (justFinishedLoadingTeams && freshTransient is! ChatErrorOccurred) {
      _handleTeamsLoadCompleted(next);
    }

    if (freshTransient is ChatConversationOpened) {
      _syncConversationFromBloc(next);
      _handleConversationOpened();
    } else if (freshTransient is ChatMessagesRefreshed ||
        freshTransient is ChatOlderMessagesLoaded ||
        freshTransient is ChatReactionUpdated ||
        freshTransient is ChatMessageDeleted ||
        freshTransient is ChatConversationMarkReadCompleted) {
      _syncConversationFromBloc(next);
    } else if (freshTransient is ChatMessageSent) {
      _syncConversationFromBloc(next);
      _scrollToBottom();
    } else if (freshTransient is ChatMessageSendFailed) {
      _syncConversationFromBloc(next);
      _handleMessageSendFailed(freshTransient);
    }
  }

  /// The "should I put the draft back?" decision reads the *live*
  /// `TextEditingController`/current attachment/reply-target — only the
  /// widget can make it, which is why the bloc hands back the original
  /// payload in [ChatMessageSendFailed] instead of deciding itself.
  void _handleMessageSendFailed(ChatMessageSendFailed transient) {
    final shouldRestoreDraft =
        _messageController.text.trim().isEmpty &&
        _selectedAttachment == null &&
        _replyTarget == null;
    if (shouldRestoreDraft) {
      _chatBloc.add(
        ChatDraftRestored(
          attachment: transient.attachment,
          replyTarget: transient.replyTarget,
        ),
      );
      _messageController.text = transient.content;
      _messageController.selection = TextSelection.fromPosition(
        TextPosition(offset: _messageController.text.length),
      );
    }
    AppSnackBar.showError(context, transient.message);
  }

  void _syncConversationFromBloc(ChatState state) {
    setState(() {
      _conversation = state.conversation;
      _conversationDisplayName = state.conversationDisplayName;
      _selectedMemberUserId = state.selectedMemberUserId;
      _messages = state.messages;
      _hasMoreOlderMessages = state.hasMoreOlderMessages;
    });
  }

  /// Runs the scroll/focus/mark-read side effects that used to sit right
  /// after `_loadConversation`'s cache-render and server-reconcile setState
  /// calls. Both steps are unified here (see `ChatConversationOpened`'s
  /// doc): a cache-render with nothing pending-focus now also runs the
  /// mark-read check a little earlier than before, which is harmless — the
  /// reconcile step's own firing would have triggered it moments later
  /// anyway.
  void _handleConversationOpened() {
    _notifyConversationTitleChanged();
    if (_pendingForceLatestFocus) {
      _focusLatestMessage(animate: false);
    } else {
      _scrollToBottom(animate: false);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        unawaited(_markConversationReadIfVisible());
      });
    }
  }

  void _handleTeamsLoadCompleted(ChatState next) {
    final nextTeamId = next.selectedTeamId;
    setState(() {
      _selectedTeamId = nextTeamId;
    });
    _notifyConversationTitleChanged();

    if (nextTeamId != null) {
      // Skip the redundant reload only once, right after the initState
      // fast path already kicked off this exact conversation.
      if (_skipNextTeamsConversationLoad &&
          nextTeamId == widget.initialTeamId) {
        _skipNextTeamsConversationLoad = false;
      } else {
        _loadConversation(
          nextTeamId,
          memberUserId: widget.initialMemberUserId?.trim(),
        );
      }
    } else {
      setState(() {
        _conversation = null;
        _messages = const <ChatMessageEntity>[];
        _selectedMemberUserId = null;
        _conversationDisplayName = null;
        _loadingMessages = false;
        _loadingOlderMessages = false;
        _hasMoreOlderMessages = true;
      });
      _notifyConversationTitleChanged();
    }

    if (_pendingTeamsRefreshFeedback) {
      _pendingTeamsRefreshFeedback = false;
      AppSnackBar.showSuccess(
        context,
        AppLocalizations.of(context)!.chatRefreshed,
      );
    }
  }

  /// Dispatches to [ChatBloc] and returns immediately — [_handleChatBlocState]
  /// reacts to the resulting `ChatConversationOpened` transient(s) (cache
  /// render, then server reconcile) by syncing `_conversation`/`_messages`/etc.
  /// and running the scroll/focus/mark-read side effects that need a live
  /// `BuildContext`/`ScrollController`, which the bloc can't own.
  void _loadConversation(String teamId, {String? memberUserId}) {
    unawaited(_ensureTeamAccessContextLoaded(teamId));
    _chatBloc.add(ChatConversationRequested(teamId, memberUserId: memberUserId));
  }

  /// Bridges to [ChatBloc]'s equivalent event for callers that need to
  /// `await` completion (e.g. before reading permissions off
  /// [_teamMembersByTeamId]/[_rolesByTeamId] to decide what to show).
  /// [ChatTeamAccessContextReady] fires whether the underlying fetch
  /// succeeded or not, so this never hangs on a failure — it just means the
  /// caches may still be unpopulated afterwards, exactly as before.
  Future<void> _ensureTeamAccessContextLoaded(String teamId) async {
    final normalizedTeamId = teamId.trim();
    if (normalizedTeamId.isEmpty) {
      return;
    }
    if (_teamMembersByTeamId.containsKey(normalizedTeamId) &&
        _rolesByTeamId.containsKey(normalizedTeamId)) {
      return;
    }

    final ready = _chatBloc.stream.firstWhere(
      (state) =>
          state.transient is ChatTeamAccessContextReady &&
          (state.transient as ChatTeamAccessContextReady).teamId ==
              normalizedTeamId,
    );
    _chatBloc.add(ChatTeamAccessContextRequested(normalizedTeamId));
    await ready;
  }

  bool _canManageTeam(TeamEntity team) {
    final teamId = team.id?.trim();
    if (teamId == null || teamId.isEmpty) {
      return false;
    }
    if (team.createdByUserId.trim() == _currentUid) {
      return true;
    }

    final currentMember = _findCurrentTeamMember(teamId);
    final roleCode = _normalizeRoleCode(currentMember?.roleId);
    if (roleCode == 'OWNER' || roleCode == 'ADMIN') {
      return true;
    }

    final permissions = _normalizePermissions(
      roleCode,
      _findRoleByCode(teamId, roleCode)?.permissions,
    );
    return permissions.contains('ADMIN') || permissions.contains('MANAGE');
  }

  bool _canUseWorkflowMessageActions() {
    if (!RuntimeConfig.enableWorkflowActions) {
      return false;
    }
    final selectedTeam = _selectedTeam;
    if (selectedTeam == null) {
      return false;
    }
    return _canManageTeam(selectedTeam);
  }

  bool _isWorkflowAiEnabledForSelectedTeam() {
    final selectedTeam = _selectedTeam;
    return RuntimeConfig.enableWorkflowActions &&
        _workflowAiAppEnabled &&
        selectedTeam != null &&
        selectedTeam.workflowAiEnabled;
  }

  TeamMemberEntity? _findCurrentTeamMember(String teamId) {
    final members = _teamMembersByTeamId[teamId];
    if (members == null || members.isEmpty) {
      return null;
    }

    for (final member in members) {
      final memberUserId = member.userId?.trim();
      if (memberUserId != null &&
          memberUserId.isNotEmpty &&
          memberUserId == _currentUid) {
        return member;
      }
    }

    for (final member in members) {
      if (member.userEmail.trim().toLowerCase() == _currentEmail) {
        return member;
      }
    }

    return null;
  }

  String _normalizeRoleCode(String? value) {
    return value?.trim().toUpperCase() ?? '';
  }

  RoleEntity? _findRoleByCode(String teamId, String roleCode) {
    final roles = _rolesByTeamId[teamId];
    if (roles == null || roles.isEmpty) {
      return null;
    }

    for (final role in roles) {
      if (_normalizeRoleCode(role.id) == roleCode) {
        return role;
      }
    }
    return null;
  }

  Set<String> _normalizePermissions(
    String roleCode,
    List<String>? permissions,
  ) {
    if (permissions == null || permissions.isEmpty) {
      return switch (roleCode) {
        'OWNER' => {'READ', 'UPDATE', 'ADMIN', 'DELETE', 'MANAGE'},
        'ADMIN' => {'READ', 'UPDATE', 'ADMIN', 'DELETE'},
        _ => {'READ'},
      };
    }

    return permissions
        .map((value) => value.trim().toUpperCase())
        .where((value) => value.isNotEmpty)
        .toSet();
  }

  bool _ensureWorkflowMessageActionPermission() {
    if (_canUseWorkflowMessageActions()) {
      return true;
    }

    AppSnackBar.showError(
      context,
      _chatActionText(
        Localizations.localeOf(context).languageCode,
        it: 'Solo owner, admin o ruoli con permessi Admin/Manage possono usare queste azioni dalla chat.',
        en: 'Only owners, admins, or roles with Admin/Manage permissions can use these chat actions.',
      ),
    );
    return false;
  }

  /// Bridges to [ChatBloc]'s equivalent event. Awaits [ChatMessagesRefreshed]
  /// (fired on both success and failure — see its doc) rather than the
  /// shared `refreshingMessages` flag, since that flag is also touched by
  /// conversation-loading and would risk resolving on the wrong emission.
  /// `_isNearBottom()` is captured *before* dispatching, exactly like the
  /// widget method this replaces: whether to auto-scroll after a
  /// realtime-triggered refresh depends on where the user already was.
  Future<void> _refreshMessages() async {
    if (_conversation == null) {
      return;
    }

    final shouldKeepBottomVisible = _isNearBottom();
    final settled = _chatBloc.stream.firstWhere(
      (state) => state.transient is ChatMessagesRefreshed,
    );
    _chatBloc.add(const ChatMessagesRefreshRequested());
    await settled;
    if (!mounted) {
      return;
    }

    if (_pendingForceLatestFocus) {
      _focusLatestMessage();
    } else if (shouldKeepBottomVisible) {
      _scrollToBottom();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        unawaited(_markConversationReadIfVisible());
      });
    }
  }

  /// Bridges to [ChatBloc]'s equivalent event. The guard below is a fast,
  /// synchronous re-entrancy check (`_loadingOlderMessages` is set `true`
  /// immediately, before any bloc round-trip) so rapid repeated calls from
  /// `_handleScroll` during one scroll gesture can't all slip through
  /// before the bloc's own `state.loadingOlderMessages` guard would catch
  /// them — that one alone still needed `sequential` processing to be
  /// race-free (see the bloc's own comment), so this local guard is a
  /// cheap first line of defense, not a substitute for it.
  ///
  /// The scroll-position-preserving jump only runs when the message count
  /// actually grew — mirrors the widget method this replaces skipping it
  /// entirely on failure or on an empty "nothing new" page.
  Future<void> _loadOlderMessages() async {
    if (_conversation == null ||
        _loadingMessages ||
        _loadingOlderMessages ||
        !_hasMoreOlderMessages ||
        _messages.isEmpty) {
      return;
    }

    final previousMessageCount = _messages.length;
    final previousMaxScrollExtent = _scrollController.hasClients
        ? _scrollController.position.maxScrollExtent
        : 0.0;
    final previousPixels = _scrollController.hasClients
        ? _scrollController.position.pixels
        : 0.0;

    setState(() {
      _loadingOlderMessages = true;
    });

    final settled = _chatBloc.stream.firstWhere(
      (state) => state.transient is ChatOlderMessagesLoaded,
    );
    _chatBloc.add(const ChatOlderMessagesRequested());
    await settled;
    if (!mounted || _messages.length <= previousMessageCount) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) {
        return;
      }
      final newMaxScrollExtent = _scrollController.position.maxScrollExtent;
      final delta = newMaxScrollExtent - previousMaxScrollExtent;
      _scrollController.jumpTo(previousPixels + delta);
    });
  }

  /// Dispatches to [ChatBloc], which owns the optimistic-insert +
  /// reconcile-by-id + failure-restore-payload logic in full (built and
  /// tested well before this widget was wired to it). Clears the
  /// controller immediately, matching the widget method this replaces —
  /// the bloc's `ChatMessageSent` transient (fired on the optimistic
  /// insert too) drives the scroll-to-bottom via [_handleChatBlocState].
  void _sendMessage() {
    if (_conversation == null) {
      return;
    }
    final content = _messageController.text.trim();
    final attachment = _selectedAttachment;
    if (content.isEmpty && attachment == null) {
      return;
    }

    final replyTarget = _replyTarget;
    _messageController.clear();
    _chatBloc.add(
      ChatMessageSendRequested(
        content: content,
        actorDisplayName: AppLocalizations.of(context)!.chatYouLabel,
        attachment: attachment,
        replyTarget: replyTarget,
      ),
    );
  }

  Future<void> _pickImageAttachment() async {
    final pickedFile = await _imagePicker.pickImage(
      source: ImageSource.gallery,
    );
    if (pickedFile == null) {
      return;
    }
    await _applyPickedImageAttachment(pickedFile);
  }

  Future<void> _pickDocumentAttachment() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      withData: true,
      type: FileType.custom,
      allowedExtensions: const [
        'pdf',
        'doc',
        'docx',
        'xls',
        'xlsx',
        'ppt',
        'pptx',
        'txt',
      ],
    );
    final file = result?.files.singleOrNull;
    final bytes = file?.bytes;
    final fileName = file?.name.trim() ?? '';
    if (file == null || bytes == null || bytes.isEmpty || fileName.isEmpty) {
      return;
    }
    _chatBloc.add(
      ChatAttachmentSelected(
        ChatDraftAttachment(
          bytes: bytes,
          fileName: fileName,
          contentType: _resolveDocumentContentType(file.extension),
          sizeBytes: bytes.length,
        ),
      ),
    );
  }

  Future<void> _applyPickedImageAttachment(XFile pickedFile) async {
    final bytes = await pickedFile.readAsBytes();
    if (bytes.isEmpty) {
      return;
    }
    _chatBloc.add(
      ChatAttachmentSelected(
        ChatDraftAttachment(
          bytes: bytes,
          fileName: pickedFile.name,
          contentType: _resolveImageContentType(pickedFile.name),
          sizeBytes: bytes.length,
        ),
      ),
    );
  }

  void _clearSelectedAttachment() {
    if (_selectedAttachment == null) {
      return;
    }
    _chatBloc.add(const ChatAttachmentCleared());
  }

  String _resolveImageContentType(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    switch (extension) {
      case 'png':
        return 'image/png';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      default:
        return 'image/jpeg';
    }
  }

  String _resolveDocumentContentType(String? extension) {
    switch ((extension ?? '').toLowerCase()) {
      case 'pdf':
        return 'application/pdf';
      case 'doc':
        return 'application/msword';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case 'xls':
        return 'application/vnd.ms-excel';
      case 'xlsx':
        return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
      case 'ppt':
        return 'application/vnd.ms-powerpoint';
      case 'pptx':
        return 'application/vnd.openxmlformats-officedocument.presentationml.presentation';
      case 'txt':
        return 'text/plain';
      default:
        return 'application/octet-stream';
    }
  }

  Future<void> _markConversationRead() async {
    if (_conversation == null || _markingConversationRead) {
      return;
    }
    if (!_messages.any(
      (message) => !message.mine && !message.readByCurrentUser,
    )) {
      return;
    }
    _chatBloc.add(const ChatConversationMarkReadRequested());
  }

  Future<void> _markConversationReadIfVisible() async {
    if (!_isLatestPortionVisible()) {
      return;
    }
    await _markConversationRead();
  }

  void _handleRefreshPressed() {
    _loadTeams(showFeedback: true);
  }

  void _handleTeamChanged(String teamId) {
    if (teamId == _selectedTeamId) {
      return;
    }
    _loadConversation(teamId);
  }

  Future<void> _handleSenderPressed(ChatMessageEntity message) async {
    final teamId = _selectedTeamId?.trim();
    if (teamId == null ||
        teamId.isEmpty ||
        _selectedMemberUserId?.isNotEmpty == true ||
        message.mine) {
      return;
    }

    final memberUserId = message.senderUserId.trim();
    final displayName = message.senderName.trim();
    if (memberUserId.isEmpty || displayName.isEmpty) {
      return;
    }

    final shouldOpenDirect = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return ChatDirectActionDialog(
          displayName: displayName,
          onOpenDirectPressed: () {
            Navigator.of(dialogContext).pop(true);
          },
        );
      },
    );

    if (!mounted || shouldOpenDirect != true) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _openDirectConversation(
        teamId: teamId,
        memberUserId: memberUserId,
        memberName: displayName,
      );
    });
  }

  void _handleReplyRequested(ChatMessageEntity message) {
    _chatBloc.add(ChatReplyTargetSet(message));
  }

  void _clearReplyTarget() {
    if (_replyTarget == null) {
      return;
    }
    _chatBloc.add(const ChatReplyTargetCleared());
  }

  Future<void> _handleReactionRequested(
    ChatMessageEntity message,
    String emoji,
  ) async {
    _chatBloc.add(ChatReactionToggled(message.id, emoji));
  }

  Future<void> _handleMessagePressed(ChatMessageEntity message) async {
    if (message.deleted) {
      return;
    }

    if (message.isImageAttachment) {
      await _showImageAttachmentViewer(message);
      return;
    }

    final selectedEmoji = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final theme = Theme.of(sheetContext);
        final loc = AppLocalizations.of(sheetContext)!;
        final quickReactions = <String>[
          '👍',
          '❤️',
          '😂',
          '🔥',
          '👏',
          '😮',
          '😢',
          '😎',
        ];

        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      loc.chatReactTitle,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      loc.chatReactHint,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: quickReactions
                          .map(
                            (emoji) => InkWell(
                              onTap: () =>
                                  Navigator.of(sheetContext).pop(emoji),
                              borderRadius: BorderRadius.circular(999),
                              child: Container(
                                width: 46,
                                height: 46,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.surfaceContainerHigh,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  emoji,
                                  style: theme.textTheme.titleLarge,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );

    if (!mounted || selectedEmoji == null || selectedEmoji.isEmpty) {
      return;
    }
    await _handleReactionRequested(message, selectedEmoji);
  }

  Future<void> _handleMessageLongPressed(ChatMessageEntity message) async {
    if (message.deleted && !message.hasAttachment) {
      return;
    }

    final selectedTeamId = _selectedTeamId?.trim();
    if (selectedTeamId != null && selectedTeamId.isNotEmpty) {
      await _ensureTeamAccessContextLoaded(selectedTeamId);
      if (!mounted) {
        return;
      }
    }

    final selectedAction = await _showMessageActionSheet(message);
    if (!mounted || selectedAction == null) {
      return;
    }

    switch (selectedAction) {
      case 'reply':
        _handleReplyRequested(message);
        return;
      case 'create_sondage':
        await _handleCreateSondageFromMessage(message);
        return;
      case 'create_shift':
        await _handleCreateShiftFromMessage(message);
        return;
      case 'create_task':
        await _handleCreateTaskFromMessage(message);
        return;
      case 'create_event':
        await _handleCreateEventFromMessage(message);
        return;
      case 'detect_workflow_suggestions':
        await _handleDetectWorkflowSuggestionsFromMessage(message);
        return;
      case 'open_attachment':
        if (message.isImageAttachment) {
          await _showImageAttachmentViewer(message);
        } else {
          await _downloadAttachment(message);
        }
        return;
      case 'delete':
        await _handleDeleteRequested(message);
        return;
      default:
        return;
    }
  }

  Future<String?> _showMessageActionSheet(ChatMessageEntity message) {
    return showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final theme = Theme.of(sheetContext);
        final locale = Localizations.localeOf(sheetContext).languageCode;
        final canUseWorkflowActions = _canUseWorkflowMessageActions();
        final canUseWorkflowAi =
            canUseWorkflowActions && _isWorkflowAiEnabledForSelectedTeam();
        final items = <_ChatMessageActionItem>[
          if (!message.deleted)
            _ChatMessageActionItem(
              value: 'reply',
              icon: Icons.reply_rounded,
              label: _chatActionText(
                locale,
                it: 'Rispondi',
                en: 'Reply',
                fr: 'Repondre',
                es: 'Responder',
              ),
            ),
          if (!message.deleted && canUseWorkflowAi)
            _ChatMessageActionItem(
              value: 'detect_workflow_suggestions',
              icon: Icons.auto_awesome_outlined,
              label: _chatActionText(
                locale,
                it: 'Suggerimenti AI',
                en: 'AI suggestions',
                fr: 'Suggestions IA',
                es: 'Sugerencias IA',
              ),
            ),
          if (!message.deleted && canUseWorkflowActions)
            _ChatMessageActionItem(
              value: 'create_sondage',
              icon: Icons.poll_outlined,
              label: _chatActionText(
                locale,
                it: 'Crea sondaggio',
                en: 'Create survey',
                fr: 'Creer un sondage',
                es: 'Crear encuesta',
              ),
            ),
          if (!message.deleted && canUseWorkflowActions)
            _ChatMessageActionItem(
              value: 'create_shift',
              icon: Icons.event_available_outlined,
              label: _chatActionText(
                locale,
                it: 'Precompila turno',
                en: 'Prefill shift',
                fr: 'Pre-remplir le quart',
                es: 'Prellenar turno',
              ),
            ),
          if (!message.deleted && canUseWorkflowActions)
            _ChatMessageActionItem(
              value: 'create_task',
              icon: Icons.task_alt_outlined,
              label: _chatActionText(
                locale,
                it: 'Crea task',
                en: 'Create task',
                fr: 'Creer une tache',
                es: 'Crear tarea',
              ),
            ),
          if (!message.deleted && canUseWorkflowActions)
            _ChatMessageActionItem(
              value: 'create_event',
              icon: Icons.event_note_outlined,
              label: _chatActionText(
                locale,
                it: 'Crea evento',
                en: 'Create event',
                fr: 'Creer un evenement',
                es: 'Crear evento',
              ),
            ),
          if (message.hasAttachment)
            _ChatMessageActionItem(
              value: 'open_attachment',
              icon: message.isImageAttachment
                  ? Icons.image_outlined
                  : Icons.download_rounded,
              label: message.isImageAttachment
                  ? _chatActionText(
                      locale,
                      it: 'Apri allegato',
                      en: 'Open attachment',
                      fr: 'Ouvrir la piece jointe',
                      es: 'Abrir adjunto',
                    )
                  : _chatActionText(
                      locale,
                      it: 'Scarica allegato',
                      en: 'Download attachment',
                      fr: 'Telecharger la piece jointe',
                      es: 'Descargar adjunto',
                    ),
            ),
          if (message.mine && !message.deleted)
            _ChatMessageActionItem(
              value: 'delete',
              icon: Icons.delete_outline_rounded,
              label: _chatActionText(
                locale,
                it: 'Elimina',
                en: 'Delete',
                fr: 'Supprimer',
                es: 'Eliminar',
              ),
              destructive: true,
            ),
        ];

        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 12),
                  Container(
                    width: 38,
                    height: 4,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.onSurfaceVariant.withValues(
                        alpha: 0.24,
                      ),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  const SizedBox(height: 10),
                  for (final item in items)
                    ListTile(
                      leading: Icon(
                        item.icon,
                        color: item.destructive
                            ? theme.colorScheme.error
                            : theme.colorScheme.onSurface,
                      ),
                      title: Text(
                        item.label,
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: item.destructive
                              ? theme.colorScheme.error
                              : theme.colorScheme.onSurface,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      onTap: () => Navigator.of(sheetContext).pop(item.value),
                    ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _chatActionText(
    String locale, {
    required String it,
    required String en,
    String? fr,
    String? es,
  }) {
    return switch (locale) {
      'it' => it,
      'fr' => fr ?? en,
      'es' => es ?? en,
      _ => en,
    };
  }

  Future<void> _handleCreateSondageFromMessage(
    ChatMessageEntity message,
  ) async {
    final conversation = _conversation;
    final teamId = _selectedTeamId?.trim();
    if (conversation == null || teamId == null || teamId.isEmpty) {
      return;
    }
    if (!_ensureWorkflowMessageActionPermission()) {
      return;
    }

    try {
      final result = await _runWithLoadingOverlay(
        () => _sondageWorkflowController.prepareDraft(
          conversation: conversation,
          message: message,
          teamId: teamId,
          locale: Localizations.localeOf(context).languageCode,
          memberUserId: _selectedMemberUserId,
          memberDisplayName: _conversationDisplayName,
        ),
      );
      if (!mounted) {
        return;
      }
      if (result.isUnsupported || result.sondagePrefill == null) {
        AppSnackBar.showWarning(
          context,
          result.primaryMessage ??
              _chatActionText(
                Localizations.localeOf(context).languageCode,
                it: 'Non siamo riusciti a creare una bozza sondaggio da questo messaggio.',
                en: 'We could not build a survey draft from this message.',
              ),
        );
        return;
      }
      await _sondageWorkflowController.openDraft(
        context: context,
        prefill: result.sondagePrefill!,
        useMobileLayout: widget.layout == ChatScreenLayout.mobile,
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      AppSnackBar.showError(
        context,
        AppErrorMessageResolver.resolve(
          error,
          fallback: _chatActionText(
            Localizations.localeOf(context).languageCode,
            it: 'Errore durante la preparazione della bozza sondaggio.',
            en: 'Failed to prepare the survey draft.',
          ),
        ),
      );
    }
  }

  Future<void> _handleCreateShiftFromMessage(ChatMessageEntity message) async {
    final conversation = _conversation;
    final teamId = _selectedTeamId?.trim();
    if (conversation == null || teamId == null || teamId.isEmpty) {
      return;
    }
    if (!_ensureWorkflowMessageActionPermission()) {
      return;
    }

    try {
      final result = await _runWithLoadingOverlay(
        () => _shiftWorkflowController.prepareDraft(
          conversation: conversation,
          message: message,
          teamId: teamId,
          locale: Localizations.localeOf(context).languageCode,
          memberUserId: _selectedMemberUserId,
          memberDisplayName: _conversationDisplayName,
        ),
      );
      if (!mounted) {
        return;
      }
      final shiftDraft = result.shiftDraft;
      if (result.isUnsupported || shiftDraft == null) {
        AppSnackBar.showWarning(
          context,
          '${result.primaryMessage ?? _chatActionText(Localizations.localeOf(context).languageCode, it: 'Non siamo riusciti a precompilare il turno da questo messaggio.', en: 'We could not prefill a shift from this message.')}\n\n${_chatActionText(Localizations.localeOf(context).languageCode, it: 'Suggerimento: usa un messaggio con data e orario, ad esempio "30/08 09:00-16:00".', en: 'Tip: use a message with date and time, for example "30/08 09:00-16:00".')}',
        );
        return;
      }
      if (result.isPartial) {
        AppSnackBar.showWarning(
          context,
          '${result.primaryMessage ?? _chatActionText(Localizations.localeOf(context).languageCode, it: 'La bozza del turno e parziale.', en: 'The shift draft is partial.')}\n\n${_chatActionText(Localizations.localeOf(context).languageCode, it: 'Apriamo comunque il form con i dati riconosciuti, cosi puoi completare i campi mancanti.', en: 'We will still open the form with the recognized data so you can complete the missing fields.')}',
        );
      }

      final profiles = await _shiftWorkflowController.loadProfiles();
      if (!mounted) {
        return;
      }
      final shiftResult = await _shiftWorkflowController.openShiftDayDialog(
        context: context,
        date: shiftDraft.shiftDate,
        profiles: profiles,
        allTeams: _teams,
        initialDraft: shiftDraft,
        initialTeamId: shiftDraft.teamId ?? teamId,
        ownerTeams: _shiftWorkflowController.resolveOwnerTeams(
          teams: _teams,
          preferredTeamId: shiftDraft.teamId ?? teamId,
        ),
      );
      if (!mounted || shiftResult == null) {
        return;
      }

      final requests = _shiftWorkflowController.buildRequestsFromDialog(
        fallbackDate: shiftDraft.shiftDate,
        result: shiftResult,
      );
      if (requests.isEmpty) {
        return;
      }

      await _runWithLoadingOverlay(() => _shiftWorkflowController.submit(requests));
      if (!mounted) {
        return;
      }
      AppSnackBar.showSuccess(
        context,
        _chatActionText(
          Localizations.localeOf(context).languageCode,
          it: requests.length == 1
              ? 'Turno creato con successo.'
              : 'Turni creati con successo.',
          en: requests.length == 1
              ? 'Shift created successfully.'
              : 'Shifts created successfully.',
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      AppSnackBar.showError(
        context,
        AppErrorMessageResolver.resolve(
          error,
          fallback: _chatActionText(
            Localizations.localeOf(context).languageCode,
            it: 'Errore durante la preparazione o creazione del turno.',
            en: 'Failed to prepare or create the shift.',
          ),
        ),
      );
    }
  }

  Future<void> _handleCreateTaskFromMessage(ChatMessageEntity message) async {
    final conversation = _conversation;
    final teamId = _selectedTeamId?.trim();
    if (conversation == null || teamId == null || teamId.isEmpty) {
      return;
    }
    if (!_ensureWorkflowMessageActionPermission()) {
      return;
    }

    try {
      final result = await _runWithLoadingOverlay(
        () => _taskWorkflowController.prepareDraft(
          conversation: conversation,
          message: message,
          teamId: teamId,
          locale: Localizations.localeOf(context).languageCode,
          memberUserId: _selectedMemberUserId,
          memberDisplayName: _conversationDisplayName,
        ),
      );
      if (!mounted) {
        return;
      }

      final taskDraft = result.taskDraft;
      if (result.isUnsupported || taskDraft == null) {
        AppSnackBar.showWarning(
          context,
          result.primaryMessage ??
              _chatActionText(
                Localizations.localeOf(context).languageCode,
                it: 'Non siamo riusciti a costruire una bozza task da questo messaggio.',
                en: 'We could not build a task draft from this message.',
              ),
        );
        return;
      }

      if (result.isPartial) {
        AppSnackBar.showWarning(
          context,
          result.primaryMessage ??
              _chatActionText(
                Localizations.localeOf(context).languageCode,
                it: 'La bozza task e parziale: conferma scadenza e assegnatario prima di creare.',
                en: 'The task draft is partial: confirm due date and assignee before creating.',
              ),
        );
      }

      final createdTask = await _taskWorkflowController.openTaskEditor(
        context: context,
        teams: _teams,
        teamId: teamId,
        loadMembers: (selectedTeamId) async {
          await _ensureTeamAccessContextLoaded(selectedTeamId);
          return _teamMembersByTeamId[selectedTeamId] ??
              const <TeamMemberEntity>[];
        },
        actorUserId: _currentUid,
        actorDisplayName: _actorDisplayName,
        initialDraft: taskDraft,
        lockTeamSelection: true,
      );
      if (!mounted || createdTask == null) {
        return;
      }
      AppSnackBar.showSuccess(
        context,
        _chatActionText(
          Localizations.localeOf(context).languageCode,
          it: 'Task creato con successo.',
          en: 'Task created successfully.',
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      AppSnackBar.showError(
        context,
        AppErrorMessageResolver.resolve(
          error,
          fallback: _chatActionText(
            Localizations.localeOf(context).languageCode,
            it: 'Errore durante la preparazione del task.',
            en: 'Failed to prepare the task.',
          ),
        ),
      );
    }
  }

  Future<void> _handleCreateEventFromMessage(ChatMessageEntity message) async {
    final conversation = _conversation;
    final teamId = _selectedTeamId?.trim();
    if (conversation == null || teamId == null || teamId.isEmpty) {
      return;
    }
    if (!_ensureWorkflowMessageActionPermission()) {
      return;
    }

    try {
      await _ensureTeamAccessContextLoaded(teamId);

      final result = await _runWithLoadingOverlay(
        () => _eventWorkflowController.prepareDraft(
          conversation: conversation,
          message: message,
          teamId: teamId,
          locale: Localizations.localeOf(context).languageCode,
          memberUserId: _selectedMemberUserId,
          memberDisplayName: _conversationDisplayName,
        ),
      );
      if (!mounted) {
        return;
      }

      final eventDraft = result.eventDraft;
      if (result.isUnsupported || eventDraft == null) {
        AppSnackBar.showWarning(
          context,
          '${result.primaryMessage ?? _chatActionText(Localizations.localeOf(context).languageCode, it: 'Non siamo riusciti a costruire una bozza evento da questo messaggio.', en: 'We could not build an event draft from this message.')}\n\n${_chatActionText(Localizations.localeOf(context).languageCode, it: 'Suggerimento: usa un messaggio con data e orario, ad esempio "riunione 25/08 alle 14:30".', en: 'Tip: use a message with date and time, for example "meeting on 2026-08-25 at 14:30".')}',
        );
        return;
      }

      if (result.isPartial) {
        AppSnackBar.showWarning(
          context,
          result.primaryMessage ??
              _chatActionText(
                Localizations.localeOf(context).languageCode,
                it: 'La bozza evento e parziale: conferma orario, location e partecipanti prima di creare.',
                en: 'The event draft is partial: confirm time, location, and participants before creating.',
              ),
        );
      }

      final effectiveTeamId = eventDraft.teamId?.trim().isNotEmpty == true
          ? eventDraft.teamId!.trim()
          : teamId;
      final editorResult = await _eventWorkflowController.openEventEditor(
        context: context,
        initialTeamId: effectiveTeamId,
        initialEvent: _eventWorkflowController.buildPreviewEntity(
          eventDraft,
          fallbackTeamId: effectiveTeamId,
          actorUserId: _currentUid,
          actorDisplayName: _actorDisplayName,
        ),
        teamMembers: _eventWorkflowController.buildTeamMembersForView(
          _teamMembersByTeamId[effectiveTeamId] ?? const <TeamMemberEntity>[],
        ),
      );
      if (!mounted || editorResult == null) {
        return;
      }

      await _runWithLoadingOverlay(
        () => _eventWorkflowController.createEvent(
          EventCreateRequestEntity(
            teamId: editorResult.teamId,
            title: editorResult.title,
            description: editorResult.description,
            startsAt: editorResult.startsAt,
            endsAt: editorResult.endsAt,
            allDay: editorResult.allDay,
            location: editorResult.location,
            participantUserIds: editorResult.participantUserIds,
            participantDisplayNames: editorResult.participantDisplayNames,
            createdByUserId: _currentUid,
            createdByDisplayName: _actorDisplayName,
            workflowMetadata: eventDraft.workflowMetadata,
            reminderOffsets: editorResult.reminderOffsets,
            reminderAnchor: editorResult.reminderAnchor,
          ),
        ),
      );
      if (!mounted) {
        return;
      }
      AppSnackBar.showSuccess(
        context,
        _chatActionText(
          Localizations.localeOf(context).languageCode,
          it: 'Evento creato con successo.',
          en: 'Event created successfully.',
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      AppSnackBar.showError(
        context,
        AppErrorMessageResolver.resolve(
          error,
          fallback: _chatActionText(
            Localizations.localeOf(context).languageCode,
            it: 'Errore durante la preparazione o creazione dell evento.',
            en: 'Failed to prepare or create the event.',
          ),
        ),
      );
    }
  }

  Future<void> _handleDetectWorkflowSuggestionsFromMessage(
    ChatMessageEntity message,
  ) async {
    final conversation = _conversation;
    final teamId = _selectedTeamId?.trim();
    if (conversation == null || teamId == null || teamId.isEmpty) {
      return;
    }
    if (!_ensureWorkflowMessageActionPermission()) {
      return;
    }

    try {
      final result = await _runWithLoadingOverlay(
        () => _messageSuggestionService.detectWorkflowSuggestionFromMessage(
          conversationId: conversation.id,
          messageId: message.id,
          teamId: teamId,
          locale: Localizations.localeOf(context).languageCode,
          allowedActionTypes: const <ChatMessageActionType>[
            ChatMessageActionType.createTask,
            ChatMessageActionType.createEvent,
            ChatMessageActionType.createSondage,
            ChatMessageActionType.createShift,
          ],
          selectedMessageText: message.contentText,
          memberUserId: _selectedMemberUserId,
          memberDisplayName: _conversationDisplayName,
        ),
      );
      if (!mounted) {
        return;
      }

      if (result.isUnsupported || result.suggestions.isEmpty) {
        final fallbackMessage = result.fallback?.message.trim();
        final warningMessage = result.warnings
            .map((item) => item.message.trim())
            .firstWhere((item) => item.isNotEmpty, orElse: () => '');
        AppSnackBar.showWarning(
          context,
          fallbackMessage != null && fallbackMessage.isNotEmpty
              ? fallbackMessage
              : warningMessage.isNotEmpty
              ? warningMessage
              : _chatActionText(
                  Localizations.localeOf(context).languageCode,
                  it: 'Nessun suggerimento AI affidabile trovato per questo messaggio.',
                  en: 'No reliable AI suggestion was found for this message.',
                ),
        );
        return;
      }

      final selectedSuggestion = await _showWorkflowSuggestionSelectionSheet(
        result,
      );
      if (!mounted || selectedSuggestion == null) {
        return;
      }
      await _handleWorkflowSuggestionSelection(message, selectedSuggestion);
    } catch (error) {
      if (!mounted) {
        return;
      }
      AppSnackBar.showError(
        context,
        AppErrorMessageResolver.resolve(
          error,
          fallback: _chatActionText(
            Localizations.localeOf(context).languageCode,
            it: 'Errore durante il rilevamento dei suggerimenti AI.',
            en: 'Failed to detect AI suggestions.',
          ),
        ),
      );
    }
  }

  Future<WorkflowSuggestionItem?> _showWorkflowSuggestionSelectionSheet(
    DetectWorkflowSuggestionResult result,
  ) {
    return showModalBottomSheet<WorkflowSuggestionItem>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final theme = Theme.of(sheetContext);
        final locale = Localizations.localeOf(sheetContext).languageCode;

        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 12),
                  Container(
                    width: 38,
                    height: 4,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.onSurfaceVariant.withValues(
                        alpha: 0.24,
                      ),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        _chatActionText(
                          locale,
                          it: 'Suggerimenti AI',
                          en: 'AI suggestions',
                          fr: 'Suggestions IA',
                          es: 'Sugerencias IA',
                        ),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  for (final suggestion in result.suggestions)
                    ListTile(
                      leading: Icon(
                        _iconForWorkflowActionType(suggestion.actionType),
                        color: theme.colorScheme.primary,
                      ),
                      title: Text(
                        suggestion.title.isNotEmpty
                            ? suggestion.title
                            : _labelForWorkflowActionType(
                                locale,
                                suggestion.actionType,
                              ),
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      subtitle: Text(
                        suggestion.reason.isNotEmpty
                            ? suggestion.reason
                            : _chatActionText(
                                locale,
                                it: 'Conferma per aprire la bozza suggerita.',
                                en: 'Confirm to open the suggested draft.',
                              ),
                      ),
                      trailing: suggestion.confidence.trim().isEmpty
                          ? null
                          : Text(
                              suggestion.confidence.trim(),
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                      onTap: () => Navigator.of(sheetContext).pop(suggestion),
                    ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _handleWorkflowSuggestionSelection(
    ChatMessageEntity message,
    WorkflowSuggestionItem suggestion,
  ) async {
    switch (suggestion.actionType) {
      case ChatMessageActionType.createSondage:
        await _handleCreateSondageFromMessage(message);
        return;
      case ChatMessageActionType.createShift:
        await _handleCreateShiftFromMessage(message);
        return;
      case ChatMessageActionType.createTask:
        await _handleCreateTaskFromMessage(message);
        return;
      case ChatMessageActionType.createEvent:
        await _handleCreateEventFromMessage(message);
        return;
      case null:
        AppSnackBar.showWarning(
          context,
          _chatActionText(
            Localizations.localeOf(context).languageCode,
            it: 'Il suggerimento selezionato non e ancora supportato.',
            en: 'The selected suggestion is not supported yet.',
          ),
        );
        return;
    }
  }

  IconData _iconForWorkflowActionType(ChatMessageActionType? actionType) {
    return switch (actionType) {
      ChatMessageActionType.createSondage => Icons.poll_outlined,
      ChatMessageActionType.createShift => Icons.event_available_outlined,
      ChatMessageActionType.createTask => Icons.task_alt_outlined,
      ChatMessageActionType.createEvent => Icons.event_note_outlined,
      null => Icons.auto_awesome_outlined,
    };
  }

  String _labelForWorkflowActionType(
    String locale,
    ChatMessageActionType? actionType,
  ) {
    return switch (actionType) {
      ChatMessageActionType.createSondage => _chatActionText(
        locale,
        it: 'Crea sondaggio',
        en: 'Create survey',
      ),
      ChatMessageActionType.createShift => _chatActionText(
        locale,
        it: 'Precompila turno',
        en: 'Prefill shift',
      ),
      ChatMessageActionType.createTask => _chatActionText(
        locale,
        it: 'Crea task',
        en: 'Create task',
      ),
      ChatMessageActionType.createEvent => _chatActionText(
        locale,
        it: 'Crea evento',
        en: 'Create event',
      ),
      null => _chatActionText(locale, it: 'Suggerimento', en: 'Suggestion'),
    };
  }

  Future<T> _runWithLoadingOverlay<T>(Future<T> Function() action) async {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    try {
      return await action();
    } finally {
      if (mounted && Navigator.of(context, rootNavigator: true).canPop()) {
        Navigator.of(context, rootNavigator: true).pop();
      }
    }
  }

  Future<void> _handleDeleteRequested(ChatMessageEntity message) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final loc = AppLocalizations.of(dialogContext)!;
        return AlertDialog(
          title: Text(loc.chatDeleteTitle),
          content: Text(loc.chatDeleteMessage),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(loc.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(loc.deleteAction),
            ),
          ],
        );
      },
    );

    if (!mounted || shouldDelete != true) {
      return;
    }

    _chatBloc.add(ChatMessageDeleteConfirmed(message.id));
  }

  void _openDirectConversation({
    required String teamId,
    required String memberUserId,
    required String memberName,
  }) {
    final path = Uri(
      path: widget.layout == ChatScreenLayout.mobile
          ? RouterPaths.sondageChatConversation
          : RouterPaths.chat,
      queryParameters: <String, String>{
        'teamId': teamId,
        'memberUserId': memberUserId,
        'memberName': memberName,
      },
    ).toString();
    if (widget.layout == ChatScreenLayout.mobile) {
      context.pushReplacement(path);
      return;
    }
    context.go(path);
  }

  void _handleRealtimeNotification(RealtimeNotification notification) {
    final eventType = notification.eventType.toUpperCase();
    final selectedTeamId = _selectedTeamId;
    final teamId = notification.metadata['teamId']?.trim();
    if (selectedTeamId == null) {
      return;
    }

    if (eventType.startsWith('TEAM_')) {
      if (teamId != null && teamId.isNotEmpty && teamId == selectedTeamId) {
        _loadTeams();
      }
      return;
    }

    if (!eventType.startsWith('CHAT_MESSAGE_')) {
      return;
    }

    final conversation = _conversation;
    final conversationId = notification.metadata['conversationId']?.trim();

    if (conversation == null) {
      return;
    }
    if (teamId != null && teamId.isNotEmpty && teamId != selectedTeamId) {
      return;
    }
    if (conversationId != null &&
        conversationId.isNotEmpty &&
        conversationId != conversation.id) {
      return;
    }

    unawaited(_refreshMessages());
  }

  void _handleScroll() {
    if (!_scrollController.hasClients) {
      return;
    }
    if (_scrollController.position.pixels <= _olderMessagesLoadThreshold) {
      unawaited(_loadOlderMessages());
    }
    if (_isLatestPortionVisible()) {
      unawaited(_markConversationReadIfVisible());
    }
  }

  bool _isNearBottom() {
    if (!_scrollController.hasClients) {
      return true;
    }
    final position = _scrollController.position;
    return (position.maxScrollExtent - position.pixels) <=
        _readVisibilityThreshold;
  }

  bool _isLatestPortionVisible() {
    if (!_messages.any(
      (message) => !message.mine && !message.readByCurrentUser,
    )) {
      return false;
    }
    return _isNearBottom();
  }

  void _focusLatestMessage({bool animate = true}) {
    if (!_pendingForceLatestFocus) {
      return;
    }
    _pendingForceLatestFocus = false;
    _scrollToBottom(animate: animate);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      unawaited(_markConversationReadIfVisible());
    });
  }

  void _scrollToBottom({bool animate = true}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) {
        return;
      }
      final target = _scrollController.position.maxScrollExtent;
      if (animate) {
        _scrollController.animateTo(
          target,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
        );
      } else {
        _scrollController.jumpTo(target);
      }
    });
  }

  bool _canShowWorkflowSuggestionFooter(ChatMessageEntity message) {
    if (!_canUseWorkflowMessageActions() ||
        !_isWorkflowAiEnabledForSelectedTeam() ||
        message.deleted) {
      return false;
    }
    final content = message.contentText.trim();
    return content.isNotEmpty;
  }

  Future<void> _prefetchWorkflowSuggestionsForMessage(
    ChatMessageEntity message,
  ) async {
    final conversation = _conversation;
    final teamId = _selectedTeamId?.trim();
    if (conversation == null || teamId == null || teamId.isEmpty) {
      return;
    }
    if (!_isWorkflowAiEnabledForSelectedTeam()) {
      return;
    }
    if (_loadingWorkflowSuggestionMessageIds.contains(message.id) ||
        _workflowSuggestionsByMessageId.containsKey(message.id)) {
      return;
    }

    setState(() {
      _loadingWorkflowSuggestionMessageIds.add(message.id);
    });

    try {
      final result = await _messageSuggestionService
          .detectWorkflowSuggestionFromMessage(
            conversationId: conversation.id,
            messageId: message.id,
            teamId: teamId,
            locale: Localizations.localeOf(context).languageCode,
            allowedActionTypes: const <ChatMessageActionType>[
              ChatMessageActionType.createTask,
              ChatMessageActionType.createEvent,
              ChatMessageActionType.createSondage,
              ChatMessageActionType.createShift,
            ],
            selectedMessageText: message.contentText,
            memberUserId: _selectedMemberUserId,
            memberDisplayName: _conversationDisplayName,
          );
      if (!mounted) {
        return;
      }
      setState(() {
        _workflowSuggestionsByMessageId[message.id] = result;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _workflowSuggestionsByMessageId[message.id] =
            const DetectWorkflowSuggestionResult(
              resolutionStatus: 'unsupported',
              suggestions: <WorkflowSuggestionItem>[],
              warnings: <ChatMessageActionWarning>[],
            );
      });
    } finally {
      if (mounted) {
        setState(() {
          _loadingWorkflowSuggestionMessageIds.remove(message.id);
        });
      }
    }
  }

  Widget? _buildWorkflowSuggestionFooter(
    BuildContext context,
    ChatMessageEntity message,
  ) {
    if (!_canShowWorkflowSuggestionFooter(message)) {
      return null;
    }

    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).languageCode;
    final suggestionResult = _workflowSuggestionsByMessageId[message.id];
    final isLoading = _loadingWorkflowSuggestionMessageIds.contains(message.id);
    final alignment = message.mine
        ? Alignment.centerRight
        : Alignment.centerLeft;
    final suggestions = suggestionResult?.suggestions ?? const [];

    return Align(
      alignment: alignment,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: widget.layout == ChatScreenLayout.mobile ? 320 : 420,
        ),
        child: Wrap(
          alignment: message.mine ? WrapAlignment.end : WrapAlignment.start,
          spacing: 8,
          runSpacing: 8,
          children: [
            if (isLoading)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _chatActionText(
                        locale,
                        it: 'Analisi AI...',
                        en: 'AI analysis...',
                      ),
                      style: theme.textTheme.labelMedium,
                    ),
                  ],
                ),
              )
            else if (suggestions.isNotEmpty) ...[
              for (final suggestion in suggestions)
                ActionChip(
                  avatar: Icon(
                    _iconForWorkflowActionType(suggestion.actionType),
                    size: 18,
                    color: theme.colorScheme.primary,
                  ),
                  label: Text(
                    suggestion.title.isNotEmpty
                        ? suggestion.title
                        : _labelForWorkflowActionType(
                            locale,
                            suggestion.actionType,
                          ),
                  ),
                  onPressed: () async {
                    await _handleWorkflowSuggestionSelection(
                      message,
                      suggestion,
                    );
                  },
                ),
              ActionChip(
                avatar: const Icon(Icons.refresh_rounded, size: 18),
                label: Text(
                  _chatActionText(locale, it: 'Aggiorna AI', en: 'Refresh AI'),
                ),
                onPressed: () {
                  setState(() {
                    _workflowSuggestionsByMessageId.remove(message.id);
                  });
                  unawaited(_prefetchWorkflowSuggestionsForMessage(message));
                },
              ),
            ] else if (suggestionResult != null) ...[
              ActionChip(
                avatar: const Icon(Icons.auto_awesome_outlined, size: 18),
                label: Text(
                  _chatActionText(
                    locale,
                    it: 'Nessun suggerimento AI',
                    en: 'No AI suggestion',
                  ),
                ),
                onPressed: () => unawaited(
                  _handleDetectWorkflowSuggestionsFromMessage(message),
                ),
              ),
            ] else
              ActionChip(
                avatar: const Icon(Icons.auto_awesome_outlined, size: 18),
                label: Text(
                  _chatActionText(
                    locale,
                    it: 'Suggerimenti AI',
                    en: 'AI suggestions',
                  ),
                ),
                onPressed: () {
                  unawaited(_prefetchWorkflowSuggestionsForMessage(message));
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<Uint8List> _loadAttachmentBytes(String path) async {
    final response = await DioClient().dio.get<List<int>>(
      DioClient.usesAuthenticatedImageProxy(path) ? '/api/storage/file' : path,
      queryParameters: DioClient.usesAuthenticatedImageProxy(path)
          ? {'path': path}
          : null,
      options: Options(responseType: ResponseType.bytes),
    );
    final data = response.data;
    if (data == null || data.isEmpty) {
      throw StateError('Attachment bytes not available');
    }
    return Uint8List.fromList(data);
  }

  Future<void> _downloadAttachment(ChatMessageEntity message) async {
    final path = message.attachmentPath?.trim();
    if (path == null || path.isEmpty) {
      return;
    }

    try {
      final bytes = await _loadAttachmentBytes(path);
      final downloaded = await _fileDownloadBridge.saveBytes(
        bytes: bytes,
        fileName: message.attachmentOriginalName,
      );
      if (downloaded && mounted) {
        AppSnackBar.showSuccess(context, 'Attachment saved.');
      } else if (mounted) {
        AppSnackBar.showError(context, 'Unable to download attachment.');
      }
    } catch (error) {
      if (!mounted) {
        return;
      }
      AppSnackBar.showError(
        context,
        AppErrorMessageResolver.resolve(
          error,
          fallback: 'Unable to download attachment.',
        ),
      );
    }
  }

  Future<void> _showImageAttachmentViewer(ChatMessageEntity message) async {
    final path = message.attachmentPath?.trim();
    if (path == null || path.isEmpty || !mounted) {
      return;
    }

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return ChatImageViewerDialog(
          attachmentPath: path,
          attachmentName: message.attachmentOriginalName,
          onDownloadPressed: () async {
            Navigator.of(dialogContext).pop();
            await Future<void>.delayed(const Duration(milliseconds: 180));
            if (!mounted) {
              return;
            }
            await _downloadAttachment(message);
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isMobileLayout = widget.layout == ChatScreenLayout.mobile;
    final accentColor = ChatThemeTokens.resolveTeamAccentColor(
      _selectedTeam?.color,
      theme.colorScheme.primary,
    );

    // When we already know which conversation to open (tapped from a chat
    // card), don't block the whole screen on the unrelated team-list fetch.
    final hasKnownConversationTarget = (widget.initialTeamId ?? '').isNotEmpty;

    if (_loadingTeams && !hasKnownConversationTarget) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_teams.isEmpty && !hasKnownConversationTarget) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(isMobileLayout ? 16 : 24),
          child: Text(
            loc.chatNoTeamsAvailable,
            style: theme.textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    if (!_didNotifyContentReady) {
      _didNotifyContentReady = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        widget.onContentReady?.call();
      });
    }

    if (isMobileLayout) {
      return ChatMobileSection(
        headerDescription: _headerDescription(loc),
        teams: _teams,
        messages: _messages,
        messageController: _messageController,
        scrollController: _scrollController,
        loadingMessages: _loadingMessages,
        refreshingMessages: _refreshingMessages,
        loadingOlderMessages: _loadingOlderMessages,
        hasMoreOlderMessages: _hasMoreOlderMessages,
        sending: _sending,
        accentColor: accentColor,
        selectedAttachment: _selectedAttachment,
        showTeamHeader: widget.showTeamHeader,
        selectedTeamId: _selectedTeamId,
        selectedTeamName: _conversationDisplayName ?? _selectedTeam?.name,
        replyTarget: _replyPreviewTarget,
        onRefreshPressed: _handleRefreshPressed,
        onSendPressed: _sendMessage,
        onPickImagePressed: _pickImageAttachment,
        onPickDocumentPressed: _pickDocumentAttachment,
        onClearAttachmentPressed: _clearSelectedAttachment,
        onClearReplyPressed: _clearReplyTarget,
        onTeamChanged: _handleTeamChanged,
        onSenderPressed: _handleSenderPressed,
        onMessagePressed: _handleMessagePressed,
        onMessageLongPressed: _handleMessageLongPressed,
        onReplyRequested: _handleReplyRequested,
        onDeleteRequested: _handleDeleteRequested,
        messageFooterBuilder: _buildWorkflowSuggestionFooter,
        timelineShowcaseKey: widget.timelineShowcaseKey,
        timelineShowcaseTitle: widget.timelineShowcaseTitle,
        timelineShowcaseDescription: widget.timelineShowcaseDescription,
        composerShowcaseKey: widget.composerShowcaseKey,
        composerShowcaseTitle: widget.composerShowcaseTitle,
        composerShowcaseDescription: widget.composerShowcaseDescription,
      );
    }

    return ChatWebLayout(
      headerDescription: _headerDescription(loc),
      teams: _teams,
      messages: _messages,
      messageController: _messageController,
      scrollController: _scrollController,
      loadingMessages: _loadingMessages,
      refreshingMessages: _refreshingMessages,
      loadingOlderMessages: _loadingOlderMessages,
      hasMoreOlderMessages: _hasMoreOlderMessages,
      sending: _sending,
      accentColor: accentColor,
      selectedAttachment: _selectedAttachment,
      showTeamHeader: widget.showTeamHeader,
      selectedTeamId: _selectedTeamId,
      selectedTeamName: _conversationDisplayName ?? _selectedTeam?.name,
      replyTarget: _replyPreviewTarget,
      onRefreshPressed: _handleRefreshPressed,
      onSendPressed: _sendMessage,
      onPickImagePressed: _pickImageAttachment,
      onPickDocumentPressed: _pickDocumentAttachment,
      onClearAttachmentPressed: _clearSelectedAttachment,
      onClearReplyPressed: _clearReplyTarget,
      onTeamChanged: _handleTeamChanged,
      onSenderPressed: _handleSenderPressed,
      onMessagePressed: _handleMessagePressed,
      onMessageLongPressed: _handleMessageLongPressed,
      onReplyRequested: _handleReplyRequested,
      onDeleteRequested: _handleDeleteRequested,
      messageFooterBuilder: _buildWorkflowSuggestionFooter,
      timelineShowcaseKey: widget.timelineShowcaseKey,
      timelineShowcaseTitle: widget.timelineShowcaseTitle,
      timelineShowcaseDescription: widget.timelineShowcaseDescription,
      composerShowcaseKey: widget.composerShowcaseKey,
      composerShowcaseTitle: widget.composerShowcaseTitle,
      composerShowcaseDescription: widget.composerShowcaseDescription,
    );
  }
}

class _ChatMessageActionItem {
  const _ChatMessageActionItem({
    required this.value,
    required this.icon,
    required this.label,
    this.destructive = false,
  });

  final String value;
  final IconData icon;
  final String label;
  final bool destructive;
}
