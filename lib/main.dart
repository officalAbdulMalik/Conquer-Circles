import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:test_steps/core/theme/app_theme.dart';
import 'package:test_steps/features/auth/gender_selection_screen.dart';
import 'package:test_steps/features/auth/update_password_screen.dart';
import 'package:test_steps/services/supabase_service.dart';
import 'package:test_steps/services/subscription_service.dart';
import 'package:test_steps/widgets/shared/app_loading_screen.dart';
import 'screens/main_navigation.dart';
import 'screens/splash_screen.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  await Firebase.initializeApp();
  await Supabase.initialize(
    url: 'https://dpvelnjzovjhxgpjvtay.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRwdmVsbmp6b3ZqaHhncGp2dGF5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzEzOTI0MTAsImV4cCI6MjA4Njk2ODQxMH0.Nbssvqd6jnpXXQpdDCzfrPpx1k4CxBiP9FDQSVNkous',
    authOptions: const FlutterAuthClientOptions(
      authFlowType: AuthFlowType.pkce,
    ),
  );

  // TEMP: RevenueCat disabled on Android for APK test builds — re-enable
  // once Android products/API key are set up in RevenueCat.
  if (!Platform.isAndroid) {
    await initializeRevenueCat();
    _bindRevenueCatToAuth();
  }
  try {
    await NotificationService.initialize();
  } catch (e) {
    if (kDebugMode) {
      print('[Notifications] initialization failed: $e');
    }
  }

  runApp(ProviderScope(child: MyApp()));
}

Future<void> initializeRevenueCat() async {
  // Platform-specific API keys
  String apiKey;
  if (Platform.isIOS) {
    apiKey = 'appl_aZwriMjRvqqBNqHLKJvwlmnVGMw';
  } else if (Platform.isAndroid) {
    apiKey = 'test_YDZGDEqNkGYZabKuUVVljSMBBVC';
  } else {
    throw UnsupportedError('Platform not supported');
  }

  await Purchases.configure(PurchasesConfiguration(apiKey));
}

/// Keeps RevenueCat's identity in lock-step with Supabase auth: log the user
/// into RevenueCat on sign-in (so entitlements follow their account) and out on
/// sign-out. Entitlement changes are mirrored to `profiles.is_premium` by
/// SubscriptionService's customer-info listener.
void _bindRevenueCatToAuth() {
  final subscriptions = SubscriptionService()..init();
  final auth = Supabase.instance.client.auth;

  final currentUserId = auth.currentSession?.user.id;
  if (currentUserId != null) {
    subscriptions.login(currentUserId);
  }

  auth.onAuthStateChange.listen((data) {
    switch (data.event) {
      case AuthChangeEvent.signedIn:
        final id = data.session?.user.id;
        if (id != null) subscriptions.login(id);
        break;
      case AuthChangeEvent.signedOut:
        subscriptions.logout();
        break;
      default:
        break;
    }
  });
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final SupabaseService _service = SupabaseService();

  // Cached once so rebuilds / hot reloads don't re-subscribe (which would snap
  // the UI back to a loading spinner and re-navigate — looking like a restart).
  late final Stream<AuthState> _authStream =
      Supabase.instance.client.auth.onAuthStateChange;

  // The profile load is cached per signed-in user, so it is only recreated on
  // an actual login/logout — never on a plain rebuild or hot reload.
  String? _profileUserId;
  Future<Map<String, dynamic>?>? _profileFuture;

  Future<Map<String, dynamic>?> _profileFor(String userId) {
    if (_profileUserId != userId || _profileFuture == null) {
      _profileUserId = userId;
      _profileFuture = _loadSignedInProfile();
    }
    return _profileFuture!;
  }

  Future<Map<String, dynamic>?> _loadSignedInProfile() async {
    await _service.ensureProfileExists();
    return _service.getProfile();
  }

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(390, 850),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) => MaterialApp(
        title: 'Health Data',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: child,
      ),
      child: StreamBuilder<AuthState>(
        stream: _authStream,
        builder: (context, snapshot) {
          // Prefer the live session so a preserved snapshot after hot reload
          // still resolves immediately instead of showing the spinner.
          final session =
              Supabase.instance.client.auth.currentSession ??
              snapshot.data?.session;

          if (snapshot.connectionState == ConnectionState.waiting &&
              session == null) {
            return const AppLoadingScreen();
          }

          if (snapshot.data?.event == AuthChangeEvent.passwordRecovery) {
            return const UpdatePasswordScreen();
          }

          if (session != null) {
            return FutureBuilder<Map<String, dynamic>?>(
              future: _profileFor(session.user.id),
              builder: (context, profileSnapshot) {
                if (profileSnapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const AppLoadingScreen();
                }

                final profile = profileSnapshot.data;
                if (_service.isProfileOnboardingComplete(profile)) {
                  return const MainNavigation();
                }

                return const GenderSelectionScreen();
              },
            );
          } else {
            _profileUserId = null;
            _profileFuture = null;
            return const SplashScreen();
          }
        },
      ),
    );
  }
}
