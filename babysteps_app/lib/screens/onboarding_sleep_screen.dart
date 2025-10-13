import 'package:flutter/material.dart';
import 'package:babysteps_app/models/baby.dart';
import 'package:babysteps_app/theme/app_theme.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:babysteps_app/screens/onboarding_short_term_focus_screen.dart';
import 'package:babysteps_app/screens/app_container.dart';
import 'package:provider/provider.dart';
import 'package:babysteps_app/providers/baby_provider.dart';
import 'package:babysteps_app/utils/app_animations.dart';
import 'package:babysteps_app/widgets/onboarding_app_bar.dart';

class OnboardingSleepScreen extends StatefulWidget {
  final List<Baby> babies;
  final int initialIndex;
  const OnboardingSleepScreen({required this.babies, this.initialIndex = 0, super.key});

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
  int _currentIndex = 0;

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
      // Persist in local list
      widget.babies[_currentIndex] = _selectedBaby;

      // Save to Supabase via provider (update schedule)
      final babyProvider = Provider.of<BabyProvider>(context, listen: false);
      await babyProvider.updateBabySleepSchedule(
        bedtime: bedtime,
        wakeTime: wakeTime,
        naps: napTimes,
      );

      // If more babies, advance to next baby on this page
      if (_currentIndex < widget.babies.length - 1) {
        setState(() {
          _currentIndex += 1;
          _selectedBaby = widget.babies[_currentIndex];
          _resetNaps();
          _preloadFromBaby();
          _isSaving = false;
        });
        return;
      }

      // Last baby: onboarding complete -> go to main app
      if (mounted) {
        Navigator.of(context).pushWithFade(const AppContainer());
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

  void _preloadFromBaby() {
    // Set defaults if not present
    _bedtimeController.text = _selectedBaby.bedtime ?? '20:00';
    _wakeTimeController.text = _selectedBaby.wakeTime ?? '07:00';
    // Reset and load naps
    _resetNaps();
    final existing = _selectedBaby.naps ?? [];
    for (int i = 0; i < existing.length; i++) {
      if (i >= _napTimes.length) {
        _napTimes.add(NapTime(id: _nextNapId++));
      }
      _napTimes[i].startController.text = existing[i]['start'] ?? '';
      _napTimes[i].endController.text = existing[i]['end'] ?? '';
    }
  }

  void _resetNaps() {
    for (var nap in _napTimes) {
      nap.startController.clear();
      nap.endController.clear();
    }
    _napTimes
      ..clear()
      ..add(NapTime(id: 1));
    _nextNapId = 2;
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
                    OnboardingShortTermFocusScreen(babies: widget.babies, initialIndex: _currentIndex),
                  );
                }
              },
            ),
            const OnboardingProgressBar(progress: 0.9),
            // Main content
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title & subtitle
                      Text('Sleep Patterns', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text("Help us understand ${_selectedBaby.name}'s sleep schedule.",
                          style: const TextStyle(fontSize: 16, color: Colors.black54)),
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
            
            // Navigation button
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveSleepData,
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
                            : 'Complete',
                      ),
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
