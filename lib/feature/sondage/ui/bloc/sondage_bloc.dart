import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:note_sondage/feature/sondage/domain/entities/sondage_entity.dart';
import 'package:note_sondage/feature/sondage/domain/use_case/sondage_use_case.dart';

part 'sondage_event.dart';
part 'sondage_state.dart';

class SondageBloc extends Bloc<SondageEvent, SondageState> {
  final SondageUseCase sondageUseCase;

  /// Cache dei sondaggi caricati per evitare flickering
  List<SondageEntity> _cachedSondages = [];

  SondageBloc({required this.sondageUseCase}) : super(SondageInitial()) {
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
    if (_cachedSondages.isNotEmpty) {
      emit(SondagesLoaded(_cachedSondages));
    } else {
      emit(SondageLoading());
    }
    try {
      final sondages = await sondageUseCase.getAllSondages();
      _cachedSondages = sondages;
      emit(SondagesLoaded(sondages));
    } catch (e) {
      if (_cachedSondages.isEmpty) {
        emit(SondageError(e.toString()));
      }
    }
  }

  Future<void> _onLoadSondagesByUserId(
    LoadSondagesByUserIdEvent event,
    Emitter<SondageState> emit,
  ) async {
    if (_cachedSondages.isNotEmpty) {
      emit(SondagesLoaded(_cachedSondages));
    } else {
      emit(SondageLoading());
    }
    try {
      final sondages = await sondageUseCase.getAllSondagesByUserId(
        event.userId,
      );
      _cachedSondages = sondages;
      emit(SondagesLoaded(sondages));
    } catch (e) {
      if (_cachedSondages.isEmpty) {
        emit(SondageError(e.toString()));
      }
    }
  }

  Future<void> _onLoadSondageById(
    LoadSondageByIdEvent event,
    Emitter<SondageState> emit,
  ) async {
    emit(SondageLoading());
    try {
      final sondage = await sondageUseCase.getSondageById(event.id);
      if (sondage != null) {
        emit(SondageLoaded(sondage));
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
      final sondage = await sondageUseCase.createSondage(event.sondage);
      emit(SondageCreated(sondage));
      _cachedSondages = [..._cachedSondages, sondage];
      emit(SondagesLoaded(_cachedSondages));
    } catch (e) {
      emit(SondageError(e.toString()));
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
      final sondage = await sondageUseCase.updateSondage(event.sondage);
      emit(SondageUpdated(sondage));
      _cachedSondages = _cachedSondages.map((s) {
        return s.id == sondage.id ? sondage : s;
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
      await sondageUseCase.deleteSondage(event.id);
      emit(SondageDeleted());
      _cachedSondages = _cachedSondages.where((s) => s.id != event.id).toList();
      emit(SondagesLoaded(_cachedSondages));
    } catch (e) {
      emit(SondageError(e.toString()));
      if (_cachedSondages.isNotEmpty) {
        emit(SondagesLoaded(_cachedSondages));
      }
    }
  }
}
