import 'package:hive/hive.dart';

class HiveService {
  // Metodo per ottenere la box già aperta
  static Box<T> getAppBox<T>(String nameBox) {
    return Hive.box<T>(nameBox);
  }

  static bool isBoxOpen(String boxName) {
    return Hive.isBoxOpen(boxName);
  }

  static Future<Box<T>> getOrOpenBox<T>(String boxName) async {
    try {
      if (Hive.isBoxOpen(boxName)) {
        return Hive.box<T>(boxName);
      } else {
        return await Hive.openBox<T>(boxName);
      }
    } catch (e) {
      rethrow;
    }
  }

  // Esempio di utilizzo
  static Future<void> putHive<T>(
    T config,
    String nameBox,
    String keyBox,
  ) async {
    try {
      final box = getAppBox<T>(nameBox);
      await box.put(keyBox, config);
    } catch (e) {
      rethrow;
    }
  }

  static T? getHive<T>(String nameBox, String keyBox) {
    try {
      final box = getAppBox<T>(nameBox);
      return box.get(keyBox);
    } catch (e) {
      rethrow;
    }
  }

  static Future<void> updateHive<T>(
    T config,
    String nameBox,
    String keyBox,
  ) async {
    try {
      final box = getAppBox<T>(nameBox);
      await box.put(keyBox, config);
    } catch (e) {
      rethrow;
    }
  }

  static Future<void> deleteHive<T>(String nameBox, String keyBox) async {
    try {
      final box = getAppBox<T>(nameBox);
      await box.delete(keyBox);
    } catch (e) {
      rethrow;
    }
  }
}
