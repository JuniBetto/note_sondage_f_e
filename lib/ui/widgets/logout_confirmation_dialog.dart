import 'package:flutter/material.dart';
import 'package:note_sondage/languages/l10n/app_localizations.dart';
import 'package:note_sondage/theme/extensions/color_scheme/color_scheme.dart';

Future<bool> showLogoutConfirmationDialog(BuildContext context) async {
  final localization = AppLocalizations.of(context)!;
 
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      final colorScheme = Theme.of(dialogContext).colorScheme;
      return AlertDialog(
        title: Text(localization.logout),
        content: Text(localization.logoutConfirmation),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(localization.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: colorScheme.deleteCard,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(localization.confirm),
          ),
        ],
      );
    },
  );

  return confirmed ?? false;
}
