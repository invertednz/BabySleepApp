import 'dart:math';
import 'package:babysteps_app/models/baby.dart';
import 'package:babysteps_app/models/milestone.dart';
import 'package:babysteps_app/models/milestone_group.dart';
import 'package:babysteps_app/providers/baby_provider.dart';
import 'package:babysteps_app/providers/milestone_provider.dart';
import 'package:babysteps_app/theme/app_theme.dart';
import 'package:babysteps_app/widgets/baby_selector.dart';
import 'package:babysteps_app/widgets/bottom_nav_bar.dart';
import 'package:babysteps_app/widgets/milestone_group_card.dart';
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:provider/provider.dart';

class MilestonesScreen extends StatefulWidget {
  final bool showBottomNav;

  const MilestonesScreen({super.key, this.showBottomNav = true});

  @override
  State<MilestonesScreen> createState() => _MilestonesScreenState();
}

class _MilestonesScreenState extends State<MilestonesScreen> {
  late ConfettiController _confettiController;
  int _currentNavIndex = 1; // Set to 1 for Milestones tab

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
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 1));
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  List<MilestoneGroup> _getRelevantMilestoneGroups(
      List<Milestone> allMilestones, Baby? baby) {
    if (baby == null) return [];

    final List<MilestoneGroup> groups = [];

    for (var ageGroup in _ageGroups) {
      List<Milestone> groupMilestones = allMilestones
          .where((m) =>
              m.firstNoticedWeeks >= ageGroup['min']! &&
              m.firstNoticedWeeks <= ageGroup['max']!)
          .toList();

      if (groupMilestones.isNotEmpty) {
        for (var m in groupMilestones) {
          m.isCompleted = baby.completedMilestones.contains(m.title);
        }

        groups.add(MilestoneGroup(
          id: 'g_${ageGroup['name']}',
          title: ageGroup['name']!,
          isExpanded: true, // Default to expanded
          milestones: groupMilestones,
        ));
      }
    }
    return groups;
  }

  void _onMilestoneChanged(Milestone milestone, bool isCompleted) {
    final babyProvider = Provider.of<BabyProvider>(context, listen: false);
    setState(() {
      milestone.isCompleted = isCompleted;
    });

    if (isCompleted) {
      babyProvider.addMilestone(milestone.title);
      _confettiController.play();
    } else {
      babyProvider.removeMilestone(milestone.title);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: widget.showBottomNav
          ? BottomNavBar(
              currentIndex: _currentNavIndex,
              onTap: (index) {
                setState(() {
                  _currentNavIndex = index;
                });
              },
            )
          : null,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                // Header with app title
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFFF1E9F8), Color(0xFFEBE0F6)],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              height: 32,
                              width: 32,
                              color: Colors.white,
                              child: const Icon(
                                FeatherIcons.award,
                                size: 16,
                                color: AppTheme.primaryPurple,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Milestones',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1F2937),
                            ),
                          ),
                        ],
                      ),
                      Consumer<BabyProvider>(
                        builder: (context, babyProvider, _) {
                          final baby = babyProvider.selectedBaby;
                          String ageString = '';
                          
                          if (baby != null) {
                            final now = DateTime.now();
                            final difference = now.difference(baby.birthdate);
                            final months = (difference.inDays / 30).floor();
                            final years = (months / 12).floor();
                            
                            if (years > 0) {
                              ageString = '$years ${years == 1 ? 'year' : 'years'}';
                            } else {
                              ageString = '$months ${months == 1 ? 'month' : 'months'}';
                            }
                          }
                          
                          return BabySelector(
                            name: baby?.name ?? 'Select Baby',
                            age: ageString,
                            onTap: () {
                              // Navigate to baby selector or show dropdown
                              // This is a placeholder - implement actual navigation if needed
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),

                // Main content
                Expanded(
                  child: Consumer2<BabyProvider, MilestoneProvider>(
                    builder: (context, babyProvider, milestoneProvider, child) {
                      if (babyProvider.isLoading ||
                          milestoneProvider.isLoading) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final selectedBaby = babyProvider.selectedBaby;

                      if (selectedBaby == null) {
                        return const Center(
                          child: Text('Please select a baby first.'),
                        );
                      }

                      if (milestoneProvider.milestones.isEmpty) {
                        return const Center(
                          child: Text('No milestones found.'),
                        );
                      }

                      final milestoneGroups = _getRelevantMilestoneGroups(
                        milestoneProvider.milestones,
                        selectedBaby,
                      );
                      final totalMilestones =
                          milestoneGroups.expand((g) => g.milestones).length;
                      final completedMilestones = milestoneGroups
                          .expand((g) => g.milestones)
                          .where((m) => m.isCompleted)
                          .length;
                      final progress = totalMilestones > 0
                          ? completedMilestones / totalMilestones
                          : 0.0;

                      return Container(
                        color: const Color(0xFFFAFBFF),
                        child: Column(
                          children: [
                            // Progress bar
                            FractionallySizedBox(
                              widthFactor: 1,
                              child: Container(
                                height: 8,
                                color: const Color(0xFFE5E7EB),
                                child: FractionallySizedBox(
                                  alignment: Alignment.centerLeft,
                                  widthFactor: progress,
                                  child: DecoratedBox(
                                    decoration: const BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Color(0xFFE6D7F2),
                                          Color(0xFFC8A2C8)
                                        ],
                                        begin: Alignment.centerLeft,
                                        end: Alignment.centerRight,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            // Title and description
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                children: [
                                  Text(
                                    '${selectedBaby.name}\'s Milestones',
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF1F2937),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Check off the milestones your baby has reached.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Milestone groups list
                            Expanded(
                              child: ListView.builder(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                physics: const BouncingScrollPhysics(),
                                itemCount: milestoneGroups.length,
                                itemBuilder: (context, index) {
                                  return MilestoneGroupCard(
                                    group: milestoneGroups[index],
                                    onMilestoneChanged: (id, value) {
                                      final milestone = milestoneGroups
                                          .expand((g) => g.milestones)
                                          .firstWhere((m) => m.id == id);
                                      _onMilestoneChanged(milestone, value);
                                    },
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),

            // Confetti effect
            Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(
                confettiController: _confettiController,
                blastDirection: pi / 2, // straight up
                emissionFrequency: 0.05,
                numberOfParticles: 20,
                maxBlastForce: 20,
                minBlastForce: 10,
                gravity: 0.1,
                colors: const [
                  Color(0xFFE6D7F2),
                  Color(0xFFC8A2C8),
                  Color(0xFFF5F0E6),
                  Color(0xFFE0E8D9),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
