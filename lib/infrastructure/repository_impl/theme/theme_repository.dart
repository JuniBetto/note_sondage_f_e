import 'package:flutter/material.dart';
import 'package:note_sondage/core/utils/app_constant.dart';
import 'package:note_sondage/core/utils/hive_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeRepository {
  static const String _themeKey = 'is_dark_theme';

  static Future<bool> getIsDark() async {
    try {
      // Prima prova con Hive
      final hiveValue = HiveService.getHive<bool>(themeConfigBox, themeKeyBox);
      if (hiveValue != null) {
        debugPrint("Theme loaded from Hive: $hiveValue");
        return hiveValue;
      }

      // Se Hive fallisce, prova con SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final prefsValue = prefs.getBool(_themeKey);
      debugPrint("Theme loaded from SharedPreferences: $prefsValue");
      return prefsValue ?? false;
    } catch (e) {
      debugPrint("Error loading theme: $e");
      return false;
    }
  }

  static Future<void> setIsDark(bool isDark) async {
    try {
      // Salva in entrambi i storage
      await HiveService.putHive<bool>(isDark, themeConfigBox, themeKeyBox);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_themeKey, isDark);

      debugPrint("Theme saved to both storage: $isDark");
    } catch (e) {
      debugPrint("Error saving theme: $e");
    }
  }
}
