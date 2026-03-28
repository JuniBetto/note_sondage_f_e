// sondage_bloc.dart
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

part 'sondage_event.dart';
part 'sondage_state.dart';

// TODO: Creare SondageEntity e SondageUseCase
// Per ora il BLoC è commentato per permettere i test con dati fittizi

/* 
class SondageBloc extends Bloc<SondageEvent, SondageState> {
  final SondageUseCase SondageUseCase;

  /// Cache of loaded Sondages to avoid flickering on CRUD operations
  List<SondageEntity> _cachedSondages = [];

  SondageBloc({required this.SondageUseCase}) : super(SondageInitial()) {
    on<LoadSondagesEvent>(_onLoadSondages);
    on<LoadSondagesByUserIdEvent>(_onLoadSondagesByUserId);
    on<LoadSondageByIdEvent>(_onLoadSondageById);
    on<CreateSondageEvent>(_onCreateSondage);
    on<UpdateSondageEvent>(_onUpdateSondage);
    on<DeleteSondageEvent>(_onDeleteSondage);
  }

  Future<void> _onLoadSondages(
    LoadSondagesEvent event,
    Emitter<SondageState> emit,
  ) async {
    // Show loading only on first load (cache is empty)
    if (_cachedSondages.isEmpty) {
      emit(SondageLoading());
    }
    try {
      final Sondages = await SondageUseCase.getAllSondages();
      _cachedSondages = Sondages;
      emit(SondagesLoaded(Sondages));
    } catch (e) {
      emit(SondageError(e.toString()));
    }
  }

  Future<void> _onLoadSondagesByUserId(
    LoadSondagesByUserIdEvent event,
    Emitter<SondageState> emit,
  ) async {
    // Show loading only on first load (cache is empty)
    if (_cachedSondages.isEmpty) {
      emit(SondageLoading());
    }
    try {
      final Sondages = await SondageUseCase.getAllSondagesByUserId(
        event.userId,
      );
      _cachedSondages = Sondages;
      emit(SondagesLoaded(Sondages));
    } catch (e) {
      emit(SondageError(e.toString()));
    }
  }

  Future<void> _onLoadSondageById(
    LoadSondageByIdEvent event,
    Emitter<SondageState> emit,
  ) async {
    emit(SondageLoading());
    try {
      final Sondage = await SondageUseCase.getSondageById(event.id);
      if (Sondage != null) {
        emit(SondageLoaded(Sondage));
      } else {
        emit(const SondageError('Sondage not found'));
      }
    } catch (e) {
      emit(SondageError(e.toString()));
    }
  }

  Future<void> _onCreateSondage(
    CreateSondageEvent event,
    Emitter<SondageState> emit,
  ) async {
    try {
      final SondageEntity Sondage;
      if (event.userId != null && event.userId!.isNotEmpty) {
        Sondage = await SondageUseCase.createSondageByUser(
          event.Sondage,
          event.userId!,
        );
      } else {
        Sondage = await SondageUseCase.createSondage(event.Sondage);
      }
      emit(SondageCreated(Sondage));

      // Optimistic update: add to cache immediately
      _cachedSondages = [..._cachedSondages, Sondage];
      emit(SondagesLoaded(_cachedSondages));
    } catch (e) {
      emit(SondageError(e.toString()));
      // Re-emit cached Sondages so UI doesn't break
      if (_cachedSondages.isNotEmpty) {
        emit(SondagesLoaded(_cachedSondages));
      }
    }
  }

  Future<void> _onUpdateSondage(
    UpdateSondageEvent event,
    Emitter<SondageState> emit,
  ) async {
    try {
      final Sondage = await SondageUseCase.updateSondage(event.Sondage);
      emit(SondageUpdated(Sondage));

      // Optimistic update: replace in cache
      _cachedSondages = _cachedSondages.map((t) {
        return t.id == Sondage.id ? Sondage : t;
      }).toList();
      emit(SondagesLoaded(_cachedSondages));
    } catch (e) {
      emit(SondageError(e.toString()));
      if (_cachedSondages.isNotEmpty) {
        emit(SondagesLoaded(_cachedSondages));
      }
    }
  }

  Future<void> _onDeleteSondage(
    DeleteSondageEvent event,
    Emitter<SondageState> emit,
  ) async {
    try {
      final success = await SondageUseCase.deleteSondage(event.id);
      if (success) {
        emit(SondageDeleted());

        // Optimistic update: remove from cache
        _cachedSondages = _cachedSondages
            .where((t) => t.id != event.id)
            .toList();
        emit(SondagesLoaded(_cachedSondages));
      } else {
        emit(const SondageError('Failed to delete Sondage'));
        if (_cachedSondages.isNotEmpty) {
          emit(SondagesLoaded(_cachedSondages));
        }
      }
    } catch (e) {
      emit(SondageError(e.toString()));
      if (_cachedSondages.isNotEmpty) {
        emit(SondagesLoaded(_cachedSondages));
      }
    }
  }
}
*/
