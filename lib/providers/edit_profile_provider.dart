import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod/legacy.dart';

import 'package:test_steps/services/supabase_service.dart';

/// Formatted, ready-to-display profile values produced by the provider from
/// the raw profile row. The view seeds its text controllers from this once —
/// no data mapping happens in the UI layer.
class EditProfileFormData {
  const EditProfileFormData({
    this.displayName = '',
    this.username = '',
    this.email = '',
    this.location = '',
    this.bio = '',
    this.age = '',
    this.height = '',
    this.weight = '',
    this.weightGoal = '',
    this.dailyGoal = '',
    this.birthday = '',
    this.gender = 'Male',
    this.avatarUrl,
    this.birthDate,
  });

  final String displayName;
  final String username;
  final String email;
  final String location;
  final String bio;
  final String age;
  final String height;
  final String weight;
  final String weightGoal;
  final String dailyGoal;
  final String birthday;
  final String gender;
  final String? avatarUrl;
  final DateTime? birthDate;
}

class EditProfileState {
  const EditProfileState({
    this.isLoading = true,
    this.isSaving = false,
    this.form,
    this.selectedAvatarBytes,
    this.selectedAvatarExt = 'jpg',
    this.selectedGender = 'Male',
    this.message,
    this.saved = false,
  });

  final bool isLoading;
  final bool isSaving;
  final EditProfileFormData? form;
  final Uint8List? selectedAvatarBytes;
  final String selectedAvatarExt;
  final String selectedGender;

  /// One-shot user feedback (snackbar); cleared implicitly by being replaced.
  final String? message;

  /// True once a save completed successfully — the view pops on this.
  final bool saved;

  EditProfileState copyWith({
    bool? isLoading,
    bool? isSaving,
    EditProfileFormData? form,
    Uint8List? selectedAvatarBytes,
    String? selectedAvatarExt,
    String? selectedGender,
    String? message,
    bool clearMessage = false,
    bool? saved,
  }) {
    return EditProfileState(
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      form: form ?? this.form,
      selectedAvatarBytes: selectedAvatarBytes ?? this.selectedAvatarBytes,
      selectedAvatarExt: selectedAvatarExt ?? this.selectedAvatarExt,
      selectedGender: selectedGender ?? this.selectedGender,
      message: clearMessage ? null : message ?? this.message,
      saved: saved ?? this.saved,
    );
  }
}

class EditProfileNotifier extends StateNotifier<EditProfileState> {
  EditProfileNotifier(this._service) : super(const EditProfileState()) {
    load();
  }

  final SupabaseService _service;

  static const _displayNameKeys = ['display_name', 'full_name', 'name'];
  static const _locationKeys = ['location', 'city', 'region'];
  static const _birthdayKeys = ['birth_date', 'birthday', 'date_of_birth'];
  static const _bioKeys = ['bio', 'about', 'about_me'];
  static const _heightKeys = ['height_cm', 'height'];
  static const _weightKeys = ['weight_kg', 'weight'];
  static const _weightGoalKeys = ['weight_goal', 'goal'];
  static const _dailyGoalKeys = ['daily_steps_goal', 'step_goal'];

  final Set<String> _profileKeys = <String>{};
  DateTime? _selectedBirthDate;

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearMessage: true);
    try {
      final profile = await _service.getProfile() ?? <String, dynamic>{};
      _profileKeys
        ..clear()
        ..addAll(profile.keys.map((e) => e.toString()));

      final username =
          profile['username']?.toString() ??
          _service.currentUser?.email?.split('@').first ??
          '';
      var displayName = _readText(profile, _displayNameKeys);
      if (displayName.trim().isEmpty) displayName = username;

      var birthday = '';
      String age = _formatAge(profile['age']);
      final birthdayRaw = _readText(profile, _birthdayKeys);
      if (birthdayRaw.isNotEmpty) {
        final parsed = DateTime.tryParse(birthdayRaw);
        if (parsed != null) {
          _selectedBirthDate = parsed;
          birthday = _formatDate(parsed);
          if (age.isEmpty) age = _formatAge(_ageFromBirthDate(parsed));
        } else {
          birthday = birthdayRaw;
        }
      }

      final gender = _formatGender(profile['gender']);
      if (!mounted) return;
      state = state.copyWith(
        isLoading: false,
        selectedGender: gender,
        form: EditProfileFormData(
          displayName: displayName,
          username: username,
          email: _service.currentUser?.email ?? '',
          location: _readText(profile, _locationKeys),
          bio: _readText(profile, _bioKeys),
          age: age,
          height: _formatHeight(_readText(profile, _heightKeys)),
          weight: _formatWeight(_readText(profile, _weightKeys)),
          weightGoal: _formatGoal(_readText(profile, _weightGoalKeys)),
          dailyGoal: _formatDailyGoal(_readText(profile, _dailyGoalKeys)),
          birthday: birthday,
          gender: gender,
          avatarUrl: profile['avatar_url']?.toString(),
          birthDate: _selectedBirthDate,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(
        isLoading: false,
        message: 'Failed to load profile: $e',
      );
    }
  }

  void setGender(String gender) {
    state = state.copyWith(selectedGender: gender);
  }

  /// Records the birthday chosen via the date picker. The view owns the
  /// birthday/age text display; the notifier only needs the date for saving.
  void setBirthDate(DateTime date) {
    _selectedBirthDate = date;
  }

  /// Age (in whole years) derived from a chosen birth date — used by the view
  /// to keep the age field in sync when the birthday changes.
  int ageForBirthDate(DateTime date) => _ageFromBirthDate(date);

  void setAvatar(Uint8List bytes, String extension) {
    state = state.copyWith(
      selectedAvatarBytes: bytes,
      selectedAvatarExt: extension.toLowerCase(),
    );
  }

  /// Builds the schema-aware update map and persists it (avatar upload
  /// included). Field values come from the view's text controllers.
  Future<void> save({
    required String displayNameText,
    required String usernameText,
    required String ageText,
    required String locationText,
    required String bioText,
    required String heightText,
    required String weightText,
    required String weightGoalText,
    required String dailyGoalText,
  }) async {
    final displayName = displayNameText.trim();
    final username = usernameText.trim().isNotEmpty
        ? usernameText.trim()
        : displayName;
    if (username.isEmpty) {
      state = state.copyWith(message: 'Name is required');
      return;
    }

    state = state.copyWith(isSaving: true, clearMessage: true);
    try {
      var avatarUrl = state.form?.avatarUrl;
      final avatarBytes = state.selectedAvatarBytes;
      if (avatarBytes != null) {
        avatarUrl = await _service.uploadProfileAvatar(
          avatarBytes,
          fileExtension: state.selectedAvatarExt,
        );
      }

      final updates = <String, dynamic>{'username': username};

      if (_profileKeys.contains('avatar_url') && avatarUrl != null) {
        updates['avatar_url'] = avatarUrl;
      }

      final displayNameKey = _existingKey(_displayNameKeys);
      if (displayNameKey != null) {
        updates[displayNameKey] = displayName.isEmpty ? null : displayName;
      }

      if (_profileKeys.contains('gender')) {
        updates['gender'] = state.selectedGender;
      }

      if (_profileKeys.contains('age')) {
        updates['age'] = _readNumber(ageText)?.round();
      }

      final locationKey = _existingKey(_locationKeys);
      if (locationKey != null) {
        final value = locationText.trim();
        updates[locationKey] = value.isEmpty ? null : value;
      }

      final bioKey = _existingKey(_bioKeys);
      if (bioKey != null) {
        final value = bioText.trim();
        updates[bioKey] = value.isEmpty ? null : value;
      }

      final birthdayKey = _existingKey(_birthdayKeys);
      if (birthdayKey != null) {
        updates[birthdayKey] = _selectedBirthDate
            ?.toIso8601String()
            .split('T')
            .first;
      }

      final heightKey = _existingKey(_heightKeys);
      if (heightKey != null) {
        final value = heightText.trim();
        updates[heightKey] = value.isEmpty ? null : _readNumber(value);
      }

      final weightKey = _existingKey(_weightKeys);
      if (weightKey != null) {
        final value = weightText.trim();
        updates[weightKey] = value.isEmpty ? null : _readNumber(value);
      }

      final weightGoalKey = _existingKey(_weightGoalKeys);
      if (weightGoalKey != null) {
        final value = _stripGoalPrefix(weightGoalText).trim();
        updates[weightGoalKey] = value.isEmpty ? null : value;
      }

      final dailyGoalValue = _readNumber(dailyGoalText)?.round();
      for (final dailyGoalKey in _dailyGoalKeys) {
        if (_profileKeys.contains(dailyGoalKey)) {
          updates[dailyGoalKey] = dailyGoalValue;
        }
      }

      await _service.updateProfile(updates);
      if (!mounted) return;
      state = state.copyWith(
        isSaving: false,
        saved: true,
        message: 'Profile updated',
      );
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(
        isSaving: false,
        message: 'Failed to update profile: $e',
      );
    }
  }

  // ── Data mapping helpers (moved out of the UI layer) ────────────────────

  String _readText(Map<String, dynamic> profile, List<String> keys) {
    for (final key in keys) {
      final value = profile[key];
      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString();
      }
    }
    return '';
  }

  String? _existingKey(List<String> keys) {
    for (final key in keys) {
      if (_profileKeys.contains(key)) return key;
    }
    return null;
  }

  String _formatDate(DateTime date) {
    final mm = date.month.toString().padLeft(2, '0');
    final dd = date.day.toString().padLeft(2, '0');
    return '${date.year}-$mm-$dd';
  }

  int _ageFromBirthDate(DateTime date) {
    final now = DateTime.now();
    var age = now.year - date.year;
    if (now.month < date.month ||
        (now.month == date.month && now.day < date.day)) {
      age -= 1;
    }
    return age;
  }

  String _formatAge(Object? value) {
    final age = _readNumber(value);
    return age == null ? '' : '${age.round()}y';
  }

  String _formatWeight(String value) {
    final number = _readNumber(value);
    if (number == null) return '';
    return '${_trimNumber(number)} kg';
  }

  String _formatHeight(String value) {
    final number = _readNumber(value);
    if (number == null) return '';
    return '${_trimNumber(number)} cm';
  }

  String _formatGoal(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? '' : 'Goal: $trimmed';
  }

  String _formatDailyGoal(String value) {
    final number = _readNumber(value);
    if (number == null) return '';
    return '${_formatInt(number.round())} Daily Goal';
  }

  String _formatGender(Object? value) {
    final gender = value?.toString().trim().toLowerCase();
    return gender == 'female' ? 'Female' : 'Male';
  }

  num? _readNumber(Object? value) {
    if (value is num) return value;
    final text = value?.toString() ?? '';
    final match = RegExp(r'-?\d+(?:[.,]\d+)?').firstMatch(text);
    if (match == null) return null;
    return num.tryParse(match.group(0)!.replaceAll(',', '.'));
  }

  String _trimNumber(num value) {
    if (value % 1 == 0) return value.round().toString();
    return value.toStringAsFixed(1);
  }

  String _formatInt(int value) {
    final text = value.toString();
    final buffer = StringBuffer();
    for (var index = 0; index < text.length; index++) {
      final remaining = text.length - index;
      buffer.write(text[index]);
      if (remaining > 1 && remaining % 3 == 1) buffer.write(',');
    }
    return buffer.toString();
  }

  String _stripGoalPrefix(String value) {
    return value.replaceFirst(RegExp(r'^goal:\s*', caseSensitive: false), '');
  }
}

final editProfileProvider = StateNotifierProvider.autoDispose<
    EditProfileNotifier, EditProfileState>(
  (ref) => EditProfileNotifier(SupabaseService()),
);
