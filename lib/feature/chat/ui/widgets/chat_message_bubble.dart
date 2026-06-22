import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:note_sondage/core/network/setup_dio.dart';
import 'package:note_sondage/feature/chat/domain/entities/chat_message_entity.dart';
import 'package:note_sondage/feature/chat/domain/entities/chat_message_reaction_entity.dart';
import 'package:note_sondage/feature/chat/domain/entities/chat_message_reply_entity.dart';
import 'package:note_sondage/languages/l10n/app_localizations.dart';
import 'package:note_sondage/ui/widgets/aspect_ratio.dart' as app_ratio;
import 'package:url_launcher/url_launcher.dart';

class ChatMessageBubble extends StatelessWidget {
  const ChatMessageBubble({
    super.key,
    required this.message,
    required this.accentColor,
    this.onPressed,
    this.onLongPressed,
    this.onSenderPressed,
  });

  final ChatMessageEntity message;
  final Color accentColor;
  final VoidCallback? onPressed;
  final VoidCallback? onLongPressed;
  final VoidCallback? onSenderPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context)!;
    final rowAlignment = message.mine
        ? MainAxisAlignment.end
        : MainAxisAlignment.start;
    final bubbleAlignment = message.mine
        ? CrossAxisAlignment.end
        : CrossAxisAlignment.start;
    final bubbleColor = message.mine
        ? accentColor.withValues(alpha: 0.96)
        : accentColor.withValues(alpha: 0.14);
    final textColor = message.mine
        ? Colors.white
        : _incomingTextColor(accentColor);
    final metaColor = theme.colorScheme.onSurfaceVariant;
    final maxBubbleWidth = MediaQuery.sizeOf(context).width * 0.68;
    final nameUser = message.senderName.split('@')[0];
    final borderRadius = BorderRadius.only(
      topLeft: const Radius.circular(18),
      topRight: const Radius.circular(18),
      bottomLeft: Radius.circular(message.mine ? 18 : 6),
      bottomRight: Radius.circular(message.mine ? 6 : 18),
    );

    return Column(
      crossAxisAlignment: bubbleAlignment,
      children: [
        _MessageHeaderRow(
          senderName: nameUser,
          timestamp: message.createdAt,
          localeName: loc.localeName,
          mine: message.mine,
          isPending: message.isPendingLocal,
          isDelivered: message.isDeliveredToOthers,
          isSeen: message.isReadByOthers,
          accentColor: accentColor,
          metaColor: metaColor,
          onSenderPressed: onSenderPressed,
        ),
        const SizedBox(height: 3),
        Row(
          mainAxisAlignment: rowAlignment,
          children: [
            Flexible(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: maxBubbleWidth.clamp(220, 540),
                ),
                child: Column(
                  crossAxisAlignment: bubbleAlignment,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: onPressed,
                        onLongPress: onLongPressed,
                        borderRadius: borderRadius,
                        child: Ink(
                          decoration: BoxDecoration(
                            color: bubbleColor,
                            borderRadius: borderRadius,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 13,
                              vertical: 9,
                            ),
                            child: _MessageBody(
                              message: message,
                              accentColor: accentColor,
                              textColor: textColor,
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (message.reactions.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      _ReactionRow(
                        reactions: message.reactions,
                        accentColor: accentColor,
                        alignEnd: message.mine,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Color _incomingTextColor(Color accentColor) {
    final brightness = ThemeData.estimateBrightnessForColor(accentColor);
    if (brightness == Brightness.dark) {
      return accentColor.withValues(alpha: 0.96);
    }
    return Colors.black.withValues(alpha: 0.8);
  }
}

class _MessageHeaderRow extends StatelessWidget {
  const _MessageHeaderRow({
    required this.senderName,
    required this.timestamp,
    required this.localeName,
    required this.mine,
    required this.isPending,
    required this.isDelivered,
    required this.metaColor,
    required this.isSeen,
    required this.accentColor,
    this.onSenderPressed,
  });

  final String senderName;
  final DateTime timestamp;
  final String localeName;
  final bool mine;
  final bool isPending;
  final bool isDelivered;
  final Color metaColor;
  final bool isSeen;
  final Color accentColor;
  final VoidCallback? onSenderPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context)!;
    final nameStyle = theme.textTheme.titleSmall?.copyWith(
      color: theme.colorScheme.onSurface,
      fontWeight: FontWeight.w800,
    );
    final metaStyle = theme.textTheme.bodySmall?.copyWith(
      color: metaColor,
      fontWeight: FontWeight.w500,
    );

    return Row(
      mainAxisAlignment: mine ? MainAxisAlignment.end : MainAxisAlignment.start,
      children: [
        Flexible(
          child: Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 10,
            runSpacing: 2,
            alignment: mine ? WrapAlignment.end : WrapAlignment.start,
            children: [
              if (onSenderPressed == null)
                Text(senderName, style: nameStyle)
              else
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: onSenderPressed,
                    child: Text(
                      senderName,
                      style: nameStyle?.copyWith(
                        decoration: TextDecoration.underline,
                        decorationColor: metaColor.withValues(alpha: 0.36),
                      ),
                    ),
                  ),
                ),
              Text(
                ChatRelativeTimeFormatter.formatHeader(timestamp, localeName),
                style: metaStyle,
              ),
              if (mine)
                _ReadStateIndicator(
                  isPending: isPending,
                  isDelivered: isDelivered,
                  isSeen: isSeen,
                  accentColor: accentColor,
                  metaColor: metaColor,
                  seenLabel: loc.chatSeen,
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ReadStateIndicator extends StatelessWidget {
  const _ReadStateIndicator({
    required this.isPending,
    required this.isDelivered,
    required this.isSeen,
    required this.accentColor,
    required this.metaColor,
    required this.seenLabel,
  });

  final bool isPending;
  final bool isDelivered;
  final bool isSeen;
  final Color accentColor;
  final Color metaColor;
  final String seenLabel;

  @override
  Widget build(BuildContext context) {
    if (isPending) {
      return Icon(
        Icons.schedule_rounded,
        size: 15,
        color: metaColor.withValues(alpha: 0.86),
      );
    }

    final iconColor = isSeen
        ? accentColor.withValues(alpha: 0.92)
        : metaColor.withValues(alpha: isDelivered ? 0.92 : 0.78);
    final icon = (isSeen || isDelivered)
        ? Icons.done_all_rounded
        : Icons.done_rounded;
    final iconWidget = Icon(icon, size: 15, color: iconColor);

    if (!isSeen) {
      return iconWidget;
    }

    return Tooltip(message: seenLabel, child: iconWidget);
  }
}

class _MessageBody extends StatelessWidget {
  const _MessageBody({
    required this.message,
    required this.accentColor,
    required this.textColor,
  });

  final ChatMessageEntity message;
  final Color accentColor;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context)!;
    final children = <Widget>[];

    if (message.replyTo != null) {
      children.add(
        _ReplyPreviewStrip(
          replyTo: message.replyTo!,
          accentColor: accentColor,
          mine: message.mine,
          textColor: textColor,
        ),
      );
      children.add(const SizedBox(height: 7));
    }

    if (message.deleted) {
      children.add(
        Text(
          loc.chatDeletedMessage,
          style: theme.textTheme.bodySmall?.copyWith(
            color: textColor.withValues(alpha: 0.82),
            fontStyle: FontStyle.italic,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: children,
      );
    }

    if (message.isImageAttachment) {
      children.add(_ImageAttachmentPreview(message: message));
    } else if (message.isFileAttachment) {
      children.add(
        _FileAttachmentPreview(message: message, textColor: textColor),
      );
    }

    if (message.hasAttachment && message.hasTextContent) {
      children.add(const SizedBox(height: 7));
    }

    if (message.hasTextContent) {
      children.add(
        Text(
          message.contentText,
          style: theme.textTheme.bodySmall?.copyWith(
            color: textColor,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    if (children.isEmpty) {
      children.add(
        Text(
          message.attachmentOriginalName ?? loc.chatAttachmentFallback,
          style: theme.textTheme.bodySmall?.copyWith(
            color: textColor,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: children,
    );
  }
}

class _ReplyPreviewStrip extends StatelessWidget {
  const _ReplyPreviewStrip({
    required this.replyTo,
    required this.accentColor,
    required this.mine,
    required this.textColor,
  });

  final ChatMessageReplyEntity replyTo;
  final Color accentColor;
  final bool mine;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context)!;
    final surface = mine
        ? Colors.white.withValues(alpha: 0.18)
        : Colors.white.withValues(alpha: 0.72);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(12),
        border: Border(
          left: BorderSide(color: mine ? Colors.white : accentColor, width: 3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            replyTo.senderName,
            style: theme.textTheme.labelMedium?.copyWith(
              color: textColor,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            replyTo.deleted ? loc.chatDeletedMessage : replyTo.contentPreview,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: textColor.withValues(alpha: 0.86),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReactionRow extends StatelessWidget {
  const _ReactionRow({
    required this.reactions,
    required this.accentColor,
    required this.alignEnd,
  });

  final List<ChatMessageReactionEntity> reactions;
  final Color accentColor;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Wrap(
      alignment: alignEnd ? WrapAlignment.end : WrapAlignment.start,
      spacing: 6,
      runSpacing: 4,
      children: reactions
          .map(
            (reaction) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: accentColor.withValues(
                    alpha: reaction.mine ? 0.45 : 0.18,
                  ),
                ),
              ),
              child: Text(
                '${reaction.emoji} ${reaction.count}',
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _ImageAttachmentPreview extends StatelessWidget {
  const _ImageAttachmentPreview({required this.message});

  final ChatMessageEntity message;

  @override
  Widget build(BuildContext context) {
    final path = message.attachmentPath;
    if (path == null || path.isEmpty) {
      return const SizedBox.shrink();
    }

    final imageUrl = DioClient.resolveImageUrl(path);
    final requiresAuth = DioClient.usesAuthenticatedImageProxy(path);
    final authHeadersFuture = requiresAuth
        ? DioClient.resolveImageHeaders(path)
        : Future<Map<String, String>?>.value(null);

    return SizedBox(
      width: 220,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          app_ratio.AspectRatio(
            aspectRatio: 11 / 7.5,
            borderRadius: BorderRadius.circular(14),
            child: FutureBuilder<Map<String, String>?>(
              future: authHeadersFuture,
              builder: (context, snapshot) {
                if (requiresAuth &&
                    snapshot.connectionState != ConnectionState.done) {
                  return Container(
                    color: Colors.white.withValues(alpha: 0.16),
                    alignment: Alignment.center,
                    child: const CircularProgressIndicator(strokeWidth: 2),
                  );
                }

                if (requiresAuth &&
                    (snapshot.data == null || snapshot.data!.isEmpty)) {
                  return Container(
                    color: Colors.white.withValues(alpha: 0.2),
                    alignment: Alignment.center,
                    child: const Icon(Icons.broken_image_outlined),
                  );
                }

                return Image.network(
                  imageUrl,
                  headers: snapshot.data,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.white.withValues(alpha: 0.2),
                      alignment: Alignment.center,
                      child: const Icon(Icons.broken_image_outlined),
                    );
                  },
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) {
                      return child;
                    }
                    return Container(
                      color: Colors.white.withValues(alpha: 0.16),
                      alignment: Alignment.center,
                      child: const CircularProgressIndicator(strokeWidth: 2),
                    );
                  },
                );
              },
            ),
          ),
          if (message.attachmentOriginalName?.trim().isNotEmpty == true) ...[
            const SizedBox(height: 8),
            Text(
              message.attachmentOriginalName!.trim(),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(
                  context,
                ).textTheme.bodyMedium?.color?.withValues(alpha: 0.92),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _FileAttachmentPreview extends StatelessWidget {
  const _FileAttachmentPreview({
    required this.message,
    required this.textColor,
  });

  final ChatMessageEntity message;
  final Color textColor;

  Future<void> _openAttachment() async {
    final path = message.attachmentPath;
    if (path == null || path.isEmpty) {
      return;
    }
    final response = await DioClient().dio.get(
      '/api/storage/file/url',
      queryParameters: {'path': path},
    );
    final url = (response.data as Map<String, dynamic>)['url']?.toString();
    if (url == null || url.isEmpty) {
      return;
    }
    final uri = Uri.parse(url);
    await launchUrl(uri, mode: LaunchMode.platformDefault);
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        await _openAttachment();
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.22),
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.insert_drive_file_outlined, size: 18, color: textColor),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                message.attachmentOriginalName ??
                    AppLocalizations.of(context)!.chatOpenDocument,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: textColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ChatRelativeTimeFormatter {
  const ChatRelativeTimeFormatter._();

  static String formatHeader(DateTime value, String localeName) {
    return DateFormat('EEE HH:mm', localeName).format(value.toLocal());
  }

  static String format(DateTime value, AppLocalizations loc) {
    final now = DateTime.now();
    final difference = now.difference(value.toLocal());

    if (difference.inSeconds < 45) {
      return loc.chatJustNow;
    }
    if (difference.inMinutes < 60) {
      return loc.chatMinutesAgo(difference.inMinutes);
    }
    if (difference.inHours < 24) {
      return loc.chatHoursAgo(difference.inHours);
    }
    if (difference.inDays == 1) {
      return loc.chatYesterday;
    }
    if (difference.inDays < 7) {
      return loc.chatDaysAgo(difference.inDays);
    }
    return DateFormat('dd/MM HH:mm', loc.localeName).format(value.toLocal());
  }
}
