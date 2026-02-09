import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:babysteps_app/providers/baby_provider.dart';
import 'package:babysteps_app/models/baby.dart';
import 'package:babysteps_app/services/sleep_recommendation_service.dart';
import 'package:babysteps_app/services/supabase_service.dart';
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
  List<NapRecord> _naps = [];
  bool _napSkipped = false;
  DateTime? _activeDate;
  DateTime? _sleepTime;
  DateTime? _recommendedWakeTime;
  SleepPattern? _historicalPattern;
  bool _loadingHistory = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _activeDate = DateUtils.dateOnly(DateTime.now());
    _loadHistoricalData();
  }

  Future<void> _loadHistoricalData() async {
    final babyProvider = Provider.of<BabyProvider>(context, listen: false);
    final baby = babyProvider.selectedBaby;
    if (baby == null) return;

    setState(() => _loadingHistory = true);

    try {
      final supabaseService = SupabaseService();
      final history = await supabaseService.getSleepHistory(baby.id, days: 14);
      final pattern = SleepRecommendationService.analyzeHistory(history);

      if (mounted) {
        setState(() {
          _historicalPattern = pattern;
          _loadingHistory = false;
        });
      }
    } catch (e) {
      // Silently ignored
      if (mounted) {
        setState(() => _loadingHistory = false);
      }
    }
  }

  int _getAgeInMonths(Baby baby) {
    if (baby.birthdate == null) return 6;
    final now = DateTime.now();
    final birthdate = baby.birthdate!;
    return ((now.year - birthdate.year) * 12 + now.month - birthdate.month);
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
          _napSkipped = false;
        });
        _loadHistoricalData();
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
    final ageInMonths = _getAgeInMonths(baby);

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
                            _getRecommendedSleepExplanation(baby),
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

  String _getRecommendedSleepExplanation(Baby baby) {
    final ageInMonths = _getAgeInMonths(baby);
    final schedule = SleepRecommendationService.getScheduleForAge(ageInMonths);
    final hours = schedule.nightSleepDuration.inHours;
    final minutes = schedule.nightSleepDuration.inMinutes % 60;

    String base = '$hours${minutes > 0 ? '.${minutes ~/ 6}' : ''} hours of sleep recommended';

    // Add context about adjustments
    if (_historicalPattern != null && _historicalPattern!.hasEnoughData) {
      base += ' (personalized from history)';
    }

    final typicalBedtime = SleepRecommendationService.getTypicalBedtime(ageInMonths, _historicalPattern);
    if (_sleepTime != null) {
      final sleepMinutes = _sleepTime!.hour * 60 + _sleepTime!.minute;
      final typicalMinutes = typicalBedtime.hour * 60 + typicalBedtime.minute;
      if (sleepMinutes > typicalMinutes + 30) {
        base += '\nAdjusted for late bedtime';
      }
    }

    return base;
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
                              _napSkipped = false;
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
    final ageInMonths = _getAgeInMonths(baby);
    final schedule = SleepRecommendationService.getScheduleForAge(ageInMonths);
    final recommendation = _getNextNapRecommendation(baby);
    final completedNapsCount = _naps.where((n) => n.isComplete).length;

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
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Naps',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${completedNapsCount}/${schedule.napsPerDay} naps today',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_naps.isNotEmpty) ...[
              ..._naps.asMap().entries.map((entry) {
                final index = entry.key;
                final nap = entry.value;
                return _buildNapCard(index, nap, baby);
              }),
              const SizedBox(height: 12),
            ],
            if (recommendation != null) ...[
              _buildNapRecommendationCard(recommendation, baby),
            ] else if (_naps.length < schedule.napsPerDay && !_napSkipped) ...[
              // Show skip option if no recommendation but naps remaining
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    const Text(
                      'No nap recommended right now',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: () => _manuallyAddNap(baby),
                      icon: const Icon(FeatherIcons.plus, size: 16),
                      label: const Text('Add Nap Manually'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFA67EB7),
                        side: const BorderSide(color: Color(0xFFA67EB7)),
                      ),
                    ),
                  ],
                ),
              ),
            ] else if (completedNapsCount >= schedule.napsPerDay) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFD1FAE5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(
                      FeatherIcons.checkCircle,
                      color: Color(0xFF059669),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'All naps complete for today!',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF059669),
                      ),
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

  Widget _buildNapRecommendationCard(DateTime recommendation, Baby baby) {
    final ageInMonths = _getAgeInMonths(baby);
    final schedule = SleepRecommendationService.getScheduleForAge(ageInMonths);
    final napNumber = _naps.length + 1;

    // Calculate recommended end time
    final recommendedEnd = SleepRecommendationService.calculateRecommendedNapEnd(
      napStart: recommendation,
      ageInMonths: ageInMonths,
      napNumber: napNumber,
      totalNapsPlanned: schedule.napsPerDay,
      history: _historicalPattern,
    );

    final napDuration = recommendedEnd.difference(recommendation);
    final hours = napDuration.inHours;
    final minutes = napDuration.inMinutes % 60;

    return Container(
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Recommended Nap Time',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF6B7280),
                ),
              ),
              Text(
                'Nap $napNumber',
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF6B7280),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    DateFormat('h:mm a').format(recommendation),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFA67EB7),
                    ),
                  ),
                  Text(
                    '${hours > 0 ? '${hours}h ' : ''}${minutes}m nap suggested',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    'Wake by',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                  Text(
                    DateFormat('h:mm a').format(recommendedEnd),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ],
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
                      _napSkipped = true;
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Nap skipped. Bedtime adjusted accordingly.'),
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
    );
  }

  Widget _buildNapCard(int index, NapRecord nap, Baby baby) {
    final ageInMonths = _getAgeInMonths(baby);

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
              Row(
                children: [
                  Text(
                    'Nap ${index + 1}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (nap.isComplete) ...[
                    const SizedBox(width: 8),
                    if (nap.isShort)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Short',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.orange,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      )
                    else if (nap.isLong)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Long',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.blue,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ],
              ),
              IconButton(
                onPressed: () {
                  setState(() {
                    _naps.removeAt(index);
                    _napSkipped = false;
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
              if (nap.actualEndTime == null)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Wake by',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('h:mm a').format(nap.recommendedEndTime),
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
                        DateFormat('h:mm a').format(nap.actualEndTime!),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFA67EB7),
                        ),
                      ),
                    ],
                  ),
                ),
              if (nap.isComplete)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Duration',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatDuration(nap.actualDuration),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          if (nap.actualEndTime == null) ...[
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

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }

  Widget _buildBedtimeRecommendation(Baby baby) {
    final bedtime = _getRecommendedBedtime(baby);
    final ageInMonths = _getAgeInMonths(baby);
    final schedule = SleepRecommendationService.getScheduleForAge(ageInMonths);

    // Build explanation
    String explanation = '';
    final completedNaps = _naps.where((n) => n.isComplete).length;
    final shortNaps = _naps.where((n) => n.isShort).length;

    if (_naps.isEmpty && _napSkipped) {
      explanation = 'Adjusted earlier due to skipped nap';
    } else if (_naps.isEmpty) {
      explanation = 'Based on no naps today';
    } else {
      explanation = 'Based on $completedNaps nap${completedNaps > 1 ? 's' : ''} today';
      if (shortNaps > 0) {
        explanation += ' ($shortNaps short)';
      }
    }

    if (_historicalPattern != null && _historicalPattern!.hasEnoughData) {
      explanation += '\nPersonalized from sleep history';
    }

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
                    explanation,
                    textAlign: TextAlign.center,
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
    final ageInMonths = _getAgeInMonths(baby);
    final typicalBedtime = SleepRecommendationService.getTypicalBedtime(ageInMonths, _historicalPattern);

    final initialTime = _sleepTime != null
        ? TimeOfDay.fromDateTime(_sleepTime!)
        : TimeOfDay.fromDateTime(typicalBedtime);

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
        // Calculate recommended wake time using the service
        _recommendedWakeTime = SleepRecommendationService.calculateRecommendedWakeTime(
          sleepTime: _sleepTime!,
          ageInMonths: ageInMonths,
          history: _historicalPattern,
          typicalBedtime: typicalBedtime,
        );
      });
    }
  }

  Future<void> _selectWakeUpTime(BuildContext context) async {
    final now = DateTime.now();
    final initialTime = _wakeUpTime != null
        ? TimeOfDay.fromDateTime(_wakeUpTime!)
        : (_recommendedWakeTime != null
            ? TimeOfDay.fromDateTime(_recommendedWakeTime!)
            : const TimeOfDay(hour: 7, minute: 0));

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
        _napSkipped = false;
      });
    }
  }

  void _addNap(DateTime startTime) {
    final baby = Provider.of<BabyProvider>(context, listen: false).selectedBaby;
    if (baby == null) return;

    final ageInMonths = _getAgeInMonths(baby);
    final schedule = SleepRecommendationService.getScheduleForAge(ageInMonths);
    final napNumber = _naps.length + 1;

    final recommendedEnd = SleepRecommendationService.calculateRecommendedNapEnd(
      napStart: startTime,
      ageInMonths: ageInMonths,
      napNumber: napNumber,
      totalNapsPlanned: schedule.napsPerDay,
      history: _historicalPattern,
    );

    setState(() {
      _napSkipped = false;
      _naps.add(NapRecord(
        startTime: startTime,
        recommendedEndTime: recommendedEnd,
      ));
    });
  }

  Future<void> _manuallyAddNap(Baby baby) async {
    final now = DateTime.now();
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(now),
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
      final start = DateTime(now.year, now.month, now.day, picked.hour, picked.minute);
      _addNap(start);
    }
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
        _naps[index] = NapRecord(
          startTime: _naps[index].startTime,
          recommendedEndTime: _naps[index].recommendedEndTime,
          actualEndTime: endTime,
        );
      });
    }
  }

  DateTime? _getNextNapRecommendation(Baby baby) {
    if (_wakeUpTime == null) return null;

    final ageInMonths = _getAgeInMonths(baby);

    return SleepRecommendationService.calculateNextNapTime(
      wakeUpTime: _wakeUpTime!,
      ageInMonths: ageInMonths,
      completedNaps: _naps,
      napSkipped: _napSkipped,
      history: _historicalPattern,
    );
  }

  DateTime _getRecommendedBedtime(Baby baby) {
    if (_wakeUpTime == null) return DateTime.now();

    final ageInMonths = _getAgeInMonths(baby);

    return SleepRecommendationService.calculateRecommendedBedtime(
      wakeUpTime: _wakeUpTime!,
      ageInMonths: ageInMonths,
      naps: _naps,
      napSkipped: _napSkipped,
      history: _historicalPattern,
    );
  }
}
