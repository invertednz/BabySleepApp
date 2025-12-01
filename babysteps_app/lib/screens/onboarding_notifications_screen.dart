import 'package:flutter/material.dart';
import 'package:babysteps_app/theme/app_theme.dart';
import 'package:babysteps_app/screens/onboarding_parenting_style_screen.dart';
import 'package:babysteps_app/screens/onboarding_parent_feelings_screen.dart';
import 'package:provider/provider.dart';
import 'package:babysteps_app/providers/baby_provider.dart';
import 'package:babysteps_app/utils/app_animations.dart';
import 'package:babysteps_app/widgets/onboarding_app_bar.dart';

class OnboardingNotificationsScreen extends StatefulWidget {
  const OnboardingNotificationsScreen({super.key});

  @override
  State<OnboardingNotificationsScreen> createState() =>
      _OnboardingNotificationsScreenState();
}

class _OnboardingNotificationsScreenState
    extends State<OnboardingNotificationsScreen> {
  String? _selectedTime;
  bool _isLoading = false;

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
    if (_selectedTime == null || _isLoading) return;
    
    setState(() {
      _isLoading = true;
    });
    
    final babyProvider = Provider.of<BabyProvider>(context, listen: false);
    
    // Always save locally for persistence during onboarding
    await babyProvider.savePendingOnboardingPreferences({
      'notification_time': _selectedTime,
    });
    
    try {
      await babyProvider.saveNotificationPreference(_selectedTime!);
    } catch (e) {
      // In guest mode, save fails. Data is already stored locally.
      print('Error saving notification preference (will persist on signup): $e');
    }
    
    if (!mounted) return;
    Navigator.of(context).pushReplacementWithFade(
      OnboardingParentingStyleScreen(babies: const []),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 40.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              OnboardingAppBar(
                onBackPressed: () {
                  Navigator.of(context).pushReplacementWithFade(
                    const OnboardingParentFeelingsScreen(),
                  );
                },
              ),
              const Spacer(),
              const Text(
                'When should we\ncheck in?',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1F2937),
                  height: 1.2,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Text(
                'Get personalized reminders and insights when it works best for you.',
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF6B7280),
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
              const SizedBox(height: 16),
              if (_selectedTime == null)
                const Text(
                  'Please select a time to continue',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF9CA3AF),
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: (_selectedTime != null && !_isLoading) ? _saveAndContinue : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _selectedTime != null 
                        ? AppTheme.primaryPurple 
                        : AppTheme.primaryPurple.withOpacity(0.5),
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                    disabledBackgroundColor: AppTheme.primaryPurple.withOpacity(0.5),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
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
                color: isSelected
                    ? AppTheme.primaryPurple
                    : const Color(0xFFE5E7EB),
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
                  const SizedBox(height: 2),
                  Text(
                    time,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF9CA3AF),
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
