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
import 'package:babysteps_app/widgets/app_header.dart';
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
  final Map<String, bool> _groupExpansion = {};
  String? _activeBabyId;
  bool _visibleWindowInitialized = false;
  int _baseStartIndex = 0;
  int _extraGroupsRevealed = 0;
  int _futureGroupsWindow = 2;
  final Map<String, Map<String, bool>> _manualMilestoneOverrides = {};
  final Map<String, Set<String>> _completedMilestoneIdsByBaby = {};

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
    // Ensure we have latest baby data (completed milestones) when landing here
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      try {
        final babyProvider = Provider.of<BabyProvider>(context, listen: false);
        await babyProvider.initialize();
        // Don't call setState here as it can cause build issues
        // The Consumer in build method will handle updates
      } catch (_) {}
    });
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  int _determineTargetGroupIndex(List<MilestoneGroup> groups, Baby baby) {
    if (groups.isEmpty) return 0;

    print('🎯 [MilestonesScreen] Determining target group for baby: ${baby.name}');
    
    // Prefer first group that has any milestone not truly completed in DB
    final completedIds = _completedMilestoneIdsByBaby[baby.id] ?? <String>{};
    print('  📊 Total completed IDs in cache: ${completedIds.length}');
    
    for (int i = 0; i < groups.length; i++) {
      final group = groups[i];
      final uncompletedMilestones = group.milestones.where(
        (m) => !(completedIds.contains(m.id) || completedIds.contains(m.title))
      ).toList();
      
      print('  📂 Group $i: "${group.title}" - ${group.milestones.length} total, ${uncompletedMilestones.length} unticked');
      
      if (uncompletedMilestones.isNotEmpty) {
        print('    ✅ First unticked: ${uncompletedMilestones.first.title}');
        print('    🎯 SCROLLING TO GROUP $i: ${group.title}');
        return i;
      }
    }
    
    print('  ℹ️ All milestones completed, using age-based fallback');
    final incompleteIndex = -1;
    if (incompleteIndex != -1) return incompleteIndex;

    // Fallback: age-based group if everything is truly completed
    final babyAgeWeeks = (DateTime.now().difference(baby.birthdate).inDays / 7).round();
    int targetIndex = 0;
    if (babyAgeWeeks > 8) {
      final targetAgeWeeks = babyAgeWeeks - 4;
      for (int i = 0; i < groups.length; i++) {
        final ageGroupData = _ageGroups.firstWhere((ag) => ag['name'] == groups[i].title, orElse: () => {});
        final minW = ageGroupData['min'] ?? 0;
        final maxW = ageGroupData['max'] ?? 9999;
        if (targetAgeWeeks >= minW && targetAgeWeeks <= maxW) {
          targetIndex = i;
          break;
        }
      }
    }

    return targetIndex.clamp(0, groups.length - 1).toInt();
  }

  Future<Set<String>> _loadCompletedMilestonesForBaby(Baby baby, BabyProvider babyProvider) async {
    final completedSet = <String>{};

    print('🔍 [MilestonesScreen] Loading completed milestones for baby: ${baby.name} (${baby.id})');
    
    // Add from babies.completed_milestones
    completedSet.addAll(baby.completedMilestones);
    print('  📋 From babies.completed_milestones: ${baby.completedMilestones.length} items');
    print('  📋 Items: ${baby.completedMilestones.take(5).join(", ")}${baby.completedMilestones.length > 5 ? "..." : ""}');

    // Add from baby_milestones table (has achieved_at)
    try {
      final assessments = await babyProvider.getMilestoneAssessmentsForBaby(baby.id);
      int achievedCount = 0;
      for (final assessment in assessments) {
        final achievedAtIso = assessment['achieved_at'] as String?;
        if (achievedAtIso != null) {
          final milestoneId = assessment['milestone_id'] as String? ?? '';
          final title = assessment['title'] as String? ?? '';
          if (milestoneId.isNotEmpty) { completedSet.add(milestoneId); achievedCount++; }
          if (title.isNotEmpty) completedSet.add(title);
        }
      }
      print('  📊 From baby_milestones (achieved_at): $achievedCount milestones');
    } catch (e) {
      print('  ⚠️ Error loading baby_milestones: $e');
    }

    print('  ✅ Total completed (union): ${completedSet.length}');
    return completedSet;
  }

  Future<List<MilestoneGroup>> _getRelevantMilestoneGroups(
      List<Milestone> allMilestones, Baby? baby, BabyProvider babyProvider) async {
    if (baby == null) return [];

    // Load completed milestones if not already loaded for this baby
    if (!_completedMilestoneIdsByBaby.containsKey(baby.id)) {
      _completedMilestoneIdsByBaby[baby.id] = await _loadCompletedMilestonesForBaby(baby, babyProvider);
    }
    final completedIds = _completedMilestoneIdsByBaby[baby.id]!;

    final List<MilestoneGroup> groups = [];
    final overrides = _manualMilestoneOverrides[baby.id] ?? {};
    final babyAgeInWeeks = (DateTime.now().difference(baby.birthdate).inDays / 7).round();

    for (var ageGroup in _ageGroups) {
      List<Milestone> groupMilestones = allMilestones
          .where((m) =>
              m.firstNoticedWeeks >= ageGroup['min']! &&
              m.firstNoticedWeeks <= ageGroup['max']!)
          .toList();

      if (groupMilestones.isNotEmpty) {
        // Set completion from baby's saved list
        for (var m in groupMilestones) {
          final override = overrides[m.id];
          if (override != null) {
            m.isCompleted = override;
            continue;
          }

          // Check both sources for completion status only (no age-based suggestion)
          final alreadyCompleted = completedIds.contains(m.id) || completedIds.contains(m.title);
          m.isCompleted = alreadyCompleted;
        }

        // Sort by firstNoticedWeeks then alphabetically by title
        groupMilestones.sort((a, b) {
          final cmp = a.firstNoticedWeeks.compareTo(b.firstNoticedWeeks);
          if (cmp != 0) return cmp;
          return a.title.toLowerCase().compareTo(b.title.toLowerCase());
        });

        final String groupId = 'g_${ageGroup['name']}';
        final bool isExpanded = _groupExpansion[groupId] ?? true; // default expanded
        groups.add(MilestoneGroup(
          id: groupId,
          title: ageGroup['name']!,
          isExpanded: isExpanded,
          milestones: groupMilestones,
        ));
      }
    }
    return groups;
  }

  void _onMilestoneChanged(Milestone milestone, bool isCompleted) {
    final babyProvider = Provider.of<BabyProvider>(context, listen: false);

    // Update the milestone completion status locally without setState
    milestone.isCompleted = isCompleted;
    final selectedBaby = babyProvider.selectedBaby;
    if (selectedBaby != null) {
      final overrides =
          _manualMilestoneOverrides[selectedBaby.id] ??= {};
      overrides[milestone.id] = isCompleted;
    }

    if (isCompleted) {
      // Capture achieved date now for normal logging
      babyProvider.upsertAchievedMilestone(
        milestoneId: milestone.id,
        achievedAt: DateTime.now(),
        source: 'log',
      );
      babyProvider.addMilestone(milestone.title);
      _confettiController.play();
    } else {
      babyProvider.removeMilestone(milestone.title);
    }

    // Force a rebuild by calling setState in a post-frame callback to avoid during-build issues
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: widget.showBottomNav
          ? BottomNavBar(
              currentIndex: _currentNavIndex,
              onTap: (index) {
                // Use post-frame callback to avoid setState during build
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) {
                    setState(() {
                      _currentNavIndex = index;
                    });
                  }
                });
              },
            )
          : null,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                const AppHeader(),

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

                      _manualMilestoneOverrides[selectedBaby.id] =
                          _manualMilestoneOverrides[selectedBaby.id] ?? {};

                      if (milestoneProvider.milestones.isEmpty) {
                        return const Center(
                          child: Text('No milestones found.'),
                        );
                      }

                      return FutureBuilder<List<MilestoneGroup>>(
                        future: _getRelevantMilestoneGroups(
                          milestoneProvider.milestones,
                          selectedBaby,
                          babyProvider,
                        ),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return const Center(child: CircularProgressIndicator());
                          }

                          final milestoneGroups = snapshot.data!;

                          // Find the first truly incomplete milestone (DB-only)
                          String? targetGroupId;
                          String? targetMilestoneId;
                          final completedIds = _completedMilestoneIdsByBaby[selectedBaby.id] ?? <String>{};
                          for (final g in milestoneGroups) {
                            for (final m in g.milestones) {
                              final isCompleted = completedIds.contains(m.id) || completedIds.contains(m.title);
                              if (!isCompleted) { targetGroupId = g.id; targetMilestoneId = m.id; break; }
                            }
                            if (targetGroupId != null) break;
                          }
                          final targetIndex = _determineTargetGroupIndex(milestoneGroups, selectedBaby);
                      final shouldResetWindow = !_visibleWindowInitialized ||
                          _activeBabyId != selectedBaby.id ||
                          _baseStartIndex >= milestoneGroups.length;
                      if (shouldResetWindow || (_extraGroupsRevealed == 0 && _baseStartIndex != targetIndex)) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (!mounted) return;
                          setState(() {
                            _activeBabyId = selectedBaby.id;
                            _baseStartIndex = targetIndex;
                            _extraGroupsRevealed = min(_extraGroupsRevealed, _baseStartIndex);
                            _futureGroupsWindow = 2;
                            _visibleWindowInitialized = true;
                          });
                        });
                      }

                      final startIndex = milestoneGroups.isEmpty
                          ? 0
                          : max(0, _baseStartIndex - _extraGroupsRevealed);
                      final totalGroups = milestoneGroups.length;
                      final positionOfBase = max(0, _baseStartIndex - startIndex);
                      final endIndexExclusive = min(
                        totalGroups,
                        startIndex + positionOfBase + _futureGroupsWindow,
                      );
                      final visibleCount = max(0, endIndexExclusive - startIndex);
                      final hasLoadPrev = startIndex > 0;
                      final hasLoadNext = endIndexExclusive < totalGroups;
                      final listCount = visibleCount + (hasLoadPrev ? 1 : 0) + (hasLoadNext ? 1 : 0);

                      return Container(
                        color: const Color(0xFFFAFBFF),
                        child: Column(
                          children: [
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
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                physics: const BouncingScrollPhysics(),
                                itemCount: listCount,
                                itemBuilder: (context, index) {
                                  if (hasLoadPrev && index == 0) {
                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 12),
                                      child: OutlinedButton.icon(
                                        onPressed: () {
                                          setState(() {
                                            _extraGroupsRevealed = min(_baseStartIndex, _extraGroupsRevealed + 1);
                                          });
                                        },
                                        icon: const Icon(FeatherIcons.chevronUp, size: 16),
                                        label: const Text('Load previous milestones'),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: AppTheme.primaryPurple,
                                          side: const BorderSide(color: AppTheme.primaryPurple, width: 1.2),
                                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                                        ),
                                      ),
                                    );
                                  }

                                  final firstGroupIndex = hasLoadPrev ? 1 : 0;
                                  final lastGroupIndexExclusive = firstGroupIndex + visibleCount;

                                  if (hasLoadNext && index == lastGroupIndexExclusive) {
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 12, bottom: 12),
                                      child: OutlinedButton.icon(
                                        onPressed: () {
                                          setState(() {
                                            _futureGroupsWindow += 1;
                                          });
                                        },
                                        icon: const Icon(FeatherIcons.chevronDown, size: 16),
                                        label: const Text('Load next milestones'),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: AppTheme.primaryPurple,
                                          side: const BorderSide(color: AppTheme.primaryPurple, width: 1.2),
                                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                                        ),
                                      ),
                                    );
                                  }

                                  final groupIndex = startIndex + (index - firstGroupIndex);
                                  final group = milestoneGroups[groupIndex];
                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 0),
                                    child: MilestoneGroupCard(
                                      group: group,
                                      onMilestoneChanged: (id, value) {
                                        final milestone = milestoneGroups
                                            .expand((g) => g.milestones)
                                            .firstWhere((m) => m.id == id);
                                        _onMilestoneChanged(milestone, value);
                                      },
                                      onExpansionChanged: (expanded) {
                                        _groupExpansion[group.id] = expanded;
                                      },
                                      scrollToMilestoneId: group.id == targetGroupId ? targetMilestoneId : null,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      );
                        },
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
