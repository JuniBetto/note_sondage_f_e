part of 'workflow_ai_preferences_cubit.dart';

enum WorkflowAiPreferenceStatus { initial, loading, loaded, saving, error }

class WorkflowAiPreferencesState extends Equatable {
  const WorkflowAiPreferencesState({
    this.status = WorkflowAiPreferenceStatus.initial,
    this.appAiEnabled = false,
    this.errorMessage,
  });

  final WorkflowAiPreferenceStatus status;
  final bool appAiEnabled;
  final String? errorMessage;

  WorkflowAiPreferencesState copyWith({
    WorkflowAiPreferenceStatus? status,
    bool? appAiEnabled,
    String? errorMessage,
  }) {
    return WorkflowAiPreferencesState(
      status: status ?? this.status,
      appAiEnabled: appAiEnabled ?? this.appAiEnabled,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, appAiEnabled, errorMessage];
}
