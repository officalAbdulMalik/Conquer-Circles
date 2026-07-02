import 'package:riverpod/legacy.dart';
import 'package:test_steps/models/dashboard_model.dart';
import 'package:test_steps/services/ai_service.dart';

class AiState {
  final bool isLoadingSuggestion;
  final bool isLoadingObjectives;
  final String? territorySuggestion;
  final List<AiObjective> objectives;
  final String? error;

  const AiState({
    this.isLoadingSuggestion = false,
    this.isLoadingObjectives = false,
    this.territorySuggestion,
    this.objectives = const [],
    this.error,
  });

  AiState copyWith({
    bool? isLoadingSuggestion,
    bool? isLoadingObjectives,
    String? territorySuggestion,
    List<AiObjective>? objectives,
    String? error,
    bool clearError = false,
  }) => AiState(
    isLoadingSuggestion: isLoadingSuggestion ?? this.isLoadingSuggestion,
    isLoadingObjectives: isLoadingObjectives ?? this.isLoadingObjectives,
    territorySuggestion: territorySuggestion ?? this.territorySuggestion,
    objectives: objectives ?? this.objectives,
    error: clearError ? null : (error ?? this.error),
  );
}

class AiNotifier extends StateNotifier<AiState> {
  final AiService _service;

  AiNotifier(this._service) : super(const AiState());

  Future<void> fetchTerritorySuggestion(DashboardState stats) async {
    if (state.isLoadingSuggestion) return;
    state = state.copyWith(isLoadingSuggestion: true, clearError: true);
    try {
      final suggestion = await _service.generateTerritorySuggestion(stats);
      if (mounted) {
        state = state.copyWith(
          isLoadingSuggestion: false,
          territorySuggestion: suggestion,
        );
      }
    } catch (e) {
      if (mounted) {
        state = state.copyWith(isLoadingSuggestion: false, error: e.toString());
      }
    }
  }

  Future<void> fetchObjectives(DashboardState stats) async {
    if (state.isLoadingObjectives) return;
    state = state.copyWith(isLoadingObjectives: true, clearError: true);
    try {
      final objectives = await _service.generateObjectives(stats);
      if (mounted) {
        state = state.copyWith(
          isLoadingObjectives: false,
          objectives: objectives,
        );
      }
    } catch (e) {
      if (mounted) {
        state = state.copyWith(
          isLoadingObjectives: false,
          error: e.toString(),
        );
      }
    }
  }
}

final aiProvider = StateNotifierProvider<AiNotifier, AiState>((ref) {
  return AiNotifier(AiService());
});
