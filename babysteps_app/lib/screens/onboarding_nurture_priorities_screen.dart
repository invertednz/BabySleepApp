import 'package:flutter/material.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:babysteps_app/models/baby.dart';
import 'package:babysteps_app/theme/app_theme.dart';
import 'package:babysteps_app/screens/onboarding_short_term_focus_screen.dart';
import 'package:babysteps_app/screens/onboarding_parenting_style_screen.dart';
import 'package:provider/provider.dart';
import 'package:babysteps_app/providers/baby_provider.dart';
import 'package:babysteps_app/screens/onboarding_concerns_screen.dart';
import 'package:babysteps_app/utils/app_animations.dart';
import 'package:babysteps_app/widgets/onboarding_app_bar.dart';

class OnboardingNurturePrioritiesScreen extends StatefulWidget {
  final List<Baby> babies;
  final int initialIndex;
  const OnboardingNurturePrioritiesScreen({required this.babies, this.initialIndex = 0, super.key});

  @override
  State<OnboardingNurturePrioritiesScreen> createState() => _OnboardingNurturePrioritiesScreenState();
}

class _OnboardingNurturePrioritiesScreenState extends State<OnboardingNurturePrioritiesScreen> {
  late Baby _selectedBaby;
  int _currentIndex = 0;
  final Set<String> _selected = {};

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

  @override
  void initState() {
    super.initState();
    _currentIndex = (widget.initialIndex >= 0 && widget.initialIndex < widget.babies.length)
        ? widget.initialIndex
        : 0;
    _selectedBaby = widget.babies[_currentIndex];
    _loadSelections();
  }

  Future<void> _loadSelections() async {
    final babyProvider = Provider.of<BabyProvider>(context, listen: false);
    final items = await babyProvider.getNurturePriorities(babyId: _selectedBaby.id);
    _selected
      ..clear()
      ..addAll(items);
    if (mounted) setState(() {});
  }

  Future<void> _saveSelections() async {
    final babyProvider = Provider.of<BabyProvider>(context, listen: false);
    try {
      await babyProvider.saveNurturePriorities(
        babyId: _selectedBaby.id,
        priorities: _selected.toList(),
      );
    } catch (e) {
      print('Error saving nurture priorities for baby during onboarding: $e');
    }
  }

  void _toggle(String label, bool value) {
    setState(() {
      if (value) {
        _selected.add(label);
      } else {
        _selected.remove(label);
      }
    });
  }

  Future<void> _next() async {
    await _saveSelections();
    if (!mounted) return;
    // Stay on Nurture for the next baby until last
    if (_currentIndex < widget.babies.length - 1) {
      setState(() {
        _currentIndex += 1;
        _selectedBaby = widget.babies[_currentIndex];
      });
      await _loadSelections();
    } else {
      Navigator.of(context).pushWithFade(
        OnboardingParentingStyleScreen(
          babies: widget.babies,
          initialIndex: _currentIndex,
        ),
      );
    }
  }

  Future<void> _back() async {
    await _saveSelections();
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex -= 1;
        _selectedBaby = widget.babies[_currentIndex];
      });
      await _loadSelections();
    } else {
      if (!mounted) return;
      Navigator.of(context).pushReplacementWithFade(
        OnboardingConcernsScreen(
          babies: widget.babies,
          initialIndex: _currentIndex,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            OnboardingAppBar(
              onBackPressed: _back,
            ),
            const OnboardingProgressBar(progress: 0.8),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text('Which qualities would you most like to nurture in ${_selectedBaby.name} right now?',
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  const Text('Choose a few you’d like extra support with. You can change these anytime.',
                      style: TextStyle(color: AppTheme.textSecondary)),
                  const SizedBox(height: 16),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    physics: const NeverScrollableScrollPhysics(),
                    childAspectRatio: 3.0,
                    children: _options.map((opt) {
                      final isSelected = _selected.contains(opt);
                      return GestureDetector(
                        onTap: () => _toggle(opt, !isSelected),
                        child: Card(
                          elevation: isSelected ? 3 : 1,
                          color: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: isSelected ? AppTheme.primaryPurple : Colors.grey.shade300,
                              width: isSelected ? 2 : 1.5,
                            ),
                          ),
                          child: Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8.0),
                              child: Text(
                                opt,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: isSelected ? AppTheme.primaryPurple : AppTheme.textPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton(
                onPressed: _next,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryPurple,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: Text(
                  _currentIndex < widget.babies.length - 1
                      ? 'Next: ${widget.babies[_currentIndex + 1].name}'
                      : 'Next',
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
