import 'package:flutter/material.dart';
import 'package:babysteps_app/theme/app_theme.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

enum LegalDocumentType { terms, privacy }

class LegalScreen extends StatelessWidget {
  final LegalDocumentType documentType;

  const LegalScreen({required this.documentType, super.key});

  String get _title => documentType == LegalDocumentType.terms
      ? 'Terms of Service'
      : 'Privacy Policy';

  String get _content => documentType == LegalDocumentType.terms
      ? _termsOfService
      : _privacyPolicy;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(_title),
        backgroundColor: AppTheme.background,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
      ),
      body: Markdown(
        data: _content,
        padding: const EdgeInsets.all(20),
        styleSheet: MarkdownStyleSheet(
          h1: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
          h2: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
          h3: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
          p: const TextStyle(
            fontSize: 15,
            height: 1.6,
            color: AppTheme.textSecondary,
          ),
          listBullet: const TextStyle(
            fontSize: 15,
            color: AppTheme.textSecondary,
          ),
        ),
      ),
    );
  }
}

const _termsOfService = '''
# Terms of Service

**Last Updated: February 2026**

Welcome to BabySteps. By using our app, you agree to these terms.

## 1. Acceptance of Terms

By accessing or using BabySteps ("the App"), you agree to be bound by these Terms of Service. If you do not agree, please do not use the App.

## 2. Description of Service

BabySteps is a baby development tracking application that helps parents monitor milestones, growth, and daily activities. The App provides informational content and tracking tools but **does not provide medical advice**.

## 3. Account Registration

- You must provide accurate and complete information when creating an account.
- You are responsible for maintaining the security of your account credentials.
- You must be at least 16 years of age to create an account.
- You are responsible for all activity that occurs under your account.

## 4. User Content

- You retain ownership of any content you submit (photos, notes, diary entries).
- You grant us a limited licence to store and display your content back to you within the App.
- We do not share your content with other users or third parties without your consent.

## 5. Acceptable Use

You agree not to:
- Use the App for any unlawful purpose
- Attempt to gain unauthorised access to the App or its systems
- Upload malicious content or interfere with the App's operation
- Use the App to collect data about other users

## 6. Medical Disclaimer

BabySteps is **not a medical device** and does not provide medical advice, diagnosis, or treatment. Milestone information and developmental guidance are for informational purposes only. Always consult a qualified healthcare professional for medical concerns about your child.

## 7. Subscriptions and Payments

- Some features may require a paid subscription.
- Subscriptions automatically renew unless cancelled at least 24 hours before the end of the current period.
- You can manage and cancel subscriptions through your device's app store settings.
- Refunds are handled according to the policies of the Apple App Store or Google Play Store.

## 8. Intellectual Property

The App, including its design, features, and content (excluding user content), is owned by BabySteps and protected by intellectual property laws. You may not copy, modify, or distribute any part of the App.

## 9. Termination

We may suspend or terminate your account if you violate these terms. You may delete your account at any time through the App settings. Upon deletion, your data will be removed in accordance with our Privacy Policy.

## 10. Limitation of Liability

To the maximum extent permitted by law, BabySteps shall not be liable for any indirect, incidental, or consequential damages arising from your use of the App.

## 11. Changes to Terms

We may update these terms from time to time. We will notify you of material changes through the App. Continued use after changes constitutes acceptance.

## 12. Contact Us

If you have questions about these terms, please contact us at support@babystepsapp.com.
''';

const _privacyPolicy = '''
# Privacy Policy

**Last Updated: February 2026**

Your privacy is important to us. This policy explains how BabySteps collects, uses, and protects your information.

## 1. Information We Collect

### Information You Provide
- **Account information**: Email address, password
- **Baby profiles**: Name, date of birth, gender
- **Tracking data**: Milestone completions, sleep logs, feeding records, diary entries, growth measurements
- **Photos**: Images you upload for your baby's profile or diary

### Information Collected Automatically
- **Device information**: Device type, operating system version
- **Usage data**: Features used, screen views (anonymised analytics via Mixpanel)
- **Crash reports**: Technical information to help us fix bugs

## 2. How We Use Your Information

We use your information to:
- Provide and improve the App's features
- Store and display your baby's development data
- Generate personalised milestone recommendations
- Send notifications you have opted into (e.g. milestone reminders)
- Analyse usage patterns to improve the App (anonymised)
- Provide customer support

## 3. Data Storage and Security

- Your data is stored securely using Supabase (hosted on AWS infrastructure).
- We use industry-standard encryption for data in transit (TLS) and at rest.
- We do not sell your personal data to third parties.
- Access to your data is restricted to authorised personnel only.

## 4. Third-Party Services

We use the following third-party services:
- **Supabase**: Database and authentication (stores your account and baby data)
- **Mixpanel**: Anonymised analytics to understand how the App is used
- **Google Sign-In / Apple Sign-In**: Optional authentication providers
- **Google AI (Gemini)**: Powers the AI chat assistant (conversation data is not stored by Google)

## 5. Data Sharing

We do **not** sell, rent, or share your personal data with third parties for marketing purposes. We may share data only:
- With service providers who help operate the App (listed above)
- If required by law or legal process
- To protect the rights and safety of our users

## 6. Children's Privacy

BabySteps is designed for parents and carers to track their children's development. We do not knowingly collect data directly from children. All data is entered and managed by the parent or carer account holder.

## 7. Your Rights

You have the right to:
- **Access** your personal data stored in the App
- **Correct** inaccurate information in your profile or baby data
- **Delete** your account and all associated data
- **Export** your data (contact support for assistance)
- **Withdraw consent** for optional data processing at any time

## 8. Data Retention

- Your data is retained for as long as your account is active.
- Upon account deletion, your data is permanently removed within 30 days.
- Anonymised analytics data may be retained for product improvement.

## 9. Cookies and Tracking

The App does not use cookies. We use Mixpanel for anonymised usage analytics, which you can opt out of in the App settings.

## 10. Changes to This Policy

We may update this policy from time to time. We will notify you of material changes through the App. The "Last Updated" date at the top indicates the most recent revision.

## 11. Contact Us

If you have questions about this privacy policy or your data, please contact us at privacy@babystepsapp.com.
''';
