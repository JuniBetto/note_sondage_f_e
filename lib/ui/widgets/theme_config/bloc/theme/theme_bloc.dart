import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:note_sondage/core/utils/app_constant.dart';
import 'package:note_sondage/core/utils/hive_service.dart';
import 'package:note_sondage/infrastructure/repository_impl/theme/theme_repository.dart';
import 'package:note_sondage/theme/theme.dart';
import 'package:note_sondage/ui/widgets/theme_config/bloc/theme/theme_event.dart';
import 'package:note_sondage/ui/widgets/theme_config/bloc/theme/theme_state.dart';

class ThemeBloc extends Bloc<ThemeEvent, ThemeState> {
  ThemeBloc() : super(ThemeInitial(AppTheme.buildTheme(false))) {
    on<ThemeSetLightEvent>(_onSetLightTheme);
    on<ThemeSetDarkEvent>(_onSetDarkTheme);
    on<ThemeSetSystemEvent>(_onSetSystemTheme);
    on<ThemeLoadEvent>(_onLoadConfig);
    // Carica il tema all'inizializzazione
    add(ThemeLoadEvent());
  }

  Future<void> _onLoadConfig(
    ThemeLoadEvent event,
    Emitter<ThemeState> emit,
  ) async {
    try {
      final isDark = await ThemeRepository.getIsDark();

      if (isDark) {
        emit(ThemeisDark(AppTheme.buildTheme(true)));
      } else {
        emit(ThemeisLight(AppTheme.buildTheme(false)));
      }
    } catch (e) {
      emit(ThemeisLight(AppTheme.buildTheme(false)));
    }
  }

  Future<void> _onSetDarkTheme(
    ThemeSetDarkEvent event,
    Emitter<ThemeState> emit,
  ) async {
    debugPrint("[ThemeBloc] Setting DARK theme");
    await ThemeRepository.setIsDark(true);
    emit(ThemeisDark(AppTheme.buildTheme(true)));
  }

  Future<void> _onSetLightTheme(
    ThemeSetLightEvent event,
    Emitter<ThemeState> emit,
  ) async {
    debugPrint("[ThemeBloc] Setting LIGHT theme");
    await ThemeRepository.setIsDark(false);
    emit(ThemeisLight(AppTheme.buildTheme(false)));
  }

  Future<void> _onSetSystemTheme(
    ThemeSetSystemEvent event,
    Emitter<ThemeState> emit,
  ) async {
    final Brightness platformBrightness =
        WidgetsBinding.instance.platformDispatcher.platformBrightness;

    final bool isSystemDark = platformBrightness == Brightness.dark;

    // Salva lo stato del tema di sistema
    await HiveService.putHive<bool>(isSystemDark, themeConfigBox, themeKeyBox);

    final ThemeData systemTheme = AppTheme.buildTheme(isSystemDark);
    emit(ThemeisSystem(systemTheme));
  }
}
