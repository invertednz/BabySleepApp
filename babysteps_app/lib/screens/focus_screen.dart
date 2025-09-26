import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:babysteps_app/theme/app_theme.dart';
import 'package:babysteps_app/providers/baby_provider.dart';
import 'package:babysteps_app/providers/milestone_provider.dart';
import 'package:babysteps_app/models/baby.dart';
import 'package:babysteps_app/widgets/app_header.dart';

class FocusScreen extends StatefulWidget {
  const FocusScreen({super.key});

  @override
  State<FocusScreen> createState() => _FocusScreenState();
}

class _FocusScreenState extends State<FocusScreen> {
  final Set<String> _selected = {};
  final TextEditingController _customController = TextEditingController();
  String? _currentBabyId;

  @override
  void dispose() {
    _customController.dispose();
    super.dispose();
  }

  Future<void> _loadSelections(String babyId) async {
    final babyProvider = Provider.of<BabyProvider>(context, listen: false);
    final items = await babyProvider.getShortTermFocus(babyId: babyId);
    if (!mounted) return;
    setState(() {
      _selected
        ..clear()
        ..addAll(items);
      _currentBabyId = babyId;
    });
  }

  Future<void> _saveSelections(String babyId) async {
    final now = DateTime.now();
    final babyProvider = Provider.of<BabyProvider>(context, listen: false);
    await babyProvider.saveShortTermFocus(
      babyId: babyId,
      focus: _selected.toList(),
      start: now,
      end: now.add(const Duration(days: 14)),
    );
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

  void _toggleAndSave(String label, String babyId) async {
    setState(() {
      if (_selected.contains(label)) {
        _selected.remove(label);
      } else {
        _selected.add(label);
      }
    });
    await _saveSelections(babyId);
  }

  @override
  Widget build(BuildContext context) {
    final babyProvider = Provider.of<BabyProvider>(context);
    final milestoneProvider = Provider.of<MilestoneProvider>(context, listen: false);
    final baby = babyProvider.selectedBaby;

    if (baby == null) {
      return const Scaffold(
        body: SafeArea(
          child: Center(child: Text('Please select a baby first.')),
        ),
      );
    }

    // If baby changed, load selections after this frame
    if (_currentBabyId != baby.id) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _loadSelections(baby.id);
      });
    }

    // Suggestions (age + milestone)
    final base = _suggestionsForAge(baby);
    final weeks = DateTime.now().difference(baby.birthdate).inDays ~/ 7;
    List<String> milestoneSuggestions = [];
    try {
      milestoneSuggestions = milestoneProvider.milestones
          .where((m) => m.firstNoticedWeeks <= weeks && !baby.completedMilestones.contains(m.title))
          .map((m) => m.title)
          .toList();
    } catch (_) {}
    final merged = {...base, ...milestoneSuggestions};
    final customSelected = _selected.where((s) => !merged.contains(s)).toList();
    final items = [...merged];

    // Split into current and potential
    final current = [..._selected, ...customSelected];
    final potential = items.where((i) => !_selected.contains(i)).toList();

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            const AppHeader(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text('Short-Term Focus for ${baby.name}',
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  const Text('Pick as many as you like. You can change these anytime.',
                      style: TextStyle(color: AppTheme.textSecondary)),
                  const SizedBox(height: 16),
                  // Current Focus section
                  const Text('Current focus', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  if (current.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                      ),
                      child: const Text('No current focus. Add from the suggestions below.'),
                    )
                  else
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      physics: const NeverScrollableScrollPhysics(),
                      childAspectRatio: 6.0,
                      children: current.map((opt) {
                        return GestureDetector(
                          onTap: () async {
                            setState(() { _selected.remove(opt); });
                            await _saveSelections(baby.id);
                          },
                          child: Card(
                            elevation: 1,
                            color: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: const BorderSide(color: AppTheme.primaryPurple, width: 1.5),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8.0),
                              child: Center(
                                child: Text(
                                  opt,
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                    height: 1.2,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),

            const SizedBox(height: 20),
            // Potential Focus
            const Text('Potential focus', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 6.0,
              children: [
                ...potential.map((opt) {
                  return GestureDetector(
                    onTap: () async {
                      setState(() { _selected.add(opt); });
                      await _saveSelections(baby.id);
                    },
                    child: Card(
                      elevation: 1,
                      color: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.grey.shade300, width: 1.5),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Center(
                          child: Text(
                            opt,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                              height: 1.2,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }),

                // + Custom focus card
                GestureDetector(
                  onTap: () async {
                    final controller = TextEditingController();
                    final text = await showDialog<String>(
                      context: context,
                      builder: (ctx) {
                        return AlertDialog(
                          title: const Text('Add custom focus'),
                          content: TextField(
                            controller: controller,
                            decoration: const InputDecoration(hintText: 'Enter a custom focus'),
                            autofocus: true,
                          ),
                          actions: [
                            TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
                            TextButton(onPressed: () => Navigator.of(ctx).pop(controller.text.trim()), child: const Text('Add')),
                          ],
                        );
                      },
                    );
                    if (text != null && text.isNotEmpty) {
                      setState(() { _selected.add(text); });
                      await _saveSelections(baby.id);
                    }
                  },
                  child: Card(
                    elevation: 1,
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Colors.grey.shade300, width: 1.5),
                    ),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8.0),
                      child: Center(
                        child: Text(
                          '+ Custom focus',
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                            height: 1.2,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
