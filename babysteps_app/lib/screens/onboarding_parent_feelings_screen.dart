import 'package:flutter/material.dart';
import 'package:babysteps_app/theme/app_theme.dart';
import 'package:babysteps_app/screens/onboarding_notifications_screen.dart';
import 'package:babysteps_app/screens/onboarding_concerns_reassurance_screen.dart';
import 'package:babysteps_app/utils/app_animations.dart';
import 'package:babysteps_app/widgets/onboarding_app_bar.dart';

class OnboardingParentFeelingsScreen extends StatelessWidget {
  const OnboardingParentFeelingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 24.0),
          child: Column(
            children: [
              OnboardingAppBar(
                onBackPressed: () {
                  Navigator.of(context).pushReplacementWithFade(
                    const OnboardingConcernsReassuranceScreen(),
                  );
                },
              ),
              const SizedBox(height: 16),
              const Spacer(),
              // Quote marks icon
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F2FC),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Text(
                    '💡',
                    style: TextStyle(fontSize: 36),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Headline
              const Text(
                'We Bet You\'ve',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1F2937),
                  height: 1.2,
                ),
                textAlign: TextAlign.center,
              ),
              const Text(
                'Thought This:',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primaryPurple,
                  height: 1.2,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),
              // Quote card
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F2FC),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryPurple.withOpacity(0.1),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const Text(
                      '"Am I the only one who ends each day wondering if I did enough?"',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        fontStyle: FontStyle.italic,
                        color: Color(0xFF1F2937),
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryPurple.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        '9 out of 10 parents say yes',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryPurple,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              // Promise
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: AppTheme.primaryPurple.withOpacity(0.3),
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryPurple,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.favorite,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'We get it — deeply',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1F2937),
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'BabySteps was built by parents who felt exactly the same way.',
                            style: TextStyle(
                              fontSize: 13,
                              color: Color(0xFF6B7280),
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              // CTA
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pushReplacementWithFade(
                      const OnboardingNotificationsScreen(),
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
                    'Let\'s Do This Together',
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
}
