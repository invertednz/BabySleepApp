import 'package:babysteps_app/screens/login_screen.dart';
import 'package:babysteps_app/screens/splash_screen.dart';
import 'package:babysteps_app/screens/app_container.dart';
import 'package:babysteps_app/screens/onboarding_baby_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:babysteps_app/theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:babysteps_app/config/supabase_config.dart';
import 'package:babysteps_app/services/supabase_service.dart';
import 'package:babysteps_app/services/mixpanel_service.dart';
import 'package:babysteps_app/providers/auth_provider.dart';
import 'package:babysteps_app/providers/baby_provider.dart';
import 'package:babysteps_app/providers/milestone_provider.dart';
import 'package:babysteps_app/providers/referral_provider.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final mixpanelService = MixpanelService();

  // Load environment variables
  try {
    await dotenv.load(fileName: ".env");
    // Helpful log to confirm dotenv loaded on web
    // ignore: avoid_print
    print('dotenv loaded: .env');
  } catch (e) {
    // ignore: avoid_print
    print('Failed to load .env: $e');
    runApp(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Text(
                'Failed to load .env file. Ensure babysteps_app/.env exists and is listed under flutter->assets in pubspec.yaml.',
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ),
    );
    return;
  }

  // Set preferred orientations
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));

  // Initialize Supabase
  try {
    final url = SupabaseConfig.supabaseUrl;
    final anonKey = SupabaseConfig.supabaseAnonKey;
    if (url.isEmpty || anonKey.isEmpty) {
      // ignore: avoid_print
      print('Supabase env missing: SUPABASE_URL or SUPABASE_ANON_KEY is empty');
      runApp(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          home: Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Text(
                  'Missing Supabase credentials. Please set SUPABASE_URL and SUPABASE_ANON_KEY in .env.',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ),
      );
      return;
    }

    await Supabase.initialize(
      url: url,
      anonKey: anonKey,
    );
    // ignore: avoid_print
    print('Supabase initialized successfully');
  } catch (e) {
    // ignore: avoid_print
    print('Error initializing Supabase: $e');
    runApp(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Text(
                'Error initializing Supabase. Check your .env values and network. Details in console.',
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ),
    );
    return;
  }

  await mixpanelService.initialize();
  mixpanelService.trackEvent('App Launched');

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()..initialize()),
        ChangeNotifierProvider(create: (_) => BabyProvider()..initialize()),
        ChangeNotifierProvider(create: (_) => MilestoneProvider()..loadMilestones()),
        ChangeNotifierProvider(create: (_) => ReferralProvider()),
      ],
      child: const BabyStepsApp(),
    ),
  );
}

class BabyStepsApp extends StatelessWidget {
  const BabyStepsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BabySteps',
      theme: AppTheme.lightTheme,
      home: const SplashScreen(),
      debugShowCheckedModeBanner: false,
      navigatorKey: GlobalKey<NavigatorState>(),
    );
  }
}
