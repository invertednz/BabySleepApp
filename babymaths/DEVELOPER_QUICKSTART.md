# Developer Quick Start Guide

Get up and running with Baby Maths development in 30 minutes.

---

## Prerequisites

- Flutter SDK (3.0+)
- Dart SDK (3.0+)
- Supabase CLI installed
- Git
- IDE (VS Code or Android Studio recommended)
- OpenAI API key (for AI features)
- iOS: Xcode 14+ and CocoaPods
- Android: Android Studio and Android SDK

---

## Step 1: Clone and Setup (5 minutes)

### 1.1 Create Project Directory
```bash
cd "c:\Trae Apps\BabySleepApp"
mkdir babymaths
cd babymaths
```

### 1.2 Copy Existing App
```bash
# Copy the entire babysteps_app to babymaths_app
cp -r ../babysteps_app ./babymaths_app
cd babymaths_app
```

### 1.3 Update pubspec.yaml
```yaml
name: babymaths_app
description: Early mathematics learning app for children 0-5 years

environment:
  sdk: '>=3.0.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter
  
  # State Management
  provider: ^6.0.5
  
  # Supabase (Backend)
  supabase_flutter: ^2.0.0
  
  # UI Components
  flutter_feather_icons: ^2.0.0
  
  # Charts
  fl_chart: ^0.65.0
  
  # Utilities
  intl: ^0.18.0
  shared_preferences: ^2.2.0
  
  # Analytics
  mixpanel_flutter: ^2.0.0
  
  # Other existing dependencies...

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.0
```

### 1.4 Install Dependencies
```bash
flutter pub get
```

---

## Step 2: Firebase Setup (10 minutes)

### 2.1 Create Firebase Project
1. Go to https://console.firebase.google.com
2. Create project: `baby-maths`
3. Add iOS and Android apps (bundle/package `com.babymaths.app`)
4. Download configs: `GoogleService-Info.plist` (iOS) and `google-services.json` (Android)

### 2.2 Configure Flutter with FlutterFire
```bash
dart pub global activate flutterfire_cli
flutterfire configure --project=baby-maths --out=lib/firebase_options.dart
```

### 2.3 Add Firebase Packages
Add to `pubspec.yaml` and run `flutter pub get`:
```
firebase_core, firebase_auth, cloud_firestore, firebase_storage, firebase_messaging, firebase_analytics
```

### 2.4 Initialize Firebase
In `lib/main.dart`:
```dart
await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
```

See `FIREBASE_SETUP.md` for detailed steps.

---

## Step 3: Code Cleanup (5 minutes)

### 3.1 Delete Unnecessary Screens
```bash
# From lib/screens/ directory
rm sleep_schedule_screen.dart
rm diary_screen.dart
rm concerns_screen.dart
rm focus_screen.dart
rm onboarding_sleep_screen.dart
rm onboarding_feeding_screen.dart
rm onboarding_diaper_screen.dart
# ... (see page_migration_map.md for complete list)
```

### 3.2 Update main.dart
```dart
// lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await dotenv.load();
  
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );
  
  runApp(const BabyMathsApp());
}

class BabyMathsApp extends StatelessWidget {
  const BabyMathsApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => BabyProvider()),
        ChangeNotifierProvider(create: (_) => MilestoneProvider()),
        ChangeNotifierProvider(create: (_) => ActivityProvider()),
      ],
      child: MaterialApp(
        title: 'Baby Maths',
        theme: AppTheme.lightTheme,
        home: const SplashScreen(),
      ),
    );
  }
}
```

---

## Step 4: Create Core Models (5 minutes)

### 4.1 MathsMilestone Model
Create `lib/models/maths_milestone.dart`:
```dart
class MathsMilestone {
  final String id;
  final String category;
  final String title;
  final String description;
  final int ageMonthsMin;
  final int ageMonthsMax;
  final int difficultyLevel;
  final List<MathsActivity> activities;
  final List<String> indicators;
  final List<String> nextSteps;
  
  MathsMilestone({
    required this.id,
    required this.category,
    required this.title,
    required this.description,
    required this.ageMonthsMin,
    required this.ageMonthsMax,
    this.difficultyLevel = 1,
    required this.activities,
    required this.indicators,
    required this.nextSteps,
  });
  
  factory MathsMilestone.fromJson(Map<String, dynamic> json) {
    return MathsMilestone(
      id: json['id'],
      category: json['category'],
      title: json['title'],
      description: json['description'],
      ageMonthsMin: json['age_months_min'],
      ageMonthsMax: json['age_months_max'],
      difficultyLevel: json['difficulty_level'] ?? 1,
      activities: (json['activities'] as List)
          .map((a) => MathsActivity.fromJson(a))
          .toList(),
      indicators: List<String>.from(json['indicators'] ?? []),
      nextSteps: List<String>.from(json['next_steps'] ?? []),
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'category': category,
      'title': title,
      'description': description,
      'age_months_min': ageMonthsMin,
      'age_months_max': ageMonthsMax,
      'difficulty_level': difficultyLevel,
      'activities': activities.map((a) => a.toJson()).toList(),
      'indicators': indicators,
      'next_steps': nextSteps,
    };
  }
}
```

### 4.2 MathsActivity Model
Create `lib/models/maths_activity.dart`:
```dart
class MathsActivity {
  final String title;
  final int durationMinutes;
  final List<String> materials;
  final List<String> instructions;
  final List<String> variations;
  final List<String> tips;
  
  MathsActivity({
    required this.title,
    required this.durationMinutes,
    required this.materials,
    required this.instructions,
    required this.variations,
    required this.tips,
  });
  
  factory MathsActivity.fromJson(Map<String, dynamic> json) {
    return MathsActivity(
      title: json['title'],
      durationMinutes: json['duration_minutes'],
      materials: List<String>.from(json['materials'] ?? []),
      instructions: List<String>.from(json['instructions'] ?? []),
      variations: List<String>.from(json['variations'] ?? []),
      tips: List<String>.from(json['tips'] ?? []),
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'duration_minutes': durationMinutes,
      'materials': materials,
      'instructions': instructions,
      'variations': variations,
      'tips': tips,
    };
  }
}
```

### 4.3 ActivityLog Model
Create `lib/models/activity_log.dart`:
```dart
class ActivityLog {
  final String? id;
  final String babyId;
  final String userId;
  final String? milestoneId;
  final String activityTitle;
  final String activityCategory;
  final DateTime completedAt;
  final int? durationMinutes;
  final int? engagementLevel;
  final String? notes;
  
  ActivityLog({
    this.id,
    required this.babyId,
    required this.userId,
    this.milestoneId,
    required this.activityTitle,
    required this.activityCategory,
    required this.completedAt,
    this.durationMinutes,
    this.engagementLevel,
    this.notes,
  });
  
  factory ActivityLog.fromJson(Map<String, dynamic> json) {
    return ActivityLog(
      id: json['id'],
      babyId: json['baby_id'],
      userId: json['user_id'],
      milestoneId: json['milestone_id'],
      activityTitle: json['activity_title'],
      activityCategory: json['activity_category'],
      completedAt: DateTime.parse(json['completed_at']),
      durationMinutes: json['duration_minutes'],
      engagementLevel: json['engagement_level'],
      notes: json['notes'],
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'baby_id': babyId,
      'user_id': userId,
      'milestone_id': milestoneId,
      'activity_title': activityTitle,
      'activity_category': activityCategory,
      'completed_at': completedAt.toIso8601String(),
      'duration_minutes': durationMinutes,
      'engagement_level': engagementLevel,
      'notes': notes,
    };
  }
}
```

---

## Step 5: Create Services (5 minutes)

### 5.1 MathsMilestoneService
Create `lib/services/maths_milestone_service.dart`:
```dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/maths_milestone.dart';

class MathsMilestoneService {
  final _supabase = Supabase.instance.client;
  
  Future<List<MathsMilestone>> fetchMilestonesByAge(int ageMonths) async {
    final response = await _supabase
        .from('maths_milestones')
        .select()
        .lte('age_months_min', ageMonths)
        .gte('age_months_max', ageMonths)
        .order('category')
        .order('sort_order');
    
    return (response as List)
        .map((json) => MathsMilestone.fromJson(json))
        .toList();
  }
  
  Future<List<MathsMilestone>> fetchMilestonesByCategory(String category) async {
    final response = await _supabase
        .from('maths_milestones')
        .select()
        .eq('category', category)
        .order('age_months_min');
    
    return (response as List)
        .map((json) => MathsMilestone.fromJson(json))
        .toList();
  }
  
  Future<MathsMilestone> fetchMilestoneById(String id) async {
    final response = await _supabase
        .from('maths_milestones')
        .select()
        .eq('id', id)
        .single();
    
    return MathsMilestone.fromJson(response);
  }
}
```

### 5.2 ActivityService
Create `lib/services/activity_service.dart`:
```dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/activity_log.dart';

class ActivityService {
  final _supabase = Supabase.instance.client;
  
  Future<bool> logActivity(ActivityLog log) async {
    try {
      await _supabase
          .from('activity_logs')
          .insert(log.toJson());
      
      // Update streak
      await _supabase.functions.invoke(
        'update-streak',
        body: {'baby_id': log.babyId},
      );
      
      return true;
    } catch (e) {
      print('Error logging activity: $e');
      return false;
    }
  }
  
  Future<List<ActivityLog>> fetchActivityLogs(
    String babyId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    var query = _supabase
        .from('activity_logs')
        .select()
        .eq('baby_id', babyId);
    
    if (startDate != null) {
      query = query.gte('completed_at', startDate.toIso8601String());
    }
    if (endDate != null) {
      query = query.lte('completed_at', endDate.toIso8601String());
    }
    
    final response = await query.order('completed_at', ascending: false);
    
    return (response as List)
        .map((json) => ActivityLog.fromJson(json))
        .toList();
  }
}
```

---

## Step 6: Test Basic Functionality (5 minutes)

### 6.1 Create Test Screen
Create `lib/screens/test_screen.dart`:
```dart
import 'package:flutter/material.dart';
import '../services/maths_milestone_service.dart';

class TestScreen extends StatefulWidget {
  @override
  _TestScreenState createState() => _TestScreenState();
}

class _TestScreenState extends State<TestScreen> {
  final _service = MathsMilestoneService();
  List<dynamic> _milestones = [];
  bool _loading = false;
  
  Future<void> _loadMilestones() async {
    setState(() => _loading = true);
    try {
      final milestones = await _service.fetchMilestonesByAge(24);
      setState(() {
        _milestones = milestones;
        _loading = false;
      });
    } catch (e) {
      print('Error: $e');
      setState(() => _loading = false);
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Test Milestones')),
      body: _loading
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _milestones.length,
              itemBuilder: (context, index) {
                final milestone = _milestones[index];
                return ListTile(
                  title: Text(milestone.title),
                  subtitle: Text(milestone.category),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _loadMilestones,
        child: Icon(Icons.refresh),
      ),
    );
  }
}
```

### 6.2 Run Test
```bash
flutter run
```

Navigate to test screen and tap refresh to verify database connection.

---

## Next Steps

Now that basic setup is complete, follow the implementation checklist:

1. **Phase 1 Tasks** (see implementation_checklist.md)
   - Complete file deletion
   - Update branding
   - Modify Baby model
   
2. **Phase 2 Tasks**
   - Create remaining models
   - Create remaining services
   - Write unit tests

3. **Phase 3 Tasks**
   - Write milestone content
   - Populate database

4. **Continue through Phase 9**
   - Follow checklist step by step

---

## Useful Commands

### Flutter
```bash
# Run app
flutter run

# Run tests
flutter test

# Build APK
flutter build apk

# Build iOS
flutter build ios
```

### Supabase
```bash
# Start local Supabase
supabase start

# Stop local Supabase
supabase stop

# Push migrations
supabase db push

# Generate types
supabase gen types typescript --local > lib/supabase_types.ts
```

### Git
```bash
# Create feature branch
git checkout -b feature/home-screen-redesign

# Commit changes
git add .
git commit -m "Implement home screen redesign"

# Push
git push origin feature/home-screen-redesign
```

---

## Troubleshooting

### Issue: Flutter dependencies conflict
**Solution:** Run `flutter pub upgrade --major-versions`

### Issue: Supabase connection fails
**Solution:** 
1. Check .env file has correct URL and key
2. Verify project is not paused on Supabase dashboard
3. Check internet connection

### Issue: Database queries return empty
**Solution:**
1. Verify migrations ran: `supabase db reset`
2. Check RLS policies allow access
3. Verify JWT token is being sent

### Issue: Hot reload not working
**Solution:** Stop app and run `flutter clean && flutter pub get`

---

## Resources

- [Flutter Documentation](https://docs.flutter.dev)
- [Supabase Documentation](https://supabase.com/docs)
- [Project Planning Docs](./mathsplan.md)
- [Implementation Checklist](./implementation_checklist.md)
- [API Specifications](./api_specifications.md)

---

## Support

For questions during development:
- Check existing documentation in `/babymaths/` folder
- Review BabySleepApp code for patterns
- Supabase Discord for backend questions
- Flutter Discord for UI questions

---

**You're ready to start building! 🚀**
