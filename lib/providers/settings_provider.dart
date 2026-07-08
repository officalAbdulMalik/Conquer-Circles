import 'package:riverpod/legacy.dart';
import '../services/supabase_service.dart';
import '../models/profile_data_model.dart';

/// App settings state. Centralised here (instead of widget-local setState)
/// so preferences survive navigation and can later be persisted or synced
/// server-side without touching the UI.
class SettingsState {
  const SettingsState({
    this.selectedTheme = 'Light',
    this.dailyAlerts = true,
    this.reminders = false,
    this.units = 'Metric',
  });

  final String selectedTheme;
  final bool dailyAlerts;
  final bool reminders;
  final String units;

  SettingsState copyWith({
    String? selectedTheme,
    bool? dailyAlerts,
    bool? reminders,
    String? units,
  }) {
    return SettingsState(
      selectedTheme: selectedTheme ?? this.selectedTheme,
      dailyAlerts: dailyAlerts ?? this.dailyAlerts,
      reminders: reminders ?? this.reminders,
      units: units ?? this.units,
    );
  }
}

class SettingsNotifier extends StateNotifier<SettingsState> {
  final SupabaseService _supabaseService;

  SettingsNotifier(this._supabaseService) : super(const SettingsState());

  void initializeFromProfile(ProfileInfo profile) {
    state = SettingsState(
      selectedTheme: profile.theme,
      units: profile.units,
      dailyAlerts: profile.dailyAlerts,
      reminders: profile.reminders,
    );
  }

  Future<void> setTheme(String theme) async {
    state = state.copyWith(selectedTheme: theme);
    try {
      await _supabaseService.updateAppSettings(theme: theme);
    } catch (e) {
      // Log/handle error if necessary
    }
  }

  Future<void> setDailyAlerts(bool value) async {
    state = state.copyWith(dailyAlerts: value);
    try {
      await _supabaseService.updateAppSettings(dailyAlerts: value);
    } catch (e) {
      // Log/handle error if necessary
    }
  }

  Future<void> setReminders(bool value) async {
    state = state.copyWith(reminders: value);
    try {
      await _supabaseService.updateAppSettings(reminders: value);
    } catch (e) {
      // Log/handle error if necessary
    }
  }

  Future<void> setUnits(String units) async {
    state = state.copyWith(units: units);
    try {
      await _supabaseService.updateAppSettings(units: units);
    } catch (e) {
      // Log/handle error if necessary
    }
  }
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsState>(
  (ref) => SettingsNotifier(SupabaseService()),
);
