import 'package:flutter/material.dart';
import 'package:babysteps_app/models/diary_entry.dart';
import 'package:babysteps_app/screens/recommendations_screen.dart';
import 'package:babysteps_app/screens/recommendation_detail_screen.dart';
import 'package:babysteps_app/services/recommendation_service.dart';
import 'package:babysteps_app/theme/app_theme.dart';
import 'package:babysteps_app/models/recommendation.dart';
import 'package:provider/provider.dart';
import 'package:babysteps_app/providers/baby_provider.dart';
import 'package:babysteps_app/widgets/app_header.dart';
import 'package:babysteps_app/widgets/bottom_nav_bar.dart';
import 'package:babysteps_app/widgets/home_card.dart';
import 'package:babysteps_app/widgets/recommendation_card.dart';
import 'package:babysteps_app/widgets/recommended_time_item.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:intl/intl.dart';

class HomeScreen extends StatefulWidget {
  final bool showBottomNav;
  
  const HomeScreen({this.showBottomNav = true, super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _askAiController = TextEditingController();
  int _currentNavIndex = 0;
  final Set<String> _dismissedRecommendationIds = <String>{};
  int _currentStreak = 0;
  bool _isLoadingStreak = true;
  double? _overallPercentile;
  double? _motorPercentile;
  double? _languagePercentile;
  double? _socialPercentile;
  bool _isLoadingPercentile = true;
  Map<String, dynamic>? _weeklyAdvicePlan;
  bool _isLoadingAdvice = true;
  List<Recommendation> _geminiRecommendations = [];

  // Activities list (mutable so we can remove after logging)
  late List<Map<String, String>> _activities;

  @override
  void initState() {
    super.initState();
    _activities = [
      {
        'title': 'Tummy Time Adventure',
        'desc': 'Gentle tummy time for 5–10 minutes.'
      },
      {
        'title': 'Read & Point',
        'desc': 'Read a picture book and point to objects.'
      },
      {
        'title': 'High‑Contrast Cards',
        'desc': 'Show black & white cards 8–12 inches from face.'
      },
    ];
    _loadStreak();
    _loadOverallPercentile();
    _loadWeeklyAdvice();
  }

  Future<void> _loadStreak() async {
    try {
      final babyProvider = Provider.of<BabyProvider>(context, listen: false);
      final streak = await babyProvider.getUserStreak();
      if (mounted) {
        setState(() {
          _currentStreak = streak;
          _isLoadingStreak = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingStreak = false;
        });
      }
    }
  }

  Future<void> _loadOverallPercentile() async {
    try {
      final babyProvider = Provider.of<BabyProvider>(context, listen: false);
      final data = await babyProvider.getOverallTrackingScore();
      if (!mounted) return;
      setState(() {
        double? motor;
        double? language;
        double? social;

        if (data != null) {
          _overallPercentile = (data['overall_percentile'] as num?)?.toDouble();

          final dynamic domainsRaw = data['domains'];
          final Map<String, dynamic> domains = domainsRaw is Map<String, dynamic>
              ? domainsRaw
              : <String, dynamic>{};

          double? extractPercentile(String key) {
            final dynamic value = domains[key];
            if (value is Map) {
              final dynamic avg = value['avg_percentile'];
              if (avg is num) return avg.toDouble();
            }
            return null;
          }

          motor = extractPercentile('motor');
          language = extractPercentile('language');
          social = extractPercentile('social');

          _motorPercentile = motor;
          _languagePercentile = language;
          _socialPercentile = social;

          if (_overallPercentile == null) {
            final domainValues = <double?>[motor, language, social]
                .whereType<double>()
                .toList();
            if (domainValues.isNotEmpty) {
              _overallPercentile = domainValues.reduce((a, b) => a + b) / domainValues.length;
            }
          }
        } else {
          _overallPercentile = null;
          _motorPercentile = null;
          _languagePercentile = null;
          _socialPercentile = null;
        }

        _isLoadingPercentile = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _overallPercentile = null;
        _motorPercentile = null;
        _languagePercentile = null;
        _socialPercentile = null;
        _isLoadingPercentile = false;
      });
    }
  }

  Future<void> _loadWeeklyAdvice() async {
    try {
      final babyProvider = Provider.of<BabyProvider>(context, listen: false);
      final res = await babyProvider.generateWeeklyAdvicePlan(forceRefresh: false);
      final plan = res != null ? res['plan'] as Map<String, dynamic>? : null;
      if (!mounted) return;

      List<Map<String, String>> todayActivities = _activities;
      final List<Recommendation> recs = [];

      if (plan != null) {
        // Extract today's activities
        final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
        final List<dynamic> days = List<dynamic>.from(plan['activities'] ?? const []);
        Map<String, dynamic>? day = days.cast<Map<String, dynamic>?>().firstWhere(
          (d) => (d?['date'] as String?) == todayStr,
          orElse: () => null,
        );
        day ??= days.isNotEmpty ? Map<String, dynamic>.from(days.first as Map) : null;
        if (day != null) {
          final items = List<Map<String, dynamic>>.from(day['items'] ?? const []);
          todayActivities = items
              .map((it) => {
                    'title': (it['title'] ?? '').toString(),
                    'desc': (it['description'] ?? '').toString(),
                  })
              .where((m) => m['title']!.isNotEmpty)
              .toList();
        }

        // Extract recommendations
        final rec = Map<String, dynamic>.from(plan['recommendations'] ?? const {});
        int idx = 0;
        for (final tip in List<Map<String, dynamic>>.from(rec['interaction_tips'] ?? const [])) {
          recs.add(Recommendation(
            id: 'tip_${idx++}',
            title: (tip['title'] ?? 'Tip').toString(),
            description: (tip['tip'] ?? '').toString(),
            category: RecommendationCategory.development,
          ));
        }
        for (final up in List<Map<String, dynamic>>.from(rec['upcoming'] ?? const [])) {
          final what = (up['what_to_expect'] ?? '').toString();
          final when = (up['when'] ?? '').toString();
          recs.add(Recommendation(
            id: 'up_${idx++}',
            title: (up['title'] ?? 'Upcoming').toString(),
            description: [what, when].where((s) => s.isNotEmpty).join(' · '),
            category: RecommendationCategory.upcoming,
          ));
        }
        for (final pi in List<Map<String, dynamic>>.from(rec['potential_issues'] ?? const [])) {
          final watch = (pi['what_to_watch'] ?? '').toString();
          final doThis = (pi['what_to_do'] ?? '').toString();
          recs.add(Recommendation(
            id: 'issue_${idx++}',
            title: (pi['title'] ?? 'Watch for').toString(),
            description: [watch, doThis].where((s) => s.isNotEmpty).join(' · '),
            category: RecommendationCategory.health,
          ));
        }
      }

      setState(() {
        _weeklyAdvicePlan = plan;
        _activities = todayActivities;
        _geminiRecommendations = recs;
        _isLoadingAdvice = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingAdvice = false;
      });
    }
  }

  @override
  void dispose() {
    _askAiController.dispose();
    super.dispose();
  }

  Future<void> _handleActivityAction({required String title, required String result}) async {
    final babyProvider = Provider.of<BabyProvider>(context, listen: false);
    try {
      await babyProvider.logActivityResult(title: title, result: result);
      if (!mounted) return;
      setState(() {
        _activities.removeWhere((a) => a['title'] == title);
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving activity: $e')),
      );
    }
  }

  @override
  // Get recommendations for home screen
  List<Recommendation> get _featuredRecommendations => 
      RecommendationService
          .getFeaturedRecommendations()
          .where((r) => !_dismissedRecommendationIds.contains(r.id))
          .toList();
      
  // Handle sleep time tracking
  void _recordWakeUpTime() {
    // TODO: Implement wake up time recording
    final now = DateTime.now();
    final timeString = DateFormat('h:mm a').format(now);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Wake up time recorded: $timeString')),
    );
  }
  
  void _recordNapTime() {
    // TODO: Implement nap time recording
    final now = DateTime.now();
    final timeString = DateFormat('h:mm a').format(now);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Nap time recorded: $timeString')),
    );
  }
  
  void _recordSleepTime() {
    // TODO: Implement sleep time recording
    final now = DateTime.now();
    final timeString = DateFormat('h:mm a').format(now);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Sleep time recorded: $timeString')),
    );
  }
  
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: widget.showBottomNav ? BottomNavBar(
        currentIndex: _currentNavIndex,
        onTap: (index) {
          setState(() {
            _currentNavIndex = index;
          });
        },
      ) : null,
      body: SafeArea(
        child: Column(
          children: [
            const AppHeader(),
            // Removed mocked BabySelector for 'Luna' in favor of real dropdown above
            
            // Main content
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                children: [
                  // Summary tiles (Streak + Overall Tracking)
                  _buildSummaryTiles(),
                  const SizedBox(height: 16),

                  // Activities Today
                  _buildActivitiesSection(),
                  const SizedBox(height: 16),

                  // Recommendations section with dismiss X
                  _buildRecommendationsSection(),
                  // const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, Widget content) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          content,
        ],
      ),
    );
  }

  Widget _buildRecommendedTimes() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Recommended Times',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF1F2937)),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                // Wake Time
                _buildTimeRow(
                  icon: FeatherIcons.sunrise,
                  title: 'Wake Up',
                  time: '7:00 AM',
                  subtitle: 'Daily',
                ),
                const Divider(height: 24),
                // Morning Nap
                _buildTimeRow(
                  icon: FeatherIcons.cloud,
                  title: 'Morning Nap',
                  time: '10:00 AM',
                  subtitle: '~1 hour',
                ),
                const Divider(height: 24),
                // Afternoon Nap
                _buildTimeRow(
                  icon: FeatherIcons.cloud,
                  title: 'Afternoon Nap',
                  time: '1:30 PM',
                  subtitle: '~1.5 hours',
                ),
                const Divider(height: 24),
                // Evening Nap
                _buildTimeRow(
                  icon: FeatherIcons.cloud,
                  title: 'Evening Nap',
                  time: '5:00 PM',
                  subtitle: '~45 min',
                ),
                const Divider(height: 24),
                // Bedtime
                _buildTimeRow(
                  icon: FeatherIcons.moon,
                  title: 'Bedtime',
                  time: '8:30 PM',
                  subtitle: 'Until 7:00 AM',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildTimeRow({
    required IconData icon,
    required String title,
    required String time,
    required String subtitle,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F2FC),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 20, color: const Color(0xFFA67EB7)),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                ),
                Text(
                  time,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1F2937)),
                ),
              ],
            ),
          ],
        ),
        Text(
          subtitle,
          style: const TextStyle(fontSize: 12, color: Color(0xFFA67EB7)),
        ),
      ],
    );
  }

  Widget _buildSleepTrackingButtons() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildQuickActionButton(
            icon: FeatherIcons.sunrise,
            label: 'Wake Up',
            onTap: _recordWakeUpTime,
          ),
          _buildQuickActionButton(
            icon: FeatherIcons.sunset,
            label: 'Nap Time',
            onTap: _recordNapTime,
          ),
          _buildQuickActionButton(
            icon: FeatherIcons.moon,
            label: 'Sleep Time',
            onTap: _recordSleepTime,
          ),
        ],
      ),
    );
  }
  
  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    VoidCallback? onTap,
  }) {
    return Column(
      children: [
        FloatingActionButton(
          onPressed: onTap,
          backgroundColor: AppTheme.lightPurple,
          heroTag: label, // Unique heroTag for each FAB
          mini: true,
          elevation: 1,
          child: Icon(icon, color: AppTheme.darkPurple),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF4B5563)),
        ),
      ],
    );
  }
  
  Widget _buildAskAiCard() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ask AI',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF1F2937)),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _askAiController,
                  decoration: InputDecoration(
                    hintText: 'Ask about baby sleep, development, or care...',
                    hintStyle: const TextStyle(color: Color(0xFFA0AEC0)),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFA67EB7), width: 2),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    suffixIcon: IconButton(
                      icon: const Icon(FeatherIcons.send, color: Color(0xFFA67EB7)),
                      onPressed: () {},
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationsSection() {
    final list = _isLoadingAdvice
        ? <Recommendation>[]
        : (_geminiRecommendations.isNotEmpty
            ? _geminiRecommendations.where((r) => !_dismissedRecommendationIds.contains(r.id)).toList()
            : _featuredRecommendations);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F2FC),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(FeatherIcons.gift, size: 20, color: Color(0xFFA67EB7)),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Recommendations',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF1F2937)),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFF1E8F7),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Text(
                _isLoadingAdvice
                    ? 'Loading...'
                    : (_geminiRecommendations.isNotEmpty ? 'Personalized (Gemini)' : 'Featured'),
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFFA67EB7)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (_isLoadingAdvice) const Center(child: CircularProgressIndicator()),

        // Vertical list of recommendations with dismiss X and category pill
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: list.length,
          itemBuilder: (context, index) {
            final rec = list[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE5E7EB)),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              padding: const EdgeInsets.all(14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left column with badge + text
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _categoryPill(rec.category),
                        const SizedBox(height: 6),
                        Text(rec.title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 2),
                        Text(
                          rec.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Color(0xFF6B7280), fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  // Right-side actions: Dismiss only
                  Column(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.close),
                        color: Colors.grey.shade600,
                        tooltip: 'Dismiss',
                        onPressed: () {
                          setState(() {
                            _dismissedRecommendationIds.add(rec.id);
                          });
                        },
                      ),
                    ],
                  )
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _categoryPill(RecommendationCategory cat) {
    // Map category to label and colors to mirror mockup classes
    late String label;
    late Color bg;
    late Color dot;
    switch (cat) {
      case RecommendationCategory.behavior:
        label = 'Behavior';
        bg = const Color(0xFFF6EBDD); // amber-like bg
        dot = const Color(0xFFE6C8A2);
        break;
      case RecommendationCategory.sleep:
        label = 'Sleep';
        bg = const Color(0xFFF3EAF8); // lavender-ish
        dot = const Color(0xFFA67EB7);
        break;
      case RecommendationCategory.activity:
        label = 'Activity';
        bg = const Color(0xFFE7F4F0); // green-ish
        dot = const Color(0xFF87CBB9);
        break;
      case RecommendationCategory.development:
        label = 'Development';
        bg = const Color(0xFFEAF0F6); // blue-ish
        dot = const Color(0xFFA2B3C8);
        break;
      default:
        label = cat.name[0].toUpperCase() + cat.name.substring(1);
        bg = const Color(0xFFF3F4F6);
        dot = const Color(0xFF9CA3AF);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(color: dot, borderRadius: BorderRadius.circular(999))),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildSummaryTiles() {
    // Determine streak color based on length
    Color getStreakColor(int streak) {
      if (streak >= 30) return const Color(0xFFEC4899); // Pink for 30+ days
      if (streak >= 14) return const Color(0xFF8B5CF6); // Purple for 14+ days
      if (streak >= 7) return const Color(0xFF3B82F6); // Blue for 7+ days
      if (streak >= 3) return const Color(0xFF10B981); // Green for 3+ days
      if (streak >= 1) return const Color(0xFFFBBF24); // Yellow for 1+ days
      return const Color(0xFF9CA3AF); // Gray for 0 days
    }

    Widget metricTile({
      required IconData icon,
      required String title,
      required String value,
      String? subtitle,
      Color? iconColor,
      Color? iconBgColor,
    }) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE5E7EB)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: iconBgColor ?? const Color(0xFFF8F2FC),
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: Icon(icon, size: 18, color: iconColor ?? const Color(0xFFA67EB7)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF))),
                  Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF)),
                    ),
                  ],
                ],
              ),
            )
          ],
        ),
      );
    }

    final streakColor = getStreakColor(_currentStreak);
    final streakValue = _isLoadingStreak 
        ? '...' 
        : _currentStreak == 0 
            ? 'Start today!' 
            : '$_currentStreak ${_currentStreak == 1 ? 'day' : 'days'}';

    String percentileValue;
    String domainSummary;
    if (_isLoadingPercentile) {
      percentileValue = '...';
      domainSummary = 'Loading tracking data';
    } else {
      final double? overall = _overallPercentile;
      percentileValue = overall != null ? '${overall.round()}%ile' : '--';

      String formatDomain(String label, double? value) {
        return '$label ${value != null ? '${value.round()}%ile' : '--'}';
      }

      domainSummary = [
        formatDomain('Motor', _motorPercentile),
        formatDomain('Language', _languagePercentile),
        formatDomain('Social', _socialPercentile),
      ].join(' · ');
    }

    return Row(
      children: [
        Expanded(
          child: metricTile(
            icon: FeatherIcons.zap,
            title: 'Streak',
            value: streakValue,
            iconColor: streakColor,
            iconBgColor: streakColor.withOpacity(0.1),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: metricTile(
            icon: FeatherIcons.trendingUp,
            title: 'Overall Tracking',
            value: percentileValue,
            subtitle: domainSummary,
          ),
        ),
      ],
    );
  }

  Widget _buildActivitiesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Activities Today',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFF1E8F7),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: const Text(
                'On track · 70th %ile',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFFA67EB7)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ..._activities.map((a) => _ActivityListCard(
              title: a['title']!,
              desc: a['desc']!,
              onAction: (result) => _handleActivityAction(title: a['title']!, result: result),
            )),
      ],
    );
  }

  Widget _buildDiaryCard() {
    final today = DateFormat('MMMM d, yyyy').format(DateTime.now());
    
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Diary',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF1F2937)),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8F2FC),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(FeatherIcons.bookOpen, size: 20, color: Color(0xFFA67EB7)),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Today\'s Entry',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF1F2937)),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(FeatherIcons.edit, color: Color(0xFFA67EB7), size: 20),
                      constraints: const BoxConstraints(),
                      padding: EdgeInsets.zero,
                      onPressed: () {},
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  today,
                  style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Luna smiled for the first time today! She also seems more interested in her surroundings...',
                    style: TextStyle(fontSize: 14, color: Color(0xFF4B5563)),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFE6D7F2), Color(0xFFC8A2C8)],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: const Text(
                    'View Full Diary',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.white),
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

class _ActivityListCard extends StatelessWidget {
  final String title;
  final String desc;
  final ValueChanged<String>? onAction; // dismiss, ok, meh, sad
  const _ActivityListCard({required this.title, required this.desc, this.onAction});

  @override
  Widget build(BuildContext context) {
    Widget _iconButton(String emoji, Color color, {VoidCallback? onPressed}) {
      return OutlinedButton(
        onPressed: onPressed ?? () {},
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: color.withOpacity(0.6)),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          minimumSize: const Size(0, 0),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: Text(emoji, style: const TextStyle(fontSize: 16)),
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          const SizedBox(height: 8),
          Text(desc, style: const TextStyle(color: Color(0xFF6B7280), fontSize: 14)),
          const SizedBox(height: 14),
          Row(
            children: [
              _iconButton('×', Colors.grey, onPressed: () async {
                onAction?.call('dismiss');
              }),
              const SizedBox(width: 10),
              _iconButton('🙂', Colors.green, onPressed: () async {
                onAction?.call('ok');
              }),
              const SizedBox(width: 10),
              _iconButton('😐', Colors.amber, onPressed: () async {
                onAction?.call('meh');
              }),
              const SizedBox(width: 10),
              _iconButton('🙁', Colors.redAccent, onPressed: () async {
                onAction?.call('sad');
              }),
            ],
          ),
        ],
      ),
    );
  }
}

class _TimeRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String time;

  const _TimeRow({required this.icon, required this.title, required this.time});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(width: 16),
          Text(title, style: const TextStyle(color: Colors.white, fontSize: 16)),
          const Spacer(),
          Text(time, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;

  const _ActionButton({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        FloatingActionButton(
          onPressed: () {},
          backgroundColor: AppTheme.lightPurple,
          heroTag: label, // Unique heroTag for each FAB
          mini: true,
          elevation: 1,
          child: Icon(icon, color: AppTheme.darkPurple),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}
