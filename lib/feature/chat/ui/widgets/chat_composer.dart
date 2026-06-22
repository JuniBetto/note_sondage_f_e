import 'package:flutter/material.dart';
import 'package:note_sondage/feature/chat/domain/entities/chat_message_reply_entity.dart';
import 'package:note_sondage/feature/chat/ui/widgets/chat_draft_attachment.dart';
import 'package:note_sondage/feature/chat/ui/widgets/chat_theme.dart';
import 'package:note_sondage/languages/l10n/app_localizations.dart';
import 'package:note_sondage/theme/extensions/color_scheme/color_scheme.dart';

class ChatComposer extends StatefulWidget {
  const ChatComposer({
    super.key,
    required this.messageController,
    required this.compact,
    required this.sending,
    required this.accentColor,
    required this.onPickImagePressed,
    required this.onPickDocumentPressed,
    required this.onClearAttachmentPressed,
    required this.onSendPressed,
    this.selectedAttachment,
    this.replyTarget,
    this.onClearReplyPressed,
  });

  final TextEditingController messageController;
  final bool compact;
  final bool sending;
  final Color accentColor;
  final VoidCallback onPickImagePressed;
  final VoidCallback onPickDocumentPressed;
  final VoidCallback onClearAttachmentPressed;
  final VoidCallback onSendPressed;
  final ChatDraftAttachment? selectedAttachment;
  final ChatMessageReplyEntity? replyTarget;
  final VoidCallback? onClearReplyPressed;

  @override
  State<ChatComposer> createState() => _ChatComposerState();
}

class _ChatComposerState extends State<ChatComposer> {
  bool _showTools = false;
  bool _showEmojiPicker = false;

  bool get _hasText => widget.messageController.text.trim().isNotEmpty;
  bool get _canSend => _hasText || widget.selectedAttachment != null;

  @override
  void initState() {
    super.initState();
    widget.messageController.addListener(_handleTextChanged);
  }

  @override
  void didUpdateWidget(covariant ChatComposer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.messageController == widget.messageController) {
      return;
    }
    oldWidget.messageController.removeListener(_handleTextChanged);
    widget.messageController.addListener(_handleTextChanged);
  }

  @override
  void dispose() {
    widget.messageController.removeListener(_handleTextChanged);
    super.dispose();
  }

  void _handleTextChanged() {
    if (_hasText && _showTools) {
      setState(() {
        _showTools = false;
        _showEmojiPicker = false;
      });
      return;
    }
    if (mounted) {
      setState(() {});
    }
  }

  void _handlePrimaryPressed() {
    if (_canSend) {
      widget.onSendPressed();
      return;
    }
    setState(() {
      _showTools = !_showTools;
      if (!_showTools) {
        _showEmojiPicker = false;
      }
    });
  }

  void _toggleEmojiPicker() {
    setState(() {
      _showTools = true;
      _showEmojiPicker = !_showEmojiPicker;
    });
  }

  void _insertEmoji(String emoji) {
    final value = widget.messageController.value;
    final text = value.text;
    final selection = value.selection;
    final start = selection.isValid ? selection.start : text.length;
    final end = selection.isValid ? selection.end : text.length;
    final safeStart = start < 0 ? text.length : start;
    final safeEnd = end < 0 ? text.length : end;
    final updatedText = text.replaceRange(safeStart, safeEnd, emoji);

    widget.messageController.value = TextEditingValue(
      text: updatedText,
      selection: TextSelection.collapsed(offset: safeStart + emoji.length),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final palette = ChatThemeTokens.composerPalette(widget.accentColor);
    final containerPadding = widget.compact ? 8.0 : 10.0;
    final fieldHeight = widget.compact ? 40.0 : 44.0;
    final inputTextStyle = widget.compact
        ? theme.textTheme.bodyMedium
        : theme.textTheme.bodyLarge;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        widget.compact ? 10 : 18,
        0,
        widget.compact ? 10 : 18,
        widget.compact ? 6 : 10,
      ),
      child: Column(
        children: [
          if (widget.replyTarget != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _ReplyPreviewCard(
                compact: widget.compact,
                replyTarget: widget.replyTarget!,
                palette: palette,
                onClearPressed: widget.onClearReplyPressed,
              ),
            ),
          if (widget.selectedAttachment != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _SelectedAttachmentCard(
                compact: widget.compact,
                attachment: widget.selectedAttachment!,
                palette: palette,
                onClearPressed: widget.onClearAttachmentPressed,
              ),
            ),
          if (_showTools)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: colorScheme.bgColorNew!.withValues(alpha: 0.65),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: palette.borderColor.withValues(alpha: 0.65),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: palette.accentColor.withValues(alpha: 0.08),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Padding(
                  padding: EdgeInsets.all(widget.compact ? 10 : 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _AccessoryToolbar(
                        compact: widget.compact,
                        palette: palette,
                        loc: loc,
                        onPickImagePressed: widget.onPickImagePressed,
                        onPickDocumentPressed: widget.onPickDocumentPressed,
                        onEmojiPressed: _toggleEmojiPicker,
                        emojiActive: _showEmojiPicker,
                      ),
                      if (_showEmojiPicker) ...[
                        const SizedBox(height: 8),
                        _EmojiPickerPanel(
                          compact: widget.compact,
                          palette: palette,
                          onEmojiSelected: _insertEmoji,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          DecoratedBox(
            decoration: BoxDecoration(
              color: palette.surfaceColor,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: palette.borderColor.withValues(alpha: 0.42),
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0x22000000),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
                BoxShadow(
                  color: palette.accentColor.withValues(alpha: 0.06),
                  blurRadius: 22,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Padding(
              padding: EdgeInsets.all(containerPadding),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      constraints: BoxConstraints(minHeight: fieldHeight),
                      alignment: Alignment.centerLeft,
                      padding: EdgeInsets.symmetric(
                        horizontal: widget.compact ? 12 : 14,
                        vertical: widget.compact ? 10 : 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.95),
                        ),
                      ),
                      child: TextField(
                        controller: widget.messageController,

                        minLines: 1,
                        maxLines: 3,
                        keyboardType: TextInputType.multiline,
                        textInputAction: TextInputAction.newline,
                        style: inputTextStyle?.copyWith(
                          color:
                              Colors.black87, //colorScheme.textInvertedColor,
                        ),
                        decoration: InputDecoration(
                          hintText: loc.chatComposerHint,
                          hintStyle: inputTextStyle?.copyWith(
                            color: Colors.black87,
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          border: InputBorder.none,
                          isCollapsed: true,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _PrimaryComposerButton(
                    sending: widget.sending,
                    canSend: _canSend,
                    compact: widget.compact,
                    palette: palette,
                    onPressed: _handlePrimaryPressed,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AccessoryToolbar extends StatelessWidget {
  const _AccessoryToolbar({
    required this.compact,
    required this.palette,
    required this.loc,
    required this.onPickImagePressed,
    required this.onPickDocumentPressed,
    required this.onEmojiPressed,
    required this.emojiActive,
  });

  final bool compact;
  final ChatComposerPalette palette;
  final AppLocalizations loc;
  final VoidCallback onPickImagePressed;
  final VoidCallback onPickDocumentPressed;
  final VoidCallback onEmojiPressed;
  final bool emojiActive;

  @override
  Widget build(BuildContext context) {
    final buttonSize = compact ? 30.0 : 34.0;

    return Wrap(
      spacing: compact ? 6 : 8,
      runSpacing: compact ? 6 : 8,
      children: [
        _ComposerAccessory(
          icon: Icons.image_outlined,
          tooltip: loc.chatPickImage,
          compact: compact,
          buttonSize: buttonSize,
          palette: palette,
          onPressed: onPickImagePressed,
        ),
        _ComposerAccessory(
          icon: Icons.attach_file_rounded,
          tooltip: loc.chatPickDocument,
          compact: compact,
          buttonSize: buttonSize,
          palette: palette,
          onPressed: onPickDocumentPressed,
        ),
        _ComposerAccessory(
          icon: Icons.sentiment_satisfied_alt_rounded,
          tooltip: loc.chatAddEmoji,
          compact: compact,
          buttonSize: buttonSize,
          palette: palette,
          selected: emojiActive,
          onPressed: onEmojiPressed,
        ),
      ],
    );
  }
}

class _EmojiPickerPanel extends StatelessWidget {
  const _EmojiPickerPanel({
    required this.compact,
    required this.palette,
    required this.onEmojiSelected,
  });

  final bool compact;
  final ChatComposerPalette palette;
  final ValueChanged<String> onEmojiSelected;

  static const List<String> _emojis = <String>[
    '😀',
    '😁',
    '😂',
    '😊',
    '😍',
    '😘',
    '🤝',
    '👏',
    '🙌',
    '👍',
    '👎',
    '🙏',
    '🔥',
    '🎉',
    '💪',
    '❤️',
    '💛',
    '🤍',
    '😎',
    '🤔',
    '😢',
    '😡',
    '😴',
    '🚀',
  ];

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: palette.inputSurfaceColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: palette.borderColor.withValues(alpha: 0.4)),
      ),
      child: Padding(
        padding: EdgeInsets.all(compact ? 8 : 10),
        child: Wrap(
          spacing: compact ? 6 : 8,
          runSpacing: compact ? 6 : 8,
          children: [
            for (final emoji in _emojis)
              InkWell(
                onTap: () => onEmojiSelected(emoji),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: compact ? 34 : 38,
                  height: compact ? 34 : 38,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    emoji,
                    style: TextStyle(fontSize: compact ? 19 : 21),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ReplyPreviewCard extends StatelessWidget {
  const _ReplyPreviewCard({
    required this.compact,
    required this.replyTarget,
    required this.palette,
    required this.onClearPressed,
  });

  final bool compact;
  final ChatMessageReplyEntity replyTarget;
  final ChatComposerPalette palette;
  final VoidCallback? onClearPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context)!;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: palette.borderColor.withValues(alpha: 0.5)),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 12 : 14,
          vertical: compact ? 10 : 12,
        ),
        child: Row(
          children: [
            Container(
              width: 4,
              height: compact ? 34 : 40,
              decoration: BoxDecoration(
                color: palette.accentColor,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    loc.chatReplyingTo(replyTarget.senderName),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style:
                        (compact
                                ? theme.textTheme.labelMedium
                                : theme.textTheme.bodyMedium)
                            ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    replyTarget.deleted
                        ? loc.chatDeletedMessage
                        : replyTarget.contentPreview,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style:
                        (compact
                                ? theme.textTheme.labelSmall
                                : theme.textTheme.bodySmall)
                            ?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                  ),
                ],
              ),
            ),
            if (onClearPressed != null)
              IconButton(
                onPressed: onClearPressed,
                tooltip: loc.chatCancelReply,
                icon: const Icon(Icons.close_rounded),
              ),
          ],
        ),
      ),
    );
  }
}

class _PrimaryComposerButton extends StatelessWidget {
  const _PrimaryComposerButton({
    required this.sending,
    required this.canSend,
    required this.compact,
    required this.palette,
    required this.onPressed,
  });

  final bool sending;
  final bool canSend;
  final bool compact;
  final ChatComposerPalette palette;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final icon = canSend ? Icons.send_rounded : Icons.add_rounded;
    final size = compact ? 32.0 : 38.0;

    return FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        minimumSize: Size(size, size),
        maximumSize: Size(size, size),
        padding: EdgeInsets.zero,
        backgroundColor: palette.accentColor,
        foregroundColor: palette.onAccentColor,
        shape: const CircleBorder(),
      ),
      child: Icon(icon, size: compact ? 18 : 20),
    );
  }
}

class _ComposerAccessory extends StatelessWidget {
  const _ComposerAccessory({
    required this.icon,
    required this.tooltip,
    required this.compact,
    required this.buttonSize,
    required this.palette,
    required this.onPressed,
    this.selected = false,
  });

  final IconData icon;
  final String tooltip;
  final bool compact;
  final double buttonSize;
  final ChatComposerPalette palette;
  final VoidCallback onPressed;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      tooltip: tooltip,
      style: IconButton.styleFrom(
        backgroundColor: selected
            ? palette.accentColor.withValues(alpha: 0.14)
            : Colors.white,
        minimumSize: Size(buttonSize, buttonSize),
        maximumSize: Size(buttonSize, buttonSize),
        padding: EdgeInsets.zero,
        side: BorderSide(
          color: selected
              ? palette.accentColor.withValues(alpha: 0.32)
              : palette.borderColor.withValues(alpha: 0.28),
        ),
      ),
      icon: Icon(icon, size: compact ? 16 : 18, color: palette.iconTintColor),
    );
  }
}

class _SelectedAttachmentCard extends StatelessWidget {
  const _SelectedAttachmentCard({
    required this.compact,
    required this.attachment,
    required this.palette,
    required this.onClearPressed,
  });

  final bool compact;
  final ChatDraftAttachment attachment;
  final ChatComposerPalette palette;
  final VoidCallback onClearPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context)!;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: palette.borderColor.withValues(alpha: 0.5)),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 12 : 14,
          vertical: compact ? 10 : 12,
        ),
        child: Row(
          children: [
            Container(
              width: compact ? 32 : 36,
              height: compact ? 32 : 36,
              decoration: BoxDecoration(
                color: palette.accentColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                attachment.isImage
                    ? Icons.image_outlined
                    : Icons.insert_drive_file_outlined,
                size: compact ? 18 : 20,
                color: palette.accentColor,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    attachment.fileName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style:
                        (compact
                                ? theme.textTheme.labelMedium
                                : theme.textTheme.bodyMedium)
                            ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    attachment.isImage
                        ? loc.chatImageReadyToSend
                        : loc.chatDocumentReadyToSend,
                    style:
                        (compact
                                ? theme.textTheme.labelSmall
                                : theme.textTheme.bodySmall)
                            ?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: onClearPressed,
              tooltip: loc.chatRemoveAttachment,
              icon: const Icon(Icons.close_rounded),
            ),
          ],
        ),
      ),
    );
  }
}
