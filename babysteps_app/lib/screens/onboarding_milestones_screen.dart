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
import 'package:babysteps_app/utils/app_animations.dart';
import 'package:babysteps_app/widgets/onboarding_app_bar.dart';

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
  int _baseStartIndex = 0;
  int _extraGroupsRevealed = 0;
  int _futureGroupsWindow = 2;
  int _currentIndex = 0;
  final Map<String, Map<String, bool>> _manualMilestoneOverrides = {};
  Set<String> _completedMilestoneIds = {}; // from babies.completed_milestones + achieved rows
  Set<String> _achievedMilestoneIds = {};  // from baby_milestones (achieved_at only)
  bool _isLoadingCompletedMilestones = true;

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
      _manualMilestoneOverrides[_selectedBaby.id] =
          _manualMilestoneOverrides[_selectedBaby.id] ?? {};
      _loadCompletedMilestones();
    } else {
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  Future<void> _loadCompletedMilestones() async {
    setState(() {
      _isLoadingCompletedMilestones = true;
    });

    final babyProvider = Provider.of<BabyProvider>(context, listen: false);
    final completedSet = <String>{};
    final achievedSet = <String>{};

    print('🔍 [OnboardingMilestones] Loading completed for: ${_selectedBaby.name} (${_selectedBaby.id})');
    
    // Add from babies.completed_milestones
    completedSet.addAll(_selectedBaby.completedMilestones);
    print('  📋 From babies.completed_milestones: ${_selectedBaby.completedMilestones.length}');
    print('  📋 Items: ${_selectedBaby.completedMilestones.take(5).join(", ")}${_selectedBaby.completedMilestones.length > 5 ? "..." : ""}');

    // Add from baby_milestones table (has achieved_at)
    try {
      final assessments = await babyProvider.getMilestoneAssessmentsForBaby(_selectedBaby.id);
      int achievedCount = 0;
      for (final assessment in assessments) {
        final achievedAtIso = assessment['achieved_at'] as String?;
        if (achievedAtIso != null) {
          final milestoneId = assessment['milestone_id'] as String? ?? '';
          final title = assessment['title'] as String? ?? '';
          if (milestoneId.isNotEmpty) { achievedSet.add(milestoneId); achievedCount++; }
          if (title.isNotEmpty) achievedSet.add(title);
          if (milestoneId.isNotEmpty) completedSet.add(milestoneId);
          if (title.isNotEmpty) completedSet.add(title);
        }
      }
      print('  📊 From baby_milestones (achieved_at): $achievedCount');
    } catch (e) {
      print('  ⚠️ Error loading baby_milestones: $e');
    }

    print('  ✅ Total completed (union): ${completedSet.length}');
    
    if (mounted) {
      setState(() {
        _completedMilestoneIds = completedSet;
        _achievedMilestoneIds = achievedSet;
        _isLoadingCompletedMilestones = false;
      });
    }
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  void _scrollToTarget(List<MilestoneGroup> milestoneGroups) {
    if (_didInitialScroll || _isLoadingCompletedMilestones) return; // Only scroll once on first load
    int targetIndex = 0;

    print('🎯 [OnboardingMilestones] Finding first unticked group for: ${_selectedBaby.name}');
    print('  📊 Total completed IDs: ${_completedMilestoneIds.length}');
    
    // Find the first group with an unticked milestone based on UNION of
    // babies.completed_milestones and baby_milestones (achieved rows)
    for (int i = 0; i < milestoneGroups.length; i++) {
      final group = milestoneGroups[i];
      final untickedMilestones = group.milestones.where((m) {
        final isCompleted = _completedMilestoneIds.contains(m.id) ||
                           _completedMilestoneIds.contains(m.title);
        return !isCompleted;
      }).toList();
      
      print('  📂 Group $i: "${group.title}" - ${group.milestones.length} total, ${untickedMilestones.length} unticked');
      
      if (untickedMilestones.isNotEmpty) {
        print('    ✅ First unticked: ${untickedMilestones.first.title}');
        print('    🎯 SCROLLING TO GROUP $i: ${group.title}');
        targetIndex = i;
        break;
      }
    }

    if (mounted) {
      setState(() {
        _baseStartIndex = targetIndex;
        _extraGroupsRevealed = 0;
        _futureGroupsWindow = 2;
      });
    } else {
      _baseStartIndex = targetIndex;
      _extraGroupsRevealed = 0;
      _futureGroupsWindow = 2;
    }

    print('  📍 Set _baseStartIndex = $targetIndex, _extraGroupsRevealed = 0, _futureGroupsWindow = 2');
    print('  🎮 ScrollController attached: ${_itemScrollController.isAttached}');
    
    // Use WidgetsBinding to scroll AFTER the build is complete
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_itemScrollController.isAttached) {
        // Scroll offset: account for "Load Previous" button if present
        final scrollIndex = _baseStartIndex > 0 ? 1 : 0; // If we can load prev, first item is the button
        print('  🚀 POST-FRAME: Calling jumpTo(index: $scrollIndex) for base index $_baseStartIndex');
        _itemScrollController.jumpTo(index: scrollIndex);
      }
    });

    _didInitialScroll = true;
    print('  ✅ _didInitialScroll = true');
  }

  List<MilestoneGroup> _getRelevantMilestoneGroups(List<Milestone> allMilestones) {
    final List<MilestoneGroup> groups = [];
    final babyAgeInWeeks = (DateTime.now().difference(_selectedBaby.birthdate).inDays / 7).round();
    
    // Calculate the target age in weeks (1 month earlier than current age)
    final targetAgeInWeeks = babyAgeInWeeks > 4 ? babyAgeInWeeks - 4 : babyAgeInWeeks;
    final overrides = _manualMilestoneOverrides[_selectedBaby.id] ?? {};

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
          final override = overrides[m.id];
          if (override != null) {
            m.isCompleted = override;
            continue;
          }

          // Only mark as completed if truly completed (babies list or achieved rows)
          final alreadyCompleted = _completedMilestoneIds.contains(m.id) || 
                                  _completedMilestoneIds.contains(m.title);
          m.isCompleted = alreadyCompleted;
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

  void _onMilestoneChanged(Milestone milestone, bool isCompleted) {
    final babyProvider = Provider.of<BabyProvider>(context, listen: false);
    setState(() {
      milestone.isCompleted = isCompleted;
      final overrides =
          _manualMilestoneOverrides[_selectedBaby.id] ??= {};
      overrides[milestone.id] = isCompleted;
      if (isCompleted) {
        if (!_selectedBaby.completedMilestones.contains(milestone.title)) {
          _selectedBaby.completedMilestones.add(milestone.title);
          _confettiController.play();
        }
        // Set achieved_at to current time for all checked milestones during onboarding
        // The database view will determine if it's ahead/on_track/behind based on the timestamp
        final now = DateTime.now();

        // Persist to DB tagged as onboarding; achieved_at ensures it still trends in tracking
        babyProvider.upsertAchievedMilestoneForBaby(
          babyId: _selectedBaby.id,
          milestoneId: milestone.id,
          achievedAt: now,
          source: 'onboarding',
        );
      } else {
        _selectedBaby.completedMilestones.remove(milestone.title);
        // Unchecking during onboarding: remove from DB
        babyProvider.removeAchievedMilestoneForBaby(
          babyId: _selectedBaby.id,
          milestoneId: milestone.id,
        );
      }
    });
  }

  void _persistCompletedMilestones(BabyProvider babyProvider) {
    // Ensure uniqueness and sync to Supabase babies.completed_milestones
    final unique = _selectedBaby.completedMilestones.toSet().toList()..sort();
    _selectedBaby.completedMilestones
      ..clear()
      ..addAll(unique);

    babyProvider.saveMilestonesForBaby(_selectedBaby.id, unique);
  }

  // Merge any auto-suggested completed milestones (shown as checked by age logic)
  // into the baby's completed list before saving.
  void _mergeAutoCompletedIntoSelected() {
    final milestoneProvider = Provider.of<MilestoneProvider>(context, listen: false);
    if (milestoneProvider.milestones.isEmpty) return;
    final groups = _getRelevantMilestoneGroups(milestoneProvider.milestones);
    final set = _selectedBaby.completedMilestones.toSet();
    for (final g in groups) {
      for (final m in g.milestones) {
        if (m.isCompleted) set.add(m.title);
      }
    }
    _selectedBaby.completedMilestones
      ..clear()
      ..addAll(set);
  }

  void _goNext() {
    // Persist current baby's milestones to provider and back to list
    _mergeAutoCompletedIntoSelected();
    widget.babies[_currentIndex] = _selectedBaby;
    try {
      final babyProvider = Provider.of<BabyProvider>(context, listen: false);
      babyProvider.saveMilestonesForBaby(_selectedBaby.id, _selectedBaby.completedMilestones);
    } catch (_) {}
    if (_currentIndex < widget.babies.length - 1) {
      setState(() {
        _currentIndex += 1;
        _selectedBaby = widget.babies[_currentIndex];
        _didInitialScroll = false; // allow initial scroll for the new baby
        _baseStartIndex = 0;
        _extraGroupsRevealed = 0;
        _futureGroupsWindow = 2;
      });
      _loadCompletedMilestones(); // Load completed milestones for new baby
    } else {
      Navigator.of(context).pushWithFade(
        OnboardingShortTermFocusScreen(babies: widget.babies, initialIndex: 0),
      );
    }
  }

  void _goBack() {
    if (_currentIndex > 0) {
      setState(() {
        // Persist current baby's state
        _mergeAutoCompletedIntoSelected();
        widget.babies[_currentIndex] = _selectedBaby;
      });
      try {
        final babyProvider = Provider.of<BabyProvider>(context, listen: false);
        babyProvider.saveMilestonesForBaby(_selectedBaby.id, _selectedBaby.completedMilestones);
      } catch (_) {}
      setState(() {
        _currentIndex -= 1;
        _selectedBaby = widget.babies[_currentIndex];
        _manualMilestoneOverrides[_selectedBaby.id] =
            _manualMilestoneOverrides[_selectedBaby.id] ?? {};
        _didInitialScroll = false;
        _baseStartIndex = max(0, _baseStartIndex - 1);
        _extraGroupsRevealed = 0;
        _futureGroupsWindow = 2;
      });
      _loadCompletedMilestones(); // Load completed milestones for previous baby
    } else {
      Navigator.of(context).pushReplacementWithFade(
        OnboardingActivitiesLovesHatesScreen(babies: widget.babies, initialIndex: _currentIndex),
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
                OnboardingAppBar(
                  onBackPressed: _goBack,
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
                      
                      print('🎬 [OnboardingMilestones] BUILD - Window calculation:');
                      print('  _baseStartIndex: $_baseStartIndex, _extraGroupsRevealed: $_extraGroupsRevealed');
                      print('  startIndex: $startIndex, endIndexExclusive: $endIndexExclusive');
                      print('  Showing groups $startIndex to ${endIndexExclusive - 1}');
                      if (startIndex < milestoneGroups.length) {
                        print('  📂 First visible group: "${milestoneGroups[startIndex].title}"');
                      }
                      
                      // Calculate the scroll offset for "Load Previous" button
                      final scrollOffset = hasLoadPrev ? 1 : 0;
                      final initialIndex = hasLoadPrev ? scrollOffset : 0;
                      print('  📍 ScrollablePositionedList initialScrollIndex: $initialIndex (offset: $scrollOffset)');

                      return ScrollablePositionedList.builder(
                        itemScrollController: _itemScrollController,
                        initialScrollIndex: initialIndex,
                        initialAlignment: 0.0,
                        itemCount: listCount,
                        itemBuilder: (context, index) {
                          if (hasLoadPrev && index == 0) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  setState(() {
                                    _extraGroupsRevealed = min(_baseStartIndex, _extraGroupsRevealed + 1);
                                  });
                                },
                                icon: const Icon(FeatherIcons.chevronDown, size: 16),
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
                              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
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
                          final adjustedIndex = startIndex + (index - firstGroupIndex);
                          final group = milestoneGroups[adjustedIndex];
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16.0, vertical: 8.0),
                            child: MilestoneGroupCard(
                              group: group,
                              onMilestoneChanged: (id, value) {
                                final milestone = milestoneGroups
                                    .expand((g) => g.milestones)
                                    .firstWhere((m) => m.id == id);
                                _onMilestoneChanged(milestone, value);
                              },
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ElevatedButton(
                    onPressed: _goNext,
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    child: Text(
                      _currentIndex < widget.babies.length - 1
                          ? 'Next: ${widget.babies[_currentIndex + 1].name}'
                          : 'Next',
                      style: const TextStyle(fontSize: 18),
                    ),
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
