import 'package:flutter/material.dart';
import 'package:babysteps_app/models/baby.dart';
import 'package:babysteps_app/theme/app_theme.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:babysteps_app/screens/onboarding_milestones_screen.dart';
import 'package:babysteps_app/screens/onboarding_concerns_screen.dart';
import 'package:babysteps_app/screens/app_container.dart';
import 'package:provider/provider.dart';
import 'package:babysteps_app/providers/baby_provider.dart';

class OnboardingMeasurementsScreen extends StatefulWidget {
  final List<Baby> babies;
  const OnboardingMeasurementsScreen({required this.babies, super.key});

  @override
  State<OnboardingMeasurementsScreen> createState() => _OnboardingMeasurementsScreenState();
}

class _OnboardingMeasurementsScreenState extends State<OnboardingMeasurementsScreen> {
  late Baby _selectedBaby;
  bool _isMetric = true;
  bool _isSaving = false;
  int _currentIndex = 0;
  
  // Controllers for form fields
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();
  final _headCircumferenceController = TextEditingController();
  final _chestCircumferenceController = TextEditingController();

  // Conversion factors
  static const double kgToLb = 2.20462;
  static const double cmToIn = 0.393701;

  @override
  void initState() {
    super.initState();
    if (widget.babies.isNotEmpty) {
      _currentIndex = 0;
      _selectedBaby = widget.babies[_currentIndex];
      _loadCurrentBabyIntoForm();
    }
  }

  @override
  void dispose() {
    _weightController.dispose();
    _heightController.dispose();
    _headCircumferenceController.dispose();
    _chestCircumferenceController.dispose();
    super.dispose();
  }

  void _toggleUnitSystem() {
    setState(() {
      _isMetric = !_isMetric;
      _convertValues();
    });
  }

  void _convertValues() {
    // Only convert if there are values
    if (_weightController.text.isNotEmpty) {
      double value = double.tryParse(_weightController.text) ?? 0;
      if (_isMetric) {
        // Convert from lb to kg
        _weightController.text = (value / kgToLb).toStringAsFixed(1);
      } else {
        // Convert from kg to lb
        _weightController.text = (value * kgToLb).toStringAsFixed(1);
      }
    }

    // Convert height
    if (_heightController.text.isNotEmpty) {
      double value = double.tryParse(_heightController.text) ?? 0;
      if (_isMetric) {
        // Convert from in to cm
        _heightController.text = (value / cmToIn).toStringAsFixed(1);
      } else {
        // Convert from cm to in
        _heightController.text = (value * cmToIn).toStringAsFixed(1);
      }
    }

    // Convert head circumference
    if (_headCircumferenceController.text.isNotEmpty) {
      double value = double.tryParse(_headCircumferenceController.text) ?? 0;
      if (_isMetric) {
        // Convert from in to cm
        _headCircumferenceController.text = (value / cmToIn).toStringAsFixed(1);
      } else {
        // Convert from cm to in
        _headCircumferenceController.text = (value * cmToIn).toStringAsFixed(1);
      }
    }

    // Convert chest circumference
    if (_chestCircumferenceController.text.isNotEmpty) {
      double value = double.tryParse(_chestCircumferenceController.text) ?? 0;
      if (_isMetric) {
        // Convert from in to cm
        _chestCircumferenceController.text = (value / cmToIn).toStringAsFixed(1);
      } else {
        // Convert from cm to in
        _chestCircumferenceController.text = (value * cmToIn).toStringAsFixed(1);
      }
    }
  }

  Future<void> _saveMeasurements() async {
    // Validate inputs
    if (_weightController.text.isEmpty ||
        _heightController.text.isEmpty ||
        _headCircumferenceController.text.isEmpty ||
        _chestCircumferenceController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all measurements')),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      // Parse values
      final double weight = double.parse(_weightController.text);
      final double height = double.parse(_heightController.text);
      final double headCircumference = double.parse(_headCircumferenceController.text);
      final double chestCircumference = double.parse(_chestCircumferenceController.text);

      // Convert to metric if currently in imperial
      final double weightInKg = _isMetric ? weight : weight / kgToLb;
      final double heightInCm = _isMetric ? height : height / cmToIn;
      final double headCircumferenceInCm = _isMetric ? headCircumference : headCircumference / cmToIn;
      final double chestCircumferenceInCm = _isMetric ? chestCircumference : chestCircumference / cmToIn;

      // Update the baby object with measurements and persist in the list
      _selectedBaby = _selectedBaby.copyWith(
        weightKg: weightInKg,
        heightCm: heightInCm,
        headCircumferenceCm: headCircumferenceInCm,
        chestCircumferenceCm: chestCircumferenceInCm,
      );
      widget.babies[_currentIndex] = _selectedBaby;

      // If there are more babies, go to next baby on this page
      if (_currentIndex < widget.babies.length - 1) {
        setState(() {
          _currentIndex += 1;
          _selectedBaby = widget.babies[_currentIndex];
          _isSaving = false;
          _loadCurrentBabyIntoForm();
        });
        return;
      }

      // Final baby: Validate genders for all babies before saving to Supabase
      for (final b in widget.babies) {
        if (b.gender == null || b.gender!.isEmpty) {
          throw Exception('Gender not set for ${b.name}. Please go back and select a gender.');
        }
      }

      // Upsert all babies: update if exists, create if missing
      final babyProvider = Provider.of<BabyProvider>(context, listen: false);
      await babyProvider.initialize();
      final existingIds = babyProvider.babies.map((b) => b.id).toSet();
      for (var baby in widget.babies) {
        if (existingIds.contains(baby.id)) {
          // Update measurements for existing baby
          babyProvider.selectBaby(baby.id);
          await babyProvider.updateBabyMeasurements(
            weightKg: baby.weightKg ?? 0,
            heightCm: baby.heightCm ?? 0,
            headCircumferenceCm: baby.headCircumferenceCm,
            chestCircumferenceCm: baby.chestCircumferenceCm,
          );
        } else {
          // Create new baby with measurements embedded
          await babyProvider.createBaby(baby);
        }
      }

      // Measurements are now last; navigate to the main app
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const AppContainer()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving measurements: $e')),
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

  void _loadCurrentBabyIntoForm() {
    // Preload existing values for the current baby into the form, if present
    _weightController.text = (_selectedBaby.weightKg ?? '').toString().replaceAll('null', '');
    _heightController.text = (_selectedBaby.heightCm ?? '').toString().replaceAll('null', '');
    _headCircumferenceController.text = (_selectedBaby.headCircumferenceCm ?? '').toString().replaceAll('null', '');
    _chestCircumferenceController.text = (_selectedBaby.chestCircumferenceCm ?? '').toString().replaceAll('null', '');
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
              value: 0.5, // 50% progress
              backgroundColor: const Color(0xFFE2E8F0),
              valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryPurple),
            ),
            
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(FeatherIcons.sliders, color: AppTheme.darkPurple),
                  const SizedBox(width: 12),
                  const Text(
                    'Measurements',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            
            // Main content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Enter ${_selectedBaby.name}\'s current measurements',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'These measurements help us track your baby\'s growth and development.',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Unit toggle
                    Card(
                      elevation: 0,
                      color: Colors.grey[100],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Units',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(16),
                              ),
                              padding: const EdgeInsets.all(4),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: !_isMetric ? _toggleUnitSystem : null,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 8,
                                        ),
                                        decoration: BoxDecoration(
                                          color: _isMetric ? Colors.white : Colors.transparent,
                                          borderRadius: BorderRadius.circular(12),
                                          boxShadow: _isMetric
                                              ? [
                                                  BoxShadow(
                                                    color: Colors.grey.withOpacity(0.2),
                                                    spreadRadius: 1,
                                                    blurRadius: 2,
                                                    offset: const Offset(0, 1),
                                                  ),
                                                ]
                                              : null,
                                        ),
                                        child: const Text(
                                          'Metric (cm/kg)',
                                          style: TextStyle(fontWeight: FontWeight.w500),
                                        ),
                                      ),
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: _isMetric ? _toggleUnitSystem : null,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: !_isMetric ? Colors.white : Colors.transparent,
                                        borderRadius: BorderRadius.circular(12),
                                        boxShadow: !_isMetric
                                            ? [
                                                BoxShadow(
                                                  color: Colors.grey.withOpacity(0.2),
                                                  spreadRadius: 1,
                                                  blurRadius: 2,
                                                  offset: const Offset(0, 1),
                                                ),
                                              ]
                                            : null,
                                      ),
                                      child: const Text(
                                        'Imperial (in/lb)',
                                        style: TextStyle(fontWeight: FontWeight.w500),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Measurement form
                    Card(
                      elevation: 0,
                      color: Colors.grey[100],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Weight
                            Text(
                              _isMetric ? 'Weight (kg)' : 'Weight (lb)',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _weightController,
                              keyboardType: TextInputType.numberWithOptions(decimal: true),
                              decoration: InputDecoration(
                                hintText: _isMetric ? 'e.g., 3.5' : 'e.g., 7.7',
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
                            
                            // Height
                            Text(
                              _isMetric ? 'Height (cm)' : 'Height (in)',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _heightController,
                              keyboardType: TextInputType.numberWithOptions(decimal: true),
                              decoration: InputDecoration(
                                hintText: _isMetric ? 'e.g., 50' : 'e.g., 19.7',
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
                            
                            // Head Circumference
                            Text(
                              _isMetric ? 'Head Circumference (cm)' : 'Head Circumference (in)',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _headCircumferenceController,
                              keyboardType: TextInputType.numberWithOptions(decimal: true),
                              decoration: InputDecoration(
                                hintText: _isMetric ? 'e.g., 35' : 'e.g., 13.8',
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
                            
                            // Chest Circumference
                            Text(
                              _isMetric ? 'Chest Circumference (cm)' : 'Chest Circumference (in)',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _chestCircumferenceController,
                              keyboardType: TextInputType.numberWithOptions(decimal: true),
                              decoration: InputDecoration(
                                hintText: _isMetric ? 'e.g., 40' : 'e.g., 15.7',
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
                            
                            // Note about unit conversion
                            const Text(
                              'Values will be automatically converted when switching units.',
                              style: TextStyle(
                                fontSize: 12,
                                fontStyle: FontStyle.italic,
                                color: Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
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
                      onPressed: () {
                        if (_currentIndex > 0) {
                          setState(() {
                            _currentIndex -= 1;
                            _selectedBaby = widget.babies[_currentIndex];
                            _loadCurrentBabyIntoForm();
                          });
                        } else {
                          // Go to previous onboarding step when launched directly via gating
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(
                              builder: (context) => OnboardingMilestonesScreen(babies: widget.babies),
                            ),
                          );
                        }
                      },
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
                      onPressed: _isSaving ? null : _saveMeasurements,
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
                          : Text(
                              _currentIndex < widget.babies.length - 1
                                  ? 'Next: ${widget.babies[_currentIndex + 1].name}'
                                  : 'Next',
                            ),
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
}
