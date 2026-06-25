import 'package:flutter/material.dart';
import 'package:note_sondage/languages/l10n/app_localizations.dart';

class ChatDirectListCard extends StatelessWidget {
  const ChatDirectListCard({
    super.key,
    required this.compact,
    required this.title,
    required this.teamName,
    required this.accentColor,
    required this.onTap,
    this.preview,
    this.avatarUrl,
    this.unreadCount = 0,
  });

  final bool compact;
  final String title;
  final String teamName;
  final String? preview;
  final String? avatarUrl;
  final int unreadCount;
  final Color accentColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context)!;
    final colorScheme = theme.colorScheme;
    final description = preview != null && preview!.trim().isNotEmpty
        ? preview!.trim()
        : loc.chatDirectConversationInTeam(teamName);

    return Material(
      color: Colors.transparent,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Ink(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: accentColor.withValues(alpha: 0.22)),
          ),
          child: Padding(
            padding: EdgeInsets.all(compact ? 16 : 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _DirectAvatar(
                      compact: compact,
                      title: title,
                      avatarUrl: avatarUrl,
                      accentColor: accentColor,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style:
                                (compact
                                        ? theme.textTheme.titleSmall
                                        : theme.textTheme.titleMedium)
                                    ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            teamName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: accentColor,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: unreadCount > 0
                            ? accentColor
                            : accentColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        unreadCount > 0
                            ? (unreadCount > 99 ? '99+' : '$unreadCount')
                            : '1:1',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: unreadCount > 0 ? Colors.white : accentColor,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  description,
                  maxLines: compact ? 2 : 3,
                  overflow: TextOverflow.ellipsis,
                  style:
                      (compact
                              ? theme.textTheme.bodySmall
                              : theme.textTheme.bodyMedium)
                          ?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            height: 1.3,
                            fontWeight: unreadCount > 0
                                ? FontWeight.w700
                                : FontWeight.w500,
                          ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Text(
                      loc.chatOpenConversation,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: accentColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      Icons.arrow_forward_rounded,
                      color: accentColor,
                      size: compact ? 20 : 22,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DirectAvatar extends StatelessWidget {
  const _DirectAvatar({
    required this.compact,
    required this.title,
    required this.avatarUrl,
    required this.accentColor,
  });

  final bool compact;
  final String title;
  final String? avatarUrl;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final size = compact ? 42.0 : 46.0;
    final initials = _initialsFromName(title);

    if (avatarUrl != null && avatarUrl!.trim().isNotEmpty) {
      return CircleAvatar(
        radius: size / 2,
        backgroundColor: accentColor.withValues(alpha: 0.16),
        backgroundImage: NetworkImage(avatarUrl!.trim()),
      );
    }

    return CircleAvatar(
      radius: size / 2,
      backgroundColor: accentColor.withValues(alpha: 0.16),
      child: Text(
        initials,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: accentColor,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  String _initialsFromName(String value) {
    final parts = value
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) {
      return 'U';
    }
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }
}
