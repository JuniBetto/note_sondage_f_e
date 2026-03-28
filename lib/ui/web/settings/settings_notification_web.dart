import 'package:flutter/material.dart';
import 'package:note_sondage/languages/l10n/app_localizations.dart';

class SettingsNotificationWeb extends StatelessWidget {
  const SettingsNotificationWeb({super.key});

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalizations.of(context)!;
    return Center(child: Text(localization.settingsNotification));
  }
}
