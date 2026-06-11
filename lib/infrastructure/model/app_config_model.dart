import 'package:hive/hive.dart';
import 'package:note_sondage/infrastructure/model/theme_entitie.dart';

part 'app_config_model.g.dart';

@HiveType(typeId: 1)
class AppConfigModel {
  @HiveField(0)
  final ThemeEntitie themeEntitie;

  AppConfigModel({required this.themeEntitie});

  AppConfigModel copyWith({ThemeEntitie? themeEntitie}) {
    return AppConfigModel(themeEntitie: themeEntitie ?? this.themeEntitie);
  }
}
