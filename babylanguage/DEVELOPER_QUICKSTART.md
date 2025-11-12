# Developer Quick Start (Baby Language)

---

## 1) Create App Workspace
```bash
cd "c:\Trae Apps\BabySleepApp"
mkdir babylanguage
# Option A: copy existing Flutter app as a base
# Copy manually (Explorer) or via PowerShell robocopy
# robocopy "C:\Trae Apps\BabySleepApp\babysteps_app" "C:\Trae Apps\BabySleepApp\babylanguage\babylanguage_app" /E /XD build .dart_tool ios\Pods android\.gradle
```

Rename app in `pubspec.yaml`:
```yaml
name: babylanguage_app
description: Early language learning app for children 0–5 years
```

Add Firebase packages and run pub get:
```bash
flutter pub add firebase_core firebase_auth cloud_firestore firebase_storage firebase_messaging firebase_analytics google_sign_in
```

## 2) Firebase Setup
- Create project in Firebase Console: `baby-language`
- Add iOS/Android apps (bundle/package `com.babylanguage.app`)
- Place configs:
  - `android/app/google-services.json`
  - `ios/Runner/GoogleService-Info.plist`
- Configure FlutterFire:
```bash
dart pub global activate flutterfire_cli
flutterfire configure --project=baby-language --out=lib/firebase_options.dart
```

Initialize in `lib/main.dart`:
```dart
await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
```

## 3) App Changes
- Navigation: 2 tabs (Dashboard/Advice, Milestones); Settings from Home
- Create models: `language_milestone.dart`, `language_activity.dart`, `activity_log.dart`
- Create services (Firestore): `language_milestone_service.dart`, `activity_service.dart`, `progress_service.dart`
- Create screens: `milestone_detail_screen.dart`, `activity_detail_screen.dart`, `progress_dashboard_screen.dart`

## 4) Security & Indexes
- Add `firestore.rules` and `firestore.indexes.json` from this folder
```bash
firebase deploy --only firestore:rules
firebase deploy --only firestore:indexes
```

## 5) Run
```bash
flutter run
```

## Troubleshooting
- Ensure Google Services files are in platform folders
- Check Firebase project is active
- Verify network permissions and Android/iOS Gradle plugins applied
