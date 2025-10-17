import 'package:flutter/material.dart';
import 'package:babysteps_app/theme/app_theme.dart';
import 'package:babysteps_app/models/baby.dart';
import 'package:babysteps_app/screens/onboarding_growth_chart_screen.dart';
import 'package:babysteps_app/screens/onboarding_progress_preview_screen.dart';
import 'package:babysteps_app/screens/onboarding_short_term_focus_screen.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:provider/provider.dart';
import 'package:babysteps_app/providers/baby_provider.dart';
import 'package:babysteps_app/providers/milestone_provider.dart';
import 'package:babysteps_app/utils/app_animations.dart';
import 'package:babysteps_app/widgets/onboarding_app_bar.dart';

class OnboardingBabyProgressScreen extends StatefulWidget {
  final List<Baby> babies;

  const OnboardingBabyProgressScreen({required this.babies, super.key});

  @override
  State<OnboardingBabyProgressScreen> createState() => _OnboardingBabyProgressScreenState();
}

class _OnboardingBabyProgressScreenState extends State<OnboardingBabyProgressScreen> {
  late PageController _pageController;
  int _currentPage = 0;
  Map<String, List<Map<String, dynamic>>> _babyScores = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _loadAllBabyScores();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadAllBabyScores() async {
    final babyProvider = Provider.of<BabyProvider>(context, listen: false);
    final scores = <String, List<Map<String, dynamic>>>{};
    
    for (final baby in widget.babies) {
      try {
        // Use the baby-specific method instead of temporarily changing selection
        final domainScores = await babyProvider.getDomainTrackingScoresForBaby(baby.id);
        scores[baby.id] = domainScores;
      } catch (e) {
        scores[baby.id] = [];
      }
    }
    
    if (mounted) {
      setState(() {
        _babyScores = scores;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFFAFAFA),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: SafeArea(
        child: Column(
          children: [
            OnboardingAppBar(
              onBackPressed: () {
                Navigator.of(context).pushReplacementWithFade(
                  OnboardingShortTermFocusScreen(
                    babies: widget.babies,
                    initialIndex: _currentPage,
                  ),
                );
              },
            ),
            // Title
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                'Your Baby\'s Current Progress',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1F2937),
                  height: 1.2,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 8),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                'See where they are today—and where they could be tomorrow',
                style: TextStyle(
                  fontSize: 15,
                  color: Color(0xFF6B7280),
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 24),

            // Baby carousel
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: widget.babies.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemBuilder: (context, index) {
                  final baby = widget.babies[index];
                  final scores = _babyScores[baby.id] ?? [];
                  return _buildBabyProgressCard(baby, scores);
                },
              ),
            ),

            // Page indicator
            if (widget.babies.length > 1)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    widget.babies.length,
                    (index) => Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: _currentPage == index ? 24 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _currentPage == index
                            ? AppTheme.primaryPurple
                            : const Color(0xFFD1D5DB),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
              ),

            // Continue button
            Padding(
              padding: const EdgeInsets.all(20),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    final babyProvider = Provider.of<BabyProvider>(context, listen: false);
                    final milestoneProvider = Provider.of<MilestoneProvider>(context, listen: false);
                    final currentBaby = widget.babies.isNotEmpty ? widget.babies[_currentPage] : null;
                    
                    Navigator.of(context).pushWithFade(
                      OnboardingProgressPreviewScreen(
                        baby: currentBaby,
                        milestones: milestoneProvider.milestones,
                      ),
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
                    'See Their Potential',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBabyProgressCard(Baby baby, List<Map<String, dynamic>> domainScores) {
    final helper = _DomainScoreHelper(domainScores);
    final imgPath = _heroImageForGender(baby.gender);
    final ageLabel = _formatAgeMonths(baby.birthdate);
    final insights = _generateInsights(baby.name, helper);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          // Baby avatar with progress pins
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: const Color(0xFFE9ECEF)),
              borderRadius: BorderRadius.circular(16),
            ),
            clipBehavior: Clip.antiAlias,
            child: SizedBox(
              height: 320,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final h = constraints.maxHeight;
                  final w = constraints.maxWidth;
                  return Stack(
                    children: [
                      Positioned.fill(
                        child: Image.asset(
                          imgPath,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: const Color(0xFFF1F3F5),
                              alignment: Alignment.center,
                              child: const Icon(
                                FeatherIcons.image,
                                color: Color(0xFF9CA3AF),
                                size: 40,
                              ),
                            );
                          },
                        ),
                      ),
                      Positioned(
                        left: 16,
                        top: 16,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.45),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                baby.name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                              if (ageLabel.isNotEmpty)
                                Text(
                                  ageLabel,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      ..._buildProgressPins(helper, h, w),
                    ],
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 16),

          // General Percentile Row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.primaryPurple.withOpacity(0.1),
                  AppTheme.primaryPurple.withOpacity(0.05),
                ],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppTheme.primaryPurple.withOpacity(0.2),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryPurple.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        FeatherIcons.trendingUp,
                        color: AppTheme.primaryPurple,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Overall Progress',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF6B7280),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _calculateOverallPercentile(helper),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getOverallColor(helper),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    _getOverallLabel(helper),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Personalized insights
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0FDF4),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        FeatherIcons.trendingUp,
                        color: Color(0xFF10B981),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'What\'s Going Well',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  insights['strength']!,
                  style: const TextStyle(
                    fontSize: 15,
                    color: Color(0xFF374151),
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        FeatherIcons.target,
                        color: Color(0xFFF59E0B),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Growth Opportunity',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  insights['opportunity']!,
                  style: const TextStyle(
                    fontSize: 15,
                    color: Color(0xFF374151),
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  String _calculateOverallPercentile(_DomainScoreHelper helper) {
    final domains = ['Cognitive', 'Social', 'Communication', 'Motor', 'Fine Motor'];
    final values = domains
        .map((d) => helper.value(d))
        .where((v) => v != null)
        .cast<double>()
        .toList();
    
    if (values.isEmpty) {
      return 'Calculating...';
    }
    
    final average = values.reduce((a, b) => a + b) / values.length;
    return '${average.round()}th percentile';
  }

  Color _getOverallColor(_DomainScoreHelper helper) {
    final domains = ['Cognitive', 'Social', 'Communication', 'Motor', 'Fine Motor'];
    final values = domains
        .map((d) => helper.value(d))
        .where((v) => v != null)
        .cast<double>()
        .toList();
    
    if (values.isEmpty) return const Color(0xFF9CA3AF);
    
    final average = values.reduce((a, b) => a + b) / values.length;
    if (average >= 75) return const Color(0xFF46B17B);
    if (average >= 50) return AppTheme.primaryPurple;
    if (average >= 33) return const Color(0xFFE6C370);
    return const Color(0xFFE66A6A);
  }

  String _getOverallLabel(_DomainScoreHelper helper) {
    final domains = ['Cognitive', 'Social', 'Communication', 'Motor', 'Fine Motor'];
    final values = domains
        .map((d) => helper.value(d))
        .where((v) => v != null)
        .cast<double>()
        .toList();
    
    if (values.isEmpty) return 'Pending';
    
    final average = values.reduce((a, b) => a + b) / values.length;
    if (average >= 75) return 'Excellent';
    if (average >= 50) return 'On Track';
    if (average >= 33) return 'Developing';
    return 'Needs Focus';
  }

  List<Widget> _buildProgressPins(_DomainScoreHelper helper, double height, double width) {
    final pins = <Widget>[];
    
    // Motor pin
    final motorVal = helper.value('Motor');
    if (motorVal != null) {
      pins.add(_ProgressPin(
        top: height * (1 - motorVal / 100) - 20,
        right: width * 0.15,
        label: 'Motor',
        percentile: helper.formattedPercentile('Motor'),
        color: helper.colorFor('Motor'),
      ));
    }
    
    // Communication pin
    final commVal = helper.value('Communication');
    if (commVal != null) {
      pins.add(_ProgressPin(
        top: height * (1 - commVal / 100) - 20,
        right: width * 0.35,
        label: 'Speech',
        percentile: helper.formattedPercentile('Communication'),
        color: helper.colorFor('Communication'),
      ));
    }
    
    // Social pin
    final socialVal = helper.value('Social');
    if (socialVal != null) {
      pins.add(_ProgressPin(
        top: height * (1 - socialVal / 100) - 20,
        right: width * 0.55,
        label: 'Social',
        percentile: helper.formattedPercentile('Social'),
        color: helper.colorFor('Social'),
      ));
    }
    
    return pins;
  }

  Map<String, String> _generateInsights(String name, _DomainScoreHelper helper) {
    final domains = ['Cognitive', 'Social', 'Communication', 'Motor', 'Fine Motor'];
    final labels = {
      'Cognitive': 'brain development',
      'Social': 'social skills',
      'Communication': 'speech and language',
      'Motor': 'gross motor skills',
      'Fine Motor': 'fine motor skills',
    };

    final available = domains
        .map((d) => MapEntry(d, helper.value(d)))
        .where((entry) => entry.value != null)
        .toList();

    if (available.isEmpty) {
      return {
        'strength': 'We\'re gathering more observations about $name\'s development. Check back soon for personalized insights.',
        'opportunity': 'Once we have enough milestone check-ins, we\'ll highlight areas to celebrate and where to focus next.',
      };
    }

    available.sort((a, b) => b.value!.compareTo(a.value!));
    final strongest = available.first;
    final weakest = available.last;

    String strengthMsg;
    if (strongest.value! >= 75) {
      strengthMsg = '$name is excelling in ${labels[strongest.key]}—they\'re in the top ${(100 - strongest.value!).round()}% of babies their age! This strong foundation will help them thrive as they grow.';
    } else if (strongest.value! >= 50) {
      strengthMsg = '$name is doing really well with ${labels[strongest.key]}, showing solid progress that\'s right on track for their age. Keep up the great work!';
    } else {
      strengthMsg = '$name is making steady progress in ${labels[strongest.key]}. Every baby develops at their own pace, and they\'re building important skills every day.';
    }

    String opportunityMsg;
    if (weakest.value! < 33) {
      opportunityMsg = 'Let\'s focus on boosting ${labels[weakest.key]}. With the right activities and guidance, $name can catch up quickly—this is the perfect time to make a difference.';
    } else if (weakest.value! < 66) {
      opportunityMsg = 'There\'s room to strengthen ${labels[weakest.key]}. Small, consistent efforts now can lead to big improvements and help $name reach their full potential.';
    } else {
      opportunityMsg = 'While $name is doing great overall, we can still enhance ${labels[weakest.key]} to help them excel even further. Every percentile gained makes a lasting impact.';
    }

    return {
      'strength': strengthMsg,
      'opportunity': opportunityMsg,
    };
  }
}

class _ProgressPin extends StatelessWidget {
  final double top;
  final double right;
  final String label;
  final String percentile;
  final Color color;

  const _ProgressPin({
    required this.top,
    required this.right,
    required this.label,
    required this.percentile,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top,
      right: right,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            Text(
              percentile,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DomainScoreHelper {
  final Map<String, Map<String, dynamic>> _byDomain;

  _DomainScoreHelper(List<Map<String, dynamic>> rows)
      : _byDomain = {
          for (final r in rows) (r['domain'] as String): r,
        };

  double? value(String domain) {
    final row = _byDomain[domain];
    if (row == null || row['avg_percentile'] == null) {
      return null;
    }
    final v = (row['avg_percentile'] as num).toDouble();
    if (v < 1.0) return 1.0;
    if (v > 99.0) return 99.0;
    return v;
  }

  String formattedPercentile(String domain) {
    final v = value(domain);
    if (v == null) return 'waiting...';
    return '${v.round()}%ile';
  }

  Color colorFor(String domain) {
    final v = value(domain);
    if (v == null) return const Color(0xFF9CA3AF);
    if (v < 33) return const Color(0xFFE66A6A);
    if (v < 66) return const Color(0xFFE6C370);
    return const Color(0xFF46B17B);
  }

  bool hasAnyScores() => _byDomain.values.any((row) => row['avg_percentile'] != null);
}

String _heroImageForGender(String? gender) {
  final g = (gender ?? '').toLowerCase();
  if (g.contains('f') || g.contains('girl') || g.contains('woman')) {
    return 'assets/girl.jpg';
  }
  return 'assets/boy.jpg';
}

String _formatAgeMonths(DateTime? birthdate) {
  if (birthdate == null) return '';
  final now = DateTime.now();
  int months = (now.year - birthdate.year) * 12 + (now.month - birthdate.month);
  if (now.day < birthdate.day) months = months - 1;
  if (months < 0) months = 0;
  return '$months mo';
}
