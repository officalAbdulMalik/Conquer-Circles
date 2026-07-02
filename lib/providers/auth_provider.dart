import 'package:flutter/foundation.dart';
import 'package:riverpod/legacy.dart';
import 'package:test_steps/services/notification_service.dart';
import 'package:test_steps/services/supabase_service.dart';

class AuthActionResult {
  const AuthActionResult._({
    required this.success,
    this.completedSession = false,
    this.error,
  });

  const AuthActionResult.success()
    : this._(success: true, completedSession: true);
  const AuthActionResult.externalAuthStarted() : this._(success: true);
  const AuthActionResult.failure(String error)
    : this._(success: false, error: error);
  const AuthActionResult.needsVerification()
    : this._(
        success: false,
        error:
            'Signup created your account, but Supabase has not started a session yet. Disable email confirmation in Supabase Auth or verify the email before continuing.',
      );

  final bool success;
  final bool completedSession;
  final String? error;
}

class AppAuthState {
  const AppAuthState({
    this.isEmailAuthLoading = false,
    this.isSocialAuthLoading = false,
    this.isOtpVerifying = false,
    this.isProfileSaving = false,
    this.isPasswordResetLoading = false,
    this.isPasswordUpdating = false,
    this.loginPasswordObscured = true,
    this.signupPasswordObscured = true,
    this.signupName,
    this.selectedGender,
    this.selectedAge = 25,
    this.selectedWeight = 25,
    this.selectedWeightUnit = 'kg',
    this.selectedHeight = 175,
    this.selectedHeightUnit = 'cm',
    this.selectedWeightGoal = 'Lose Weight',
    this.selectedDailyStepsGoal = 5000,
    this.otpDigits = const ['', '', '', '', '', ''],
  });

  final bool isEmailAuthLoading;
  final bool isSocialAuthLoading;
  final bool isOtpVerifying;
  final bool isProfileSaving;
  final bool isPasswordResetLoading;
  final bool isPasswordUpdating;
  final bool loginPasswordObscured;
  final bool signupPasswordObscured;
  final String? signupName;
  final String? selectedGender;
  final int selectedAge;
  final int selectedWeight;
  final String selectedWeightUnit;
  final int selectedHeight;
  final String selectedHeightUnit;
  final String selectedWeightGoal;
  final int selectedDailyStepsGoal;
  final List<String> otpDigits;

  String get otpCode => otpDigits.join();
  bool get isOtpComplete => otpCode.length == otpDigits.length;
  bool get hasSelectedGender => selectedGender != null;
  bool get isKgSelected => selectedWeightUnit == 'kg';
  bool get isCmSelected => selectedHeightUnit == 'cm';
  List<int> get visibleWeights {
    return List.generate(5, (index) => selectedWeight - 2 + index);
  }

  List<int> get visibleHeights {
    final start = selectedHeight - ((selectedHeight + 2) % 5);
    return List.generate(5, (index) => start + index);
  }

  int get selectedHeightIndex {
    return visibleHeights.indexOf(selectedHeight);
  }

  AppAuthState copyWith({
    bool? isEmailAuthLoading,
    bool? isSocialAuthLoading,
    bool? isOtpVerifying,
    bool? isProfileSaving,
    bool? isPasswordResetLoading,
    bool? isPasswordUpdating,
    bool? loginPasswordObscured,
    bool? signupPasswordObscured,
    String? signupName,
    String? selectedGender,
    bool clearSelectedGender = false,
    int? selectedAge,
    int? selectedWeight,
    String? selectedWeightUnit,
    int? selectedHeight,
    String? selectedHeightUnit,
    String? selectedWeightGoal,
    int? selectedDailyStepsGoal,
    List<String>? otpDigits,
  }) {
    return AppAuthState(
      isEmailAuthLoading: isEmailAuthLoading ?? this.isEmailAuthLoading,
      isSocialAuthLoading: isSocialAuthLoading ?? this.isSocialAuthLoading,
      isOtpVerifying: isOtpVerifying ?? this.isOtpVerifying,
      isProfileSaving: isProfileSaving ?? this.isProfileSaving,
      isPasswordResetLoading:
          isPasswordResetLoading ?? this.isPasswordResetLoading,
      isPasswordUpdating: isPasswordUpdating ?? this.isPasswordUpdating,
      loginPasswordObscured:
          loginPasswordObscured ?? this.loginPasswordObscured,
      signupPasswordObscured:
          signupPasswordObscured ?? this.signupPasswordObscured,
      signupName: signupName ?? this.signupName,
      selectedGender: clearSelectedGender
          ? null
          : selectedGender ?? this.selectedGender,
      selectedAge: selectedAge ?? this.selectedAge,
      selectedWeight: selectedWeight ?? this.selectedWeight,
      selectedWeightUnit: selectedWeightUnit ?? this.selectedWeightUnit,
      selectedHeight: selectedHeight ?? this.selectedHeight,
      selectedHeightUnit: selectedHeightUnit ?? this.selectedHeightUnit,
      selectedWeightGoal: selectedWeightGoal ?? this.selectedWeightGoal,
      selectedDailyStepsGoal:
          selectedDailyStepsGoal ?? this.selectedDailyStepsGoal,
      otpDigits: otpDigits ?? this.otpDigits,
    );
  }
}

class AuthNotifier extends StateNotifier<AppAuthState> {
  AuthNotifier(this._supabaseService) : super(const AppAuthState());

  final SupabaseService _supabaseService;

  void toggleLoginPasswordVisibility() {
    state = state.copyWith(loginPasswordObscured: !state.loginPasswordObscured);
  }

  void toggleSignupPasswordVisibility() {
    state = state.copyWith(
      signupPasswordObscured: !state.signupPasswordObscured,
    );
  }

  void selectGender(String gender) {
    state = state.copyWith(selectedGender: gender);
  }

  AuthActionResult completeGenderSelection() {
    if (!state.hasSelectedGender) {
      return const AuthActionResult.failure('Please select your gender.');
    }

    return const AuthActionResult.success();
  }

  void setAge(int age) {
    state = state.copyWith(selectedAge: age.clamp(13, 100));
  }

  void incrementAge() {
    setAge(state.selectedAge + 1);
  }

  void decrementAge() {
    setAge(state.selectedAge - 1);
  }

  void setWeight(int weight) {
    state = state.copyWith(selectedWeight: weight.clamp(20, 300));
  }

  void setWeightUnit(String unit) {
    if (unit == state.selectedWeightUnit) {
      return;
    }

    state = state.copyWith(selectedWeightUnit: unit);
  }

  void setHeight(int height) {
    state = state.copyWith(selectedHeight: height.clamp(90, 250));
  }

  void decrementHeight() {
    setHeight(state.selectedHeight - 1);
  }

  void incrementHeight() {
    setHeight(state.selectedHeight + 1);
  }

  void setHeightUnit(String unit) {
    if (unit == state.selectedHeightUnit) {
      return;
    }

    state = state.copyWith(selectedHeightUnit: unit);
  }

  void setWeightGoal(String goal) {
    state = state.copyWith(selectedWeightGoal: goal);
  }

  void setDailyStepsGoal(int stepsGoal) {
    state = state.copyWith(selectedDailyStepsGoal: stepsGoal);
  }

  void setOtpDigit(int index, String value) {
    final digits = [...state.otpDigits];
    final numericValue = value.replaceAll(RegExp(r'\D'), '');
    digits[index] = numericValue.isEmpty ? '' : numericValue.substring(0, 1);
    state = state.copyWith(otpDigits: digits);
  }

  void fillOtpFromPaste(String value) {
    final pastedDigits = value.replaceAll(RegExp(r'\D'), '').split('');
    final digits = List<String>.filled(state.otpDigits.length, '');
    for (var index = 0; index < digits.length; index++) {
      digits[index] = index < pastedDigits.length ? pastedDigits[index] : '';
    }
    state = state.copyWith(otpDigits: digits);
  }

  void clearOtp() {
    state = state.copyWith(
      otpDigits: List<String>.filled(state.otpDigits.length, ''),
    );
  }

  Future<AuthActionResult> login({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isEmailAuthLoading: true);
    try {
      debugPrint('🔐 [Auth] Logging in user: $email');
      await _supabaseService.signIn(email: email, password: password);
      debugPrint('✅ [Auth] Login successful, sending welcome notification...');
      await NotificationService.sendWelcomeNotification();
      debugPrint('✅ [Auth] Welcome notification sent');
      return const AuthActionResult.success();
    } catch (e) {
      debugPrint('❌ [Auth] Login failed: $e');
      return AuthActionResult.failure('Login failed: ${e.toString()}');
    } finally {
      state = state.copyWith(isEmailAuthLoading: false);
    }
  }

  Future<AuthActionResult> signup({
    required String name,
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isEmailAuthLoading: true);
    try {
      final response = await _supabaseService.signUp(
        name: name,
        email: email,
        password: password,
      );
      if (response.session == null || response.user == null) {
        return const AuthActionResult.needsVerification();
      }

      await _supabaseService.ensureProfileExists(name: name);
      if (!_supabaseService.hasActiveUser) {
        return const AuthActionResult.failure(
          'Signup succeeded, but no active Supabase session was found. Please log in and try again.',
        );
      }

      state = state.copyWith(signupName: name);
      return const AuthActionResult.success();
    } catch (e) {
      return AuthActionResult.failure('Signup failed: ${e.toString()}');
    } finally {
      state = state.copyWith(isEmailAuthLoading: false);
    }
  }

  Future<AuthActionResult> continueWithGoogle() {
    return _runSocialAuth(_supabaseService.signInWithGoogle);
  }

  Future<AuthActionResult> continueWithApple() {
    return _runSocialAuth(_supabaseService.signInWithApple);
  }

  Future<AuthActionResult> verifySignupOtp({required String email}) async {
    if (!state.isOtpComplete) {
      return const AuthActionResult.failure(
        'Please enter the complete OTP code.',
      );
    }

    state = state.copyWith(isOtpVerifying: true);
    try {
      await _supabaseService.verifySignupOtp(
        email: email,
        token: state.otpCode,
      );
      await NotificationService.sendWelcomeNotification();
      return const AuthActionResult.success();
    } catch (e) {
      return AuthActionResult.failure(
        'OTP verification failed: ${e.toString()}',
      );
    } finally {
      state = state.copyWith(isOtpVerifying: false);
    }
  }

  Future<AuthActionResult> sendPasswordResetEmail({
    required String email,
  }) async {
    state = state.copyWith(isPasswordResetLoading: true);
    try {
      await _supabaseService.sendPasswordResetEmail(email: email);
      return const AuthActionResult.success();
    } catch (e) {
      return AuthActionResult.failure(
        'Failed to send reset link: ${e.toString()}',
      );
    } finally {
      state = state.copyWith(isPasswordResetLoading: false);
    }
  }

  Future<AuthActionResult> updatePassword({required String password}) async {
    state = state.copyWith(isPasswordUpdating: true);
    try {
      await _supabaseService.updatePassword(password: password);
      return const AuthActionResult.success();
    } catch (e) {
      return AuthActionResult.failure(
        'Failed to update password: ${e.toString()}',
      );
    } finally {
      state = state.copyWith(isPasswordUpdating: false);
    }
  }

  Future<AuthActionResult> saveOnboardingProfile() async {
    if (!state.hasSelectedGender) {
      return const AuthActionResult.failure('Please select your gender.');
    }

    state = state.copyWith(isProfileSaving: true);
    try {
      await _supabaseService.saveOnboardingProfile(
        name: state.signupName,
        gender: state.selectedGender,
        age: state.selectedAge,
        weight: state.selectedWeight,
        weightUnit: state.selectedWeightUnit,
        height: state.selectedHeight,
        heightUnit: state.selectedHeightUnit,
        weightGoal: state.selectedWeightGoal,
        dailyStepsGoal: state.selectedDailyStepsGoal,
      );
      await NotificationService.sendWelcomeNotification();
      return const AuthActionResult.success();
    } catch (e) {
      return AuthActionResult.failure(
        'Failed to save profile: ${e.toString()}',
      );
    } finally {
      state = state.copyWith(isProfileSaving: false);
    }
  }

  Future<bool> isCurrentProfileOnboardingComplete() async {
    final profile = await _supabaseService.getProfile();
    return _supabaseService.isProfileOnboardingComplete(profile);
  }

  Future<AuthActionResult> _runSocialAuth(
    Future<void> Function() signIn,
  ) async {
    if (state.isSocialAuthLoading) {
      return const AuthActionResult.failure(
        'Auth request already in progress.',
      );
    }

    state = state.copyWith(isSocialAuthLoading: true);
    try {
      await signIn();
      if (_supabaseService.hasActiveUser) {
        await _supabaseService.ensureProfileExists();
        return const AuthActionResult.success();
      }
      return const AuthActionResult.externalAuthStarted();
    } catch (e) {
      return AuthActionResult.failure('Sign in failed: ${e.toString()}');
    } finally {
      state = state.copyWith(isSocialAuthLoading: false);
    }
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AppAuthState>((ref) {
  return AuthNotifier(SupabaseService());
});
