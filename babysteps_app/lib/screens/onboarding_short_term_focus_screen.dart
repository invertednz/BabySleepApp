import 'dart:collection';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:babysteps_app/models/baby.dart';
import 'package:babysteps_app/theme/app_theme.dart';
import 'package:babysteps_app/screens/app_container.dart';
import 'package:provider/provider.dart';
import 'package:babysteps_app/models/milestone.dart';
import 'package:babysteps_app/providers/milestone_provider.dart';
import 'package:babysteps_app/providers/baby_provider.dart';
import 'package:babysteps_app/screens/onboarding_milestones_screen.dart';
import 'package:babysteps_app/screens/onboarding_progress_preview_screen.dart';
import 'package:babysteps_app/utils/app_animations.dart';
import 'package:babysteps_app/widgets/onboarding_app_bar.dart';

class OnboardingShortTermFocusScreen extends StatefulWidget {
  final List<Baby> babies;
  final int initialIndex;
  const OnboardingShortTermFocusScreen({required this.babies, this.initialIndex = 0, super.key});

  @override
  State<OnboardingShortTermFocusScreen> createState() => _OnboardingShortTermFocusScreenState();
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

class _OnboardingShortTermFocusScreenState extends State<OnboardingShortTermFocusScreen> {
  late Baby _selectedBaby;
  int _currentIndex = 0;
  final Set<String> _selected = {};
  final TextEditingController _customController = TextEditingController();
  List<_FocusArea> _allFocusAreas = [];
  bool _isLoadingAreas = true;

  @override
  void initState() {
    super.initState();
    _currentIndex = (widget.initialIndex >= 0 && widget.initialIndex < widget.babies.length)
        ? widget.initialIndex
        : 0;
    _selectedBaby = widget.babies[_currentIndex];
    _loadSelections();
    _loadFocusAreas();
  }

  Future<void> _loadFocusAreas() async {
    try {
      final raw = await rootBundle.loadString('data/unique_focus_concerns.json');
      final decoded = json.decode(raw) as Map<String, dynamic>;
      final List<dynamic> areas = decoded['areas'] as List<dynamic>? ?? <dynamic>[];
      _allFocusAreas = areas
          .map((dynamic entry) => _FocusArea.fromJson(entry as Map<String, dynamic>))
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
    
    // Always save locally for persistence during onboarding
    await babyProvider.savePendingShortTermFocus(_selectedBaby.id, _selected.toList());
    
    // Two-week window from now as an example timeframe
    final now = DateTime.now();
    try {
      await babyProvider.saveShortTermFocus(
        babyId: _selectedBaby.id,
        focus: _selected.toList(),
        start: now,
        end: now.add(const Duration(days: 14)),
      );
    } catch (e) {
      // Silently ignored
    }
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
      final babyProvider = Provider.of<BabyProvider>(context, listen: false);
      final milestoneProvider = Provider.of<MilestoneProvider>(context, listen: false);
      final currentBaby = widget.babies.isNotEmpty ? widget.babies[_currentIndex] : null;
      
      Navigator.of(context).pushReplacementWithFade(
        OnboardingProgressPreviewScreen(
          baby: currentBaby,
          milestones: milestoneProvider.milestones,
        ),
      );
    }
  }

  Future<void> _back() async {
    await _saveSelections();
    if (!mounted) return;
    Navigator.of(context).pushReplacementWithFade(
      OnboardingMilestonesScreen(babies: widget.babies),
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
                  width: 24, height: 24,
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

  @override
  Widget build(BuildContext context) {
    final baseSuggestions = _focusSuggestionsForAge(_selectedBaby);

    List<String> milestoneSuggestions = [];
    try {
      final milestoneProvider = Provider.of<MilestoneProvider>(context, listen: false);
      final List<Milestone> all = List<Milestone>.from(milestoneProvider.milestones);
      final int babyAgeWeeks = DateTime.now().difference(_selectedBaby.birthdate).inDays ~/ 7;
      final completed = _selectedBaby.completedMilestones.toSet();
      final outstanding = all.where((m) => !completed.contains(m.id) && !completed.contains(m.title)).toList();
      outstanding.sort((a, b) => a.firstNoticedWeeks.compareTo(b.firstNoticedWeeks));

      final prioritized = outstanding
          .where((m) => m.firstNoticedWeeks <= babyAgeWeeks)
          .take(6)
          .toList();

      final fallbackNeeded = prioritized.length < 6;
      final List<Milestone> finalList = List<Milestone>.from(prioritized);
      if (fallbackNeeded) {
        final remaining = outstanding.where((m) => !finalList.contains(m)).take(6 - finalList.length);
        finalList.addAll(remaining);
      }

      milestoneSuggestions = finalList.map((m) => m.title).toList();
    } catch (_) {
      // Provider may not be ready; ignore milestone suggestions in that case.
    }

    final LinkedHashSet<String> merged = LinkedHashSet<String>()
      ..addAll(baseSuggestions)
      ..addAll(milestoneSuggestions);
    final customSelected = _selected.where((s) => !merged.contains(s)).toList();
    final items = [...merged, ...customSelected];

    // Split into selected and unselected
    final selectedItems = items.where((i) => _selected.contains(i)).toList();
    final unselectedItems = items.where((i) => !_selected.contains(i)).toList();

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            OnboardingAppBar(
              onBackPressed: _back,
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text('What would you like to focus on for ${_selectedBaby.name} right now?',
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  const Text('Tap to add or remove. You can change these anytime.',
                      style: TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
                  const SizedBox(height: 20),
                  if (_isLoadingAreas)
                    const Center(child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 32.0),
                      child: CircularProgressIndicator(),
                    ))
                  else ...[
                    // Selected items section
                    if (selectedItems.isNotEmpty) ...[
                      Row(
                        children: [
                          Container(
                            width: 28, height: 28,
                            decoration: BoxDecoration(
                              color: AppTheme.primaryPurple.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.star_rounded, size: 16, color: AppTheme.primaryPurple),
                          ),
                          const SizedBox(width: 10),
                          const Text('Selected', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryPurple.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text('${selectedItems.length}',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.primaryPurple)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ...selectedItems.map((opt) => _buildFocusItem(
                        label: opt, isSelected: true, onTap: () => _toggle(opt),
                      )),
                      const SizedBox(height: 20),
                    ],

                    // Unselected suggestions
                    Row(
                      children: [
                        Container(
                          width: 28, height: 28,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(Icons.add_rounded, size: 16, color: Colors.grey.shade500),
                        ),
                        const SizedBox(width: 10),
                        const Text('Suggestions', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ...unselectedItems.map((opt) => _buildFocusItem(
                      label: opt, isSelected: false, onTap: () => _toggle(opt),
                    )),

                    // Add custom
                    Padding(
                      padding: const EdgeInsets.only(top: 4, bottom: 8),
                      child: GestureDetector(
                        onTap: () {
                          final text = _customController.text.trim();
                          if (text.isEmpty) return;
                          setState(() {
                            _selected.add(text);
                            _customController.clear();
                          });
                        },
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _customController,
                                decoration: InputDecoration(
                                  hintText: 'Add a custom focus',
                                  hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: AppTheme.primaryPurple.withOpacity(0.3)),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: AppTheme.primaryPurple.withOpacity(0.3)),
                                  ),
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
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryPurple,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                              ),
                              child: const Text('Add'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton(
                onPressed: _selected.isEmpty ? null : _next,
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: Text(
                  _currentIndex < widget.babies.length - 1
                      ? 'Next: ${widget.babies[_currentIndex + 1].name}'
                      : 'Complete',
                  style: const TextStyle(fontSize: 18),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
