# Firebase Setup (Baby Language)

## 1) Create Firebase Project
- Console → New project `baby-language`
- Enable Analytics (optional)

## 2) Add iOS & Android Apps
- Bundle/package: `com.babylanguage.app`
- Download configs:
  - `android/app/google-services.json`
  - `ios/Runner/GoogleService-Info.plist`

## 3) FlutterFire Configure
```bash
dart pub global activate flutterfire_cli
flutterfire configure --project=baby-language --out=lib/firebase_options.dart
```

## 4) Packages
```bash
flutter pub add firebase_core firebase_auth cloud_firestore firebase_storage firebase_messaging firebase_analytics google_sign_in
```

## 5) Initialize
```dart
await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
```

## 6) Firestore Structure
- Collections: `babies`, `language_milestones`, `activity_logs`, `milestone_completions`, `daily_activity_suggestions`, `weekly_progress_summaries`, `user_streaks`

## 7) Security Rules & Indexes
- See `firestore.rules` and `firestore.indexes.json`
```bash
firebase deploy --only firestore:rules
firebase deploy --only firestore:indexes
```

## 8) Cloud Functions
- Implement HTTPS functions:
  - `generateDailyActivities`, `generateWeeklyAdvice`, `calculateProgressMetrics`, `updateStreak`, `logActivity`, `completeMilestone`
- Set env:
```bash
firebase functions:config:set openai.key="sk-xxx"
```
- Deploy:
```bash
firebase deploy --only functions
```
