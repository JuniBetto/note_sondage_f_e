import 'package:flutter/material.dart';
import 'package:note_sondage/languages/l10n/app_localizations.dart';
import 'package:note_sondage/theme/extensions/theme_extensions.dart';
import 'package:note_sondage/ui/widgets/custom_app_button.dart';

Future<bool> showAppConfirmationDialog(
  BuildContext context, {
  required String title,
  String? message,
  String? confirmLabel,
  String? cancelLabel,
  bool destructive = false,
}) async {
  final localization = AppLocalizations.of(context)!;
  final theme = context.theme;
  final colorScheme = theme.colorScheme;
  final textTheme = theme.textTheme;
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(title,style: textTheme.titleLarge!.copyWith(color: colorScheme.textColor),),
      content: message == null ? null : Text(message,style: textTheme.titleMedium!.copyWith(color: colorScheme.textColor)),
      actions: [
        CustomAppButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          backgroundColor: colorScheme.bgNavbarbutton,
          type: ButtonType.text,
          isActive: false,
          child: Text(cancelLabel ?? localization.cancel,style: textTheme.bodySmall!.copyWith(color: colorScheme.textInvertedColor),),
        ),
        CustomAppButton(
          onPressed: () => Navigator.pop(dialogContext, true),
          type: ButtonType.filled,
          backgroundColor: destructive
              ? colorScheme.deleteCard
              : null,
          isActive: true,
          child: Text(confirmLabel ?? localization.confirm,style: textTheme.bodySmall!.copyWith(color: colorScheme.textInvertedColor)),
        ),
      ],
    ),
  );

  return confirmed == true;
}
