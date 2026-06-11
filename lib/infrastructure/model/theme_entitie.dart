import 'package:hive/hive.dart';

part 'theme_entitie.g.dart';

enum ThemeModeType { light, dark, system }

@HiveType(typeId: 0)
class ThemeEntitie {
  @HiveField(0)
  final ThemeModeType themeName;

  factory ThemeEntitie.themeDefault() {
    return ThemeEntitie(themeName: ThemeModeType.system);
  }

  ThemeEntitie copyWith({ThemeModeType? themeName}) {
    return ThemeEntitie(themeName: themeName ?? this.themeName);
  }

  ThemeEntitie({required this.themeName});
}
