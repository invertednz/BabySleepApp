import 'package:flutter/material.dart';
import 'package:babysteps_app/theme/app_theme.dart';
import 'package:babysteps_app/screens/onboarding_thank_you_screen.dart';
import 'package:babysteps_app/screens/onboarding_progress_preview_screen.dart';
import 'package:babysteps_app/screens/onboarding_baby_progress_screen.dart';
import 'package:babysteps_app/utils/app_animations.dart';
import 'package:babysteps_app/widgets/onboarding_app_bar.dart';
import 'package:provider/provider.dart';
import 'package:babysteps_app/providers/baby_provider.dart';
import 'dart:math' as math;

class OnboardingGrowthChartScreen extends StatelessWidget {
  const OnboardingGrowthChartScreen({super.key});

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
                  final babies = Provider.of<BabyProvider>(context, listen: false).babies;
                  if (babies.isNotEmpty) {
                    Navigator.of(context).pushReplacementWithFade(
                      OnboardingBabyProgressScreen(babies: babies),
                    );
                  } else {
                    Navigator.of(context).pushReplacementWithFade(
                      const OnboardingProgressPreviewScreen(),
                    );
                  }
                },
              ),
              const SizedBox(height: 8),
              const Spacer(),
              const Text(
                'Your Growth\nTrajectory',
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
                'Most parents see slow progress at first,\nthen exponential growth with BabySteps.',
                style: TextStyle(
                  fontSize: 16,
                  color: AppTheme.textSecondary,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              // Growth chart
              Container(
                height: 250,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F2FC),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: CustomPaint(
                  painter: GrowthChartPainter(),
                  child: Container(),
                ),
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildLegendItem(Colors.grey.shade400, 'Without BabySteps'),
                  const SizedBox(width: 20),
                  _buildLegendItem(AppTheme.primaryPurple, 'With BabySteps'),
                ],
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pushReplacementWithFade(
                      const OnboardingThankYouScreen(),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryPurple,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'I\'m Ready to Grow',
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

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 3,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }
}

class GrowthChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    // Without BabySteps - linear slow growth
    paint.color = Colors.grey.shade400;
    final pathWithout = Path();
    pathWithout.moveTo(0, size.height);
    for (int i = 0; i <= 100; i++) {
      final x = (i / 100) * size.width;
      final y = size.height - (i / 100) * size.height * 0.4;
      pathWithout.lineTo(x, y);
    }
    canvas.drawPath(pathWithout, paint);

    // With BabySteps - slow start, then rapid exponential growth after 1/3
    paint.color = AppTheme.primaryPurple;
    final pathWith = Path();
    pathWith.moveTo(0, size.height);
    for (int i = 0; i <= 100; i++) {
      final x = (i / 100) * size.width;
      final progress = i / 100;
      
      double y;
      if (progress < 0.33) {
        // First third: very slow linear growth
        final slowProgress = progress / 0.33;
        y = size.height - (slowProgress * 0.15 * size.height);
      } else {
        // After first third: rapid exponential growth
        final fastProgress = (progress - 0.33) / 0.67;
        final exponentialProgress = math.pow(fastProgress, 1.8);
        y = size.height - (0.15 * size.height + exponentialProgress * 0.75 * size.height);
      }
      
      pathWith.lineTo(x, y);
    }
    canvas.drawPath(pathWith, paint);

    // Add dots at key points
    final dotPaint = Paint()..style = PaintingStyle.fill;
    
    // Start point
    dotPaint.color = AppTheme.primaryPurple;
    canvas.drawCircle(Offset(0, size.height), 6, dotPaint);
    
    // End point
    canvas.drawCircle(Offset(size.width, size.height * 0.1), 6, dotPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
