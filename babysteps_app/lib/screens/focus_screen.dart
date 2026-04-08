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
      // Silently ignored
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
      final completed = baby.completedMilestones.toSet();
      final outstanding = all.where((m) => !completed.contains(m.id) && !completed.contains(m.title)).toList();
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
      // Silently ignored
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
                    Text('Focus for ${baby.name}',
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    const Text('Tap to add or remove focus areas. You can change these anytime.',
                        style: TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
                    const SizedBox(height: 20),

                    // Current focus section
                    Row(
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: AppTheme.primaryPurple.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.star_rounded, size: 16, color: AppTheme.primaryPurple),
                        ),
                        const SizedBox(width: 10),
                        const Text('Current focus', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryPurple.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text('${current.length}',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.primaryPurple)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    if (current.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFE5E7EB)),
                        ),
                        child: const Text('No current focus. Tap items below to add.',
                            style: TextStyle(color: AppTheme.textSecondary)),
                      )
                    else
                      ...current.map((opt) => _buildFocusItem(
                        label: opt,
                        isSelected: true,
                        onTap: () async {
                          setState(() { _selected.remove(opt); });
                          await _saveSelections(baby.id);
                        },
                      )),

                    const SizedBox(height: 24),

                    // Potential focus section
                    Row(
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(Icons.add_rounded, size: 16, color: Colors.grey.shade500),
                        ),
                        const SizedBox(width: 10),
                        const Text('Suggested focus', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ...potential.map((opt) => _buildFocusItem(
                      label: opt,
                      isSelected: false,
                      onTap: () async {
                        setState(() { _selected.add(opt); });
                        await _saveSelections(baby.id);
                      },
                    )),

                    // Custom focus button
                    Padding(
                      padding: const EdgeInsets.only(top: 4, bottom: 8),
                      child: GestureDetector(
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
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppTheme.primaryPurple.withOpacity(0.3), style: BorderStyle.solid),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_rounded, size: 18, color: AppTheme.primaryPurple),
                              SizedBox(width: 6),
                              Text('Add custom focus',
                                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.primaryPurple)),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFocusItem({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? AppTheme.primaryPurple : const Color(0xFFE5E7EB),
              width: isSelected ? 1.5 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected ? AppTheme.textPrimary : AppTheme.textSecondary,
                  ),
                ),
              ),
              if (isSelected)
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryPurple.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_rounded, size: 14, color: AppTheme.primaryPurple),
                )
              else
                Icon(Icons.add_rounded, size: 20, color: Colors.grey.shade400),
            ],
          ),
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
