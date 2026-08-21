import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'workflow_ai_preferences_state.dart';

class WorkflowAiPreferencesCubit extends Cubit<WorkflowAiPreferencesState> {
  WorkflowAiPreferencesCubit() : super(const WorkflowAiPreferencesState());

  static const String _appAiEnabledKey = 'workflow_ai_app_enabled';

  Future<void> loadPreferences({bool force = false}) async {
    if (state.status == WorkflowAiPreferenceStatus.loading) {
      return;
    }
    if (!force && state.status == WorkflowAiPreferenceStatus.loaded) {
      return;
    }

    emit(state.copyWith(status: WorkflowAiPreferenceStatus.loading));
    try {
      final preferences = await SharedPreferences.getInstance();
      final appAiEnabled = preferences.getBool(_appAiEnabledKey) ?? false;
      emit(
        state.copyWith(
          status: WorkflowAiPreferenceStatus.loaded,
          appAiEnabled: appAiEnabled,
          errorMessage: null,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: WorkflowAiPreferenceStatus.error,
          errorMessage: error.toString(),
        ),
      );
    }
  }

  Future<void> setAppAiEnabled(bool enabled) async {
    final previous = state.appAiEnabled;
    emit(
      state.copyWith(
        status: WorkflowAiPreferenceStatus.saving,
        appAiEnabled: enabled,
        errorMessage: null,
      ),
    );
    try {
      final preferences = await SharedPreferences.getInstance();
      await preferences.setBool(_appAiEnabledKey, enabled);
      emit(
        state.copyWith(
          status: WorkflowAiPreferenceStatus.loaded,
          appAiEnabled: enabled,
          errorMessage: null,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: WorkflowAiPreferenceStatus.error,
          appAiEnabled: previous,
          errorMessage: error.toString(),
        ),
      );
    }
  }
}
