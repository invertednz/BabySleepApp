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
    try {
      await babyProvider.saveShortTermFocus(
        babyId: _selectedBaby.id,
        focus: _selected.toList(),
        start: now,
        end: now.add(const Duration(days: 14)),
      );
    } catch (e) {
      print('Error saving short-term focus during onboarding: $e');
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

  @override
  Widget build(BuildContext context) {
    final baseSuggestions = _focusSuggestionsForAge(_selectedBaby);

    List<String> milestoneSuggestions = [];
    try {
      final milestoneProvider = Provider.of<MilestoneProvider>(context, listen: false);
      final List<Milestone> all = List<Milestone>.from(milestoneProvider.milestones);
      final int babyAgeWeeks = DateTime.now().difference(_selectedBaby.birthdate).inDays ~/ 7;
      final outstanding = all.where((m) => !_selectedBaby.completedMilestones.contains(m.title)).toList();
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
                  const Text('Pick as many as you like. You can change these anytime.',
                      style: TextStyle(color: AppTheme.textSecondary)),
                  const SizedBox(height: 16),
                  if (_isLoadingAreas)
                    const Center(child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 32.0),
                      child: CircularProgressIndicator(),
                    ))
                  else
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
              child: ElevatedButton(
                onPressed: _selected.isEmpty ? null : _next,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryPurple,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: Text(
                  _currentIndex < widget.babies.length - 1
                      ? 'Next: ${widget.babies[_currentIndex + 1].name}'
                      : 'Complete',
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
