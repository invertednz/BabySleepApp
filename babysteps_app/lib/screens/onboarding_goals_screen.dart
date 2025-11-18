import 'package:flutter/material.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:babysteps_app/theme/app_theme.dart';
import 'package:provider/provider.dart';
import 'package:babysteps_app/providers/baby_provider.dart';
import 'package:babysteps_app/screens/onboarding_baby_screen.dart';
import 'package:babysteps_app/screens/onboarding_nurture_global_screen.dart';
import 'package:babysteps_app/widgets/onboarding_app_bar.dart';
import 'package:babysteps_app/widgets/staggered_animation.dart';
import 'package:babysteps_app/utils/app_animations.dart';

const Color _goalsBackgroundColor = Colors.white;

const Color _goalCardIdleBackground = Colors.white;
const Color _goalCardSelectedBackground = Color(0xFFF4ECFB);

const Map<String, IconData> _goalIconKeywords = {
  'friendship': FeatherIcons.users,
  'curiosity': FeatherIcons.search,
  'intelligence': FeatherIcons.bookOpen,
  'confidence': FeatherIcons.trendingUp,
  'resilience': FeatherIcons.shield,
  'kindness': FeatherIcons.heart,
  'empathy': FeatherIcons.feather,
  'routine': FeatherIcons.clock,
  'habit': FeatherIcons.refreshCw,
  'outdoor': FeatherIcons.sun,
  'movement': FeatherIcons.activity,
  'creativity': FeatherIcons.edit3,
  'play': FeatherIcons.smile,
};

class OnboardingGoalsScreen extends StatefulWidget {
  const OnboardingGoalsScreen({super.key});

  @override
  State<OnboardingGoalsScreen> createState() => _OnboardingGoalsScreenState();
}

class _OnboardingGoalsScreenState extends State<OnboardingGoalsScreen> {
  final Set<String> _selected = <String>{};
  final TextEditingController _customController = TextEditingController();

  final List<String> _options = const [
    'Strong friendship with my child',
    'Curiosity & intelligence',
    'Confidence & resilience',
    'Kindness & empathy',
    'Healthy routines & habits',
    'Love of outdoors & movement',
    'Creativity & playfulness',
  ];

  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _customController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final babyProvider = Provider.of<BabyProvider>(context, listen: false);
    final prefs = await babyProvider.getUserPreferences();
    final existing = List<String>.from(prefs['goals'] ?? <String>[]);
    setState(() {
      _selected
        ..clear()
        ..addAll(existing);
      _loading = false;
    });
  }

  Future<void> _saveAndNext() async {
    final babyProvider = Provider.of<BabyProvider>(context, listen: false);
    try {
      await babyProvider.saveUserGoals(_selected.toList());
    } catch (e) {
      print('Error saving goals during onboarding: $e');
    }
    if (!mounted) return;
    Navigator.of(context).pushWithFade(const OnboardingBabyScreen());
  }

  IconData _resolveGoalIcon(String label) {
    final lower = label.toLowerCase();
    for (final entry in _goalIconKeywords.entries) {
      if (lower.contains(entry.key)) {
        return entry.value;
      }
    }
    return FeatherIcons.star;
  }

  Widget _buildGoalCard({required int index, required String label, required bool isSelected}) {
    final accent = AppTheme.primaryPurple;
    final icon = _resolveGoalIcon(label);
    final borderColor = isSelected ? accent.withOpacity(0.5) : accent.withOpacity(0.2);
    final background = isSelected ? _goalCardSelectedBackground : _goalCardIdleBackground;
    final shadows = [
      BoxShadow(
        color: accent.withOpacity(isSelected ? 0.18 : 0.08),
        blurRadius: isSelected ? 20 : 14,
        offset: const Offset(0, 8),
      ),
    ];

    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: StaggeredAnimation(
        index: index,
        child: GestureDetector(
          onTap: () {
            setState(() {
              if (isSelected) {
                _selected.remove(label);
              } else {
                _selected.add(label);
              }
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: borderColor, width: isSelected ? 2 : 1),
              boxShadow: shadows,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: isSelected
                        ? LinearGradient(
                            colors: [
                              accent.withOpacity(0.28),
                              accent.withOpacity(0.08),
                            ],
                          )
                        : null,
                    color: isSelected ? null : AppTheme.lightPurple.withOpacity(0.28),
                    border: Border.all(
                      color: isSelected ? accent.withOpacity(0.5) : accent.withOpacity(0.22),
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Icon(
                    icon,
                    color: isSelected ? Colors.white : accent.withOpacity(0.75),
                    size: 26,
                  ),
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
                if (isSelected)
                  Icon(
                    Icons.check_circle,
                    color: accent,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final customSelected = _selected.where((s) => !_options.contains(s)).toList();
    final items = [..._options, ...customSelected];

    return Scaffold(
      backgroundColor: _goalsBackgroundColor,
      body: Container(
        color: _goalsBackgroundColor,
        child: SafeArea(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  children: [
                    OnboardingAppBar(
                      onBackPressed: () {
                        Navigator.of(context).pushReplacementWithFade(
                          const OnboardingNurtureGlobalScreen(),
                        );
                      },
                    ),
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                        children: [
                          const SizedBox(height: 12),
                          const Text(
                            'What long-term goals do you have as a parent?',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Pick as many as you like. You can add your own.',
                            style: TextStyle(
                              fontSize: 15,
                              color: AppTheme.textSecondary.withOpacity(0.85),
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 28),
                          ...items.asMap().entries.map((entry) {
                            final label = entry.value;
                            final isSelected = _selected.contains(label);
                            return _buildGoalCard(
                              index: entry.key,
                              label: label,
                              isSelected: isSelected,
                            );
                          }),
                          const SizedBox(height: 24),
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: AppTheme.primaryPurple.withOpacity(0.12)),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.primaryPurple.withOpacity(0.08),
                                  blurRadius: 16,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Add your own',
                                  style: TextStyle(
                                    color: AppTheme.textPrimary,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextField(
                                        controller: _customController,
                                        onSubmitted: (value) {
                                          final text = value.trim();
                                          if (text.isEmpty) return;
                                          setState(() {
                                            _selected.add(text);
                                            _customController.clear();
                                          });
                                        },
                                        style: const TextStyle(color: AppTheme.textPrimary),
                                        decoration: InputDecoration(
                                          hintText: 'Enter a custom goal',
                                          hintStyle: TextStyle(color: AppTheme.textSecondary.withOpacity(0.7)),
                                          filled: true,
                                          fillColor: AppTheme.lightPurple.withOpacity(0.35),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(14),
                                            borderSide: BorderSide(color: AppTheme.primaryPurple.withOpacity(0.2)),
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(14),
                                            borderSide: BorderSide(color: AppTheme.primaryPurple.withOpacity(0.2)),
                                          ),
                                          focusedBorder: const OutlineInputBorder(
                                            borderRadius: BorderRadius.all(Radius.circular(14)),
                                            borderSide: BorderSide(color: AppTheme.primaryPurple, width: 1.6),
                                          ),
                                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    ElevatedButton(
                                      onPressed: () {
                                        final text = _customController.text.trim();
                                        if (text.isEmpty) return;
                                        setState(() {
                                          _selected.add(text);
                                          _customController.clear();
                                        });
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppTheme.primaryPurple,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      ),
                                      child: const Text(
                                        'Add',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 48),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: ElevatedButton(
                        onPressed: _selected.isEmpty ? null : _saveAndNext,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryPurple,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          minimumSize: const Size(double.infinity, 54),
                        ),
                        child: const Text(
                          'Next',
                          style: TextStyle(
                            fontSize: 16,
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
}
