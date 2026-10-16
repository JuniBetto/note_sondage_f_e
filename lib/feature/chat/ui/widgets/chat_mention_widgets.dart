import 'package:flutter/material.dart';
import 'package:note_sondage/feature/chat/domain/chat_mentions.dart';
import 'package:note_sondage/languages/l10n/app_localizations.dart';

/// Rende disponibili ai widget della chat (composer, bolle) i membri
/// menzionabili della conversazione corrente. Assente o [enabled] = false
/// nelle chat dirette: niente autocomplete né evidenziazione.
class ChatMentionScope extends InheritedWidget {
  const ChatMentionScope({
    super.key,
    required this.enabled,
    required this.candidates,
    required this.currentUserId,
    required super.child,
  });

  final bool enabled;

  /// Tutti i membri attivi del team (utente corrente incluso).
  final List<ChatMentionCandidate> candidates;
  final String currentUserId;

  /// Membri suggeribili nell'autocomplete (escluso l'utente corrente).
  List<ChatMentionCandidate> get suggestable =>
      candidates.where((c) => c.userId != currentUserId).toList();

  static ChatMentionScope? maybeOf(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<ChatMentionScope>();
    return scope != null && scope.enabled ? scope : null;
  }

  @override
  bool updateShouldNotify(ChatMentionScope oldWidget) =>
      enabled != oldWidget.enabled ||
      currentUserId != oldWidget.currentUserId ||
      !_sameCandidates(candidates, oldWidget.candidates);

  static bool _sameCandidates(
    List<ChatMentionCandidate> a,
    List<ChatMentionCandidate> b,
  ) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i].userId != b[i].userId || a[i].displayName != b[i].displayName) {
        return false;
      }
    }
    return true;
  }
}

/// Testo di un messaggio con le menzioni evidenziate. Le menzioni rivolte
/// all'utente corrente ("@me" o "@tutti") hanno un risalto più forte.
class ChatMentionText extends StatelessWidget {
  const ChatMentionText(this.text, {super.key, this.style, this.mine = false});

  final String text;
  final TextStyle? style;

  /// Messaggio inviato dall'utente corrente.
  final bool mine;

  @override
  Widget build(BuildContext context) {
    final scope = ChatMentionScope.maybeOf(context);
    final spans = scope == null
        ? const <ChatMentionSpan>[]
        : findChatMentionSpans(text, scope.candidates);
    if (spans.isEmpty) {
      return Text(text, style: style);
    }

    final children = <InlineSpan>[];
    var cursor = 0;
    for (final span in spans) {
      if (span.start > cursor) {
        children.add(TextSpan(text: text.substring(cursor, span.start)));
      }
      final targetsMe = !mine && span.mentions(scope!.currentUserId);
      children.add(
        TextSpan(
          text: text.substring(span.start, span.end),
          style: TextStyle(
            fontWeight: FontWeight.w800,
            backgroundColor: targetsMe
                ? const Color(0xFFFFC107).withValues(alpha: 0.55)
                : Colors.white.withValues(alpha: 0.22),
          ),
        ),
      );
      cursor = span.end;
    }
    if (cursor < text.length) {
      children.add(TextSpan(text: text.substring(cursor)));
    }
    return Text.rich(TextSpan(style: style, children: children));
  }
}

/// Elenco dei suggerimenti "@" sopra il composer.
class ChatMentionSuggestions extends StatelessWidget {
  const ChatMentionSuggestions({
    super.key,
    required this.candidates,
    required this.showAll,
    required this.accentColor,
    required this.onSelected,
    required this.onAllSelected,
  });

  final List<ChatMentionCandidate> candidates;
  final bool showAll;
  final Color accentColor;
  final ValueChanged<ChatMentionCandidate> onSelected;
  final VoidCallback onAllSelected;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final tiles = <Widget>[
      if (showAll)
        _SuggestionTile(
          key: const Key('chat_mention_all'),
          leading: CircleAvatar(
            radius: 16,
            backgroundColor: accentColor.withValues(alpha: 0.16),
            child: Icon(Icons.groups_rounded, size: 18, color: accentColor),
          ),
          title: '@${loc.chatMentionAllKeyword}',
          subtitle: loc.chatMentionAllDescription,
          onTap: onAllSelected,
        ),
      for (final candidate in candidates)
        _SuggestionTile(
          key: Key('chat_mention_${candidate.userId}'),
          leading: _MentionAvatar(candidate: candidate, color: accentColor),
          title: candidate.displayName,
          subtitle: candidate.secondaryLabel,
          onTap: () => onSelected(candidate),
        ),
    ];

    return Material(
      color: Colors.white,
      elevation: 3,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 232),
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 6),
          shrinkWrap: true,
          children: tiles,
        ),
      ),
    );
  }
}

class _SuggestionTile extends StatelessWidget {
  const _SuggestionTile({
    super.key,
    required this.leading,
    required this.title,
    required this.onTap,
    this.subtitle,
  });

  final Widget leading;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subtitleText = subtitle?.trim();
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: Row(
          children: [
            leading,
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.black87,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (subtitleText != null &&
                      subtitleText.isNotEmpty &&
                      subtitleText != title)
                    Text(
                      subtitleText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.black54,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MentionAvatar extends StatelessWidget {
  const _MentionAvatar({required this.candidate, required this.color});

  final ChatMentionCandidate candidate;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final url = candidate.avatarUrl?.trim();
    if (url != null && url.isNotEmpty) {
      return CircleAvatar(
        radius: 16,
        backgroundColor: color.withValues(alpha: 0.16),
        backgroundImage: NetworkImage(url),
      );
    }
    final name = candidate.displayName.trim();
    return CircleAvatar(
      radius: 16,
      backgroundColor: color.withValues(alpha: 0.16),
      child: Text(
        name.isEmpty ? '?' : name.substring(0, 1).toUpperCase(),
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: color,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
