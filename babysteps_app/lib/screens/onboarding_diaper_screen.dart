import 'package:flutter/material.dart';
import 'package:babysteps_app/models/baby.dart';
import 'package:babysteps_app/theme/app_theme.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:babysteps_app/screens/onboarding_concerns_screen.dart';
import 'package:babysteps_app/screens/onboarding_nurture_priorities_screen.dart';
import 'package:babysteps_app/screens/onboarding_feeding_screen.dart';
import 'package:provider/provider.dart';
import 'package:babysteps_app/providers/baby_provider.dart';
import 'package:babysteps_app/utils/app_animations.dart';
import 'package:babysteps_app/widgets/onboarding_app_bar.dart';

class OnboardingDiaperScreen extends StatefulWidget {
  final List<Baby> babies;
  final int initialIndex;
  const OnboardingDiaperScreen({required this.babies, this.initialIndex = 0, super.key});

  @override
  State<OnboardingDiaperScreen> createState() => _OnboardingDiaperScreenState();
}

class _OnboardingDiaperScreenState extends State<OnboardingDiaperScreen> {
  late Baby _selectedBaby;
  final _wetDiapersController = TextEditingController();
  final _dirtyDiapersController = TextEditingController();
  final _notesController = TextEditingController();
  Color? _selectedStoolColor;
  bool _isSaving = false;
  int _currentIndex = 0;

  // Stool color options
  final List<Color> _stoolColors = [
    const Color(0xFF6B4423), // Dark Brown
    const Color(0xFFA5692A), // Brown
    const Color(0xFFD4AC0D), // Yellow-Brown
    const Color(0xFF58D68D), // Green
    const Color(0xFFF4D03F), // Yellow
    const Color(0xFFE67E22), // Orange-Brown
  ];

  @override
  void initState() {
    super.initState();
    if (widget.babies.isNotEmpty) {
      _currentIndex = (widget.initialIndex >= 0 && widget.initialIndex < widget.babies.length)
          ? widget.initialIndex
          : 0;
      _selectedBaby = widget.babies[_currentIndex];
      _preloadFromBaby();
    }
  }

  @override
  void dispose() {
    _wetDiapersController.dispose();
    _dirtyDiapersController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _selectStoolColor(Color color) {
    setState(() {
      _selectedStoolColor = color;
    });
  }

  Future<void> _saveDiaperData() async {
    setState(() {
      _isSaving = true;
    });
    
    try {
      // Prepare diaper data
      final int? wetDiapers = _wetDiapersController.text.isNotEmpty
          ? int.tryParse(_wetDiapersController.text)
          : null;
      
      final int? dirtyDiapers = _dirtyDiapersController.text.isNotEmpty
          ? int.tryParse(_dirtyDiapersController.text)
          : null;
      
      final String notes = _notesController.text;
      
      // Convert color to hex string for storage
      final String? stoolColorHex = _selectedStoolColor != null
          ? '#${_selectedStoolColor!.value.toRadixString(16).padLeft(8, '0')}'
          : null;
      
      // Update the baby object with diaper preferences
      _selectedBaby = _selectedBaby.copyWith(
        wetDiapersPerDay: wetDiapers,
        dirtyDiapersPerDay: dirtyDiapers,
        stoolColor: stoolColorHex,
        diaperNotes: notes,
      );
      // Persist in local list
      widget.babies[_currentIndex] = _selectedBaby;

      // Save to Supabase via provider
      try {
        final babyProvider = Provider.of<BabyProvider>(context, listen: false);
        await babyProvider.updateBabyDiaperPreferences(
          babyId: _selectedBaby.id,
          wetDiapersPerDay: wetDiapers,
          dirtyDiapersPerDay: dirtyDiapers,
          stoolColor: stoolColorHex,
          diaperNotes: notes,
        );
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error saving diaper data: $e')),
          );
        }
        // Continue anyway even if save fails
      }

      // If there are more babies, advance to next baby on this page
      if (_currentIndex < widget.babies.length - 1) {
        setState(() {
          _currentIndex += 1;
          _selectedBaby = widget.babies[_currentIndex];
          _preloadFromBaby();
          _isSaving = false;
        });
        return;
      }

      // Last baby: continue to Nurture Priorities step (next in onboarding)
      if (mounted) {
        Navigator.of(context).pushWithFade(
          OnboardingNurturePrioritiesScreen(babies: widget.babies, initialIndex: _currentIndex),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving diaper data: $e')),
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

  void _preloadFromBaby() {
    _wetDiapersController.text = _selectedBaby.wetDiapersPerDay?.toString() ?? '';
    _dirtyDiapersController.text = _selectedBaby.dirtyDiapersPerDay?.toString() ?? '';
    _notesController.text = _selectedBaby.diaperNotes ?? '';
    if (_selectedBaby.stoolColor != null) {
      try {
        final parsed = int.parse(_selectedBaby.stoolColor!.replaceFirst('#', ''), radix: 16);
        _selectedStoolColor = Color(parsed);
      } catch (_) {
        _selectedStoolColor = null;
      }
    } else {
      _selectedStoolColor = null;
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            OnboardingAppBar(
              onBackPressed: () {
                if (_currentIndex > 0) {
                  setState(() {
                    _currentIndex -= 1;
                    _selectedBaby = widget.babies[_currentIndex];
                    _preloadFromBaby();
                  });
                } else {
                  Navigator.of(context).pushReplacementWithFade(
                    OnboardingFeedingScreen(babies: widget.babies, initialIndex: _currentIndex),
                  );
                }
              },
            ),
            const OnboardingProgressBar(progress: 0.8),
            
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
                              "Diaper Patterns",
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "Track ${_selectedBaby.name}'s diaper changes.",
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // Wet Diapers
                      const Text(
                        'Wet Diapers per Day',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _wetDiapersController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          hintText: 'e.g., 6',
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
                      
                      // Dirty Diapers
                      const Text(
                        'Dirty Diapers per Day',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _dirtyDiapersController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          hintText: 'e.g., 3',
                          prefixIcon: const Icon(FeatherIcons.layers, color: Colors.grey),
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
                      
                      // Stool Color
                      const Text(
                        'Typical Stool Color',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: _stoolColors.map((color) => _buildColorSwatch(color)).toList(),
                      ),
                      const SizedBox(height: 16),
                      
                      // Notes
                      const Text(
                        'Notes',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _notesController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          hintText: 'Any concerns or observations...',
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
            
            // Navigation button
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveDiaperData,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryPurple,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  minimumSize: const Size(double.infinity, 50),
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
    );
  }

  Widget _buildColorSwatch(Color color) {
    final isSelected = _selectedStoolColor == color;
    
    return GestureDetector(
      onTap: () => _selectStoolColor(color),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? AppTheme.primaryPurple : Colors.transparent,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 1,
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
      ),
    );
  }
}
