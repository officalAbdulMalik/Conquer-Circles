import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:riverpod/legacy.dart';

import 'package:test_steps/features/map/widgets/home_base_setup_sheet.dart'
    show HomeBaseLocationSuggestion;
import 'package:test_steps/providers/map_provider.dart';
import 'package:test_steps/services/geocoding_service.dart';

/// State for the "set home base" flow: search, suggestion selection, current
/// location, and the save call. All geocoding + RPC logic lives in the
/// notifier — the map screen only renders this state.
class HomeBaseSetupState {
  const HomeBaseSetupState({
    this.isSettingHomeBase = false,
    this.isSelectingLocation = false,
    this.isSearching = false,
    this.suggestions = const [],
    this.searchError,
    this.selectedCoordinates,
    this.selectedLabel,
    this.message,
    this.homeBaseSaved = false,
  });

  final bool isSettingHomeBase;
  final bool isSelectingLocation;
  final bool isSearching;
  final List<HomeBaseLocationSuggestion> suggestions;
  final String? searchError;
  final LatLng? selectedCoordinates;

  /// Label to display in the location field after a selection. The view
  /// mirrors this into its TextEditingController (one-shot).
  final String? selectedLabel;

  /// One-shot user feedback (snackbar).
  final String? message;

  /// True once the home base was saved successfully — the view closes the
  /// sheet and starts the countdown on this.
  final bool homeBaseSaved;

  HomeBaseSetupState copyWith({
    bool? isSettingHomeBase,
    bool? isSelectingLocation,
    bool? isSearching,
    List<HomeBaseLocationSuggestion>? suggestions,
    String? searchError,
    bool clearSearchError = false,
    LatLng? selectedCoordinates,
    bool clearSelectedCoordinates = false,
    String? selectedLabel,
    String? message,
    bool clearMessage = false,
    bool? homeBaseSaved,
  }) {
    return HomeBaseSetupState(
      isSettingHomeBase: isSettingHomeBase ?? this.isSettingHomeBase,
      isSelectingLocation: isSelectingLocation ?? this.isSelectingLocation,
      isSearching: isSearching ?? this.isSearching,
      suggestions: suggestions ?? this.suggestions,
      searchError: clearSearchError ? null : searchError ?? this.searchError,
      selectedCoordinates: clearSelectedCoordinates
          ? null
          : selectedCoordinates ?? this.selectedCoordinates,
      selectedLabel: selectedLabel ?? this.selectedLabel,
      message: clearMessage ? null : message ?? this.message,
      homeBaseSaved: homeBaseSaved ?? this.homeBaseSaved,
    );
  }
}

class HomeBaseSetupNotifier extends StateNotifier<HomeBaseSetupState> {
  HomeBaseSetupNotifier(this._ref, this._geocoding)
      : super(const HomeBaseSetupState());

  final Ref _ref;
  final GeocodingService _geocoding;

  Timer? _searchDebounce;
  int _searchRequestId = 0;

  @override
  void dispose() {
    _searchDebounce?.cancel();
    super.dispose();
  }

  /// Uses the device's current location as the home base candidate.
  Future<void> useCurrentLocation() async {
    if (state.isSelectingLocation) return;
    state = state.copyWith(isSelectingLocation: true, clearMessage: true);

    await _ref.read(mapProvider.notifier).getCurrentLocation();
    if (!mounted) return;

    final mapState = _ref.read(mapProvider);
    final location = mapState.userLocation;
    final error = mapState.error;

    if (error == null && location != null) {
      final address = await _geocoding.addressForCoordinates(location);
      if (!mounted) return;
      state = state.copyWith(
        isSelectingLocation: false,
        selectedCoordinates: location,
        suggestions: const [],
        clearSearchError: true,
        selectedLabel: address,
        message: 'Current location selected.',
      );
    } else {
      state = state.copyWith(
        isSelectingLocation: false,
        message: error ?? 'Could not get current location.',
      );
    }
  }

  /// Debounced as-you-type search.
  void onQueryChanged(String query) {
    _searchDebounce?.cancel();
    state = state.copyWith(clearSelectedCoordinates: true);

    final trimmed = query.trim();
    if (trimmed.length < 3) {
      state = state.copyWith(
        suggestions: const [],
        clearSearchError: true,
        isSearching: false,
      );
      return;
    }

    _searchDebounce = Timer(const Duration(milliseconds: 700), () {
      _loadSuggestions(trimmed);
    });
  }

  /// Immediate search (submit / search button).
  Future<void> search(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty || state.isSearching) return;
    await _loadSuggestions(trimmed);
  }

  Future<void> _loadSuggestions(String query) async {
    final requestId = ++_searchRequestId;
    state = state.copyWith(isSearching: true, clearSearchError: true);

    try {
      final suggestions = await _geocoding.searchAddress(query);
      if (!mounted || requestId != _searchRequestId) return;

      state = state.copyWith(
        suggestions: suggestions,
        searchError: suggestions.isEmpty ? 'No matching locations found.' : null,
        clearSearchError: suggestions.isNotEmpty,
      );
    } catch (_) {
      if (mounted && requestId == _searchRequestId) {
        state = state.copyWith(
          suggestions: const [],
          searchError:
              'Search is unavailable. Try a city and full street address.',
        );
      }
    } finally {
      if (mounted && requestId == _searchRequestId) {
        state = state.copyWith(isSearching: false);
      }
    }
  }

  void selectSuggestion(HomeBaseLocationSuggestion suggestion) {
    state = state.copyWith(
      selectedCoordinates: LatLng(suggestion.latitude, suggestion.longitude),
      suggestions: const [],
      clearSearchError: true,
      selectedLabel: suggestion.label,
    );
  }

  /// Persists the selected coordinates as the player's home base.
  Future<void> saveHomeBase() async {
    if (state.isSettingHomeBase) return;
    final location = state.selectedCoordinates;
    if (location == null) {
      state = state.copyWith(
        message: 'Select or search for a location first.',
      );
      return;
    }

    state = state.copyWith(isSettingHomeBase: true, clearMessage: true);
    final result = await _ref.read(mapProvider.notifier).setHomeBase(location);
    if (!mounted) return;

    final success = result['success'] == true;
    state = state.copyWith(
      isSettingHomeBase: false,
      homeBaseSaved: success,
      message: success
          ? 'Home base updated.'
          : result['error']?.toString() ?? 'Could not set home base.',
    );
  }

  /// Resets one-shot flags when the sheet is (re)opened.
  void resetFlow() {
    _searchDebounce?.cancel();
    state = const HomeBaseSetupState();
  }
}

final homeBaseSetupProvider =
    StateNotifierProvider<HomeBaseSetupNotifier, HomeBaseSetupState>(
  (ref) => HomeBaseSetupNotifier(ref, const GeocodingService()),
);
