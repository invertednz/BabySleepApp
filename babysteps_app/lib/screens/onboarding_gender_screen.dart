import 'package:flutter/material.dart';
import 'package:babysteps_app/models/baby.dart';
import 'package:babysteps_app/screens/onboarding_milestones_screen.dart';
import 'package:babysteps_app/theme/app_theme.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';

class OnboardingGenderScreen extends StatefulWidget {
  final List<Baby> babies;
  const OnboardingGenderScreen({required this.babies, super.key});

  @override
  State<OnboardingGenderScreen> createState() => _OnboardingGenderScreenState();
}

class _OnboardingGenderScreenState extends State<OnboardingGenderScreen> {
  late Baby _selectedBaby;
  String? _selectedGender;

  @override
  void initState() {
    super.initState();
    if (widget.babies.isNotEmpty) {
      _selectedBaby = widget.babies.first;
      _selectedGender = _selectedBaby.gender;
    }
  }

  void _selectGender(String gender) {
    setState(() {
      _selectedGender = gender;
      _selectedBaby.gender = gender;
    });
  }

  Widget _buildGenderCard({required String gender, required IconData icon}) {
    final bool isSelected = _selectedGender == gender;
    return Expanded(
      child: GestureDetector(
        onTap: () => _selectGender(gender),
        child: Card(
          elevation: isSelected ? 4 : 1,
          color: isSelected ? AppTheme.primaryPurple.withOpacity(0.1) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: isSelected ? AppTheme.primaryPurple : Colors.grey.shade300,
              width: 1.5,
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  const Icon(FeatherIcons.sunrise, color: AppTheme.primaryPurple, size: 32),
                  const SizedBox(width: 8),
                  const Text('BabySteps', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  if (widget.babies.length > 1)
                    DropdownButton<Baby>(
                      value: _selectedBaby,
                      onChanged: (Baby? newValue) {
                        setState(() {
                          _selectedBaby = newValue!;
                          _selectedGender = _selectedBaby.gender;
                        });
                      },
                      items: widget.babies.map<DropdownMenuItem<Baby>>((Baby baby) {
                        return DropdownMenuItem<Baby>(
                          value: baby,
                          child: Text(baby.name),
                        );
                      }).toList(),
                      underline: const SizedBox(),
                    )
                  else if (widget.babies.isNotEmpty)
                    Text(widget.babies.first.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
            // Progress Bar
            const LinearProgressIndicator(
              value: 0.4,
              backgroundColor: Color(0xFFE2E8F0),
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryPurple),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    // Title
                    Text('Which gender for ${_selectedBaby.name}?', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    const Text('This helps us personalize content.', style: TextStyle(color: AppTheme.textSecondary, fontSize: 16)),
                    const SizedBox(height: 32),
                    // Gender Selection
                    Row(
                      children: [
                        _buildGenderCard(gender: 'Girl', icon: FeatherIcons.user),
                        const SizedBox(width: 16),
                        _buildGenderCard(gender: 'Boy', icon: FeatherIcons.user),
                        const SizedBox(width: 16),
                        _buildGenderCard(gender: 'Other', icon: FeatherIcons.users),
                      ],
                    ),
                    const Spacer(),
                    // Navigation Buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('Back'),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: AppTheme.textSecondary),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _selectedGender != null
                                ? () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (context) => OnboardingMilestonesScreen(babies: widget.babies),
                                      ),
                                    );
                                  }
                                : null,
                            child: const Text('Next'),
                            style: ElevatedButton.styleFrom(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                          ),
                        ),
                      ],
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
