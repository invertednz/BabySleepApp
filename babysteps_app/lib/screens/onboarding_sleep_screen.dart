import 'package:flutter/material.dart';
import 'package:babysteps_app/models/baby.dart';
import 'package:babysteps_app/theme/app_theme.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:babysteps_app/screens/onboarding_feeding_screen.dart';
import 'package:provider/provider.dart';
import 'package:babysteps_app/providers/baby_provider.dart';

class OnboardingSleepScreen extends StatefulWidget {
  final List<Baby> babies;
  const OnboardingSleepScreen({required this.babies, super.key});

  @override
  State<OnboardingSleepScreen> createState() => _OnboardingSleepScreenState();
}

class _OnboardingSleepScreenState extends State<OnboardingSleepScreen> {
  late Baby _selectedBaby;
  final _bedtimeController = TextEditingController();
  final _wakeTimeController = TextEditingController();
  final List<NapTime> _napTimes = [NapTime(id: 1)];
  int _nextNapId = 2;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.babies.isNotEmpty) {
      _selectedBaby = widget.babies.first;
    }
    
    // Set default times
    _bedtimeController.text = '20:00'; // 8:00 PM
    _wakeTimeController.text = '07:00'; // 7:00 AM
  }

  @override
  void dispose() {
    _bedtimeController.dispose();
    _wakeTimeController.dispose();
    for (var nap in _napTimes) {
      nap.startController.dispose();
      nap.endController.dispose();
    }
    super.dispose();
  }

  void _addNap() {
    setState(() {
      _napTimes.add(NapTime(id: _nextNapId));
      _nextNapId++;
    });
  }

  void _removeNap(int id) {
    setState(() {
      _napTimes.removeWhere((nap) => nap.id == id);
    });
  }

  Future<void> _saveSleepData() async {
    // Validate inputs
    if (_bedtimeController.text.isEmpty || _wakeTimeController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please set bedtime and wake time')),
      );
      return;
    }
    
    // Validate nap times if any are added
    for (var nap in _napTimes) {
      if (nap.startController.text.isEmpty || nap.endController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please complete all nap times or remove incomplete ones')),
        );
        return;
      }
    }
    
    setState(() {
      _isSaving = true;
    });
    
    try {
      // Prepare sleep data
      final String bedtime = _bedtimeController.text;
      final String wakeTime = _wakeTimeController.text;
      
      // Format nap times
      final List<Map<String, String>> napTimes = _napTimes
          .map((nap) => {
                'start': nap.startController.text,
                'end': nap.endController.text,
              })
          .toList();
      
      // Update the baby object with sleep schedule
      _selectedBaby = _selectedBaby.copyWith(
        bedtime: bedtime,
        wakeTime: wakeTime,
        naps: napTimes,
      );
      
      // Save to Supabase via provider
      final babyProvider = Provider.of<BabyProvider>(context, listen: false);
      await babyProvider.updateBabySleepSchedule(
        bedtime: bedtime,
        wakeTime: wakeTime,
        naps: napTimes,
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
            builder: (context) => OnboardingFeedingScreen(babies: widget.babies),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving sleep data: $e')),
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
              value: 0.6, // 60% progress
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
                            Text(
                              "Sleep Patterns",
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "Help us understand ${_selectedBaby.name}'s sleep schedule.",
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // Form inputs
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
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
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Bedtime
                            const Text(
                              'Typical Bedtime',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _bedtimeController,
                              readOnly: true,
                              onTap: () async {
                                final TimeOfDay? picked = await showTimePicker(
                                  context: context,
                                  initialTime: TimeOfDay(
                                    hour: int.parse(_bedtimeController.text.split(':')[0]),
                                    minute: int.parse(_bedtimeController.text.split(':')[1]),
                                  ),
                                );
                                if (picked != null) {
                                  setState(() {
                                    _bedtimeController.text = 
                                        '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
                                  });
                                }
                              },
                              decoration: InputDecoration(
                                prefixIcon: const Icon(FeatherIcons.moon, color: Colors.grey),
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
                            
                            // Wake-up time
                            const Text(
                              'Typical Wake-up Time',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _wakeTimeController,
                              readOnly: true,
                              onTap: () async {
                                final TimeOfDay? picked = await showTimePicker(
                                  context: context,
                                  initialTime: TimeOfDay(
                                    hour: int.parse(_wakeTimeController.text.split(':')[0]),
                                    minute: int.parse(_wakeTimeController.text.split(':')[1]),
                                  ),
                                );
                                if (picked != null) {
                                  setState(() {
                                    _wakeTimeController.text = 
                                        '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
                                  });
                                }
                              },
                              decoration: InputDecoration(
                                prefixIcon: const Icon(FeatherIcons.sun, color: Colors.grey),
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
                            const SizedBox(height: 24),
                            
                            // Nap Schedule Section
                            Container(
                              decoration: BoxDecoration(
                                border: Border(
                                  top: BorderSide(color: Colors.grey[200]!),
                                ),
                              ),
                              padding: const EdgeInsets.only(top: 16),
                              child: Column(
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text(
                                        'Nap Schedule',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      TextButton.icon(
                                        onPressed: _addNap,
                                        icon: const Icon(
                                          FeatherIcons.plusCircle,
                                          size: 16,
                                          color: AppTheme.primaryPurple,
                                        ),
                                        label: const Text(
                                          'Add Nap',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: AppTheme.primaryPurple,
                                          ),
                                        ),
                                        style: TextButton.styleFrom(
                                          padding: EdgeInsets.zero,
                                          minimumSize: Size.zero,
                                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  
                                  // Nap items
                                  ..._napTimes.map((nap) => _buildNapItem(nap)).toList(),
                                ],
                              ),
                            ),
                          ],
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
                      onPressed: _isSaving ? null : _saveSleepData,
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

  Widget _buildNapItem(NapTime nap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F2FC),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Nap ${nap.id}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
              IconButton(
                onPressed: () => _removeNap(nap.id),
                icon: const Icon(FeatherIcons.x, size: 16),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                color: Colors.grey,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Start Time',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 4),
                    TextField(
                      controller: nap.startController,
                      readOnly: true,
                      onTap: () async {
                        final TimeOfDay? picked = await showTimePicker(
                          context: context,
                          initialTime: nap.startController.text.isEmpty
                              ? const TimeOfDay(hour: 12, minute: 0)
                              : TimeOfDay(
                                  hour: int.parse(nap.startController.text.split(':')[0]),
                                  minute: int.parse(nap.startController.text.split(':')[1]),
                                ),
                        );
                        if (picked != null) {
                          setState(() {
                            nap.startController.text = 
                                '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
                          });
                        }
                      },
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey[200]!),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey[200]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: AppTheme.primaryPurple),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'End Time',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 4),
                    TextField(
                      controller: nap.endController,
                      readOnly: true,
                      onTap: () async {
                        final TimeOfDay? picked = await showTimePicker(
                          context: context,
                          initialTime: nap.endController.text.isEmpty
                              ? const TimeOfDay(hour: 13, minute: 0)
                              : TimeOfDay(
                                  hour: int.parse(nap.endController.text.split(':')[0]),
                                  minute: int.parse(nap.endController.text.split(':')[1]),
                                ),
                        );
                        if (picked != null) {
                          setState(() {
                            nap.endController.text = 
                                '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
                          });
                        }
                      },
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey[200]!),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey[200]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: AppTheme.primaryPurple),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class NapTime {
  final int id;
  final TextEditingController startController = TextEditingController();
  final TextEditingController endController = TextEditingController();

  NapTime({required this.id});
}
