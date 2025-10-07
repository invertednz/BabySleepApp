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
              child: const Text(
                'Personalized',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFFA67EB7)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        // Vertical list of recommendations with dismiss X and category pill
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _featuredRecommendations.length,
          itemBuilder: (context, index) {
            final rec = _featuredRecommendations[index];
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
    Widget metricTile({required IconData icon, required String title, required String value}) {
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
                color: const Color(0xFFF8F2FC), // lavender bg like mockup
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: Icon(icon, size: 18, color: const Color(0xFFA67EB7)),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF))),
                Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              ],
            )
          ],
        ),
      );
    }

    return Row(
      children: [
        Expanded(child: metricTile(icon: FeatherIcons.zap, title: 'Streak', value: '7 days')),
        const SizedBox(width: 10),
        Expanded(child: metricTile(icon: FeatherIcons.trendingUp, title: 'Overall Tracking', value: '72nd %ile')),
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
