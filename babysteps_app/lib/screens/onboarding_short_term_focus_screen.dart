import 'package:flutter/material.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:babysteps_app/models/baby.dart';
import 'package:babysteps_app/theme/app_theme.dart';
import 'package:babysteps_app/screens/app_container.dart';
import 'package:provider/provider.dart';
import 'package:babysteps_app/models/milestone.dart';
import 'package:babysteps_app/providers/milestone_provider.dart';
import 'package:babysteps_app/providers/baby_provider.dart';
import 'package:babysteps_app/screens/onboarding_milestones_screen.dart';

class OnboardingShortTermFocusScreen extends StatefulWidget {
  final List<Baby> babies;
  final int initialIndex;
  const OnboardingShortTermFocusScreen({required this.babies, this.initialIndex = 0, super.key});

  @override
  State<OnboardingShortTermFocusScreen> createState() => _OnboardingShortTermFocusScreenState();
}

class _OnboardingShortTermFocusScreenState extends State<OnboardingShortTermFocusScreen> {
  late Baby _selectedBaby;
  int _currentIndex = 0;
  final Set<String> _selected = {};
  final TextEditingController _customController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _currentIndex = (widget.initialIndex >= 0 && widget.initialIndex < widget.babies.length)
        ? widget.initialIndex
        : 0;
    _selectedBaby = widget.babies[_currentIndex];
    _loadSelections();
  }

  List<String> _suggestionsForAge(Baby baby) {
    final weeks = DateTime.now().difference(baby.birthdate).inDays ~/ 7;
    if (weeks <= 8) {
      return [
        'Longer, more predictable naps',
        'Night wakings and self-settling',
        'Feeding efficiency or latch',
        'Tummy time tolerance',
        'Soothing routines for fussiness',
        'Day-night rhythm',
      ];
    } else if (weeks <= 17) {
      return [
        'Naps and wake windows',
        'Evening fussiness',
        'Feeding amounts and spacing',
        'Head shape (flat spots)',
        'Tummy time consistency',
        'Bedtime routine',
      ];
    } else if (weeks <= 26) {
      return [
        'Introducing solids',
        'Allergy awareness',
        'Constipation relief',
        'Rolling/sitting practice',
        'Sleep regression support',
        'Daily rhythm consistency',
      ];
    } else if (weeks <= 39) {
      return [
        'Crawling and safe exploration',
        'Separation anxiety support',
        'Teething nights',
        'Standing/cruising practice',
        'Consistent nap schedule',
        'Self-settling at bedtime',
      ];
    } else if (weeks <= 52) {
      return [
        'Early walking safety',
        'Milk intake balance',
        'Transition from bottle',
        'Food variety',
        'Night wakings reduction',
        'Stranger anxiety support',
      ];
    } else if (weeks <= 78) {
      return [
        'Speech burst support',
        'Tantrum de-escalation',
        'Sleep transitions',
        'Balanced meals and snacks',
        'Active play ideas',
        'Independent routines',
      ];
    } else if (weeks <= 104) {
      return [
        'Toilet training readiness',
        'Sleep resistance strategies',
        'Sharing and turn-taking',
        'Picky eating progress',
        'Outdoor active play',
        'Calm-down routines',
      ];
    } else {
      return [
        'Toilet training progress',
        'Night waking reduction',
        'Speech clarity support',
        'Big feelings coaching',
        'Varied foods acceptance',
        'Daily rhythm structure',
      ];
    }
  }

  Future<void> _loadSelections() async {
    final babyProvider = Provider.of<BabyProvider>(context, listen: false);
    final items = await babyProvider.getShortTermFocus(babyId: _selectedBaby.id);
    _selected
      ..clear()
      ..addAll(items);
    if (mounted) setState(() {});
  }

  Future<void> _saveSelections() async {
    final babyProvider = Provider.of<BabyProvider>(context, listen: false);
    // Two-week window from now as an example timeframe
    final now = DateTime.now();
    await babyProvider.saveShortTermFocus(
      babyId: _selectedBaby.id,
      focus: _selected.toList(),
      start: now,
      end: now.add(const Duration(days: 14)),
    );
  }

  void _toggle(String label) {
    setState(() {
      if (_selected.contains(label)) {
        _selected.remove(label);
      } else {
        _selected.add(label);
      }
    });
  }

  Future<void> _next() async {
    await _saveSelections();
    if (_currentIndex < widget.babies.length - 1) {
      setState(() {
        _currentIndex += 1;
        _selectedBaby = widget.babies[_currentIndex];
        _selected.clear();
      });
      await _loadSelections();
      if (!mounted) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Select short-term focus for ${_selectedBaby.name}')),
        );
      });
    } else {
      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => const AppContainer()),
      );
    }
  }

  Future<void> _back() async {
    await _saveSelections();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => OnboardingMilestonesScreen(babies: widget.babies),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Base suggestions
    final baseSuggestions = _suggestionsForAge(_selectedBaby);

    // Milestone-based suggestions: age-appropriate and not completed
    final weeks = DateTime.now().difference(_selectedBaby.birthdate).inDays ~/ 7;
    List<String> milestoneSuggestions = [];
    try {
      final milestoneProvider = Provider.of<MilestoneProvider>(context, listen: false);
      final List<Milestone> all = milestoneProvider.milestones;
      milestoneSuggestions = all
          .where((m) => m.firstNoticedWeeks <= weeks && !_selectedBaby.completedMilestones.contains(m.title))
          .map((m) => m.title)
          .toList();
    } catch (_) {
      // If provider not available yet, skip milestone-derived suggestions
    }

    // Merge and de-duplicate
    final Set<String> merged = {...baseSuggestions, ...milestoneSuggestions};
    // Include any custom selections not in merged so they display as cards
    final customSelected = _selected.where((s) => !merged.contains(s)).toList();
    final items = [...merged, ...customSelected];

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header like Gender screen
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  const Icon(FeatherIcons.sunrise, color: AppTheme.primaryPurple, size: 32),
                  const SizedBox(width: 8),
                  const Text('BabySteps', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  Text(_selectedBaby.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
            const LinearProgressIndicator(
              value: 0.55,
              backgroundColor: Color(0xFFE2E8F0),
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryPurple),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text('What would you like to focus on for ${_selectedBaby.name} right now?',
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Text('Baby ${_currentIndex + 1} of ${widget.babies.length}', style: const TextStyle(color: AppTheme.textSecondary)),
                  const SizedBox(height: 6),
                  const Text('Pick as many as you like. You can change these anytime.',
                      style: TextStyle(color: AppTheme.textSecondary)),
                  const SizedBox(height: 16),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    physics: const NeverScrollableScrollPhysics(),
                    childAspectRatio: 3.0,
                    children: items.map((opt) {
                      final isSelected = _selected.contains(opt);
                      return GestureDetector(
                        onTap: () => _toggle(opt),
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
                  const SizedBox(height: 8),
                  const Text('Add your own', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _customController,
                          decoration: const InputDecoration(
                            hintText: 'Enter a custom focus',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () {
                          final text = _customController.text.trim();
                          if (text.isEmpty) return;
                          setState(() {
                            _selected.add(text);
                            _customController.clear();
                          });
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryPurple),
                        child: const Text('Add'),
                      )
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _back,
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.grey),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Back'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _selected.isEmpty ? null : _next,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryPurple,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Next'),
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
