import 'package:flutter/material.dart';
import 'package:note_sondage/domain/entities/setting_type.dart';
import 'package:note_sondage/ui/mobile/widgets/settings/widgets/change_language.dart';
import 'package:note_sondage/ui/mobile/widgets/settings/widgets/element_inside_setting.dart';

class ElementSetting extends StatelessWidget {
  const ElementSetting({super.key, required this.settings});

  final List<SettingType> settings;

  @override
  Widget build(BuildContext context) {
    final List<List<SettingType>> settingsByCategory = [];

    final settingsType = settings
        .map((setting) => setting.category)
        .toSet()
        .toList();

    settingsType.forEach((setting) {
      settingsByCategory.add(
        settings.where((s) => s.category == setting).toList(),
      );
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: settingsByCategory
          .map(
            (setting) => Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    setting.first.category.toUpperCase(),
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: setting.asMap().entries.expand((entry) {
                          final isLast = entry.key == setting.length - 1;
                          return [
                            ElementInsideSetting(
                              setting: entry.value,
                              contentModal: entry.value.title == "Language"
                                  ? ChangeLanguage()
                                  : SizedBox(height: 40),
                            ),
                            if (!isLast) const Divider(height: 16),
                          ];
                        }).toList(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}



// Widget element(BuildContext context, SettingType setting, Function()? onTap) {
//   final theme = Theme.of(context);
//   final colorScheme = theme.colorScheme;
//   final textTheme = theme.textTheme;



//   return GestureDetector(
//     onTap: onTap,
//     child: Padding(
//       padding: const EdgeInsets.only(left: 4.0),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(setting.title, style: textTheme.bodyLarge),
//           const SizedBox(height: 8),
//           Text(setting.subtitle, style: textTheme.bodyMedium),
//         ],
//       ),
//     ),
//   );
// }
