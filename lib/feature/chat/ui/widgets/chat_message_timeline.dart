import 'package:flutter/material.dart';
import 'package:note_sondage/feature/chat/domain/entities/chat_message_entity.dart';
import 'package:note_sondage/feature/chat/ui/widgets/chat_message_bubble.dart';
import 'package:note_sondage/languages/l10n/app_localizations.dart';
import 'package:note_sondage/theme/extensions/color_scheme/color_scheme.dart';

class ChatMessageTimeline extends StatelessWidget {
  const ChatMessageTimeline({
    super.key,
    required this.messages,
    required this.scrollController,
    required this.compact,
    required this.accentColor,
    required this.loadingOlderMessages,
    required this.hasMoreOlderMessages,
    this.selectedTeamName,
    this.onSenderPressed,
    this.onMessagePressed,
    this.onMessageLongPressed,
    this.onReplyRequested,
    this.onDeleteRequested,
  });

  final List<ChatMessageEntity> messages;
  final ScrollController scrollController;
  final bool compact;
  final Color accentColor;
  final bool loadingOlderMessages;
  final bool hasMoreOlderMessages;
  final String? selectedTeamName;
  final ValueChanged<ChatMessageEntity>? onSenderPressed;
  final ValueChanged<ChatMessageEntity>? onMessagePressed;
  final ValueChanged<ChatMessageEntity>? onMessageLongPressed;
  final ValueChanged<ChatMessageEntity>? onReplyRequested;
  final ValueChanged<ChatMessageEntity>? onDeleteRequested;

  @override
  Widget build(BuildContext context) {
    return ListView(
      controller: scrollController,
      padding: EdgeInsets.fromLTRB(
        compact ? 10 : 18,
        compact ? 10 : 14,
        compact ? 10 : 18,
        compact ? 2 : 6,
      ),
      children: _buildTimelineChildren(context),
    );
  }

  List<Widget> _buildTimelineChildren(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final widgets = <Widget>[
      if (loadingOlderMessages) ...[
        const _OlderMessagesLoadingIndicator(),
        const SizedBox(height: 10),
      ] else if (!hasMoreOlderMessages && messages.isNotEmpty) ...[
        ChatSystemTimelineText(text: loc.chatTimelineBeginning),
        const SizedBox(height: 8),
      ],
      ChatSystemTimelineText(
        text: loc.chatTimelineActive(
          (selectedTeamName?.trim().isNotEmpty ?? false)
              ? selectedTeamName!.trim()
              : loc.team,
        ),
      ),
      const SizedBox(height: 8),
    ];

    if (messages.isEmpty) {
      widgets.add(const ChatEmptyState());
      return widgets;
    }

    DateTime? previousTimestamp;
    for (final message in messages) {
      if (previousTimestamp != null) {
        final gap = message.createdAt.difference(previousTimestamp).inMinutes;
        if (gap >= 30) {
          widgets.add(
            ChatSystemTimelineText(
              text: loc.chatTimelineResumed(_formatGapLabel(gap, loc)),
            ),
          );
          widgets.add(const SizedBox(height: 12));
        } else {
          widgets.add(const SizedBox(height: 8));
        }
      }

      widgets.add(
        _SwipeMessageWrapper(
          key: ValueKey(message.id),
          message: message,
          onReplyRequested: onReplyRequested,
          onDeleteRequested: onDeleteRequested,
          child: ChatMessageBubble(
            message: message,
            accentColor: accentColor,
            onPressed: onMessagePressed == null
                ? null
                : () => onMessagePressed!(message),
            onLongPressed:
                onMessageLongPressed == null || !message.hasAttachment
                ? null
                : () => onMessageLongPressed!(message),
            onSenderPressed: onSenderPressed == null
                ? null
                : () => onSenderPressed!(message),
          ),
        ),
      );
      previousTimestamp = message.createdAt;
    }

    return widgets;
  }

  String _formatGapLabel(int minutes, AppLocalizations loc) {
    if (minutes < 60) {
      return loc.chatDurationMinutesShort(minutes);
    }
    final hours = minutes ~/ 60;
    if (hours < 24) {
      return loc.chatDurationHoursShort(hours);
    }
    final days = hours ~/ 24;
    return loc.chatDurationDaysShort(days);
  }
}

class _SwipeMessageWrapper extends StatelessWidget {
  const _SwipeMessageWrapper({
    super.key,
    required this.message,
    required this.child,
    this.onReplyRequested,
    this.onDeleteRequested,
  });

  final ChatMessageEntity message;
  final Widget child;
  final ValueChanged<ChatMessageEntity>? onReplyRequested;
  final ValueChanged<ChatMessageEntity>? onDeleteRequested;

  @override
  Widget build(BuildContext context) {
    final canDelete = message.mine && !message.deleted;
    final canReply = !message.deleted;

    if (!canDelete && !canReply) {
      return child;
    }

    return Dismissible(
      key: key ?? ValueKey('dismiss-${message.id}'),
      direction: canDelete
          ? DismissDirection.horizontal
          : DismissDirection.startToEnd,
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd && canReply) {
          onReplyRequested?.call(message);
          return false;
        }
        if (direction == DismissDirection.endToStart && canDelete) {
          onDeleteRequested?.call(message);
          return false;
        }
        return false;
      },
      background: _SwipeActionBackground(
        alignment: Alignment.centerLeft,
        icon: Icons.reply_rounded,
        label: AppLocalizations.of(context)!.chatReplyAction,
      ),
      secondaryBackground: canDelete
          ? _SwipeActionBackground(
              alignment: Alignment.centerRight,
              icon: Icons.delete_outline_rounded,
              label: AppLocalizations.of(context)!.deleteAction,
            )
          : null,
      child: child,
    );
  }
}

class _SwipeActionBackground extends StatelessWidget {
  const _SwipeActionBackground({
    required this.alignment,
    required this.icon,
    required this.label,
  });

  final Alignment alignment;
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final isLeft = alignment == Alignment.centerLeft;
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      alignment: alignment,
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: EdgeInsets.symmetric(horizontal: isLeft ? 16 : 20),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!isLeft) Text(label),
          if (!isLeft) const SizedBox(width: 8),
          Icon(icon, size: 18),
          if (isLeft) const SizedBox(width: 8),
          if (isLeft) Text(label),
        ],
      ),
    );
  }
}

class _OlderMessagesLoadingIndicator extends StatelessWidget {
  const _OlderMessagesLoadingIndicator();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 10),
          Text(
            AppLocalizations.of(context)!.chatLoadingOlderMessages,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class ChatSystemTimelineText extends StatelessWidget {
  const ChatSystemTimelineText({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
          ),
        ),
      ),
    );
  }
}

class ChatEmptyState extends StatelessWidget {
  const ChatEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 32),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colorScheme.bgColorNew!.withValues(alpha: 0.82),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: colorScheme.borderColor!),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Icon(
                Icons.chat_bubble_outline_rounded,
                size: 34,
                color: Color(0xFF7C8C84),
              ),
              const SizedBox(height: 12),
              Text(
                AppLocalizations.of(context)!.chatNoMessagesYet,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                AppLocalizations.of(context)!.chatEmptyDescription,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
