import 'package:flutter/material.dart';
import 'package:note_sondage/core/config/public_legal_links.dart';
import 'package:note_sondage/languages/l10n/app_localizations.dart';

class PublicLegalLinksPanel extends StatelessWidget {
  const PublicLegalLinksPanel({
    super.key,
    this.centered = false,
    this.showDescription = true,
  });

  final bool centered;
  final bool showDescription;

  Future<void> _openDocument(
    BuildContext context,
    PublicLegalDocument document,
  ) async {
    await PublicLegalLinks.open(Localizations.localeOf(context), document);
  }

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final crossAxisAlignment = centered
        ? CrossAxisAlignment.center
        : CrossAxisAlignment.start;
    final textAlign = centered ? TextAlign.center : TextAlign.start;

    return Column(
      crossAxisAlignment: crossAxisAlignment,
      children: [
        Text(
          localization.reviewPublicLegalPages,
          textAlign: textAlign,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        if (showDescription) ...[
          const SizedBox(height: 8),
          Text(
            localization.reviewPublicLegalPagesDescription,
            textAlign: textAlign,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
              height: 1.5,
            ),
          ),
        ],
        const SizedBox(height: 14),
        Wrap(
          alignment: centered ? WrapAlignment.center : WrapAlignment.start,
          spacing: 12,
          runSpacing: 12,
          children: [
            OutlinedButton.icon(
              onPressed: () =>
                  _openDocument(context, PublicLegalDocument.privacy),
              icon: const Icon(Icons.privacy_tip_outlined),
              label: Text(localization.privacyPolicy),
            ),
            OutlinedButton.icon(
              onPressed: () =>
                  _openDocument(context, PublicLegalDocument.terms),
              icon: const Icon(Icons.gavel_rounded),
              label: Text(localization.termsOfService),
            ),
          ],
        ),
      ],
    );
  }
}
