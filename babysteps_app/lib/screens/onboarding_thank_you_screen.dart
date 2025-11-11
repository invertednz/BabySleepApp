import 'package:flutter/material.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:babysteps_app/theme/app_theme.dart';
import 'package:babysteps_app/widgets/onboarding_app_bar.dart';
import 'package:babysteps_app/utils/app_animations.dart';
import 'package:babysteps_app/screens/onboarding_growth_chart_screen.dart';
import 'package:babysteps_app/screens/onboarding_trial_offer_screen.dart';

class OnboardingThankYouScreen extends StatelessWidget {
  const OnboardingThankYouScreen({super.key});

  Future<void> _launchReviewFlow(BuildContext context) async {
    final inAppReview = InAppReview.instance;
    final appStoreId = dotenv.env['APP_STORE_ID'];
    try {
      if (await inAppReview.isAvailable()) {
        await inAppReview.requestReview();
      } else {
        if (appStoreId != null && appStoreId.isNotEmpty) {
          await inAppReview.openStoreListing(appStoreId: appStoreId);
        } else {
          await inAppReview.openStoreListing();
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to open review page: $e'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              OnboardingAppBar(
                onBackPressed: () {
                  Navigator.of(context).pushReplacementWithFade(
                    const OnboardingGrowthChartScreen(),
                  );
                },
              ),
              const SizedBox(height: 8),
              const Spacer(),
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: AppTheme.primaryPurple.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.favorite,
                  size: 50,
                  color: AppTheme.primaryPurple,
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                'Thank You for\nTrusting Us',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                  height: 1.2,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Text(
                'Together, we\'re giving your baby the best possible start in life.',
                style: TextStyle(
                  fontSize: 18,
                  color: AppTheme.textSecondary,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F2FC),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: const [
                    Text(
                      '⏰',
                      style: TextStyle(fontSize: 40),
                    ),
                    SizedBox(height: 12),
                    Text(
                      'The First 1,000 Days Are Critical',
                      style: TextStyle(
                        fontSize: 18,
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w700,
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Research shows that 90% of brain development happens before age 5. Every day matters—and you\'re taking action right now.',
                      style: TextStyle(
                        fontSize: 15,
                        color: AppTheme.textSecondary,
                        height: 1.6,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _launchReviewFlow(context),
                  icon: const Icon(Icons.star, size: 24),
                  label: const Text(
                    'Leave a Review',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFBBF24),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pushReplacementWithFade(
                      const OnboardingTrialOfferScreen(),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryPurple,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Continue',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
