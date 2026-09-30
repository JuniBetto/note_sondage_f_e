import 'package:flutter/material.dart';
import 'package:note_sondage/languages/l10n/app_localizations.dart';
import 'package:note_sondage/theme/extensions/color_scheme/color_scheme.dart';
import 'package:note_sondage/ui/widgets/auth/request_account_deletion_dialog.dart';
import 'package:note_sondage/ui/widgets/auth/request_account_erasure_dialog.dart';

/// Azioni sull'account (disattivazione ed eliminazione) nel profilo.
/// Prima stavano sotto il pulsante di login; la riattivazione resta invece
/// nel flusso di login, perché un account disattivato non può accedere qui.
class AccountActionsCard extends StatelessWidget {
  const AccountActionsCard({super.key, required this.email});

  /// Email dell'utente, già compilata nei dialog di conferma.
  final String email;

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final errorColor = colorScheme.errorColor;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: errorColor.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            localization.accountActionsTitle,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            localization.accountActionsDescription,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.descriptionColor,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              OutlinedButton(
                key: const ValueKey('profile_deactivate_account_button'),
                onPressed: () => showDialog<bool>(
                  context: context,
                  builder: (_) =>
                      RequestAccountDeletionDialog(initialEmail: email),
                ),
                child: Text(localization.deleteAccount),
              ),
              OutlinedButton(
                key: const ValueKey('profile_delete_account_button'),
                onPressed: () => showDialog<bool>(
                  context: context,
                  builder: (_) =>
                      RequestAccountErasureDialog(initialEmail: email),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: errorColor,
                  side: BorderSide(color: errorColor),
                ),
                child: Text(localization.permanentlyDeleteAccount),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
