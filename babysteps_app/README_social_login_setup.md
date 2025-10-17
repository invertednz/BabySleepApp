# Social Login Setup Guide

This guide covers the steps required to enable Google and Apple Sign-In for the BabySteps app using Supabase.

## Requirements

- A Supabase project with the `auth` schema enabled.
- Supabase CLI (optional, for configuration).
- Access to platform developer consoles:
  - Google Cloud Console
  - Apple Developer account (paid program required for Sign in with Apple)
- Updated `.env` file for the Flutter app with Supabase credentials and redirect URLs.

## 1. Configure Supabase Auth Providers

### 1.1 Google

1. In the Supabase dashboard, go to **Authentication → Providers**.
2. Enable **Google**.
3. Provide the **Client ID** and **Client Secret** obtained from the Google Cloud Console (see section 2).
4. Set the **Redirect URL** (e.g., `https://<your-supabase-project-ref>.supabase.co/auth/v1/callback`).
5. Save the configuration.

### 1.2 Apple

1. In the Supabase dashboard, go to **Authentication → Providers**.
2. Enable **Apple**.
3. Supply the following values from the Apple Developer portal:
   - **Services ID** (Client ID)
   - **Team ID**
   - **Key ID**
   - **Private Key** (.p8 file contents)
4. Set the **Redirect URL** (same format as Google; see section 2.2 for iOS-specific notes).
5. Save the configuration.

## 2. Create OAuth Credentials

### 2.1 Google Cloud Console

1. Visit [console.cloud.google.com](https://console.cloud.google.com/) and select your project (or create a new one).
2. Enable the **Google People API** (required for Google Sign-In).
3. Navigate to **APIs & Services → Credentials → Create Credentials → OAuth client ID**.
4. Choose **Web application** for Supabase.
5. Add **Authorized JavaScript origins**:
   - `https://<your-supabase-project-ref>.supabase.co`

6. Add **Authorized redirect URIs**:
   - `https://<your-supabase-project-ref>.supabase.co/auth/v1/callback`
   - For local development (optional): `http://localhost:3000/auth/v1/callback`

7. Copy the generated **Client ID** and **Client Secret** into Supabase.

#### 2.1.1 Flutter Web redirect (optional)

If you want to handle OAuth redirects directly in the Flutter web app (instead of the Supabase callback), add:
- `https://<your-web-origin>/.netlify/functions/auth-callback` (or equivalent) to your Google credentials and Supabase redirect URL. Adjust your hosting setup accordingly.

### 2.2 Apple Developer Portal

1. Log into [developer.apple.com/account](https://developer.apple.com/account/) with a paid developer account.
2. Go to **Certificates, IDs & Profiles → Identifiers → +** to register a new **Services ID** (e.g., `com.yourcompany.babysteps.web`).
3. Enable **Sign in with Apple** for the Services ID and configure:
   - Primary App ID: usually your iOS app bundle identifier.
   - Return URLs: `https://<your-supabase-project-ref>.supabase.co/auth/v1/callback`
4. Next, create a new **Keys** entry → enable **Sign in with Apple** → choose your primary App ID → generate the `.p8` key file. Record the **Team ID** and **Key ID**.
5. Upload the `.p8` key contents, Services ID, Team ID, and Key ID to Supabase.
6. For native iOS builds, update your Xcode project:
   - Enable **Sign in with Apple** under **Signing & Capabilities**.
   - Ensure the bundle identifier matches the App ID used above.

## 3. Configure Flutter App

### 3.1 Environment variables

In `babysteps_app/.env`, add the redirect URL you intend to use:

```env
SUPABASE_URL=https://<your-supabase-project-ref>.supabase.co
SUPABASE_ANON_KEY=your-anon-key
SUPABASE_REDIRECT_URL=https://<your-supabase-project-ref>.supabase.co/auth/v1/callback
```

For local testing with `localhost`, create a separate `.env.development` if needed and adjust `SUPABASE_REDIRECT_URL` accordingly.

### 3.2 Flutter setup

The code includes helper methods to initiate OAuth flows using Supabase's Flutter SDK. Ensure `supabase_flutter` is initialized in `main.dart` (already present).

#### Android

1. Update `android/app/src/main/AndroidManifest.xml` with the redirect scheme:

```xml
<activity
    android:name="com.supabase.flutter.supabase_flutter.SupabaseDeepLinkingActivity"
    android:exported="true">
    <intent-filter android:label="flutter_supabase_oauth">
        <action android:name="android.intent.action.VIEW" />
        <category android:name="android.intent.category.DEFAULT" />
        <category android:name="android.intent.category.BROWSABLE" />
        <data android:scheme="twigzsupabase" android:host="login" />
    </intent-filter>
</activity>
```

- Replace `twigzsupabase://login` with your chosen scheme/host (must match the Supabase redirect URL using custom scheme). For example, set `SUPABASE_REDIRECT_URL=twigzsupabase://login` for native flows.
- In Supabase, add the same redirect value under **Authentication → URL Configuration → Add Redirect URL**.
- Update `android/app/build.gradle` with the correct application ID if required by Google Sign-In (or use default).

#### iOS

1. Add URL types to `ios/Runner/Info.plist`:

```xml
<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleURLSchemes</key>
    <array>
      <string>twigzsupabase</string>
    </array>
  </dict>
</array>
```

2. Update `SUPABASE_REDIRECT_URL=twigzsupabase://login` (matching the scheme above) for native builds.
3. In Xcode, enable **Sign in with Apple** capability.

#### Web

- Ensure `SUPABASE_REDIRECT_URL` uses the hosted web URL, e.g., `https://app.babysteps.com/auth/callback`.
- Supabase will redirect back to this URL after OAuth; make sure your web hosting handles the redirection (Supabase Flutter SDK automatically parses when running inside the Flutter app).

## 4. Handling OAuth callbacks

The Flutter code uses `supabase_flutter`'s auth hooks which automatically handle redirects on the supported platforms. On web, the app reloads on the redirect URL; initialize Supabase early (already configured) so that `Supabase.instance.client.auth.currentUser` is populated after redirect.

## 5. Testing

1. **Web**: Run `flutter run -d chrome`; the Google button should open a new tab and redirect back.
2. **Android**: Install the app on a device/emulator with Google Play services. Confirm the custom scheme works.
3. **iOS/macOS**: Test Sign in with Apple on real hardware (Apple requires physical device for testing in most cases).
4. Verify the Supabase dashboard shows the new OAuth user entries.

## 6. Troubleshooting

- Ensure the redirect URLs match exactly between Supabase, your OAuth provider console, and the app environment variables.
- If sign-in seems to hang on web, check browser console for blocked popups; consider using `auth.signInWithOAuth` with `skipBrowserRedirect: true` and handle the returned URL using `url_launcher`.
- Apple Sign-In requires domains and return URLs to be verified in the Apple Developer portal; ensure you complete the verification steps.
- For Android, make sure the SHA-1 fingerprint is configured in Google Cloud if using Google Sign-In with OAuth 2.0 (create an Android OAuth client for the package ID with SHA-1). For pure Supabase web flow, this may not be necessary.

## 7. Resources

- Supabase Auth documentation: https://supabase.com/docs/guides/auth
- Supabase Flutter OAuth guide: https://supabase.com/docs/guides/auth/auth-helpers/flutter
- Google OAuth credentials: https://console.cloud.google.com/apis/credentials
- Apple Sign in: https://developer.apple.com/sign-in-with-apple/

---

Once providers are enabled and the environment variables are configured, the Flutter UI will offer "Continue with Google" and "Continue with Apple" buttons that trigger Supabase OAuth flows.
