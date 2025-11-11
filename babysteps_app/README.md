# babysteps_app

A new Flutter project.

## Mixpanel Analytics Setup

1. **Install dependencies**
   Run `flutter pub get` after updating `pubspec.yaml` with the Mixpanel package.
2. **Configure environment variables**
   Copy `.env.example` to `.env` and fill in `MIXPANEL_TOKEN` with your Mixpanel project token.
3. **Build and run**
   Launch the app. It initializes Mixpanel in `lib/main.dart`, identifies users, and tracks auth/plan events via `lib/providers/auth_provider.dart`.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
