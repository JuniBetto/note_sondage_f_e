import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:note_sondage/core/utils/app_error_message_resolver.dart';
import 'package:note_sondage/feature/sondage/domain/entities/sondage_entity.dart';
import 'package:note_sondage/feature/sondage/domain/use_case/sondage_use_case.dart';
import 'package:note_sondage/feature/sondage/infrastructure/data_source/data_source_local/sondage_local_data_source.dart';

part 'sondage_event.dart';
part 'sondage_state.dart';

class SondageBloc extends Bloc<SondageEvent, SondageState> {
  final SondageUseCase sondageUseCase;
  final SondageLocalDataSource sondageLocalDataSource;

  /// Cache dei sondaggi caricati per evitare flickering
  List<SondageEntity> _cachedSondages = [];

  SondageBloc({
    required this.sondageUseCase,
    required this.sondageLocalDataSource,
  }) : super(SondageInitial()) {
    on<LoadSondagesEvent>(_onLoadSondages);
    on<LoadSondagesByUserIdEvent>(_onLoadSondagesByUserId);
    on<LoadSondageByIdEvent>(_onLoadSondageById);
    on<CreateSondageEvent>(_onCreateSondage);
    on<UpdateSondageEvent>(_onUpdateSondage);
    on<DeleteSondageEvent>(_onDeleteSondage);
    on<PublishSondageEvent>(_onPublishSondage);
    on<CloseSondageEvent>(_onCloseSondage);
    on<VoteSondageEvent>(_onVoteSondage);
    on<ResetSondageCacheEvent>(_onResetCache);
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
      emit(
        SondageError(
          AppErrorMessageResolver.resolve(
            e,
            fallback: 'We could not refresh the surveys right now.',
          ),
        ),
      );
      if (_cachedSondages.isNotEmpty) {
        emit(SondagesLoaded(_cachedSondages));
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
      emit(
        SondageError(
          AppErrorMessageResolver.resolve(
            e,
            fallback: 'We could not refresh the surveys right now.',
          ),
        ),
      );
      if (_cachedSondages.isNotEmpty) {
        emit(SondagesLoaded(_cachedSondages));
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
      emit(
        SondageError(
          AppErrorMessageResolver.resolve(
            e,
            fallback: 'We could not load this survey right now.',
          ),
        ),
      );
    }
  }

  Future<void> _onCreateSondage(
    CreateSondageEvent event,
    Emitter<SondageState> emit,
  ) async {
    try {
      final sondage = await sondageUseCase.createSondage(event.sondage);
      _cachedSondages = [..._cachedSondages, sondage];
      emit(SondageCreated(sondage));
      // SondagesLoaded viene emesso con un piccolo delay
      // per non interrompere l'animazione tab nel listener
      await Future.delayed(const Duration(milliseconds: 350));
      emit(SondagesLoaded(_cachedSondages));
    } catch (e) {
      emit(
        SondageError(
          AppErrorMessageResolver.resolve(
            e,
            fallback: 'We could not create the survey right now.',
          ),
        ),
      );
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
      emit(
        SondageError(
          AppErrorMessageResolver.resolve(
            e,
            fallback: 'We could not update the survey right now.',
          ),
        ),
      );
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
      emit(
        SondageError(
          AppErrorMessageResolver.resolve(
            e,
            fallback: 'We could not delete the survey right now.',
          ),
        ),
      );
      if (_cachedSondages.isNotEmpty) {
        emit(SondagesLoaded(_cachedSondages));
      }
    }
  }

  Future<void> _onPublishSondage(
    PublishSondageEvent event,
    Emitter<SondageState> emit,
  ) async {
    try {
      final sondage = await sondageUseCase.publishSondage(event.id);
      _upsertCache(sondage);
      emit(SondageActionSuccess(sondage));
      emit(SondagesLoaded(_cachedSondages));
    } catch (e) {
      emit(
        SondageError(
          AppErrorMessageResolver.resolve(
            e,
            fallback: 'We could not publish the survey right now.',
          ),
        ),
      );
      if (_cachedSondages.isNotEmpty) emit(SondagesLoaded(_cachedSondages));
    }
  }

  Future<void> _onCloseSondage(
    CloseSondageEvent event,
    Emitter<SondageState> emit,
  ) async {
    try {
      final sondage = await sondageUseCase.closeSondage(event.id);
      _upsertCache(sondage);
      emit(SondageActionSuccess(sondage));
      emit(SondagesLoaded(_cachedSondages));
    } catch (e) {
      emit(
        SondageError(
          AppErrorMessageResolver.resolve(
            e,
            fallback: 'We could not close the survey right now.',
          ),
        ),
      );
      if (_cachedSondages.isNotEmpty) emit(SondagesLoaded(_cachedSondages));
    }
  }

  Future<void> _onVoteSondage(
    VoteSondageEvent event,
    Emitter<SondageState> emit,
  ) async {
    try {
      final sondage = await sondageUseCase.voteSondage(
        event.sondageId,
        event.optionId,
      );
      _upsertCache(sondage);
      emit(SondageActionSuccess(sondage));
      emit(SondagesLoaded(_cachedSondages));
    } catch (e) {
      emit(
        SondageError(
          AppErrorMessageResolver.resolve(
            e,
            fallback: 'We could not save your vote right now.',
          ),
        ),
      );
      if (_cachedSondages.isNotEmpty) emit(SondagesLoaded(_cachedSondages));
    }
  }

  void _upsertCache(SondageEntity sondage) {
    final existingIndex = _cachedSondages.indexWhere(
      (item) => item.id == sondage.id,
    );
    if (existingIndex == -1) {
      _cachedSondages = [sondage, ..._cachedSondages];
      return;
    }
    _cachedSondages = List<SondageEntity>.from(_cachedSondages)
      ..[existingIndex] = sondage;
  }

  Future<void> _onResetCache(
    ResetSondageCacheEvent event,
    Emitter<SondageState> emit,
  ) async {
    _cachedSondages = [];
    await sondageLocalDataSource.clearAll();
    emit(SondageInitial());
  }
}
