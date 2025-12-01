import 'package:flutter/material.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:babysteps_app/models/baby.dart';
import 'package:babysteps_app/theme/app_theme.dart';
import 'package:babysteps_app/screens/onboarding_nurture_global_screen.dart';
import 'package:babysteps_app/screens/onboarding_notifications_screen.dart';
import 'package:provider/provider.dart' as flutter_provider;
import 'package:babysteps_app/providers/baby_provider.dart';
import 'package:babysteps_app/utils/app_animations.dart';
import 'package:babysteps_app/widgets/onboarding_app_bar.dart';
import 'package:babysteps_app/widgets/staggered_animation.dart';

const Color _parentingBackgroundColor = Colors.white;

const Color _parentingCardIdleBackground = Colors.white;
const Color _parentingCardSelectedBackground = Color(0xFFF4ECFB);

const Map<String, IconData> _styleIconMappings = {
  'gentle': FeatherIcons.heart,
  'responsive': FeatherIcons.messageCircle,
  'structured': FeatherIcons.grid,
  'predictable': FeatherIcons.clock,
  'flexible': FeatherIcons.shuffle,
  'adaptive': FeatherIcons.sliders,
  'attachment': FeatherIcons.link,
  'routine': FeatherIcons.calendar,
  'play': FeatherIcons.smile,
  'centered': FeatherIcons.smile,
};

class OnboardingParentingStyleScreen extends StatefulWidget {
  final List<Baby> babies;
  final int initialIndex;
  const OnboardingParentingStyleScreen({required this.babies, this.initialIndex = 0, super.key});

  @override
  State<OnboardingParentingStyleScreen> createState() => _OnboardingParentingStyleScreenState();
}

class _OnboardingParentingStyleScreenState extends State<OnboardingParentingStyleScreen> {
  Baby? _selectedBaby;
  int _currentIndex = 0;
  final Set<String> _selectedStyles = <String>{};
  final TextEditingController _customController = TextEditingController();

  final List<String> _styles = const [
    'Gentle & Responsive',
    'Structured & Predictable',
    'Flexible & Adaptive',
    'Attachment-Focused',
    'Routine-Led',
    'Play-Centered',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.babies.isNotEmpty) {
      _currentIndex = (widget.initialIndex >= 0 && widget.initialIndex < widget.babies.length)
          ? widget.initialIndex
          : 0;
      _selectedBaby = widget.babies[_currentIndex];
    }
  }

  @override
  void dispose() {
    _customController.dispose();
    super.dispose();
  }

  void _toggle(String style) {
    setState(() {
      if (_selectedStyles.contains(style)) {
        _selectedStyles.remove(style);
      } else {
        _selectedStyles.add(style);
      }
    });
  }

  Future<void> _next() async {
    final babyProvider = flutter_provider.Provider.of<BabyProvider>(context, listen: false);
    
    // Always save locally for persistence during onboarding
    await babyProvider.savePendingOnboardingPreferences({
      'parenting_styles': _selectedStyles.toList(),
    });
    
    try {
      await babyProvider.saveUserParentingStyles(_selectedStyles.toList());
    } catch (e) {
      // In guest mode, save fails. Data is already stored locally.
      print('Error saving parenting styles (will persist on signup): $e');
    }
    if (!mounted) return;
    Navigator.of(context).pushWithFade(const OnboardingNurtureGlobalScreen());
  }

  IconData _resolveStyleIcon(String label) {
    final lower = label.toLowerCase();
    for (final entry in _styleIconMappings.entries) {
      if (lower.contains(entry.key)) {
        return entry.value;
      }
    }
    return FeatherIcons.star;
  }

  Widget _buildStyleCard({required int index, required String label}) {
    final isSelected = _selectedStyles.contains(label);
    final accent = AppTheme.primaryPurple;

    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: StaggeredAnimation(
        index: index,
        child: GestureDetector(
          onTap: () => _toggle(label),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isSelected ? _parentingCardSelectedBackground : _parentingCardIdleBackground,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected ? accent.withOpacity(0.55) : accent.withOpacity(0.18),
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
                              accent.withOpacity(0.25),
                              accent.withOpacity(0.08),
                            ],
                          )
                        : null,
                    color: isSelected ? null : AppTheme.lightPurple.withOpacity(0.28),
                    border: Border.all(
                      color: isSelected ? accent.withOpacity(0.55) : accent.withOpacity(0.22),
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Icon(
                    _resolveStyleIcon(label),
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
    final customSelected = _selectedStyles.where((s) => !_styles.contains(s)).toList();
    final items = [..._styles, ...customSelected];

    return Scaffold(
      backgroundColor: _parentingBackgroundColor,
      body: Container(
        color: _parentingBackgroundColor,
        child: SafeArea(
          child: Column(
            children: [
              OnboardingAppBar(
                onBackPressed: () {
                  Navigator.of(context).pushReplacementWithFade(
                    const OnboardingNotificationsScreen(),
                  );
                },
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  children: [
                    const SizedBox(height: 12),
                    const Text(
                      'What is your parenting style?',
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
                    ...items.asMap().entries.map(
                      (entry) => _buildStyleCard(
                        index: entry.key,
                        label: entry.value,
                      ),
                    ),
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
                                      _selectedStyles.add(text);
                                      _customController.clear();
                                    });
                                  },
                                  style: const TextStyle(color: AppTheme.textPrimary),
                                  decoration: InputDecoration(
                                    hintText: 'Enter a custom parenting style',
                                    hintStyle: TextStyle(color: AppTheme.textSecondary.withOpacity(0.6)),
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
                                    _selectedStyles.add(text);
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
                  onPressed: _selectedStyles.isEmpty ? null : _next,
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
