import 'package:hive_flutter/hive_flutter.dart';
import 'package:note_sondage/core/utils/app_constant.dart';
import 'package:note_sondage/infrastructure/model/app_config_model.dart';
import 'package:note_sondage/infrastructure/model/theme_entitie.dart';

class HiveInitializer {
  static Future<void> initialize() async {
    try {
      //  final appDocumentDir = await getApplicationDocumentsDirectory();
      await Hive.initFlutter();

      // Register adapters
      Hive.registerAdapter(ThemeEntitieAdapter());
      Hive.registerAdapter(AppConfigModelAdapter());

      // Open boxes with unique names
      // await Future.wait([Hive.openBox<AppConfigModel>(appConfigBox)]);
      await Future.wait([
        Hive.openBox<bool>(themeConfigBox),
        Hive.openBox<String>(languageConfigBox),
      ]);
    } catch (e) {
      rethrow;
    }
  }

  static Future<void> closeBoxes() async {
    // await Future.wait([Hive.box<AppConfigModel>(appConfigBox).close()]);
    await Future.wait([
      Hive.box<bool>(themeConfigBox).close(),
      Hive.box<String>(languageConfigBox).close(),
    ]);
  }
}
