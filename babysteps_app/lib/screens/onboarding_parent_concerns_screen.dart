import 'package:flutter/material.dart';
import 'package:babysteps_app/theme/app_theme.dart';
import 'package:babysteps_app/screens/onboarding_results_screen.dart';
import 'package:babysteps_app/screens/onboarding_concerns_reassurance_screen.dart';
import 'package:babysteps_app/utils/app_animations.dart';
import 'package:babysteps_app/widgets/onboarding_app_bar.dart';

class OnboardingParentConcernsScreen extends StatefulWidget {
  const OnboardingParentConcernsScreen({super.key});

  @override
  State<OnboardingParentConcernsScreen> createState() => _OnboardingParentConcernsScreenState();
}

class _OnboardingParentConcernsScreenState extends State<OnboardingParentConcernsScreen> {
  String? _selectedKey;

  final List<Map<String, dynamic>> _concerns = const [
    {
      'key': 'sleep',
      'label': 'Sleep & nights',
      'subtitle': 'I just want everyone to get some rest',
      'icon': Icons.nightlight_round,
    },
    {
      'key': 'development',
      'label': 'Development & milestones',
      'subtitle': "I don't want to miss something important",
      'icon': Icons.show_chart,
    },
    {
      'key': 'confidence',
      'label': 'Feeling confident',
      'subtitle': 'Am I doing this "right"?',
      'icon': Icons.emoji_emotions_outlined,
    },
    {
      'key': 'balance',
      'label': 'Balancing everything',
      'subtitle': 'Baby, work, home, relationships…',
      'icon': Icons.schedule,
    },
    {
      'key': 'mental_load',
      'label': 'Remembering it all',
      'subtitle': 'Appointments, feeds, naps, questions…',
      'icon': Icons.checklist_rtl,
    },
    {
      'key': 'pressure',
      'label': 'Advice & pressure',
      'subtitle': 'So many opinions, so much noise',
      'icon': Icons.record_voice_over,
    },
  ];

  void _selectConcern(String key) {
    setState(() {
      _selectedKey = key;
    });
  }

  void _continue() {
    if (_selectedKey == null) return;
    final selected = _concerns.firstWhere((c) => c['key'] == _selectedKey);
    final label = selected['label'] as String;
    Navigator.of(context).pushReplacementWithFade(
      OnboardingConcernsReassuranceScreen(selectedConcernLabel: label),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 24.0),
          child: Column(
            children: [
              OnboardingAppBar(
                onBackPressed: () {
                  Navigator.of(context).pushReplacementWithFade(
                    const OnboardingResultsScreen(),
                  );
                },
              ),
              const SizedBox(height: 24),
              // Icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppTheme.primaryPurple.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Text('💭', style: TextStyle(fontSize: 40)),
                ),
              ),
              const SizedBox(height: 24),
              // Headlines
              const Text(
                'What keeps you',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1F2937),
                  height: 1.2,
                ),
                textAlign: TextAlign.center,
              ),
              const Text(
                'up at night?',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primaryPurple,
                  height: 1.2,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              const Text(
                'Choose the one that feels biggest right now',
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF6B7280),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),
              // Concern cards list (single select, like notification cards)
              Expanded(
                child: ListView(
                  children: _concerns.map((concern) {
                    final key = concern['key'] as String;
                    final label = concern['label'] as String;
                    final subtitle = concern['subtitle'] as String;
                    final icon = concern['icon'] as IconData;
                    final isSelected = _selectedKey == key;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: _buildConcernOption(
                        key,
                        label,
                        subtitle,
                        icon,
                        isSelected,
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 16),
              // Helper text
              if (_selectedKey == null)
                const Text(
                  'Choose the one that feels loudest today. You can change this later.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF9CA3AF),
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                )
              else
                const Text(
                  'Great, we\'ll start by focusing here first.',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.primaryPurple,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              const SizedBox(height: 20),
              // CTA
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: (_selectedKey != null) ? _continue : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _selectedKey != null
                        ? AppTheme.primaryPurple
                        : AppTheme.primaryPurple.withOpacity(0.5),
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                    disabledBackgroundColor: AppTheme.primaryPurple.withOpacity(0.5),
                  ),
                  child: const Text(
                    'Continue',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConcernOption(
    String key,
    String label,
    String subtitle,
    IconData icon,
    bool isSelected,
  ) {
    return GestureDetector(
      onTap: () => _selectConcern(key),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryPurple.withOpacity(0.05) : Colors.white,
          border: Border.all(
            color: isSelected ? AppTheme.primaryPurple : const Color(0xFFE5E7EB),
            width: 2,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.primaryPurple : const Color(0xFFE5E7EB),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: isSelected ? Colors.white : const Color(0xFF9CA3AF),
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: isSelected ? AppTheme.primaryPurple : const Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF6B7280),
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: AppTheme.primaryPurple,
                size: 28,
              ),
          ],
        ),
      ),
    );
  }
}
