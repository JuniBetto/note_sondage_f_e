import 'package:flutter/material.dart';
import 'package:note_sondage/languages/l10n/app_localizations.dart';
import 'package:note_sondage/theme/extensions/color_scheme/color_scheme.dart';

class ChatDirectActionDialog extends StatelessWidget {
  const ChatDirectActionDialog({
    super.key,
    required this.displayName,
    required this.onOpenDirectPressed,
  });

  final String displayName;
  final VoidCallback onOpenDirectPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme=theme.colorScheme;
    final textTheme= theme.textTheme;
    final loc = AppLocalizations.of(context)!;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 20, 22, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 26,
              child: Text(
                _initialsFromName(displayName),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              displayName,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              loc.chatDirectActionDescription,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: onOpenDirectPressed,
              icon:  Icon(Icons.forum_outlined,
                  color: colorScheme.textInvertedColor),
              label: Text(loc.chatOpenDirectAction,
                style: textTheme.bodyMedium!.copyWith(color: colorScheme.textInvertedColor),),
              style: ElevatedButton.styleFrom(backgroundColor: colorScheme.bgsecondary),
            ),
          ],
        ),
      ),
    );
  }

  String _initialsFromName(String value) {
    final words = value
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2)
        .toList();
    if (words.isEmpty) {
      return '?';
    }
    return words.map((part) => part[0].toUpperCase()).join();
  }
}
