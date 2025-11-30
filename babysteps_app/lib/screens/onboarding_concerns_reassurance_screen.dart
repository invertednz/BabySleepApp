import 'package:flutter/material.dart';
import 'package:babysteps_app/theme/app_theme.dart';
import 'package:babysteps_app/screens/onboarding_parent_concerns_screen.dart';
import 'package:babysteps_app/screens/onboarding_parent_feelings_screen.dart';
import 'package:babysteps_app/utils/app_animations.dart';
import 'package:babysteps_app/widgets/onboarding_app_bar.dart';

class OnboardingConcernsReassuranceScreen extends StatelessWidget {
  final String? selectedConcernLabel;

  const OnboardingConcernsReassuranceScreen({
    super.key,
    this.selectedConcernLabel,
  });

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
                    const OnboardingParentConcernsScreen(),
                  );
                },
              ),
              const SizedBox(height: 20),
              const Spacer(),
              // Big stat with ring
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppTheme.primaryPurple.withOpacity(0.2),
                        width: 8,
                      ),
                    ),
                  ),
                  Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: SweepGradient(
                        startAngle: -0.5,
                        endAngle: 4.7, // ~74% of circle
                        colors: [
                          AppTheme.primaryPurple,
                          AppTheme.primaryPurple,
                          AppTheme.primaryPurple.withOpacity(0.0),
                        ],
                        stops: const [0.0, 0.74, 0.74],
                      ),
                    ),
                    child: Container(
                      margin: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                      ),
                      child: const Center(
                        child: Text(
                          '74%',
                          style: TextStyle(
                            fontSize: 42,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.primaryPurple,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              // Headline
              const Text(
                'You\'re Not Alone.',
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1F2937),
                  height: 1.2,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: const TextStyle(
                    fontSize: 17,
                    color: Color(0xFF6B7280),
                    height: 1.5,
                  ),
                  children: [
                    const TextSpan(text: 'Nearly '),
                    TextSpan(
                      text: '3 in 4 parents',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primaryPurple,
                      ),
                    ),
                    const TextSpan(text: ' tell us their biggest worry is '),
                    TextSpan(
                      text: selectedConcernLabel ?? 'exactly what you just chose',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primaryPurple,
                      ),
                    ),
                    const TextSpan(text: '. You\'re in very good company.'),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              // Social proof cards
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F2FC),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryPurple.withOpacity(0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: AppTheme.primaryPurple.withOpacity(0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: Text('🤗', style: TextStyle(fontSize: 22)),
                          ),
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'You\'ve already taken the first step',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF1F2937),
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Naming your concerns is powerful',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF6B7280),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(height: 1, color: Color(0xFFE5E7EB)),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: AppTheme.primaryPurple.withOpacity(0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: Text('✨', style: TextStyle(fontSize: 22)),
                          ),
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'We\'ll turn these into a plan',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF1F2937),
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Personalized guidance, not generic tips',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF6B7280),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
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
                      const OnboardingParentFeelingsScreen(),
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
                    'I\'m Ready',
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
