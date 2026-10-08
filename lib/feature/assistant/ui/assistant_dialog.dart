import 'package:flutter/material.dart';
import 'package:note_sondage/feature/assistant/ui/assistant_session.dart';
import 'package:note_sondage/languages/l10n/app_localizations.dart';
import 'package:note_sondage/theme/extensions/color_scheme/color_scheme.dart';

Future<void> showAssistantDialog(
  BuildContext context, {
  AssistantSession? session,
}) {
  return showDialog<void>(
    context: context,
    builder: (_) =>
        AssistantDialog(session: session ?? AssistantSession.instance),
  );
}

class AssistantDialog extends StatefulWidget {
  const AssistantDialog({super.key, required this.session});

  final AssistantSession session;

  @override
  State<AssistantDialog> createState() => _AssistantDialogState();
}

class _AssistantDialogState extends State<AssistantDialog> {
  final TextEditingController _input = TextEditingController();
  final ScrollController _scroll = ScrollController();
  final FocusNode _inputFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    widget.session.addListener(_scrollToBottom);
  }

  @override
  void dispose() {
    widget.session.removeListener(_scrollToBottom);
    _input.dispose();
    _scroll.dispose();
    _inputFocus.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _send() {
    final text = _input.text;
    if (text.trim().isEmpty || widget.session.sending) {
      return;
    }
    _input.clear();
    widget.session.send(text);
    _inputFocus.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final size = MediaQuery.sizeOf(context);
    final borderColor = colorScheme.borderColor ?? colorScheme.outlineVariant;
    final accent = colorScheme.lightButtons ?? colorScheme.secondary;

    OutlineInputBorder inputBorder(Color color, [double width = 1]) {
      return OutlineInputBorder(
        borderRadius: BorderRadius.circular(24),
        borderSide: BorderSide(color: color, width: width),
      );
    }

    return Dialog(
      backgroundColor: colorScheme.bgSurface,
      surfaceTintColor: Colors.transparent,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: borderColor),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 560,
          maxHeight: size.height * 0.8,
        ),
        child: ListenableBuilder(
          listenable: widget.session,
          builder: (context, _) {
            final messages = widget.session.messages;
            final sending = widget.session.sending;
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _Header(
                  title: loc.assistantTitle,
                  canReset: messages.isNotEmpty && !sending,
                  resetTooltip: loc.assistantNewConversation,
                  closeTooltip: loc.close,
                  onReset: widget.session.reset,
                ),
                Divider(height: 1, thickness: 1, color: borderColor),
                Flexible(
                  child: messages.isEmpty
                      ? _EmptyState(text: loc.assistantEmptyState)
                      : ListView.builder(
                          controller: _scroll,
                          shrinkWrap: true,
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                          itemCount: messages.length + (sending ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index == messages.length) {
                              return _Bubble.thinking(loc.assistantThinking);
                            }
                            return _Bubble.forMessage(messages[index], loc);
                          },
                        ),
                ),
                Divider(height: 1, thickness: 1, color: borderColor),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: TextField(
                          key: const Key('assistant_input'),
                          controller: _input,
                          focusNode: _inputFocus,
                          autofocus: true,
                          minLines: 1,
                          maxLines: 4,
                          maxLength: 4000,
                          textInputAction: TextInputAction.send,
                          onSubmitted: (_) => _send(),
                          cursorColor: accent,
                          style: TextStyle(color: colorScheme.textColor),
                          decoration: InputDecoration(
                            hintText: loc.assistantInputHint,
                            hintStyle: TextStyle(
                              color: colorScheme.descriptionColor,
                            ),
                            counterText: '',
                            filled: true,
                            fillColor: colorScheme.messageBgColor,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            border: inputBorder(borderColor),
                            enabledBorder: inputBorder(borderColor),
                            focusedBorder: inputBorder(accent, 1.5),
                            isDense: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filled(
                        key: const Key('assistant_send'),
                        tooltip: loc.assistantSend,
                        onPressed: sending ? null : _send,
                        style: IconButton.styleFrom(
                          backgroundColor: accent,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: accent.withValues(
                            alpha: 0.35,
                          ),
                          disabledForegroundColor: Colors.white70,
                        ),
                        icon: const Icon(Icons.send_rounded, size: 20),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.title,
    required this.canReset,
    required this.resetTooltip,
    required this.closeTooltip,
    required this.onReset,
  });

  final String title;
  final bool canReset;
  final String resetTooltip;
  final String closeTooltip;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final accent = colorScheme.lightButtons ?? colorScheme.secondary;
    final iconColor = colorScheme.textColor;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.auto_awesome_rounded,
              size: 18,
              color: colorScheme.primaryColor,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: colorScheme.textColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          IconButton(
            tooltip: resetTooltip,
            onPressed: canReset ? onReset : null,
            color: iconColor,
            disabledColor: colorScheme.descriptionColor?.withValues(alpha: 0.5),
            icon: const Icon(Icons.refresh_rounded),
          ),
          IconButton(
            tooltip: closeTooltip,
            onPressed: () => Navigator.of(context).pop(),
            color: iconColor,
            icon: const Icon(Icons.close_rounded),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(color: colorScheme.descriptionColor),
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({
    required this.text,
    required this.fromUser,
    this.isError = false,
    this.isThinking = false,
  });

  factory _Bubble.forMessage(AssistantMessage message, AppLocalizations loc) {
    return switch (message.kind) {
      AssistantMessageKind.user => _Bubble(text: message.text, fromUser: true),
      AssistantMessageKind.assistant => _Bubble(
        text: message.text,
        fromUser: false,
      ),
      AssistantMessageKind.error => _Bubble(
        text: loc.assistantError,
        fromUser: false,
        isError: true,
      ),
      AssistantMessageKind.unavailable => _Bubble(
        text: loc.assistantUnavailable,
        fromUser: false,
        isError: true,
      ),
    };
  }

  factory _Bubble.thinking(String text) {
    return _Bubble(text: text, fromUser: false, isThinking: true);
  }

  final String text;
  final bool fromUser;
  final bool isError;
  final bool isThinking;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final accent = colorScheme.lightButtons ?? colorScheme.secondary;
    final background = isError
        ? colorScheme.errorColor.withValues(alpha: 0.12)
        : fromUser
        ? accent
        : colorScheme.messageBgColor;
    final foreground = isError
        ? colorScheme.errorColor
        : fromUser
        ? Colors.white
        : colorScheme.textColor;
    final textStyle = Theme.of(
      context,
    ).textTheme.bodyMedium?.copyWith(color: foreground, height: 1.4);
    const radius = Radius.circular(16);
    const tail = Radius.circular(4);

    return Align(
      alignment: fromUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: const BoxConstraints(maxWidth: 420),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.only(
            topLeft: radius,
            topRight: radius,
            bottomLeft: fromUser ? radius : tail,
            bottomRight: fromUser ? tail : radius,
          ),
          border: isError
              ? Border.all(color: colorScheme.errorColor.withValues(alpha: 0.4))
              : fromUser
              ? null
              : Border.all(
                  color: colorScheme.borderColor ?? Colors.transparent,
                ),
        ),
        child: isThinking
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: colorScheme.primaryColor,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    text,
                    style: textStyle?.copyWith(
                      color: colorScheme.descriptionColor,
                    ),
                  ),
                ],
              )
            : TextSelectionTheme(
                data: TextSelectionThemeData(
                  selectionColor: fromUser
                      ? Colors.white.withValues(alpha: 0.35)
                      : accent.withValues(alpha: 0.3),
                ),
                child: SelectableText(text, style: textStyle),
              ),
      ),
    );
  }
}
