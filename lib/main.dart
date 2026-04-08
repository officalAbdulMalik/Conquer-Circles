import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:test_steps/features/splash/screen/splash_screen.dart';
import 'package:test_steps/core/theme/app_theme.dart';
import 'screens/main_navigation.dart';
import 'services/notification_service.dart';

import 'package:purchases_flutter/purchases_flutter.dart';
import 'dart:io';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // await Firebase.initializeApp();
  await Supabase.initialize(
    url: 'https://dpvelnjzovjhxgpjvtay.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRwdmVsbmp6b3ZqaHhncGp2dGF5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzEzOTI0MTAsImV4cCI6MjA4Njk2ODQxMH0.Nbssvqd6jnpXXQpdDCzfrPpx1k4CxBiP9FDQSVNkous',
  );
  await initializeRevenueCat();
  // await NotificationService.initialize();

  runApp(ProviderScope(child: MyApp()));
}

Future<void> initializeRevenueCat() async {
  // Platform-specific API keys
  String apiKey;
  if (Platform.isIOS) {
    apiKey = 'test_YDZGDEqNkGYZabKuUVVljSMBBVC';
  } else if (Platform.isAndroid) {
    apiKey = 'test_YDZGDEqNkGYZabKuUVVljSMBBVC';
  } else {
    throw UnsupportedError('Platform not supported');
  }

  await Purchases.configure(PurchasesConfiguration(apiKey));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(390, 844),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) => MaterialApp(
        title: 'Health Data',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: child,
      ),
      child: StreamBuilder<AuthState>(
        stream: Supabase.instance.client.auth.onAuthStateChange,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          final session = snapshot.hasData ? snapshot.data!.session : null;
          if (session != null) {
            return const MainNavigation();
          } else {
            return const SplashScreen();
          }
        },
      ),
    );
  }
}
