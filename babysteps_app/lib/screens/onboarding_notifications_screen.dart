import 'package:flutter/material.dart';
import 'package:babysteps_app/theme/app_theme.dart';
import 'package:babysteps_app/screens/onboarding_parenting_style_screen.dart';
import 'package:provider/provider.dart';
import 'package:babysteps_app/providers/baby_provider.dart';

class OnboardingNotificationsScreen extends StatefulWidget {
  const OnboardingNotificationsScreen({super.key});

  @override
  State<OnboardingNotificationsScreen> createState() =>
      _OnboardingNotificationsScreenState();
}

class _OnboardingNotificationsScreenState
    extends State<OnboardingNotificationsScreen> {
  String? _selectedTime;

  final List<Map<String, dynamic>> _options = const [
    {
      'value': 'morning',
      'label': 'Morning',
      'time': '7:00 AM - 11:00 AM',
      'icon': Icons.wb_sunny,
      'description': 'Start your day with insights',
    },
    {
      'value': 'midday',
      'label': 'Mid-Day',
      'time': '11:00 AM - 3:00 PM',
      'icon': Icons.light_mode,
      'description': 'Perfect for lunch breaks',
    },
    {
      'value': 'evening',
      'label': 'Evening',
      'time': '6:00 PM - 9:00 PM',
      'icon': Icons.nightlight,
      'description': 'Wind down with progress',
    },
  ];

  Future<void> _saveAndContinue() async {
    if (_selectedTime == null) return;
    
    final babyProvider = Provider.of<BabyProvider>(context, listen: false);
    await babyProvider.saveNotificationPreference(_selectedTime!);
    
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => OnboardingParentingStyleScreen(babies: const []),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Spacer(),
              const Text(
                'When should we\ncheck in?',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                  height: 1.2,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Text(
                'Get personalized reminders and insights when it works best for you.',
                style: TextStyle(
                  fontSize: 16,
                  color: AppTheme.textSecondary,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              ..._options.map((option) => Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: _buildTimeOption(
                      option['value'] as String,
                      option['label'] as String,
                      option['time'] as String,
                      option['icon'] as IconData,
                      option['description'] as String,
                    ),
                  )),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _selectedTime != null ? _saveAndContinue : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryPurple,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Continue',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
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

  Widget _buildTimeOption(
    String value,
    String label,
    String time,
    IconData icon,
    String description,
  ) {
    final isSelected = _selectedTime == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTime = value;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryPurple.withOpacity(0.1) : Colors.white,
          border: Border.all(
            color: isSelected ? AppTheme.primaryPurple : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppTheme.primaryPurple
                    : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: isSelected ? Colors.white : Colors.grey.shade600,
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
                      fontWeight: FontWeight.bold,
                      color: isSelected ? AppTheme.primaryPurple : AppTheme.textPrimary,
                    ),
                  ),
                  Text(
                    time,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
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
