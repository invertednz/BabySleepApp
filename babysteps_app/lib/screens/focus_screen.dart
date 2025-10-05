import 'dart:collection';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:babysteps_app/theme/app_theme.dart';
import 'package:babysteps_app/providers/baby_provider.dart';
import 'package:babysteps_app/providers/milestone_provider.dart';
import 'package:babysteps_app/models/baby.dart';
import 'package:babysteps_app/models/milestone.dart';
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
  List<_FocusArea> _allFocusAreas = [];
  bool _isLoadingAreas = true;

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

  Future<void> _loadFocusAreas() async {
    try {
      final raw = await rootBundle.loadString('data/unique_focus_concerns.json');
      final decoded = json.decode(raw) as Map<String, dynamic>;
      final List<dynamic> areas = decoded['areas'] as List<dynamic>? ?? <dynamic>[];
      _allFocusAreas = areas
          .map((dynamic entry) => _FocusArea.fromJson(entry as Map<String, dynamic>))
          .where((area) => area.label.isNotEmpty)
          .toList();
    } catch (e) {
      debugPrint('Error loading focus areas: $e');
      _allFocusAreas = [];
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingAreas = false;
        });
      }
    }
  }

  List<String> _focusSuggestionsForAge(Baby baby) {
    if (_allFocusAreas.isEmpty) return [];
    final weeks = DateTime.now().difference(baby.birthdate).inDays ~/ 7;
    return _allFocusAreas
        .where((area) => area.matchesWeek(weeks))
        .map((area) => area.label)
        .toList();
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
    if (_isLoadingAreas) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_isLoadingAreas) return;
        _loadFocusAreas();
      });
    }

    final base = _focusSuggestionsForAge(baby);
    List<String> milestoneSuggestions = [];
    try {
      final List<Milestone> all = List<Milestone>.from(milestoneProvider.milestones);
      final int babyAgeWeeks = DateTime.now().difference(baby.birthdate).inDays ~/ 7;
      final outstanding = all.where((m) => !baby.completedMilestones.contains(m.title)).toList();
      outstanding.sort((a, b) => a.firstNoticedWeeks.compareTo(b.firstNoticedWeeks));

      final prioritized = outstanding
          .where((m) => m.firstNoticedWeeks <= babyAgeWeeks)
          .take(6)
          .toList();

      final List<Milestone> finalList = List<Milestone>.from(prioritized);
      if (finalList.length < 6) {
        final remaining = outstanding.where((m) => !finalList.contains(m)).take(6 - finalList.length);
        finalList.addAll(remaining);
      }

      milestoneSuggestions = finalList.map((m) => m.title).toList();
    } catch (e) {
      debugPrint('Error preparing milestone suggestions: $e');
    }

    final LinkedHashSet<String> merged = LinkedHashSet<String>()
      ..addAll(base)
      ..addAll(milestoneSuggestions);
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
                  if (_isLoadingAreas)
                    const SizedBox.shrink()
                  else ...[
                    Text('Short-Term Focus for ${baby.name}',
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    const Text('Pick as many as you like. You can change these anytime.',
                        style: TextStyle(color: AppTheme.textSecondary)),
                    const SizedBox(height: 16),
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
                              setState(() {
                                _selected.remove(opt);
                              });
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
                              setState(() {
                                _selected.add(opt);
                              });
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
                              setState(() {
                                _selected.add(text);
                              });
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
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FocusArea {
  _FocusArea({
    required this.label,
    required this.startWeek,
    required this.endWeek,
  });

  final String label;
  final int? startWeek;
  final int? endWeek;

  bool matchesWeek(int week) {
    final bool afterStart = startWeek == null || week >= startWeek!;
    final bool beforeEnd = endWeek == null || week <= endWeek!;
    return afterStart && beforeEnd;
  }

  factory _FocusArea.fromJson(Map<String, dynamic> json) {
    return _FocusArea(
      label: json['label'] as String? ?? '',
      startWeek: json['start_week'] == null ? null : (json['start_week'] as num).round(),
      endWeek: json['end_week'] == null ? null : (json['end_week'] as num).round(),
    );
  }
}
