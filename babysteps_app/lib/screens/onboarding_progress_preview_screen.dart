import 'package:flutter/material.dart';
import 'package:babysteps_app/theme/app_theme.dart';
import 'package:babysteps_app/screens/onboarding_growth_chart_screen.dart';
import 'package:babysteps_app/screens/onboarding_short_term_focus_screen.dart';
import 'package:babysteps_app/utils/app_animations.dart';
import 'package:babysteps_app/widgets/onboarding_app_bar.dart';
import 'package:babysteps_app/models/baby.dart';
import 'package:babysteps_app/models/milestone.dart';
import 'package:provider/provider.dart';
import 'package:babysteps_app/providers/baby_provider.dart';

class OnboardingProgressPreviewScreen extends StatefulWidget {
  final Baby? baby;
  final List<Milestone>? milestones;

  const OnboardingProgressPreviewScreen({
    this.baby,
    this.milestones,
    super.key,
  });

  @override
  State<OnboardingProgressPreviewScreen> createState() => _OnboardingProgressPreviewScreenState();
}

class _OnboardingProgressPreviewScreenState extends State<OnboardingProgressPreviewScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _aheadAnimation;
  late Animation<double> _onTimeAnimation;
  late Animation<double> _upcomingAnimation;
  late Animation<double> _delayedAnimation;
  final Map<String, List<Map<String, dynamic>>> _assessmentsByBaby = {};
  List<Baby> _babies = [];
  List<Milestone> _allMilestones = [];
  bool _isLoadingMilestones = true;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    // Stagger the animations slightly for each bar
    _aheadAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
      ),
    );

    _onTimeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.1, 0.8, curve: Curves.easeOut),
      ),
    );

    _upcomingAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.2, 0.9, curve: Curves.easeOut),
      ),
    );

    _delayedAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
      ),
    );

    _loadAchievedMilestones();
  }

  Future<void> _loadAchievedMilestones() async {
    final babyProvider = Provider.of<BabyProvider>(context, listen: false);
    final providerBabies = babyProvider.babies;
    final selectedBaby = babyProvider.selectedBaby;

    final babies = <Baby>[
      ...providerBabies,
      if (providerBabies.isEmpty && widget.baby != null) widget.baby!,
      if (providerBabies.isEmpty && widget.baby == null && selectedBaby != null) selectedBaby,
    ];

    // Load all milestones from database
    List<Milestone> allMilestones = [];
    try {
      allMilestones = await babyProvider.supabaseService.getMilestones();
    } catch (e) {
      // If we can't load milestones, use widget milestones as fallback
      allMilestones = widget.milestones ?? [];
    }

    if (babies.isEmpty) {
      if (mounted) {
        setState(() {
          _allMilestones = allMilestones;
          _isLoadingMilestones = false;
        });
        Future.delayed(const Duration(milliseconds: 200), () {
          if (mounted) _animationController.forward();
        });
      }
      return;
    }

    final assessmentMap = <String, List<Map<String, dynamic>>>{};

    for (final baby in babies) {
      try {
        final assessments = await babyProvider.getMilestoneAssessmentsForBaby(baby.id);
        assessmentMap[baby.id] = assessments;
      } catch (_) {
        assessmentMap[baby.id] = [];
      }
    }

    if (!mounted) return;

    setState(() {
      _assessmentsByBaby
        ..clear()
        ..addAll(assessmentMap);
      _babies = babies;
      _allMilestones = allMilestones;
      _isLoadingMilestones = false;
    });

    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) {
        _animationController.forward();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Map<String, int> _calculateMilestoneCategoriesForBaby(
    Baby baby,
    List<Map<String, dynamic>> assessments,
  ) {
    int ahead = 0;
    int onTime = 0;
    int upcoming = 0;
    int delayed = 0;

    // Calculate baby's current age in weeks
    final now = DateTime.now();
    final ageInWeeks = now.difference(baby.birthdate).inDays / 7.0;

    // Build set of completed milestone IDs/titles from both sources
    final completedFromBabiesTable = baby.completedMilestones.toSet();
    final completedFromAssessments = <String>{};
    
    for (final assessment in assessments) {
      final achievedAtIso = assessment['achieved_at'] as String?;
      if (achievedAtIso != null) {
        final milestoneId = assessment['milestone_id'] as String? ?? '';
        final title = assessment['title'] as String? ?? '';
        completedFromAssessments.add(milestoneId);
        completedFromAssessments.add(title);
      }
    }

    // If we don't have any remote assessments yet (guest onboarding, or
    // very first session), fall back to a local-only calculation based on
    // the milestones shown in onboarding and the baby's age window.
    if (assessments.isEmpty) {
      for (final milestone in _allMilestones) {
        final isCompleted =
            completedFromBabiesTable.contains(milestone.id) ||
            completedFromBabiesTable.contains(milestone.title);

        final startWeeks = milestone.firstNoticedWeeks.toDouble();
        final endWeeks = milestone.worryAfterWeeks >= 0
            ? milestone.worryAfterWeeks.toDouble()
            : (milestone.firstNoticedWeeks + 24).toDouble();

        if (isCompleted) {
          // Without precise achieved-at timestamps, treat completed
          // milestones as "On Time" for onboarding preview.
          onTime++;
        } else {
          if (ageInWeeks >= startWeeks && ageInWeeks <= endWeeks) {
            upcoming++;
          } else if (ageInWeeks > endWeeks) {
            delayed++;
          }
        }
      }

      return {
        'ahead': ahead,
        'onTime': onTime,
        'upcoming': upcoming,
        'delayed': delayed,
      };
    }

    // Count achieved milestones
    for (final assessment in assessments) {
      final source = assessment['source'] as String?;
      final milestoneId = assessment['milestone_id'] as String? ?? '';
      final title = assessment['title'] as String? ?? '';
      final achievedAtIso = assessment['achieved_at'] as String?;
      final achievedWeeks = (assessment['achieved_weeks'] as num?)?.toDouble();
      final startWeeks = (assessment['window_start_weeks'] as num?)?.toDouble();
      final endWeeks = (assessment['window_end_weeks'] as num?)?.toDouble();

      final isPreChecked = completedFromBabiesTable.contains(title) || completedFromBabiesTable.contains(milestoneId);
      final achievedAt = achievedAtIso != null ? DateTime.tryParse(achievedAtIso) : null;

      // Skip onboarding rows that were auto-checked (no achieved date) during profile creation
      if (source == 'onboarding' && achievedAt == null && isPreChecked) {
        continue;
      }

      final hasWindow = startWeeks != null && endWeeks != null;

      if (achievedAt != null && achievedWeeks != null && hasWindow) {
        if (achievedWeeks <= startWeeks!) {
          ahead++;
        } else if (achievedWeeks < endWeeks!) {
          onTime++;
        } else {
          onTime++; // Treat achieved but late milestones as completed/on time bucket
        }
      }
    }

    // Now check all milestones for upcoming/delayed
    for (final milestone in _allMilestones) {
      final isCompleted = completedFromBabiesTable.contains(milestone.id) ||
          completedFromBabiesTable.contains(milestone.title) ||
          completedFromAssessments.contains(milestone.id) ||
          completedFromAssessments.contains(milestone.title);

      if (isCompleted) {
        continue; // Already counted in ahead/onTime
      }

      final startWeeks = milestone.firstNoticedWeeks.toDouble();
      final endWeeks = milestone.worryAfterWeeks >= 0
          ? milestone.worryAfterWeeks.toDouble()
          : (milestone.firstNoticedWeeks + 24).toDouble();

      if (ageInWeeks >= startWeeks && ageInWeeks <= endWeeks) {
        upcoming++;
      } else if (ageInWeeks > endWeeks) {
        delayed++;
      }
      // If ageInWeeks < startWeeks, milestone is not yet relevant (ignored)
    }

    return {
      'ahead': ahead,
      'onTime': onTime,
      'upcoming': upcoming,
      'delayed': delayed,
    };
  }

  Map<String, int> _calculateCombinedMilestoneCategories(
    List<Baby> babies,
  ) {
    int ahead = 0;
    int onTime = 0;
    int upcoming = 0;
    int delayed = 0;

    for (final baby in babies) {
      final assessments = _assessmentsByBaby[baby.id] ?? [];
      final counts = _calculateMilestoneCategoriesForBaby(baby, assessments);
      ahead += counts['ahead']!;
      onTime += counts['onTime']!;
      upcoming += counts['upcoming']!;
      delayed += counts['delayed']!;
    }

    return {
      'ahead': ahead,
      'onTime': onTime,
      'upcoming': upcoming,
      'delayed': delayed,
    };
  }

  @override
  Widget build(BuildContext context) {
    final babyProvider = Provider.of<BabyProvider>(context, listen: false);
    final babies = _babies.isNotEmpty
        ? _babies
        : (() {
            final providerBabies = babyProvider.babies;
            if (providerBabies.isNotEmpty) return providerBabies;
            final fallbackBaby = widget.baby ?? babyProvider.selectedBaby;
            return fallbackBaby != null ? [fallbackBaby] : <Baby>[];
          })();
    final allMilestones = widget.milestones ?? [];

    final categories = babies.isNotEmpty
        ? _calculateCombinedMilestoneCategories(babies)
        : {'ahead': 5, 'onTime': 7, 'upcoming': 4, 'delayed': 3}; // Fallback values
    
    final total = categories['ahead']! + categories['onTime']! + categories['upcoming']! + categories['delayed']!;
    final maxCount = [categories['ahead']!, categories['onTime']!, categories['upcoming']!, categories['delayed']!]
        .reduce((a, b) => a > b ? a : b);
    final normalizer = maxCount > 0 ? maxCount : 1;
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
                  final babyProvider = Provider.of<BabyProvider>(context, listen: false);
                  final babies = babyProvider.babies;
                  if (babies.isNotEmpty) {
                    Navigator.of(context).pushReplacementWithFade(
                      OnboardingShortTermFocusScreen(babies: babies),
                    );
                  }
                },
              ),
              const SizedBox(height: 8),
              const Spacer(),
              const Text(
                'Your Journey\nStarts Now',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                  height: 1.2,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              // Progress visualization
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F2FC),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: AnimatedBuilder(
                  animation: _animationController,
                  builder: (context, child) {
                    return Column(
                      children: [
                        _buildProgressRow(
                          'Ahead',
                          (categories['ahead']! / normalizer) * _aheadAnimation.value,
                          '${categories['ahead']}',
                        ),
                        const SizedBox(height: 20),
                        _buildProgressRow(
                          'On Time',
                          (categories['onTime']! / normalizer) * _onTimeAnimation.value,
                          '${categories['onTime']}',
                        ),
                        const SizedBox(height: 20),
                        _buildProgressRow(
                          'Upcoming',
                          (categories['upcoming']! / normalizer) * _upcomingAnimation.value,
                          '${categories['upcoming']}',
                        ),
                        const SizedBox(height: 20),
                        _buildProgressRow(
                          'Delayed',
                          (categories['delayed']! / normalizer) * _delayedAnimation.value,
                          '${categories['delayed']}',
                        ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                'Track everything that matters to make sure your baby gets the best start.',
                style: TextStyle(
                  fontSize: 16,
                  color: AppTheme.textSecondary,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pushReplacementWithFade(
                      const OnboardingGrowthChartScreen(),
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
                    'See My Potential',
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

  Widget _buildProgressRow(String label, double progress, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryPurple,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            backgroundColor: Colors.grey.shade200,
            valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryPurple),
          ),
        ),
      ],
    );
  }
}
