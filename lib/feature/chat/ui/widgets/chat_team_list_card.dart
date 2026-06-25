import 'package:flutter/material.dart';
import 'package:note_sondage/feature/chat/domain/entities/chat_team_conversation_summary_entity.dart';
import 'package:note_sondage/feature/chat/ui/widgets/chat_theme.dart';
import 'package:note_sondage/feature/team/domain/entities/team_entity.dart';
import 'package:note_sondage/languages/l10n/app_localizations.dart';

class ChatTeamListCard extends StatelessWidget {
  const ChatTeamListCard({
    super.key,
    required this.team,
    required this.compact,
    required this.onTap,
    this.summary,
    this.memberCountOverride,
  });

  final TeamEntity team;
  final bool compact;
  final VoidCallback onTap;
  final ChatTeamConversationSummaryEntity? summary;
  final int? memberCountOverride;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context)!;
    final colorScheme = theme.colorScheme;
    final accentColor = ChatThemeTokens.resolveTeamAccentColor(
      team.color,
      colorScheme.primary,
    );
    final unreadCount = summary?.unreadCount ?? 0;
    final memberCount = memberCountOverride ?? team.memberCount;
    final description = (summary?.lastMessagePreview.trim().isNotEmpty ?? false)
        ? summary!.lastMessagePreview.trim()
        : team.description.trim().isEmpty
        ? loc.chatOpenSharedConversation
        : team.description.trim();

    return Material(
      color: Colors.transparent,
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
                    Container(
                      width: compact ? 14 : 16,
                      height: compact ? 14 : 16,
                      decoration: BoxDecoration(
                        color: accentColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        team.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style:
                            (compact
                                    ? theme.textTheme.titleSmall
                                    : theme.textTheme.titleMedium)
                                ?.copyWith(fontWeight: FontWeight.w700,color: Colors.black87),
                      ),
                    ),
                    unreadCount > 0
                        ? Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: accentColor,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              unreadCount > 99 ? '99+' : '$unreadCount',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          )
                        : Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: accentColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              loc.member(memberCount),
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: accentColor,
                                fontWeight: FontWeight.w700,
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
                            color: Colors.black87,
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
                        color: Colors.black87,
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
