import 'package:flutter/material.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:babysteps_app/theme/app_theme.dart';
import 'package:provider/provider.dart';
import 'package:babysteps_app/providers/baby_provider.dart';
import 'package:babysteps_app/screens/onboarding_goals_screen.dart';
import 'package:babysteps_app/screens/onboarding_parenting_style_screen.dart';
import 'package:babysteps_app/utils/app_animations.dart';
import 'package:babysteps_app/widgets/onboarding_app_bar.dart';
import 'package:babysteps_app/widgets/staggered_animation.dart';

const Color _nurtureBackgroundColor = Colors.white;

const Color _nurtureCardIdleBackground = Colors.white;
const Color _nurtureCardSelectedBackground = Color(0xFFF4ECFB);

const Map<String, IconData> _nurtureIconMappings = {
  'curiosity': FeatherIcons.search,
  'exploration': FeatherIcons.compass,
  'resilience': FeatherIcons.shield,
  'self-soothing': FeatherIcons.heart,
  'sleep': FeatherIcons.moon,
  'attachment': FeatherIcons.link,
  'bonding': FeatherIcons.heart,
  'communication': FeatherIcons.messageCircle,
  'language': FeatherIcons.type,
  'motor skills': FeatherIcons.activity,
  'play': FeatherIcons.playCircle,
  'emotional regulation': FeatherIcons.feather,
  'independence': FeatherIcons.unlock,
  'routines': FeatherIcons.clock,
  'creativity': FeatherIcons.edit3,
  'creativity ': FeatherIcons.edit3,
};

class OnboardingNurtureGlobalScreen extends StatefulWidget {
  const OnboardingNurtureGlobalScreen({super.key});

  @override
  State<OnboardingNurtureGlobalScreen> createState() => _OnboardingNurtureGlobalScreenState();
}

class _OnboardingNurtureGlobalScreenState extends State<OnboardingNurtureGlobalScreen> {
  final Set<String> _selected = {};
  final TextEditingController _customController = TextEditingController();

  final List<String> _options = const [
    'Curiosity and exploration',
    'Resilience and self-soothing',
    'Calm and predictable sleep',
    'Secure attachment and bonding',
    'Communication and early language',
    'Motor skills and active play',
    'Emotional regulation',
    'Independence in routines',
    'Playful creativity',
  ];

  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final babyProvider = Provider.of<BabyProvider>(context, listen: false);
    final prefs = await babyProvider.getUserPreferences();
    final existing = List<String>.from(prefs['nurture_priorities'] ?? <String>[]);
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
      await babyProvider.saveUserNurturePriorities(_selected.toList());
    } catch (e) {
      print('Error saving nurture priorities during onboarding: $e');
    }
    if (!mounted) return;
    Navigator.of(context).pushWithFade(const OnboardingGoalsScreen());
  }

  @override
  Widget build(BuildContext context) {
    IconData _resolveNurtureIcon(String label) {
      final lower = label.toLowerCase();
      for (final entry in _nurtureIconMappings.entries) {
        if (lower.contains(entry.key)) {
          return entry.value;
        }
      }
      return FeatherIcons.star;
    }

    Widget buildQualityCard({
      required int index,
      required String label,
      required IconData icon,
    }) {
      final isSelected = _selected.contains(label);
      final accent = AppTheme.primaryPurple;
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
                color: isSelected ? _nurtureCardSelectedBackground : _nurtureCardIdleBackground,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? accent.withOpacity(0.5) : accent.withOpacity(0.18),
                  width: isSelected ? 2 : 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: accent.withOpacity(isSelected ? 0.18 : 0.08),
                    blurRadius: isSelected ? 20 : 14,
                    offset: const Offset(0, 8),
                  ),
                ],
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

    final customSelected = _selected.where((s) => !_options.contains(s)).toList();
    final items = [..._options, ...customSelected];
    return Scaffold(
      backgroundColor: _nurtureBackgroundColor,
      body: Container(
        color: _nurtureBackgroundColor,
        child: SafeArea(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  children: [
                    OnboardingAppBar(
                      onBackPressed: () {
                        Navigator.of(context).pushReplacementWithFade(
                          OnboardingParentingStyleScreen(babies: const []),
                        );
                      },
                    ),
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                        children: [
                          const SizedBox(height: 12),
                          const Text(
                            'What qualities would you most like to nurture?',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Pick as many as you like. You can change these anytime.',
                            style: TextStyle(
                              fontSize: 15,
                              color: AppTheme.textSecondary.withOpacity(0.85),
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 28),
                          ...items.asMap().entries.map((entry) {
                            final index = entry.key;
                            final label = entry.value;
                            final icon = _resolveNurtureIcon(label);
                            return buildQualityCard(
                              index: index,
                              label: label,
                              icon: icon,
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
                                          hintText: 'Enter a custom quality',
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
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
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
