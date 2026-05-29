import 'dart:async';

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
  final Set<String> _syncingSondageIds = <String>{};
  String? _refreshKey;

  Set<String> get syncingSondageIds => Set.unmodifiable(_syncingSondageIds);

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
    on<_SondageCreateCommittedEvent>(_onSondageCreateCommitted);
    on<_SondageUpdateCommittedEvent>(_onSondageUpdateCommitted);
    on<_SondageMutationFailedEvent>(_onSondageMutationFailed);
    on<ResetSondageCacheEvent>(_onResetCache);
  }

  Future<void> _onLoadSondages(
    LoadSondagesEvent event,
    Emitter<SondageState> emit,
  ) async {
    const requestKey = 'all';
    if (_cachedSondages.isNotEmpty) {
      emit(SondagesLoaded(_cachedSondages));
    } else {
      final local = await sondageLocalDataSource.getAll();
      if (local.isNotEmpty) {
        _cachedSondages = local;
        emit(SondagesLoaded(local));
      } else {
        emit(SondageLoading());
      }
    }
    if (_refreshKey == requestKey) {
      return;
    }
    _refreshKey = requestKey;
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
    } finally {
      if (_refreshKey == requestKey) {
        _refreshKey = null;
      }
    }
  }

  Future<void> _onLoadSondagesByUserId(
    LoadSondagesByUserIdEvent event,
    Emitter<SondageState> emit,
  ) async {
    final requestKey = 'user:${event.userId}';
    if (_cachedSondages.isNotEmpty) {
      emit(SondagesLoaded(_cachedSondages));
    } else {
      final local = await sondageLocalDataSource.getAll();
      if (local.isNotEmpty) {
        _cachedSondages = local;
        emit(SondagesLoaded(local));
      } else {
        emit(SondageLoading());
      }
    }
    if (_refreshKey == requestKey) {
      return;
    }
    _refreshKey = requestKey;
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
    } finally {
      if (_refreshKey == requestKey) {
        _refreshKey = null;
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
    final rollbackSondages = List<SondageEntity>.from(_cachedSondages);
    final optimisticSondage = event.sondage.copyWith(
      id: _temporaryId('sondage'),
      createdDate: event.sondage.createdDate,
    );

    _syncingSondageIds.add(optimisticSondage.id);
    _cachedSondages = [optimisticSondage, ..._cachedSondages];
    await _persistCache();
    emit(SondageCreated(optimisticSondage));
    emit(SondagesLoaded(_cachedSondages));

    unawaited(() async {
      try {
        final created = await sondageUseCase.createSondage(event.sondage);
        if (!isClosed) {
          add(_SondageCreateCommittedEvent(optimisticSondage.id, created));
        }
      } catch (e) {
        if (!isClosed) {
          add(
            _SondageMutationFailedEvent(
              message: AppErrorMessageResolver.resolve(
                e,
                fallback: 'We could not create the survey right now.',
              ),
              rollbackSondages: rollbackSondages,
              syncingIdsToClear: {optimisticSondage.id},
            ),
          );
        }
      }
    }());
  }

  Future<void> _onUpdateSondage(
    UpdateSondageEvent event,
    Emitter<SondageState> emit,
  ) async {
    final rollbackSondages = List<SondageEntity>.from(_cachedSondages);
    final existingIndex = _cachedSondages.indexWhere(
      (item) => item.id == event.sondage.id,
    );

    if (existingIndex == -1) {
      _cachedSondages = [event.sondage, ..._cachedSondages];
    } else {
      _cachedSondages = List<SondageEntity>.from(_cachedSondages)
        ..[existingIndex] = event.sondage;
    }

    _syncingSondageIds.add(event.sondage.id);
    await _persistCache();
    emit(SondageUpdated(event.sondage));
    emit(SondagesLoaded(_cachedSondages));

    unawaited(() async {
      try {
        final updated = await sondageUseCase.updateSondage(event.sondage);
        if (!isClosed) {
          add(_SondageUpdateCommittedEvent(event.sondage.id, updated));
        }
      } catch (e) {
        if (!isClosed) {
          add(
            _SondageMutationFailedEvent(
              message: AppErrorMessageResolver.resolve(
                e,
                fallback: 'We could not update the survey right now.',
              ),
              rollbackSondages: rollbackSondages,
              syncingIdsToClear: {event.sondage.id},
            ),
          );
        }
      }
    }());
  }

  Future<void> _onDeleteSondage(
    DeleteSondageEvent event,
    Emitter<SondageState> emit,
  ) async {
    try {
      await sondageUseCase.deleteSondage(event.id);
      emit(SondageDeleted());
      _cachedSondages = _cachedSondages.where((s) => s.id != event.id).toList();
      await _persistCache();
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
      await _persistCache();
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
      await _persistCache();
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
      await _persistCache();
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

  Future<void> _persistCache() async {
    await sondageLocalDataSource.saveAll(_cachedSondages);
  }

  Future<void> _onResetCache(
    ResetSondageCacheEvent event,
    Emitter<SondageState> emit,
  ) async {
    _cachedSondages = [];
    await sondageLocalDataSource.clearAll();
    emit(SondageInitial());
  }

  Future<void> _onSondageCreateCommitted(
    _SondageCreateCommittedEvent event,
    Emitter<SondageState> emit,
  ) async {
    final existingIndex = _cachedSondages.indexWhere(
      (item) => item.id == event.temporaryId,
    );
    if (existingIndex == -1) {
      _cachedSondages = [event.sondage, ..._cachedSondages];
    } else {
      _cachedSondages = List<SondageEntity>.from(_cachedSondages)
        ..[existingIndex] = event.sondage;
    }
    _syncingSondageIds.remove(event.temporaryId);
    await _persistCache();
    emit(SondagesLoaded(_cachedSondages));
  }

  Future<void> _onSondageUpdateCommitted(
    _SondageUpdateCommittedEvent event,
    Emitter<SondageState> emit,
  ) async {
    _upsertCache(event.sondage);
    _syncingSondageIds.remove(event.sondageId);
    await _persistCache();
    emit(SondagesLoaded(_cachedSondages));
  }

  Future<void> _onSondageMutationFailed(
    _SondageMutationFailedEvent event,
    Emitter<SondageState> emit,
  ) async {
    _cachedSondages = List<SondageEntity>.from(event.rollbackSondages);
    _syncingSondageIds.removeAll(event.syncingIdsToClear);
    await _persistCache();
    emit(SondageError(event.message));
    emit(SondagesLoaded(_cachedSondages));
  }

  String _temporaryId(String prefix) {
    return 'local_${prefix}_${DateTime.now().microsecondsSinceEpoch}';
  }
}
