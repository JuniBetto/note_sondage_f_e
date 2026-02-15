import 'package:flutter_bloc/flutter_bloc.dart';
import 'navigation_event.dart'; // Importa gli eventi

// Il BLoC gestisce gli eventi di navigazione e mantiene l'indice corrente come stato
class NavigationBloc extends Bloc<NavigationEvent, int> {
  // Lo stato iniziale è 0 (Home)
  NavigationBloc() : super(0) {
    // Registra il gestore per l'evento NavigationPositionChanged
    on<NavigationPositionChanged>((event, emit) {
      // Emette il nuovo indice dalla proprietà dell'evento
      emit(event.newPosition);
    });
  }
}
