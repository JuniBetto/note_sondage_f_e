import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:note_sondage/domain/entities/all_enum.dart';
import 'package:note_sondage/domain/entities/setting_type.dart';
import 'package:note_sondage/languages/l10n/app_localizations.dart';
import 'package:note_sondage/theme/extensions/color_scheme/color_scheme.dart';
import 'package:note_sondage/ui/widgets/theme_config/bloc/theme/theme_bloc.dart';
import 'package:note_sondage/ui/widgets/theme_config/bloc/theme/theme_state.dart';
import 'package:note_sondage/ui/widgets/language_config/bloc/language_bloc.dart';

class ElementInsideSetting extends StatelessWidget {
  const ElementInsideSetting({
    super.key,
    required this.setting,
    required this.contentModal,
  });
  final SettingType setting;
  final Widget contentModal;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;
    final localization = AppLocalizations.of(context)!;

    // Get dynamic subtitle based on setting type
    String getSubtitle() {
      if (setting.title == SettingCategory.theme) {
        final themeState = context.watch<ThemeBloc>().state;
        if (themeState is ThemeisDark) {
          return localization.dark;
        } else if (themeState is ThemeisLight) {
          return localization.light;
        } else {
          return localization.system;
        }
      } else if (setting.title == SettingCategory.language) {
        final languageState = context.watch<LanguageBloc>().state;
        final languageCode = languageState.locale.languageCode;
        switch (languageCode) {
          case 'en':
            return 'English';
          case 'it':
            return 'Italiano';
          case 'es':
            return 'Español';
          case 'fr':
            return 'Français';
          default:
            return 'English';
        }
      }
      return setting.subtitle;
    }

    _showModalBottomPermissionEdit(BuildContext context) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        //backgroundColor: Colors.green,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        elevation: 4,
        builder: (BuildContext context) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.viewInsetsOf(context).bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Drag handle indicator
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(top: 12, bottom: 8),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[400],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Flexible(child: contentModal),
              ],
            ),
          );
        },
      );
    }

    return GestureDetector(
      onTap: () => _showModalBottomPermissionEdit(context),
      child: Padding(
        padding: const EdgeInsets.only(left: 4.0),
        child: SizedBox(
          width: double.infinity,
          child: Card(
            color: colorScheme.homeSecondary!, //Colors.transparent,
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    setting.title.name.toLowerCase(),
                    style: textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(getSubtitle(), style: textTheme.bodyMedium),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
