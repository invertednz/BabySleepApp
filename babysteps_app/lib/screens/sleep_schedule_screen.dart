import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:babysteps_app/providers/baby_provider.dart';
import 'package:babysteps_app/models/baby.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:intl/intl.dart';
import 'package:babysteps_app/widgets/app_header.dart';

class SleepScheduleScreen extends StatefulWidget {
  const SleepScheduleScreen({super.key});

  @override
  State<SleepScheduleScreen> createState() => _SleepScheduleScreenState();
}

class _SleepScheduleScreenState extends State<SleepScheduleScreen>
    with AutomaticKeepAliveClientMixin {
  DateTime? _wakeUpTime;
  List<_NapEntry> _naps = [];
  DateTime? _skippedRecommendationTime;
  DateTime? _activeDate;
  DateTime? _sleepTime;
  DateTime? _recommendedWakeTime;

  // How long to try for a nap before giving up (typical 30 minutes)
  static const Duration _napAttemptWindow = Duration(minutes: 30);

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _activeDate = DateUtils.dateOnly(DateTime.now());
  }

  Future<void> _startNapWithTimePicker(DateTime suggestedStart) async {
    final initial = TimeOfDay.fromDateTime(suggestedStart);
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: initial,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: Color(0xFFA67EB7)),
        ),
        child: child!,
      ),
    );
    if (picked == null) return;

    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day, picked.hour, picked.minute);
    _addNap(start);
  }

  void _ensureDailyState() {
    final today = DateUtils.dateOnly(DateTime.now());
    if (_activeDate == null || !DateUtils.isSameDay(_activeDate, today)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() {
          _activeDate = today;
          _sleepTime = null;
          _recommendedWakeTime = null;
          _wakeUpTime = null;
          _naps.clear();
          _skippedRecommendationTime = null;
        });
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    super.build(context);
    final babyProvider = Provider.of<BabyProvider>(context);
    final baby = babyProvider.selectedBaby;

    _ensureDailyState();

    if (baby == null) {
      return const Scaffold(
        body: Center(
          child: Text('Please select a baby to view sleep schedule'),
        ),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const AppHeader(),
            Expanded(
              child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildSleepTimeCard(baby),
            const SizedBox(height: 20),
            _buildWakeUpTimeCard(baby),
            const SizedBox(height: 20),
            if (_wakeUpTime != null) ...[
              _buildNapsSection(baby),
              const SizedBox(height: 20),
              _buildBedtimeRecommendation(baby),
            ],
          ],
        ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSleepTimeCard(Baby baby) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFA67EB7).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    FeatherIcons.moon,
                    color: Color(0xFFA67EB7),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Text(
                    'Sleep Time',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_sleepTime == null)
              FilledButton.icon(
                onPressed: () => _selectSleepTime(context, baby),
                icon: const Icon(FeatherIcons.moon),
                label: const Text('Set Sleep Time'),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFA67EB7),
                  minimumSize: const Size(double.infinity, 50),
                ),
              )
            else
              Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Sleep Time',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF6B7280),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              DateFormat('h:mm a').format(_sleepTime!),
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFA67EB7),
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            IconButton(
                              onPressed: () => _selectSleepTime(context, baby),
                              icon: const Icon(FeatherIcons.edit2),
                              color: const Color(0xFFA67EB7),
                            ),
                            IconButton(
                              onPressed: () {
                                setState(() {
                                  _sleepTime = null;
                                  _recommendedWakeTime = null;
                                });
                              },
                              icon: const Icon(FeatherIcons.x),
                              color: Colors.red,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (_recommendedWakeTime != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEEF2FF),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFA67EB7).withOpacity(0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                FeatherIcons.sunrise,
                                color: Color(0xFFA67EB7),
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Recommended Wake Time',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF6B7280),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            DateFormat('h:mm a').format(_recommendedWakeTime!),
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFA67EB7),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _getRecommendedSleepDuration(baby).inHours.toString() + ' hours of sleep',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildWakeUpTimeCard(Baby baby) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFA67EB7).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    FeatherIcons.sunrise,
                    color: Color(0xFFA67EB7),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Text(
                    'Wake Up Time',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_wakeUpTime == null)
              FilledButton.icon(
                onPressed: () => _selectWakeUpTime(context),
                icon: const Icon(FeatherIcons.clock),
                label: const Text('Set Wake Up Time'),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFA67EB7),
                  minimumSize: const Size(double.infinity, 50),
                ),
              )
            else
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      DateFormat('h:mm a').format(_wakeUpTime!),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFA67EB7),
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          onPressed: () => _selectWakeUpTime(context),
                          icon: const Icon(FeatherIcons.edit2),
                          color: const Color(0xFFA67EB7),
                        ),
                        IconButton(
                          onPressed: () {
                            setState(() {
                              _wakeUpTime = null;
                              _naps.clear();
                              _skippedRecommendationTime = null;
                            });
                          },
                          icon: const Icon(FeatherIcons.x),
                          color: Colors.red,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildNapsSection(Baby baby) {
    final schedule = _getSleepSchedule(_getAgeInMonths(baby));
    final recommendation = _getNextNapRecommendation(baby);
    final bool isFinalNap = schedule.napsPerDay <= (_naps.length + 1);
    final cutoff = recommendation != null
        ? _computeLastNapStartCutoff(recommendation, baby, schedule)
        : null;
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFA67EB7).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    FeatherIcons.moon,
                    color: Color(0xFFA67EB7),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Text(
                    'Naps',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_naps.isNotEmpty) ...[
              ..._naps.asMap().entries.map((entry) {
                final index = entry.key;
                final nap = entry.value;
                return _buildNapCard(index, nap);
              }),
              const SizedBox(height: 12),
            ],
            if (recommendation != null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF2FF),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFA67EB7).withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Recommended Nap Time',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      DateFormat('h:mm a').format(recommendation),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFA67EB7),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _startNapWithTimePicker(recommendation),
                            icon: const Icon(FeatherIcons.plus, size: 16),
                            label: const Text('Start Nap'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFFA67EB7),
                              side: const BorderSide(color: Color(0xFFA67EB7)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              setState(() {
                                _skippedRecommendationTime = recommendation;
                              });

                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Nap skipped. Bedtime recommendation updated.'),
                                ),
                              );
                            },
                            icon: const Icon(FeatherIcons.xCircle, size: 16),
                            label: const Text('Skip Nap'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red,
                              side: const BorderSide(color: Colors.red),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildNapCard(int index, _NapEntry nap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Nap ${index + 1}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              IconButton(
                onPressed: () {
                  setState(() {
                    _naps.removeAt(index);
                    _skippedRecommendationTime = null;
                  });
                },
                icon: const Icon(FeatherIcons.trash2, size: 16),
                color: Colors.red,
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
                      'Start',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat('h:mm a').format(nap.startTime),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFA67EB7),
                      ),
                    ),
                  ],
                ),
              ),
              if (nap.endTime == null)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Recommended Wake',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('h:mm a').format(nap.recommendedWakeTime),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                )
              else
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'End',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('h:mm a').format(nap.endTime!),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFA67EB7),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          if (nap.endTime == null) ...[
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () => _endNap(index),
              icon: const Icon(FeatherIcons.checkCircle, size: 16),
              label: const Text('End Nap'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFA67EB7),
                minimumSize: const Size(double.infinity, 40),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBedtimeRecommendation(Baby baby) {
    final bedtime = _getRecommendedBedtime(baby);
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFA67EB7).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    FeatherIcons.sunset,
                    color: Color(0xFFA67EB7),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Text(
                    'Recommended Bedtime',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFA67EB7), Color(0xFF8B5CF6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text(
                    DateFormat('h:mm a').format(bedtime),
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _naps.isEmpty
                        ? 'Based on no naps today'
                        : 'Based on ${_naps.length} nap${_naps.length > 1 ? 's' : ''} today',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
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

  Future<void> _selectSleepTime(BuildContext context, Baby baby) async {
    final now = DateTime.now();
    final initialTime = _sleepTime != null
        ? TimeOfDay.fromDateTime(_sleepTime!)
        : const TimeOfDay(hour: 19, minute: 0);

    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFFA67EB7),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _sleepTime = DateTime(
          now.year,
          now.month,
          now.day,
          picked.hour,
          picked.minute,
        );
        // Calculate recommended wake time
        final sleepDuration = _getRecommendedSleepDuration(baby);
        _recommendedWakeTime = _sleepTime!.add(sleepDuration);
      });
    }
  }

  Duration _getRecommendedSleepDuration(Baby baby) {
    final ageInMonths = _getAgeInMonths(baby);
    
    // Recommended sleep duration by age (nighttime sleep)
    if (ageInMonths < 3) {
      return const Duration(hours: 8, minutes: 30); // Newborns: 8-9 hours at night
    } else if (ageInMonths < 6) {
      return const Duration(hours: 10); // 3-6 months: 10-11 hours
    } else if (ageInMonths < 12) {
      return const Duration(hours: 11); // 6-12 months: 11-12 hours
    } else if (ageInMonths < 24) {
      return const Duration(hours: 11, minutes: 30); // 1-2 years: 11-14 hours
    } else {
      return const Duration(hours: 11); // 2+ years: 10-13 hours
    }
  }

  Future<void> _selectWakeUpTime(BuildContext context) async {
    final now = DateTime.now();
    final initialTime = _wakeUpTime != null
        ? TimeOfDay.fromDateTime(_wakeUpTime!)
        : const TimeOfDay(hour: 7, minute: 0);

    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFFA67EB7),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _wakeUpTime = DateTime(
          now.year,
          now.month,
          now.day,
          picked.hour,
          picked.minute,
        );
        _naps.clear();
        _skippedRecommendationTime = null;
      });
    }
  }

  void _addNap(DateTime startTime) {
    final baby = Provider.of<BabyProvider>(context, listen: false).selectedBaby;
    if (baby == null) return;

    final napDuration = _getRecommendedNapDuration(baby);
    final recommendedWakeTime = startTime.add(napDuration);

    setState(() {
      _skippedRecommendationTime = null;
      _naps.add(_NapEntry(
        startTime: startTime,
        recommendedWakeTime: recommendedWakeTime,
      ));
    });
  }

  void _endNap(int index) async {
    final now = DateTime.now();
    final initialTime = TimeOfDay.fromDateTime(now);

    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFFA67EB7),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        final endTime = DateTime(
          now.year,
          now.month,
          now.day,
          picked.hour,
          picked.minute,
        );
        _naps[index] = _NapEntry(
          startTime: _naps[index].startTime,
          recommendedWakeTime: _naps[index].recommendedWakeTime,
          endTime: endTime,
        );
      });
    }
  }

  DateTime? _getNextNapRecommendation(Baby baby) {
    if (_wakeUpTime == null) return null;

    final ageInMonths = _getAgeInMonths(baby);
    final schedule = _getSleepSchedule(ageInMonths);

    // Get the last wake time (either wake up or last nap end)
    DateTime lastWakeTime = _wakeUpTime!;
    if (_naps.isNotEmpty) {
      final lastNap = _naps.last;
      if (lastNap.endTime != null) {
        lastWakeTime = lastNap.endTime!;
      } else {
        // Nap in progress, no recommendation
        return null;
      }
    }

    // Check if we've had enough naps for the day
    if (_naps.length >= schedule.napsPerDay) {
      return null;
    }

    // Recommend next nap based on wake window
    final nextTime = lastWakeTime.add(schedule.wakeWindow);
    if (_skippedRecommendationTime != null) {
      final diff = nextTime.difference(_skippedRecommendationTime!).abs();
      if (diff <= const Duration(minutes: 1)) {
        return null;
      }
    }

    return nextTime;
  }

  DateTime _getRecommendedBedtime(Baby baby) {
    if (_wakeUpTime == null) return DateTime.now();

    final ageInMonths = _getAgeInMonths(baby);
    final schedule = _getSleepSchedule(ageInMonths);

    // Establish last wake time baseline
    DateTime lastWakeTime = _wakeUpTime!;
    Duration dynamicWindow = schedule.lastWakeWindow;

    if (_naps.isNotEmpty) {
      final lastNap = _naps.last;
      if (lastNap.endTime != null) {
        lastWakeTime = lastNap.endTime!;
        final napLen = lastNap.endTime!.difference(lastNap.startTime);
        // Heuristic based on infant sleep guidance:
        if (napLen < const Duration(minutes: 45)) {
          dynamicWindow -= const Duration(minutes: 45);
        } else if (napLen < const Duration(minutes: 60)) {
          dynamicWindow -= const Duration(minutes: 30);
        } else if (napLen > const Duration(minutes: 90)) {
          dynamicWindow += const Duration(minutes: 30);
        }
      } else {
        // Nap in progress; estimate using recommended wake time
        lastWakeTime = lastNap.recommendedWakeTime;
      }
    } else {
      // No naps: if a nap was skipped, bring bedtime earlier depending on age
      if (_skippedRecommendationTime != null) {
        if (ageInMonths < 12) {
          dynamicWindow -= const Duration(minutes: 60);
        } else if (ageInMonths < 18) {
          dynamicWindow -= const Duration(minutes: 45);
        } else {
          dynamicWindow -= const Duration(minutes: 30);
        }
      }
    }

    // Clamp dynamic window
    if (dynamicWindow < const Duration(hours: 2)) {
      dynamicWindow = const Duration(hours: 2);
    }

    final proposed = lastWakeTime.add(dynamicWindow);

    // Soft cap within a reasonable bedtime band for infants/toddlers
    final bandStart = DateTime(proposed.year, proposed.month, proposed.day, 17, 30);
    final bandEnd = DateTime(proposed.year, proposed.month, proposed.day, 20, 30);
    return proposed.isBefore(bandStart)
        ? bandStart
        : (proposed.isAfter(bandEnd) ? bandEnd : proposed);
  }

  DateTime _defaultTargetBedtimeForAge(int ageMonths) {
    final now = DateTime.now();
    final hour = ageMonths >= 24 ? 19 : 19; // 7:00 pm default for most
    return DateTime(now.year, now.month, now.day, hour, 0);
  }

  DateTime _computeLastNapStartCutoff(
      DateTime recommendedStart, Baby baby, _SleepSchedule schedule) {
    final targetBed = _defaultTargetBedtimeForAge(_getAgeInMonths(baby));
    // Latest start so that there is at least lastWakeWindow after a minimal nap (30m)
    final latestByBed = targetBed
        .subtract(schedule.lastWakeWindow)
        .subtract(const Duration(minutes: 30));
    // Also, don’t start a nap more than ~2 hours after the recommended time
    final maxLag = recommendedStart.add(const Duration(hours: 2));
    return latestByBed.isBefore(maxLag) ? latestByBed : maxLag;
  }


  Duration _getRecommendedNapDuration(Baby baby) {
    final ageInMonths = _getAgeInMonths(baby);
    final schedule = _getSleepSchedule(ageInMonths);
    return schedule.napDuration;
  }

  int _getAgeInMonths(Baby baby) {
    if (baby.birthdate == null) return 6; // Default to 6 months
    final now = DateTime.now();
    final birthdate = baby.birthdate!;
    return ((now.year - birthdate.year) * 12 + now.month - birthdate.month);
  }

  _SleepSchedule _getSleepSchedule(int ageInMonths) {
    // Sleep schedules based on age
    if (ageInMonths < 3) {
      // 0-3 months: 4-5 naps, 45-90 min wake windows
      return _SleepSchedule(
        napsPerDay: 4,
        wakeWindow: const Duration(hours: 1, minutes: 15),
        lastWakeWindow: const Duration(hours: 1, minutes: 30),
        napDuration: const Duration(hours: 1, minutes: 30),
      );
    } else if (ageInMonths < 6) {
      // 3-6 months: 3-4 naps, 1.5-2 hour wake windows
      return _SleepSchedule(
        napsPerDay: 3,
        wakeWindow: const Duration(hours: 1, minutes: 45),
        lastWakeWindow: const Duration(hours: 2),
        napDuration: const Duration(hours: 1, minutes: 30),
      );
    } else if (ageInMonths < 9) {
      // 6-9 months: 2-3 naps, 2-3 hour wake windows
      return _SleepSchedule(
        napsPerDay: 2,
        wakeWindow: const Duration(hours: 2, minutes: 30),
        lastWakeWindow: const Duration(hours: 3),
        napDuration: const Duration(hours: 1, minutes: 30),
      );
    } else if (ageInMonths < 15) {
      // 9-15 months: 2 naps, 3-4 hour wake windows
      return _SleepSchedule(
        napsPerDay: 2,
        wakeWindow: const Duration(hours: 3),
        lastWakeWindow: const Duration(hours: 4),
        napDuration: const Duration(hours: 1, minutes: 30),
      );
    } else if (ageInMonths < 24) {
      // 15-24 months: 1 nap, 4-5 hour wake windows
      return _SleepSchedule(
        napsPerDay: 1,
        wakeWindow: const Duration(hours: 5),
        lastWakeWindow: const Duration(hours: 5),
        napDuration: const Duration(hours: 2),
      );
    } else {
      // 24+ months: 1 nap or no nap, 5-6 hour wake windows
      return _SleepSchedule(
        napsPerDay: 1,
        wakeWindow: const Duration(hours: 6),
        lastWakeWindow: const Duration(hours: 6),
        napDuration: const Duration(hours: 1, minutes: 30),
      );
    }
  }
}

class _NapEntry {
  final DateTime startTime;
  final DateTime recommendedWakeTime;
  final DateTime? endTime;

  _NapEntry({
    required this.startTime,
    required this.recommendedWakeTime,
    this.endTime,
  });
}

class _SleepSchedule {
  final int napsPerDay;
  final Duration wakeWindow;
  final Duration lastWakeWindow;
  final Duration napDuration;

  _SleepSchedule({
    required this.napsPerDay,
    required this.wakeWindow,
    required this.lastWakeWindow,
    required this.napDuration,
  });
}
