import 'dart:async';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:note_sondage/core/config/routes.dart';
import 'package:note_sondage/core/network/setup_dio.dart';
import 'package:note_sondage/core/utils/app_error_message_resolver.dart';
import 'package:note_sondage/core/utils/file_download_bridge.dart';
import 'package:note_sondage/feature/chat/domain/entities/chat_conversation_entity.dart';
import 'package:note_sondage/feature/chat/domain/entities/chat_message_entity.dart';
import 'package:note_sondage/feature/chat/domain/entities/chat_message_reply_entity.dart';
import 'package:note_sondage/feature/chat/domain/use_case/chat_use_case.dart';
import 'package:note_sondage/feature/chat/ui/mobile/chat_mobile_section.dart';
import 'package:note_sondage/feature/chat/ui/widgets/chat_direct_action_dialog.dart';
import 'package:note_sondage/feature/chat/ui/widgets/chat_image_viewer_dialog.dart';
import 'package:note_sondage/feature/chat/ui/web/chat_web_layout.dart';
import 'package:note_sondage/feature/chat/ui/widgets/chat_draft_attachment.dart';
import 'package:note_sondage/feature/chat/ui/widgets/chat_theme.dart';
import 'package:note_sondage/feature/notification/realtime/realtime_notification_model.dart';
import 'package:note_sondage/feature/notification/realtime/realtime_notification_service.dart';
import 'package:note_sondage/feature/team/domain/entities/team_entity.dart';
import 'package:note_sondage/feature/team/domain/use_case/team/team_use_case.dart';
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
  });

  final String? initialTeamId;
  final String? initialMemberUserId;
  final bool focusLatestOnOpen;
  final ChatScreenLayout layout;
  final bool showTeamHeader;
  final ValueChanged<String?>? onConversationTitleChanged;

  @override
  State<TeamChatScreen> createState() => _TeamChatScreenState();
}

class _TeamChatScreenState extends State<TeamChatScreen> {
  static const int _initialMessagesLimit = 100;
  static const int _olderMessagesBatchSize = 70;
  static const double _olderMessagesLoadThreshold = 180;
  static const double _readVisibilityThreshold = 72;

  final TeamUseCase _teamUseCase = GetIt.instance<TeamUseCase>();
  final ChatUseCase _chatUseCase = GetIt.instance<ChatUseCase>();
  final RealtimeNotificationService _realtimeService =
      GetIt.instance<RealtimeNotificationService>();
  final ImagePicker _imagePicker = ImagePicker();
  final FileDownloadBridge _fileDownloadBridge = createFileDownloadBridge();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  StreamSubscription<RealtimeNotification>? _realtimeSubscription;

  List<TeamEntity> _teams = const <TeamEntity>[];
  List<ChatMessageEntity> _messages = const <ChatMessageEntity>[];
  ChatConversationEntity? _conversation;
  String? _selectedTeamId;
  String? _selectedMemberUserId;
  String? _conversationDisplayName;
  bool _loadingTeams = true;
  bool _loadingMessages = false;
  bool _refreshingMessages = false;
  bool _loadingOlderMessages = false;
  bool _hasMoreOlderMessages = true;
  bool _sending = false;
  bool _markingConversationRead = false;
  bool _pendingForceLatestFocus = false;
  ChatDraftAttachment? _selectedAttachment;
  ChatMessageEntity? _replyTarget;

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
    widget.onConversationTitleChanged?.call(_resolvedConversationTitle());
  }

  @override
  void initState() {
    super.initState();
    _pendingForceLatestFocus = widget.focusLatestOnOpen;
    _scrollController.addListener(_handleScroll);
    _realtimeSubscription = _realtimeService.stream.listen(
      _handleRealtimeNotification,
    );
    unawaited(_loadTeams());
  }

  @override
  void dispose() {
    _realtimeSubscription?.cancel();
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
      unawaited(_loadConversation(nextTeamId, memberUserId: nextMemberUserId));
      return;
    }
    unawaited(_loadTeams());
  }

  Future<void> _loadTeams({bool showFeedback = false}) async {
    try {
      final teams = await _teamUseCase.getAllTeams();
      if (!mounted) return;

      final nextTeamId = _resolveNextTeamId(teams);
      setState(() {
        _teams = teams;
        _selectedTeamId = nextTeamId;
        _loadingTeams = false;
      });
      _notifyConversationTitleChanged();

      if (nextTeamId != null) {
        await _loadConversation(
          nextTeamId,
          memberUserId: widget.initialMemberUserId?.trim(),
        );
      } else if (mounted) {
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

      if (showFeedback && mounted) {
        AppSnackBar.showSuccess(
          context,
          AppLocalizations.of(context)!.chatRefreshed,
        );
      }
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loadingTeams = false;
      });
      AppSnackBar.showError(
        context,
        AppErrorMessageResolver.resolve(
          error,
          fallback: AppLocalizations.of(context)!.chatLoadTeamsError,
        ),
      );
    }
  }

  String? _resolveNextTeamId(List<TeamEntity> teams) {
    final preferredTeamId = widget.initialTeamId ?? _selectedTeamId;
    if (preferredTeamId != null &&
        teams.any((team) => team.id == preferredTeamId)) {
      return preferredTeamId;
    }
    return teams.isNotEmpty ? teams.first.id : null;
  }

  Future<void> _loadConversation(String teamId, {String? memberUserId}) async {
    final normalizedMemberUserId = memberUserId?.trim();
    final isDirect =
        normalizedMemberUserId != null && normalizedMemberUserId.isNotEmpty;
    final cachedConversation = isDirect
        ? _chatUseCase.getCachedDirectConversation(
            teamId,
            normalizedMemberUserId,
          )
        : _chatUseCase.getCachedTeamConversation(teamId);
    final cachedMessages = cachedConversation == null
        ? const <ChatMessageEntity>[]
        : _chatUseCase.getCachedMessages(cachedConversation.id);
    final hasReliableCachedEmptyState =
        cachedConversation != null && cachedConversation.lastMessageAt == null;
    final canRenderCache =
        cachedMessages.isNotEmpty || hasReliableCachedEmptyState;

    setState(() {
      _selectedTeamId = teamId;
      _selectedMemberUserId = normalizedMemberUserId;
      if (cachedConversation != null) {
        _conversation = cachedConversation;
        _conversationDisplayName =
            cachedConversation.participantDisplayName ?? _selectedTeam?.name;
      } else {
        _conversation = null;
        _conversationDisplayName = null;
      }
      if (canRenderCache) {
        _messages = cachedMessages;
      } else {
        _messages = const <ChatMessageEntity>[];
      }
      _loadingMessages = !canRenderCache;
      _refreshingMessages = canRenderCache;
      _loadingOlderMessages = false;
      _hasMoreOlderMessages = cachedMessages.length >= _initialMessagesLimit;
    });
    _notifyConversationTitleChanged();
    if (canRenderCache && _pendingForceLatestFocus) {
      _focusLatestMessage();
    }

    try {
      final conversation = isDirect
          ? await _chatUseCase.getOrCreateDirectConversation(
              teamId,
              normalizedMemberUserId,
            )
          : await _chatUseCase.getOrCreateTeamConversation(teamId);
      final messages = await _chatUseCase.getMessages(
        conversation.id,
        limit: _initialMessagesLimit,
      );
      if (!mounted) return;
      setState(() {
        _conversation = conversation;
        _conversationDisplayName =
            conversation.participantDisplayName ?? _selectedTeam?.name;
        _messages = messages;
        _loadingMessages = false;
        _refreshingMessages = false;
        _hasMoreOlderMessages = messages.length >= _initialMessagesLimit;
      });
      _notifyConversationTitleChanged();
      if (_pendingForceLatestFocus) {
        _focusLatestMessage();
      } else {
        _scrollToBottom();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) {
            return;
          }
          unawaited(_markConversationReadIfVisible());
        });
      }
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loadingMessages = false;
        _refreshingMessages = false;
      });
      AppSnackBar.showError(
        context,
        AppErrorMessageResolver.resolve(
          error,
          fallback: AppLocalizations.of(context)!.chatLoadConversationError,
        ),
      );
    }
  }

  Future<void> _refreshMessages() async {
    final conversation = _conversation;
    if (conversation == null) {
      return;
    }

    final shouldKeepBottomVisible = _isNearBottom();

    if (mounted) {
      setState(() {
        _refreshingMessages = true;
      });
    }

    try {
      final messages = await _chatUseCase.getMessages(
        conversation.id,
        limit: _initialMessagesLimit,
      );
      final mergedMessages = _mergeRecentMessages(
        currentMessages: _messages,
        latestMessages: messages,
      );
      if (!mounted) return;
      setState(() {
        _messages = mergedMessages;
        _refreshingMessages = false;
        _hasMoreOlderMessages = messages.length >= _initialMessagesLimit;
      });
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
    } catch (_) {
      // Best effort refresh triggered by realtime notifications.
      if (!mounted) return;
      setState(() {
        _refreshingMessages = false;
      });
    }
  }

  Future<void> _loadOlderMessages() async {
    final conversation = _conversation;
    if (conversation == null ||
        _loadingMessages ||
        _loadingOlderMessages ||
        !_hasMoreOlderMessages ||
        _messages.isEmpty) {
      return;
    }

    final before = _messages.first.createdAt;
    final previousMaxScrollExtent = _scrollController.hasClients
        ? _scrollController.position.maxScrollExtent
        : 0.0;
    final previousPixels = _scrollController.hasClients
        ? _scrollController.position.pixels
        : 0.0;

    setState(() {
      _loadingOlderMessages = true;
    });

    try {
      final olderMessages = await _chatUseCase.getMessages(
        conversation.id,
        before: before,
        limit: _olderMessagesBatchSize,
      );
      if (!mounted) return;

      final existingIds = _messages.map((message) => message.id).toSet();
      final uniqueOlderMessages = olderMessages
          .where((message) => !existingIds.contains(message.id))
          .toList();

      if (uniqueOlderMessages.isEmpty) {
        setState(() {
          _loadingOlderMessages = false;
          _hasMoreOlderMessages = false;
        });
        return;
      }

      setState(() {
        _messages = <ChatMessageEntity>[...uniqueOlderMessages, ..._messages];
        _loadingOlderMessages = false;
        _hasMoreOlderMessages = olderMessages.length >= _olderMessagesBatchSize;
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_scrollController.hasClients) {
          return;
        }
        final newMaxScrollExtent = _scrollController.position.maxScrollExtent;
        final delta = newMaxScrollExtent - previousMaxScrollExtent;
        _scrollController.jumpTo(previousPixels + delta);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadingOlderMessages = false;
      });
    }
  }

  Future<void> _sendMessage() async {
    final conversation = _conversation;
    final content = _messageController.text.trim();
    final selectedAttachment = _selectedAttachment;
    if (conversation == null ||
        (content.isEmpty && selectedAttachment == null) ||
        _sending) {
      return;
    }

    final temporaryMessage = _buildOptimisticMessage(
      conversationId: conversation.id,
      content: content,
      attachment: selectedAttachment,
      replyTo: _replyTarget,
    );

    setState(() {
      _sending = true;
      _selectedAttachment = null;
      _replyTarget = null;
      _messages = <ChatMessageEntity>[..._messages, temporaryMessage];
    });
    _messageController.clear();
    _scrollToBottom();

    try {
      final message = selectedAttachment == null
          ? await _chatUseCase.sendMessage(
              conversation.id,
              content,
              replyToMessageId: temporaryMessage.replyTo?.messageId,
            )
          : await _chatUseCase.sendAttachmentMessage(
              conversation.id,
              content: content,
              bytes: selectedAttachment.bytes,
              fileName: selectedAttachment.fileName,
              contentType: selectedAttachment.contentType,
              replyToMessageId: temporaryMessage.replyTo?.messageId,
            );
      if (!mounted) return;
      setState(() {
        _messages = _messages
            .map((item) => item.id == temporaryMessage.id ? message : item)
            .toList();
        _sending = false;
      });
      _scrollToBottom();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _messages = _messages
            .where((item) => item.id != temporaryMessage.id)
            .toList();
        _sending = false;
        _selectedAttachment = selectedAttachment;
        _replyTarget = temporaryMessage.replyTo == null
            ? null
            : ChatMessageEntity(
                id: temporaryMessage.replyTo!.messageId,
                conversationId: conversation.id,
                senderUserId: '',
                senderName: temporaryMessage.replyTo!.senderName,
                senderAvatarUrl: null,
                contentText: temporaryMessage.replyTo!.contentPreview,
                messageType: temporaryMessage.replyTo!.messageType,
                attachmentPath: null,
                attachmentOriginalName: null,
                attachmentContentType: null,
                attachmentSizeBytes: null,
                replyTo: null,
                reactions: const [],
                deleted: temporaryMessage.replyTo!.deleted,
                deletedAt: null,
                createdAt: DateTime.now(),
                readByCurrentUser: true,
                deliveredByOtherCount: 0,
                readByOtherCount: 0,
                mine: false,
              );
      });
      _messageController.text = content;
      _messageController.selection = TextSelection.fromPosition(
        TextPosition(offset: _messageController.text.length),
      );
      AppSnackBar.showError(
        context,
        AppErrorMessageResolver.resolve(
          error,
          fallback: AppLocalizations.of(context)!.chatSendMessageError,
        ),
      );
    }
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
    setState(() {
      _selectedAttachment = ChatDraftAttachment(
        bytes: bytes,
        fileName: fileName,
        contentType: _resolveDocumentContentType(file.extension),
        sizeBytes: bytes.length,
      );
    });
  }

  Future<void> _applyPickedImageAttachment(XFile pickedFile) async {
    final bytes = await pickedFile.readAsBytes();
    if (bytes.isEmpty) {
      return;
    }
    setState(() {
      _selectedAttachment = ChatDraftAttachment(
        bytes: bytes,
        fileName: pickedFile.name,
        contentType: _resolveImageContentType(pickedFile.name),
        sizeBytes: bytes.length,
      );
    });
  }

  void _clearSelectedAttachment() {
    if (_selectedAttachment == null) {
      return;
    }
    setState(() {
      _selectedAttachment = null;
    });
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
    final conversation = _conversation;
    if (conversation == null || _markingConversationRead) {
      return;
    }
    if (!_messages.any(
      (message) => !message.mine && !message.readByCurrentUser,
    )) {
      return;
    }

    _markingConversationRead = true;
    try {
      await _chatUseCase.markConversationRead(conversation.id);
      if (!mounted) {
        return;
      }
      setState(() {
        _messages = _messages
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
            .toList();
      });
    } catch (_) {
      // Best effort.
    } finally {
      _markingConversationRead = false;
    }
  }

  Future<void> _markConversationReadIfVisible() async {
    if (!_isLatestPortionVisible()) {
      return;
    }
    await _markConversationRead();
  }

  void _handleRefreshPressed() {
    unawaited(_loadTeams(showFeedback: true));
  }

  void _handleTeamChanged(String teamId) {
    if (teamId == _selectedTeamId) {
      return;
    }
    unawaited(_loadConversation(teamId));
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
    setState(() {
      _replyTarget = message;
    });
  }

  void _clearReplyTarget() {
    if (_replyTarget == null) {
      return;
    }
    setState(() {
      _replyTarget = null;
    });
  }

  Future<void> _handleReactionRequested(
    ChatMessageEntity message,
    String emoji,
  ) async {
    try {
      final updated = await _chatUseCase.toggleReaction(message.id, emoji);
      if (!mounted) {
        return;
      }
      setState(() {
        _messages = _messages
            .map((item) => item.id == updated.id ? updated : item)
            .toList();
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      AppSnackBar.showError(
        context,
        AppErrorMessageResolver.resolve(
          error,
          fallback: AppLocalizations.of(context)!.chatReactionUpdateError,
        ),
      );
    }
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
    final path = message.attachmentPath?.trim();
    if (path == null || path.isEmpty) {
      return;
    }

    if (message.isImageAttachment) {
      await _showImageAttachmentViewer(message);
      return;
    }

    await _downloadAttachment(message);
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

    try {
      final updated = await _chatUseCase.deleteMessage(message.id);
      if (!mounted) {
        return;
      }
      setState(() {
        _messages = _messages
            .map((item) => item.id == updated.id ? updated : item)
            .toList();
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      AppSnackBar.showError(
        context,
        AppErrorMessageResolver.resolve(
          error,
          fallback: AppLocalizations.of(context)!.chatDeleteError,
        ),
      );
    }
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
    if (!eventType.startsWith('CHAT_MESSAGE_')) {
      return;
    }

    final selectedTeamId = _selectedTeamId;
    final conversation = _conversation;
    final teamId = notification.metadata['teamId']?.trim();
    final conversationId = notification.metadata['conversationId']?.trim();

    if (selectedTeamId == null || conversation == null) {
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

  void _focusLatestMessage() {
    if (!_pendingForceLatestFocus) {
      return;
    }
    _pendingForceLatestFocus = false;
    _scrollToBottom();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      unawaited(_markConversationReadIfVisible());
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) {
        return;
      }
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    });
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
              message.createdAt.isBefore(firstLatestTimestamp) &&
              !latestIds.contains(message.id),
        )
        .toList();

    return <ChatMessageEntity>[...preservedOlderMessages, ...latestMessages];
  }

  ChatMessageEntity _buildOptimisticMessage({
    required String conversationId,
    required String content,
    required ChatDraftAttachment? attachment,
    required ChatMessageEntity? replyTo,
  }) {
    return ChatMessageEntity(
      id: 'local-${DateTime.now().microsecondsSinceEpoch}',
      conversationId: conversationId,
      senderUserId: 'local-user',
      senderName: AppLocalizations.of(context)!.chatYouLabel,
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

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isMobileLayout = widget.layout == ChatScreenLayout.mobile;
    final accentColor = ChatThemeTokens.resolveTeamAccentColor(
      _selectedTeam?.color,
      theme.colorScheme.primary,
    );

    if (_loadingTeams) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_teams.isEmpty) {
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
    );
  }
}
