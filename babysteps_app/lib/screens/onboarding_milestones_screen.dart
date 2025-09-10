import 'dart:math';
import 'package:babysteps_app/models/milestone_group.dart';
import 'package:babysteps_app/models/milestone.dart';
import 'package:babysteps_app/providers/milestone_provider.dart';
import 'package:provider/provider.dart';
import 'package:babysteps_app/widgets/milestone_group_card.dart';
import 'package:flutter/material.dart';

import 'package:babysteps_app/models/baby.dart';
import 'package:babysteps_app/theme/app_theme.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:confetti/confetti.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:babysteps_app/screens/onboarding_measurements_screen.dart';

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
      _selectedBaby = widget.babies.first;
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
    }
  }

  List<MilestoneGroup> _getRelevantMilestoneGroups(List<Milestone> allMilestones) {
    final List<MilestoneGroup> groups = [];
    final babyAgeInWeeks = (DateTime.now().difference(_selectedBaby.birthdate).inDays / 7).round();
    
    // Calculate the target age in weeks (1 month earlier than current age)
    final targetAgeInWeeks = babyAgeInWeeks > 4 ? babyAgeInWeeks - 4 : babyAgeInWeeks;

    for (var ageGroup in _ageGroups) {
      List<Milestone> groupMilestones = allMilestones
          .where((m) =>
              m.firstNoticedWeeks > ageGroup['min']! &&
              m.firstNoticedWeeks <= ageGroup['max']!)
          .toList();

      if (groupMilestones.isNotEmpty) {
        // Set initial completion status
        for (var m in groupMilestones) {
          // Auto-tick milestones that should have been reached by now
          // Either it's already marked as completed or it's before the target age
          if (_selectedBaby.completedMilestones.contains(m.title) || 
              m.firstNoticedWeeks < targetAgeInWeeks) {
            m.isCompleted = true;
            
            // Add to baby's completed milestones if not already there
            if (!_selectedBaby.completedMilestones.contains(m.title)) {
              _selectedBaby.completedMilestones.add(m.title);
            }
          } else {
            m.isCompleted = false;
          }
        }

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
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(FeatherIcons.x),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      const Text('Milestones', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(width: 48), // to balance the close button
                    ],
                  ),
                ),
                const LinearProgressIndicator(
                  value: 0.6,
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
                      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToTarget(milestoneGroups));

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
                          onPressed: () => Navigator.of(context).pop(),
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
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) =>
                                    OnboardingMeasurementsScreen(
                                        babies: widget.babies),
                              ),
                            );
                          },
                          child: const Text('Next'),
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
