import 'package:flutter/material.dart';
import 'package:babysteps_app/theme/app_theme.dart';
import 'package:babysteps_app/screens/onboarding_notifications_screen.dart';
import 'package:babysteps_app/screens/onboarding_parent_concerns_screen.dart';
import 'package:babysteps_app/screens/onboarding_welcome_screen.dart';
import 'package:babysteps_app/utils/app_animations.dart';
import 'package:babysteps_app/widgets/onboarding_app_bar.dart';

class OnboardingResultsScreen extends StatelessWidget {
  const OnboardingResultsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 40.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              OnboardingAppBar(
                onBackPressed: () {
                  Navigator.of(context).pushReplacementWithFade(
                    const OnboardingWelcomeScreen(),
                  );
                },
              ),
              const Spacer(),
              const Text(
                'Real Results.',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1F2937),
                  height: 1.2,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Real Parents.',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primaryPurple,
                  height: 1.2,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              _buildResultCard(
                '3x',
                'faster milestone achievement',
                'compared to traditional tracking',
              ),
              const SizedBox(height: 20),
              _buildResultCard(
                '87%',
                'sleep improvement',
                'within the first 2 weeks',
              ),
              const SizedBox(height: 20),
              _buildResultCard(
                '2.5h',
                'saved per week',
                'on parenting research',
              ),
              const SizedBox(height: 40),
              // Testimonial
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F2FC),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryPurple.withOpacity(0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: const [
                    Text(
                      '"BabySteps transformed how I parent. My daughter hit her milestones faster, and I finally feel confident in my decisions."',
                      style: TextStyle(
                        fontSize: 15,
                        fontStyle: FontStyle.italic,
                        color: Color(0xFF1F2937),
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 12),
                    Text(
                      '— Sarah M., mother of 2',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primaryPurple,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pushReplacementWithFade(
                      const OnboardingParentConcernsScreen(),
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
                    'I Want These Results',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
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

  Widget _buildResultCard(String number, String metric, String context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border.all(color: AppTheme.primaryPurple.withOpacity(0.3), width: 2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              number,
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w700,
                color: AppTheme.primaryPurple,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  metric,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  context,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
