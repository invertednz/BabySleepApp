import 'package:flutter/material.dart';
import 'package:babysteps_app/theme/app_theme.dart';
import 'package:babysteps_app/models/baby.dart';
import 'package:babysteps_app/screens/onboarding_growth_chart_screen.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:provider/provider.dart';
import 'package:babysteps_app/providers/baby_provider.dart';

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
    _loadAllBabyScores();
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
        // Temporarily set this baby as selected to get their scores
        babyProvider.selectBaby(baby.id);
        final domainScores = await babyProvider.getDomainTrackingScores();
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
            // Header
            Container(
              margin: const EdgeInsets.all(20),
              padding: const EdgeInsets.all(20),
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
              child: const Row(
                children: [
                  Icon(FeatherIcons.sunrise, color: AppTheme.primaryPurple, size: 32),
                  SizedBox(width: 12),
                  Text(
                    'BabySteps',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                ],
              ),
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
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (context) => const OnboardingGrowthChartScreen(),
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
                      _ProgressPin(
                        top: h * 0.12,
                        right: w * 0.04,
                        label: 'Brain',
                        percentile: helper.formattedPercentile('Cognitive'),
                        color: helper.colorFor('Cognitive'),
                      ),
                      _ProgressPin(
                        top: h * 0.28,
                        right: w * 0.04,
                        label: 'Social',
                        percentile: helper.formattedPercentile('Social'),
                        color: helper.colorFor('Social'),
                      ),
                      _ProgressPin(
                        top: h * 0.44,
                        right: w * 0.04,
                        label: 'Speech',
                        percentile: helper.formattedPercentile('Communication'),
                        color: helper.colorFor('Communication'),
                      ),
                      _ProgressPin(
                        top: h * 0.60,
                        right: w * 0.04,
                        label: 'Gross Motor',
                        percentile: helper.formattedPercentile('Motor'),
                        color: helper.colorFor('Motor'),
                      ),
                      _ProgressPin(
                        top: h * 0.76,
                        right: w * 0.04,
                        label: 'Fine Motor',
                        percentile: helper.formattedPercentile('Fine Motor'),
                        color: helper.colorFor('Fine Motor'),
                      ),
                    ],
                  );
                },
              ),
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

  Map<String, String> _generateInsights(String name, _DomainScoreHelper helper) {
    // Find strongest and weakest areas
    final domains = ['Cognitive', 'Social', 'Communication', 'Motor', 'Fine Motor'];
    final labels = {
      'Cognitive': 'brain development',
      'Social': 'social skills',
      'Communication': 'speech and language',
      'Motor': 'gross motor skills',
      'Fine Motor': 'fine motor skills',
    };

    var strongestDomain = domains[0];
    var strongestScore = helper.value(domains[0]);
    var weakestDomain = domains[0];
    var weakestScore = helper.value(domains[0]);

    for (final domain in domains) {
      final score = helper.value(domain);
      if (score > strongestScore) {
        strongestScore = score;
        strongestDomain = domain;
      }
      if (score < weakestScore) {
        weakestScore = score;
        weakestDomain = domain;
      }
    }

    // Generate strength message
    String strengthMsg;
    if (strongestScore >= 75) {
      strengthMsg = '$name is excelling in ${labels[strongestDomain]}—they\'re in the top ${(100 - strongestScore).round()}% of babies their age! This strong foundation will help them thrive as they grow.';
    } else if (strongestScore >= 50) {
      strengthMsg = '$name is doing really well with ${labels[strongestDomain]}, showing solid progress that\'s right on track for their age. Keep up the great work!';
    } else {
      strengthMsg = '$name is making steady progress in ${labels[strongestDomain]}. Every baby develops at their own pace, and they\'re building important skills every day.';
    }

    // Generate opportunity message
    String opportunityMsg;
    if (weakestScore < 33) {
      opportunityMsg = 'Let\'s focus on boosting ${labels[weakestDomain]}. With the right activities and guidance, $name can catch up quickly—this is the perfect time to make a difference.';
    } else if (weakestScore < 66) {
      opportunityMsg = 'There\'s room to strengthen ${labels[weakestDomain]}. Small, consistent efforts now can lead to big improvements and help $name reach their full potential.';
    } else {
      opportunityMsg = 'While $name is doing great overall, we can still enhance ${labels[weakestDomain]} to help them excel even further. Every percentile gained makes a lasting impact.';
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
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              percentile,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w700,
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

  static const Map<String, double> _fallback = {
    'Cognitive': 72,
    'Social': 71,
    'Communication': 45,
    'Motor': 66,
    'Fine Motor': 22,
  };

  double value(String domain) {
    final row = _byDomain[domain];
    if (row == null || row['avg_percentile'] == null) {
      return _fallback[domain]!.toDouble();
    }
    final v = (row['avg_percentile'] as num).toDouble();
    if (v < 1.0) return 1.0;
    if (v > 99.0) return 99.0;
    return v;
  }

  String formattedPercentile(String domain) => '${value(domain).round()}%ile';

  Color colorFor(String domain) {
    final v = value(domain);
    if (v < 33) return const Color(0xFFE66A6A);
    if (v < 66) return const Color(0xFFE6C370);
    return const Color(0xFF46B17B);
  }
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
