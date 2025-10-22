# App Review Setup Guide

## Overview
The onboarding "Leave a Review" button (in `lib/screens/onboarding_thank_you_screen.dart`) uses the [`in_app_review`](https://pub.dev/packages/in_app_review) package. When pressed, it attempts to trigger the in-app review dialog; if that flow is unavailable it opens the platform store listing as a fallback.

## iOS Configuration

- **Add App Store ID**
  - Create/locate your app in App Store Connect and copy its numerical App Store ID (the digits at the end of the App Store URL).
  - Add the ID to your `.env` files (all environments that ship to iOS):
    ```bash
    APP_STORE_ID=1234567890
    ```
  - The value is read via `dotenv.env['APP_STORE_ID']` when calling `InAppReview.openStoreListing(appStoreId: ...)`.

- **Bundle settings**
  - Ensure `CFBundleIdentifier` in `ios/Runner/Info.plist` matches the identifier used in App Store Connect.
  - Confirm `Runner.xcodeproj` is configured with valid signing & provisioning so the build can be installed on devices.

- **Testing notes**
  - Apple only shows the review dialog on physical devices and rarely during development. Expect the fallback (App Store listing) while testing non-App-Store builds.
  - If the review dialog does not appear, verify `InAppReview.instance.isAvailable()` returns `false`, which is expected for debug builds.

## Android Configuration

- **Play Store listing**
  - The same button will call `requestReview()`; on Play Store builds, the Google Play in-app review API surfaces the native dialog.
  - If the dialog is unavailable, the package falls back to opening the Play Store listing via `openStoreListing()` using the application ID from `android/app/src/main/AndroidManifest.xml`.

- **Requirements**
  - Upload at least one build to the Play Console so Google Play can deliver the review flow.
  - The review dialog only appears on devices running a signed build installed via the Play Store (internal/closed/open tracks). For debug/dev builds, expect the fallback.

## General Tips

- **Dependency management**: Run `flutter pub get` after adding `in_app_review` to `pubspec.yaml`.
- **Environment loading**: Ensure `flutter_dotenv` loads the `.env` file before widgets request the review flow (already handled in app startup).
- **Error handling**: If neither review dialog nor store listing can launch, a SnackBar displays the error message. Monitor logs for further diagnostics.
