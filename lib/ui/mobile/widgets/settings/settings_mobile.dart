import 'package:flutter/material.dart';
import 'package:note_sondage/domain/entities/all_enum.dart';
import 'package:note_sondage/domain/entities/setting_type.dart';
import 'package:note_sondage/ui/mobile/widgets/settings/widgets/element_setting.dart';

class SettingsMobile extends StatelessWidget {
  const SettingsMobile({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: SingleChildScrollView(child: ElementSetting(settings: settings)),
      ),
    );
  }
}

List<SettingType> settings = [
  SettingType(
    title: SettingCategory.theme,
    subtitle: 'System',
    category: 'Preferences',
  ),
  SettingType(
    title: SettingCategory.language,
    subtitle: 'English',
    category: 'Preferences',
  ),
  SettingType(
    title: SettingCategory.notifications,
    subtitle: 'None',
    category: 'Preferences',
  ),

  SettingType(
    title: SettingCategory.privacy,
    subtitle: 'Manage your privacy settings',
    category: 'Privacy',
  ),
  SettingType(
    title: SettingCategory.contactus,
    subtitle: 'Get in touch with our support team',
    category: 'Privacy',
  ),
];
