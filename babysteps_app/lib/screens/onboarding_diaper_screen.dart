import 'package:flutter/material.dart';
import 'package:babysteps_app/models/baby.dart';
import 'package:babysteps_app/theme/app_theme.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:babysteps_app/screens/onboarding_concerns_screen.dart';
import 'package:provider/provider.dart';
import 'package:babysteps_app/providers/baby_provider.dart';

class OnboardingDiaperScreen extends StatefulWidget {
  final List<Baby> babies;
  const OnboardingDiaperScreen({required this.babies, super.key});

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
      _selectedBaby = widget.babies.first;
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
      
      // Save to Supabase via provider
      final babyProvider = Provider.of<BabyProvider>(context, listen: false);
      await babyProvider.updateBabyDiaperPreferences(
        babyId: _selectedBaby.id,
        wetDiapersPerDay: wetDiapers,
        dirtyDiapersPerDay: dirtyDiapers,
        stoolColor: stoolColorHex,
        diaperNotes: notes,
      );
      
      // Update the baby in the list
      final int index = widget.babies.indexWhere((baby) => baby.id == _selectedBaby.id);
      if (index != -1) {
        widget.babies[index] = _selectedBaby;
      }
      
      // Navigate to the concerns screen (final step of onboarding)
      if (mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => OnboardingConcernsScreen(babies: widget.babies),
          ),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            // Progress bar
            LinearProgressIndicator(
              value: 0.8, // 80% progress
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
                      onPressed: _isSaving ? null : _saveDiaperData,
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
