import 'package:flutter/material.dart';
import 'package:babysteps_app/models/baby.dart';
import 'package:babysteps_app/screens/onboarding_milestones_screen.dart';
import 'package:babysteps_app/screens/onboarding_baby_screen.dart';
import 'package:babysteps_app/theme/app_theme.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:babysteps_app/screens/onboarding_activities_loves_hates_screen.dart';
import 'package:provider/provider.dart';
import 'package:babysteps_app/providers/baby_provider.dart';
import 'package:babysteps_app/utils/app_animations.dart';
import 'package:babysteps_app/widgets/onboarding_app_bar.dart';
import 'package:babysteps_app/widgets/staggered_animation.dart';

class OnboardingGenderScreen extends StatefulWidget {
  final List<Baby> babies;
  final int initialIndex;
  const OnboardingGenderScreen({required this.babies, this.initialIndex = 0, super.key});

  @override
  State<OnboardingGenderScreen> createState() => _OnboardingGenderScreenState();
}

class _OnboardingGenderScreenState extends State<OnboardingGenderScreen> {
  late Baby _selectedBaby;
  String? _selectedGender;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    if (widget.babies.isNotEmpty) {
      _currentIndex = (widget.initialIndex >= 0 && widget.initialIndex < widget.babies.length)
          ? widget.initialIndex
          : 0;
      _selectedBaby = widget.babies[_currentIndex];
      _selectedGender = _selectedBaby.gender;
    }
  }

  void _selectGender(String gender) {
    setState(() {
      _selectedGender = gender;
      // Persist into the current baby's object in the list
      _selectedBaby.gender = gender;
      widget.babies[_currentIndex].gender = gender;
    });
  }

  Future<void> _goNext() async {
    if (_selectedGender == null) return;
    // Save gender into current baby (already done in _selectGender) and advance
    if (_currentIndex < widget.babies.length - 1) {
      setState(() {
        _currentIndex += 1;
        _selectedBaby = widget.babies[_currentIndex];
        _selectedGender = _selectedBaby.gender; // may be null
      });
      // Nudge user to pick for the next baby (schedule after frame)
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Select gender for ${_selectedBaby.name}')),
        );
      });
    } else {
      // Final baby: persist all babies before moving to Activities
      try {
        final babyProvider = Provider.of<BabyProvider>(context, listen: false);
        await babyProvider.initialize();
        final existingIds = babyProvider.babies.map((b) => b.id).toSet();
        for (final baby in widget.babies) {
          if (!existingIds.contains(baby.id)) {
            await babyProvider.createBaby(baby);
          } else {
            // Update existing record to capture gender (and any other edits)
            await babyProvider.updateBabyRecord(baby);
          }
        }
      } catch (e) {
        if (mounted) {
          final message = e.toString();
          // In guest mode, Supabase will report 'User not authenticated'.
          // Avoid surfacing this low-level error, but still continue onboarding.
          if (!message.contains('User not authenticated')) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error saving babies before activities: $e')),
            );
          }
        }
      }
      if (!mounted) return;
      Navigator.of(context).pushWithFade(
        OnboardingActivitiesLovesHatesScreen(babies: widget.babies, initialIndex: 0),
      );
    }
  }

  void _goBack() {
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex -= 1;
        _selectedBaby = widget.babies[_currentIndex];
        _selectedGender = _selectedBaby.gender;
      });
    } else {
      Navigator.of(context).pushReplacementWithFade(
        OnboardingBabyScreen(initialBabies: widget.babies),
      );
    }
  }

  Widget _buildGenderCard({required String gender, required IconData icon, required int index}) {
    final bool isSelected = _selectedGender == gender;
    return Expanded(
      child: StaggeredAnimation(
        index: index,
        child: GestureDetector(
          onTap: () => _selectGender(gender),
          child: Card(
            elevation: isSelected ? 4 : 1,
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: isSelected ? AppTheme.primaryPurple : Colors.grey.shade300,
                width: isSelected ? 2 : 1.5,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 40, color: isSelected ? AppTheme.primaryPurple : AppTheme.textSecondary),
                  const SizedBox(height: 8),
                  Text(
                    gender,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isSelected ? AppTheme.primaryPurple : AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            OnboardingAppBar(
              onBackPressed: _goBack,
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    // Title
                    Text('Which gender is ${_selectedBaby.name}?', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    Text('Baby ${_currentIndex + 1} of ${widget.babies.length}', style: const TextStyle(color: AppTheme.textSecondary)),
                    const SizedBox(height: 8),
                    const Text('This helps us personalize content.', style: TextStyle(color: AppTheme.textSecondary, fontSize: 16)),
                    const SizedBox(height: 32),
                    // Gender Selection
                    Row(
                      children: [
                        _buildGenderCard(gender: 'Girl', icon: FeatherIcons.user, index: 0),
                        const SizedBox(width: 16),
                        _buildGenderCard(gender: 'Boy', icon: FeatherIcons.user, index: 1),
                      ],
                    ),
                    const Spacer(),
                    // Navigation Button
                    ElevatedButton(
                      onPressed: _selectedGender != null ? _goNext : null,
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      child: Text(_currentIndex < widget.babies.length - 1 ? 'Next Baby' : 'Next'),
                    )
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
