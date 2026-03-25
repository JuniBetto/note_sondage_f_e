import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:note_sondage/core/utils/app_constant.dart';
import 'package:note_sondage/core/utils/hive_service.dart';
import 'package:note_sondage/ui/widgets/language_config/bloc/language_event.dart';
import 'package:note_sondage/ui/widgets/language_config/bloc/language_state.dart';

class LanguageBloc extends Bloc<LanguageEvent, LanguageState> {
  LanguageBloc() : super(const LanguageInitial(Locale('en'))) {
    on<LanguageLoadEvent>(_onLoadLanguage);
    on<LanguageChangeEvent>(_onChangeLanguage);
    // Carica la lingua all'inizializzazione
    add(const LanguageLoadEvent());
  }

  Future<void> _onLoadLanguage(
    LanguageLoadEvent event,
    Emitter<LanguageState> emit,
  ) async {
    try {
      // Recupera la lingua salvata da Hive
      final savedLanguage = await HiveService.getHive<String>(
        languageConfigBox,
        languageKeyBox,
      );

      if (savedLanguage != null && savedLanguage.isNotEmpty) {
        debugPrint("[LanguageBloc] Loaded language: $savedLanguage");
        emit(LanguageChanged(Locale(savedLanguage)));
      } else {
        debugPrint("[LanguageBloc] No saved language, using default: en");
        emit(const LanguageChanged(Locale('en')));
      }
    } catch (e) {
      debugPrint("[LanguageBloc] Error loading language: $e");
      emit(const LanguageChanged(Locale('en')));
    }
  }

  Future<void> _onChangeLanguage(
    LanguageChangeEvent event,
    Emitter<LanguageState> emit,
  ) async {
    debugPrint("[LanguageBloc] Changing language to: ${event.languageCode}");
    
    // Salva la lingua in Hive
    await HiveService.putHive<String>(
      event.languageCode,
      languageConfigBox,
      languageKeyBox,
    );

    emit(LanguageChanged(Locale(event.languageCode)));
  }
}
