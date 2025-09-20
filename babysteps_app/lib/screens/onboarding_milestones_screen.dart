import 'dart:math';
import 'package:babysteps_app/models/milestone_group.dart';
import 'package:babysteps_app/models/milestone.dart';
import 'package:babysteps_app/providers/milestone_provider.dart';
import 'package:babysteps_app/providers/baby_provider.dart';
import 'package:provider/provider.dart';
import 'package:babysteps_app/widgets/milestone_group_card.dart';
import 'package:flutter/material.dart';

import 'package:babysteps_app/models/baby.dart';
import 'package:babysteps_app/theme/app_theme.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:confetti/confetti.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:babysteps_app/screens/onboarding_short_term_focus_screen.dart';
import 'package:babysteps_app/screens/onboarding_gender_screen.dart';
import 'package:babysteps_app/screens/onboarding_activities_loves_hates_screen.dart';

class OnboardingMilestonesScreen extends StatefulWidget {
  final List<Baby> babies;
  const OnboardingMilestonesScreen({required this.babies, super.key});

  @override
  State<OnboardingMilestonesScreen> createState() =>
      _OnboardingMilestonesScreenState();
}

class _OnboardingMilestonesScreenState
    extends State<OnboardingMilestonesScreen> {
  late Baby _selectedBaby;
  late ConfettiController _confettiController;
  final ItemScrollController _itemScrollController = ItemScrollController();
  bool _didInitialScroll = false;
  int _currentIndex = 0;

  static const List<Map<String, dynamic>> _ageGroups = [
    {'name': '0-2 Months', 'min': 0, 'max': 8},
    {'name': '3-4 Months', 'min': 9, 'max': 17},
    {'name': '5-6 Months', 'min': 18, 'max': 26},
    {'name': '7-9 Months', 'min': 27, 'max': 39},
    {'name': '10-12 Months', 'min': 40, 'max': 52},
    {'name': '13-18 Months', 'min': 53, 'max': 78},
    {'name': '19-24 Months', 'min': 79, 'max': 104},
    {'name': '2-3 Years', 'min': 105, 'max': 156},
    {'name': '3-4 Years', 'min': 157, 'max': 208},
    {'name': '4-5 Years', 'min': 209, 'max': 260},
  ];

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 1));

    if (widget.babies.isNotEmpty) {
      _currentIndex = 0;
      _selectedBaby = widget.babies[_currentIndex];
    } else {
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  void _scrollToTarget(List<MilestoneGroup> milestoneGroups) {
    if (_didInitialScroll) return; // Only scroll once on first load
    final babyAgeInWeeks = (DateTime.now().difference(_selectedBaby.birthdate).inDays / 7).round();
    int targetIndex = 0;

    if (babyAgeInWeeks > 8) { // Only scroll if older than 2 months
      final targetAgeInWeeks = babyAgeInWeeks - 4; // look back 1 month

      for (int i = 0; i < milestoneGroups.length; i++) {
        final group = milestoneGroups[i];
        final ageGroupData = _ageGroups.firstWhere((ag) => ag['name'] == group.title);
        final minWeeks = ageGroupData['min']!;
        final maxWeeks = ageGroupData['max']!;

        if (targetAgeInWeeks >= minWeeks && targetAgeInWeeks <= maxWeeks) {
          targetIndex = i;
          break;
        }
      }
    }

    if (_itemScrollController.isAttached) {
      _itemScrollController.scrollTo(
        index: targetIndex,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
      _didInitialScroll = true;
    }
  }

  List<MilestoneGroup> _getRelevantMilestoneGroups(List<Milestone> allMilestones) {
    final List<MilestoneGroup> groups = [];
    final babyAgeInWeeks = (DateTime.now().difference(_selectedBaby.birthdate).inDays / 7).round();
    
    // Calculate the target age in weeks (1 month earlier than current age)
    final targetAgeInWeeks = babyAgeInWeeks > 4 ? babyAgeInWeeks - 4 : babyAgeInWeeks;

    for (var ageGroup in _ageGroups) {
      // Match main milestones screen: include lower bound
      List<Milestone> groupMilestones = allMilestones
          .where((m) =>
              m.firstNoticedWeeks >= ageGroup['min']! &&
              m.firstNoticedWeeks <= ageGroup['max']!)
          .toList();

      if (groupMilestones.isNotEmpty) {
        // Set initial completion status
        for (var m in groupMilestones) {
          // Reflect as completed in UI if either already saved or before target age,
          // but do NOT mutate the baby's completed list here.
          final alreadyCompleted = _selectedBaby.completedMilestones.contains(m.title);
          final shouldSuggestCompleted = m.firstNoticedWeeks < targetAgeInWeeks;
          m.isCompleted = alreadyCompleted || shouldSuggestCompleted;
        }

        // Order within group: by firstNoticedWeeks then alphabetically by title
        groupMilestones.sort((a, b) {
          final cmp = a.firstNoticedWeeks.compareTo(b.firstNoticedWeeks);
          if (cmp != 0) return cmp;
          return a.title.toLowerCase().compareTo(b.title.toLowerCase());
        });

        groups.add(MilestoneGroup(
          id: 'onboarding_g_${ageGroup['name']}',
          title: ageGroup['name']!,
          milestones: groupMilestones,
        ));
      }
    }
    return groups;
  }

  void _onMilestoneChanged(String milestoneTitle, bool isCompleted) {
    setState(() {
      if (isCompleted) {
        if (!_selectedBaby.completedMilestones.contains(milestoneTitle)) {
          _selectedBaby.completedMilestones.add(milestoneTitle);
          _confettiController.play();
        }
      } else {
        _selectedBaby.completedMilestones.remove(milestoneTitle);
      }
    });
  }

  void _goNext() {
    // Persist current baby's milestones to provider and back to list
    widget.babies[_currentIndex] = _selectedBaby;
    try {
      final babyProvider = Provider.of<BabyProvider>(context, listen: false);
      babyProvider.saveMilestones(_selectedBaby.completedMilestones);
    } catch (_) {}
    if (_currentIndex < widget.babies.length - 1) {
      setState(() {
        _currentIndex += 1;
        _selectedBaby = widget.babies[_currentIndex];
        _didInitialScroll = false; // allow initial scroll for the new baby
      });
    } else {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => OnboardingShortTermFocusScreen(babies: widget.babies, initialIndex: 0),
        ),
      );
    }
  }

  void _goBack() {
    if (_currentIndex > 0) {
      setState(() {
        // Persist current baby's state
        widget.babies[_currentIndex] = _selectedBaby;
      });
      try {
        final babyProvider = Provider.of<BabyProvider>(context, listen: false);
        babyProvider.saveMilestones(_selectedBaby.completedMilestones);
      } catch (_) {}
      setState(() {
        _currentIndex -= 1;
        _selectedBaby = widget.babies[_currentIndex];
        _didInitialScroll = false;
      });
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => OnboardingActivitiesLovesHatesScreen(babies: widget.babies, initialIndex: _currentIndex),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      const Icon(FeatherIcons.sunrise, color: AppTheme.primaryPurple, size: 32),
                      const SizedBox(width: 8),
                      const Text('BabySteps', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      const Spacer(),
                      if (widget.babies.isNotEmpty)
                        Text(_selectedBaby.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
                const LinearProgressIndicator(
                  value: 0.7,
                  backgroundColor: Color(0xFFE2E8F0),
                  valueColor:
                      AlwaysStoppedAnimation<Color>(AppTheme.primaryPurple),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                      'What are ${_selectedBaby.name}\'s latest milestones?',
                      style: const TextStyle(
                          fontSize: 22, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center),
                ),
                Expanded(
                  child: Consumer<MilestoneProvider>(
                    builder: (context, provider, child) {
                      if (provider.isLoading) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (provider.milestones.isEmpty) {
                        return const Center(child: Text('No milestones found.'));
                      }

                      final milestoneGroups = _getRelevantMilestoneGroups(provider.milestones);
                      if (!_didInitialScroll) {
                        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToTarget(milestoneGroups));
                      }

                      return ScrollablePositionedList.builder(
                        itemScrollController: _itemScrollController,
                        itemCount: milestoneGroups.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16.0, vertical: 8.0),
                            child: MilestoneGroupCard(
                              group: milestoneGroups[index],
                              onMilestoneChanged: (id, value) {
                                final milestone = milestoneGroups
                                    .expand((g) => g.milestones)
                                    .firstWhere((m) => m.id == id);
                                _onMilestoneChanged(milestone.title, value);
                              },
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _goBack,
                          child: const Text('Back'),
                          style: OutlinedButton.styleFrom(
                            side:
                                const BorderSide(color: AppTheme.textSecondary),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            padding:
                                const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _goNext,
                          child: Text(
                            _currentIndex < widget.babies.length - 1
                                ? 'Next: ${widget.babies[_currentIndex + 1].name}'
                                : 'Next',
                          ),
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            padding:
                                const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(
                confettiController: _confettiController,
                blastDirection: pi / 2,
                emissionFrequency: 0.05,
                numberOfParticles: 20,
                maxBlastForce: 20,
                minBlastForce: 10,
                gravity: 0.1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
