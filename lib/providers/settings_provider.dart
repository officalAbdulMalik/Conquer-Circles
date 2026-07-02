import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod/legacy.dart';

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
  SettingsNotifier() : super(const SettingsState());

  void setTheme(String theme) => state = state.copyWith(selectedTheme: theme);
  void setDailyAlerts(bool value) =>
      state = state.copyWith(dailyAlerts: value);
  void setReminders(bool value) => state = state.copyWith(reminders: value);
  void setUnits(String units) => state = state.copyWith(units: units);
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsState>(
  (ref) => SettingsNotifier(),
);
