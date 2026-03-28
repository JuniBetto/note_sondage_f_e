import 'package:flutter/material.dart';
import 'package:note_sondage/domain/entities/all_enum.dart';
import 'package:note_sondage/domain/entities/setting_type.dart';
import 'package:note_sondage/languages/l10n/app_localizations.dart';
import 'package:note_sondage/ui/mobile/widgets/settings/widgets/element_setting.dart';

class SettingsMobile extends StatelessWidget {
  const SettingsMobile({super.key});

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalizations.of(context)!;

    final settings = [
      SettingType(
        title: SettingCategory.theme,
        subtitle: localization.system,
        category: localization.preferences,
      ),
      SettingType(
        title: SettingCategory.language,
        subtitle: 'English',
        category: localization.preferences,
      ),
      SettingType(
        title: SettingCategory.notifications,
        subtitle: localization.none,
        category: localization.preferences,
      ),
      SettingType(
        title: SettingCategory.privacy,
        subtitle: localization.manageYourPrivacySettings,
        category: localization.privacy,
      ),
      SettingType(
        title: SettingCategory.contactus,
        subtitle: localization.getInTouchWithOurSupportTeam,
        category: localization.privacy,
      ),
    ];

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: SingleChildScrollView(child: ElementSetting(settings: settings)),
      ),
    );
  }
}
