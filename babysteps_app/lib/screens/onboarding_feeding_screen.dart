import 'package:flutter/material.dart';
import 'package:babysteps_app/models/baby.dart';
import 'package:babysteps_app/theme/app_theme.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:babysteps_app/screens/onboarding_diaper_screen.dart';
import 'package:provider/provider.dart';
import 'package:babysteps_app/providers/baby_provider.dart';

class OnboardingFeedingScreen extends StatefulWidget {
  final List<Baby> babies;
  const OnboardingFeedingScreen({required this.babies, super.key});

  @override
  State<OnboardingFeedingScreen> createState() => _OnboardingFeedingScreenState();
}

class _OnboardingFeedingScreenState extends State<OnboardingFeedingScreen> {
  late Baby _selectedBaby;
  String _selectedFeedingMethod = '';
  final _feedingsPerDayController = TextEditingController();
  final _amountPerFeedingController = TextEditingController();
  final _feedingDurationController = TextEditingController();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.babies.isNotEmpty) {
      _selectedBaby = widget.babies.first;
    }
  }

  @override
  void dispose() {
    _feedingsPerDayController.dispose();
    _amountPerFeedingController.dispose();
    _feedingDurationController.dispose();
    super.dispose();
  }

  void _selectFeedingMethod(String method) {
    setState(() {
      _selectedFeedingMethod = method;
    });
  }

  Future<void> _saveFeedingData() async {
    // Validate inputs
    if (_selectedFeedingMethod.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a feeding method')),
      );
      return;
    }
    
    setState(() {
      _isSaving = true;
    });
    
    try {
      // Prepare feeding data
      final int? feedingsPerDay = _feedingsPerDayController.text.isNotEmpty
          ? int.tryParse(_feedingsPerDayController.text)
          : null;
      
      final double? amountPerFeeding = _amountPerFeedingController.text.isNotEmpty
          ? double.tryParse(_amountPerFeedingController.text)
          : null;
      
      final int? feedingDuration = _feedingDurationController.text.isNotEmpty
          ? int.tryParse(_feedingDurationController.text)
          : null;
      
      // Update the baby object with feeding preferences
      _selectedBaby = _selectedBaby.copyWith(
        feedingMethod: _selectedFeedingMethod,
        feedingsPerDay: feedingsPerDay,
        amountPerFeeding: amountPerFeeding,
        feedingDuration: feedingDuration,
      );
      
      // Save to Supabase via provider
      final babyProvider = Provider.of<BabyProvider>(context, listen: false);
      await babyProvider.updateBabyFeedingPreferences(
        feedingMethod: _selectedFeedingMethod,
        feedingsPerDay: feedingsPerDay ?? 0,
        amountPerFeeding: amountPerFeeding,
        feedingDuration: feedingDuration,
      );
      
      // Update the baby in the list
      final int index = widget.babies.indexWhere((baby) => baby.id == _selectedBaby.id);
      if (index != -1) {
        widget.babies[index] = _selectedBaby;
      }
      
      // Navigate to the next screen
      if (mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => OnboardingDiaperScreen(babies: widget.babies),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving feeding data: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            // Progress bar
            LinearProgressIndicator(
              value: 0.7, // 70% progress
              backgroundColor: const Color(0xFFE2E8F0),
              valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryPurple),
            ),
            
            // Main content
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Center(
                        child: Column(
                          children: [
                            const Text(
                              "Feeding Patterns",
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "Log ${_selectedBaby.name}'s feeding habits.",
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // Feeding Method
                      const Text(
                        'Feeding Method',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: _buildFeedingMethodCard(
                              'Bottle',
                              FeatherIcons.archive,
                              _selectedFeedingMethod == 'Bottle',
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildFeedingMethodCard(
                              'Breast',
                              FeatherIcons.heart,
                              _selectedFeedingMethod == 'Breast',
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildFeedingMethodCard(
                              'Both',
                              FeatherIcons.gitMerge,
                              _selectedFeedingMethod == 'Both',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      
                      // Feedings per Day
                      const Text(
                        'Feedings per Day',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _feedingsPerDayController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          hintText: 'e.g., 8',
                          prefixIcon: const Icon(FeatherIcons.calendar, color: Colors.grey),
                          filled: true,
                          fillColor: Colors.grey[50],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey[200]!),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey[200]!),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppTheme.primaryPurple),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Amount per Feeding
                      const Text(
                        'Amount per Feeding (oz)',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _amountPerFeedingController,
                        keyboardType: TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          hintText: 'e.g., 4.5',
                          prefixIcon: const Icon(FeatherIcons.droplet, color: Colors.grey),
                          filled: true,
                          fillColor: Colors.grey[50],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey[200]!),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey[200]!),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppTheme.primaryPurple),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Feeding Duration
                      const Text(
                        'Average Feeding Duration (minutes)',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _feedingDurationController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          hintText: 'e.g., 20',
                          prefixIcon: const Icon(FeatherIcons.clock, color: Colors.grey),
                          filled: true,
                          fillColor: Colors.grey[50],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey[200]!),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey[200]!),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppTheme.primaryPurple),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            // Navigation buttons
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.grey),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Back'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _saveFeedingData,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryPurple,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Next'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeedingMethodCard(String method, IconData icon, bool isSelected) {
    return GestureDetector(
      onTap: () => _selectFeedingMethod(method),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppTheme.primaryPurple : Colors.grey[200]!,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 3,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 24,
              color: isSelected ? AppTheme.primaryPurple : Colors.grey,
            ),
            const SizedBox(height: 8),
            Text(
              method,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isSelected ? AppTheme.primaryPurple : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
