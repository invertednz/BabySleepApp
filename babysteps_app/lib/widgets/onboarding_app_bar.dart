import 'package:flutter/material.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:babysteps_app/theme/app_theme.dart';

/// Reusable app bar for onboarding screens with back arrow
class OnboardingAppBar extends StatelessWidget {
  final VoidCallback? onBackPressed;
  final bool showBackButton;

  const OnboardingAppBar({
    super.key,
    this.onBackPressed,
    this.showBackButton = true,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          if (showBackButton)
            GestureDetector(
              onTap: onBackPressed ?? () => Navigator.of(context).pop(),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryPurple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  FeatherIcons.arrowLeft,
                  color: AppTheme.primaryPurple,
                  size: 20,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Progress indicator for onboarding screens
class OnboardingProgressBar extends StatelessWidget {
  final double progress;

  const OnboardingProgressBar({
    super.key,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(3),
        child: LinearProgressIndicator(
          value: progress,
          minHeight: 6,
          backgroundColor: const Color(0xFFE5E7EB),
          valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryPurple),
        ),
      ),
    );
  }
}
