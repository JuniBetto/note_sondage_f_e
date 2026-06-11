import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:note_sondage/ui/bloc/setting_Navigation_bloc/setting_navigation_event.dart';

// Il BLoC gestisce gli eventi di navigazione e mantiene l'indice corrente come stato
class SettingNavigationBloc extends Bloc<SettingNavigationEvent, int> {
  // Lo stato iniziale è 0 (Home)
  SettingNavigationBloc() : super(0) {
    // Registra il gestore per l'evento SettingPositionChanged
    on<SettingNavigationPositionChanged>((event, emit) {
      // Emette il nuovo indice dalla proprietà dell'evento
      emit(event.newPosition);
    });
  }
}
