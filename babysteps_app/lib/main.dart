import 'package:babysteps_app/screens/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:babysteps_app/theme/app_theme.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:babysteps_app/config/supabase_config.dart';
import 'package:babysteps_app/services/mixpanel_service.dart';
import 'package:babysteps_app/providers/auth_provider.dart';
import 'package:babysteps_app/providers/baby_provider.dart';
import 'package:babysteps_app/providers/milestone_provider.dart';
import 'package:babysteps_app/providers/referral_provider.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final mixpanelService = MixpanelService();

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
      runApp(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          home: Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Text(
                  'Missing Supabase credentials. Please set SUPABASE_URL and SUPABASE_ANON_KEY in config.',
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
  } catch (e) {
    runApp(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Text(
                'Error initializing Supabase. Check your configuration and network.',
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
