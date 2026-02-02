import 'package:flutter/foundation.dart';

/// Represents age-based sleep schedule guidelines
class SleepSchedule {
  final int napsPerDay;
  final Duration wakeWindow;
  final Duration lastWakeWindow;
  final Duration napDuration;
  final Duration nightSleepDuration;
  final Duration minNapDuration;
  final Duration maxNapDuration;

  const SleepSchedule({
    required this.napsPerDay,
    required this.wakeWindow,
    required this.lastWakeWindow,
    required this.napDuration,
    required this.nightSleepDuration,
    this.minNapDuration = const Duration(minutes: 30),
    this.maxNapDuration = const Duration(hours: 2, minutes: 30),
  });
}

/// Represents a nap with start time, expected end, and actual end
class NapRecord {
  final DateTime startTime;
  final DateTime recommendedEndTime;
  final DateTime? actualEndTime;

  NapRecord({
    required this.startTime,
    required this.recommendedEndTime,
    this.actualEndTime,
  });

  Duration get actualDuration =>
      actualEndTime != null ? actualEndTime!.difference(startTime) : Duration.zero;

  bool get isComplete => actualEndTime != null;
  bool get isShort => isComplete && actualDuration < const Duration(minutes: 45);
  bool get isLong => isComplete && actualDuration > const Duration(minutes: 90);
}

/// Historical sleep pattern data for personalization
class SleepPattern {
  final Duration avgBedtime; // Average bedtime as duration from midnight
  final Duration avgWakeTime; // Average wake time as duration from midnight
  final int avgNapsPerDay;
  final Duration avgNapDuration;
  final Duration avgNightSleep;
  final int dataPoints;

  const SleepPattern({
    required this.avgBedtime,
    required this.avgWakeTime,
    required this.avgNapsPerDay,
    required this.avgNapDuration,
    required this.avgNightSleep,
    required this.dataPoints,
  });

  bool get hasEnoughData => dataPoints >= 3;
}

/// Main service for calculating sleep recommendations
class SleepRecommendationService {
  /// Get the sleep schedule guidelines for a baby's age in months
  static SleepSchedule getScheduleForAge(int ageInMonths) {
    if (ageInMonths < 3) {
      // 0-3 months: Newborns have irregular patterns
      return const SleepSchedule(
        napsPerDay: 4,
        wakeWindow: Duration(hours: 1, minutes: 15),
        lastWakeWindow: Duration(hours: 1, minutes: 30),
        napDuration: Duration(hours: 1, minutes: 30),
        nightSleepDuration: Duration(hours: 8, minutes: 30),
        minNapDuration: Duration(minutes: 20),
        maxNapDuration: Duration(hours: 2),
      );
    } else if (ageInMonths < 6) {
      // 3-6 months: More predictable patterns emerge
      return const SleepSchedule(
        napsPerDay: 3,
        wakeWindow: Duration(hours: 1, minutes: 45),
        lastWakeWindow: Duration(hours: 2),
        napDuration: Duration(hours: 1, minutes: 30),
        nightSleepDuration: Duration(hours: 10),
        minNapDuration: Duration(minutes: 30),
        maxNapDuration: Duration(hours: 2),
      );
    } else if (ageInMonths < 9) {
      // 6-9 months: Transitioning to 2 naps
      return const SleepSchedule(
        napsPerDay: 2,
        wakeWindow: Duration(hours: 2, minutes: 30),
        lastWakeWindow: Duration(hours: 3),
        napDuration: Duration(hours: 1, minutes: 30),
        nightSleepDuration: Duration(hours: 11),
        minNapDuration: Duration(minutes: 45),
        maxNapDuration: Duration(hours: 2),
      );
    } else if (ageInMonths < 15) {
      // 9-15 months: Stable 2 nap schedule
      return const SleepSchedule(
        napsPerDay: 2,
        wakeWindow: Duration(hours: 3),
        lastWakeWindow: Duration(hours: 4),
        napDuration: Duration(hours: 1, minutes: 30),
        nightSleepDuration: Duration(hours: 11),
        minNapDuration: Duration(minutes: 45),
        maxNapDuration: Duration(hours: 2),
      );
    } else if (ageInMonths < 24) {
      // 15-24 months: Transitioning to 1 nap
      return const SleepSchedule(
        napsPerDay: 1,
        wakeWindow: Duration(hours: 5),
        lastWakeWindow: Duration(hours: 5),
        napDuration: Duration(hours: 2),
        nightSleepDuration: Duration(hours: 11, minutes: 30),
        minNapDuration: Duration(hours: 1),
        maxNapDuration: Duration(hours: 3),
      );
    } else {
      // 24+ months: Single nap or dropping nap
      return const SleepSchedule(
        napsPerDay: 1,
        wakeWindow: Duration(hours: 6),
        lastWakeWindow: Duration(hours: 6),
        napDuration: Duration(hours: 1, minutes: 30),
        nightSleepDuration: Duration(hours: 11),
        minNapDuration: Duration(hours: 1),
        maxNapDuration: Duration(hours: 2, minutes: 30),
      );
    }
  }

  /// Calculate recommended wake time based on sleep time
  /// Considers: age, actual sleep time vs typical, historical patterns
  static DateTime calculateRecommendedWakeTime({
    required DateTime sleepTime,
    required int ageInMonths,
    SleepPattern? history,
    DateTime? typicalBedtime,
  }) {
    final schedule = getScheduleForAge(ageInMonths);
    Duration sleepDuration = schedule.nightSleepDuration;

    // If we have historical data, blend with guidelines
    if (history != null && history.hasEnoughData) {
      // Weight: 60% guidelines, 40% history
      final historyWeight = 0.4;
      final guidelinesWeight = 0.6;
      sleepDuration = Duration(
        minutes: (schedule.nightSleepDuration.inMinutes * guidelinesWeight +
                history.avgNightSleep.inMinutes * historyWeight)
            .round(),
      );
    }

    // Adjust for late bedtime: if baby slept later than typical, they may need slightly less sleep
    // but we shouldn't let them sleep too late (creates cycle of late bedtimes)
    if (typicalBedtime != null) {
      final sleepTimeMinutes = sleepTime.hour * 60 + sleepTime.minute;
      final typicalMinutes = typicalBedtime.hour * 60 + typicalBedtime.minute;
      final lateness = sleepTimeMinutes - typicalMinutes;

      if (lateness > 30) {
        // Baby slept more than 30 min late
        // Reduce sleep duration slightly (max 45 min reduction) to help reset schedule
        final reduction = Duration(minutes: (lateness * 0.5).clamp(0, 45).round());
        sleepDuration -= reduction;

        // But ensure minimum sleep based on age
        final minSleep = Duration(hours: ageInMonths < 12 ? 9 : 10);
        if (sleepDuration < minSleep) {
          sleepDuration = minSleep;
        }
      }
    }

    return sleepTime.add(sleepDuration);
  }

  /// Calculate recommended nap end time based on nap start
  static DateTime calculateRecommendedNapEnd({
    required DateTime napStart,
    required int ageInMonths,
    required int napNumber, // 1-indexed
    required int totalNapsPlanned,
    DateTime? bedtimeTarget,
    SleepPattern? history,
  }) {
    final schedule = getScheduleForAge(ageInMonths);
    Duration napDuration = schedule.napDuration;

    // If we have historical data, consider it
    if (history != null && history.hasEnoughData) {
      final historyWeight = 0.3;
      final guidelinesWeight = 0.7;
      napDuration = Duration(
        minutes: (schedule.napDuration.inMinutes * guidelinesWeight +
                history.avgNapDuration.inMinutes * historyWeight)
            .round(),
      );
    }

    // Last nap of the day should be shorter to protect bedtime
    if (napNumber == totalNapsPlanned && totalNapsPlanned > 1) {
      napDuration = Duration(minutes: (napDuration.inMinutes * 0.75).round());
    }

    // If bedtime target is set, ensure nap doesn't end too close to bedtime
    if (bedtimeTarget != null) {
      final maxNapEnd = bedtimeTarget.subtract(schedule.lastWakeWindow);
      final proposedEnd = napStart.add(napDuration);

      if (proposedEnd.isAfter(maxNapEnd)) {
        // Shorten nap to protect bedtime
        napDuration = maxNapEnd.difference(napStart);
        if (napDuration < schedule.minNapDuration) {
          napDuration = schedule.minNapDuration;
        }
      }
    }

    // Clamp nap duration within reasonable bounds
    if (napDuration < schedule.minNapDuration) {
      napDuration = schedule.minNapDuration;
    }
    if (napDuration > schedule.maxNapDuration) {
      napDuration = schedule.maxNapDuration;
    }

    return napStart.add(napDuration);
  }

  /// Calculate next recommended nap start time
  static DateTime? calculateNextNapTime({
    required DateTime wakeUpTime,
    required int ageInMonths,
    required List<NapRecord> completedNaps,
    bool napSkipped = false,
    SleepPattern? history,
  }) {
    final schedule = getScheduleForAge(ageInMonths);

    // Check if we've had enough naps for the day
    if (completedNaps.length >= schedule.napsPerDay) {
      return null;
    }

    // Check if there's a nap in progress
    if (completedNaps.isNotEmpty && !completedNaps.last.isComplete) {
      return null;
    }

    // Find the last awake time
    DateTime lastAwakeTime = wakeUpTime;
    if (completedNaps.isNotEmpty && completedNaps.last.actualEndTime != null) {
      lastAwakeTime = completedNaps.last.actualEndTime!;
    }

    // Calculate base wake window
    Duration wakeWindow = schedule.wakeWindow;

    // If we have history, blend it
    if (history != null && history.hasEnoughData) {
      // Mild influence from history
      final historyWeight = 0.2;
      final guidelinesWeight = 0.8;
      // History doesn't directly store wake windows, so we keep guidelines dominant
      wakeWindow = Duration(
        minutes: (schedule.wakeWindow.inMinutes * guidelinesWeight +
                schedule.wakeWindow.inMinutes * historyWeight)
            .round(),
      );
    }

    // Adjust wake window based on previous nap quality
    if (completedNaps.isNotEmpty) {
      final lastNap = completedNaps.last;
      if (lastNap.isShort) {
        // Short nap = baby might get tired sooner, reduce wake window by 15-20%
        wakeWindow = Duration(minutes: (wakeWindow.inMinutes * 0.8).round());
      } else if (lastNap.isLong) {
        // Long nap = baby might tolerate longer wake window, increase by 10-15%
        wakeWindow = Duration(minutes: (wakeWindow.inMinutes * 1.15).round());
      }
    }

    // For later naps in the day, wake windows typically increase
    final napNumber = completedNaps.length + 1;
    if (napNumber > 1 && schedule.napsPerDay > 1) {
      // Each subsequent nap might have slightly longer wake window (5-10 min per nap)
      wakeWindow += Duration(minutes: 5 * (napNumber - 1));
    }

    return lastAwakeTime.add(wakeWindow);
  }

  /// Calculate recommended bedtime based on the day's events
  static DateTime calculateRecommendedBedtime({
    required DateTime wakeUpTime,
    required int ageInMonths,
    required List<NapRecord> naps,
    bool napSkipped = false,
    DateTime? typicalBedtime,
    SleepPattern? history,
  }) {
    final schedule = getScheduleForAge(ageInMonths);
    final now = DateTime.now();

    // Find the last awake time
    DateTime lastAwakeTime = wakeUpTime;
    if (naps.isNotEmpty) {
      final lastNap = naps.last;
      if (lastNap.actualEndTime != null) {
        lastAwakeTime = lastNap.actualEndTime!;
      } else {
        // Nap in progress - use recommended end time as estimate
        lastAwakeTime = lastNap.recommendedEndTime;
      }
    }

    // Start with the last wake window
    Duration wakeWindowBeforeBed = schedule.lastWakeWindow;

    // Adjust for nap quality and quantity
    int totalNapMinutes = 0;
    int shortNapCount = 0;
    int longNapCount = 0;

    for (final nap in naps) {
      if (nap.isComplete) {
        totalNapMinutes += nap.actualDuration.inMinutes;
        if (nap.isShort) shortNapCount++;
        if (nap.isLong) longNapCount++;
      }
    }

    // Fewer naps than expected = earlier bedtime
    final napDeficit = schedule.napsPerDay - naps.length;
    if (napDeficit > 0 || napSkipped) {
      // Each missed nap = 30-60 min earlier bedtime depending on age
      final adjustmentPerNap = ageInMonths < 12 ? 45 : 30;
      final totalMissed = napSkipped ? napDeficit + 1 : napDeficit;
      wakeWindowBeforeBed -= Duration(minutes: adjustmentPerNap * totalMissed);
    }

    // Short naps = earlier bedtime (baby is likely overtired)
    if (shortNapCount > 0) {
      wakeWindowBeforeBed -= Duration(minutes: 15 * shortNapCount);
    }

    // Long naps = can tolerate slightly later bedtime
    if (longNapCount > 0 && napDeficit <= 0) {
      wakeWindowBeforeBed += Duration(minutes: 15 * longNapCount);
    }

    // Late last nap = later bedtime (to maintain minimum wake window)
    if (naps.isNotEmpty && naps.last.isComplete) {
      final lastNapEnd = naps.last.actualEndTime!;
      final minWakeBeforeBed = Duration(hours: ageInMonths < 12 ? 2 : 3);

      // If last nap ended late, ensure minimum wake window
      final proposedBedtime = lastAwakeTime.add(wakeWindowBeforeBed);
      final timeSinceLastNap = proposedBedtime.difference(lastNapEnd);

      if (timeSinceLastNap < minWakeBeforeBed) {
        // Push bedtime later to maintain minimum wake window
        wakeWindowBeforeBed = minWakeBeforeBed;
      }
    }

    // Blend with historical patterns if available
    if (history != null && history.hasEnoughData) {
      // If baby typically goes to bed at a certain time, consider it
      final typicalBedMinutes = history.avgBedtime.inMinutes;
      final calculatedBedMinutes =
          lastAwakeTime.add(wakeWindowBeforeBed).hour * 60 +
              lastAwakeTime.add(wakeWindowBeforeBed).minute;

      // If calculated is very different from typical (>45 min), pull toward typical
      final diff = (calculatedBedMinutes - typicalBedMinutes).abs();
      if (diff > 45) {
        // Blend: 70% calculated, 30% typical
        final blendedMinutes =
            (calculatedBedMinutes * 0.7 + typicalBedMinutes * 0.3).round();
        final blendedBedtime = DateTime(
          now.year,
          now.month,
          now.day,
          blendedMinutes ~/ 60,
          blendedMinutes % 60,
        );
        return _clampBedtime(blendedBedtime, ageInMonths);
      }
    }

    // Ensure minimum wake window
    if (wakeWindowBeforeBed < const Duration(hours: 2)) {
      wakeWindowBeforeBed = const Duration(hours: 2);
    }

    final proposedBedtime = lastAwakeTime.add(wakeWindowBeforeBed);
    return _clampBedtime(proposedBedtime, ageInMonths);
  }

  /// Clamp bedtime within reasonable bounds for age
  static DateTime _clampBedtime(DateTime proposed, int ageInMonths) {
    final now = DateTime.now();

    // Define reasonable bedtime bounds by age
    int earliestHour, latestHour;

    if (ageInMonths < 6) {
      earliestHour = 18; // 6 PM
      latestHour = 21; // 9 PM (newborns can be more flexible)
    } else if (ageInMonths < 24) {
      earliestHour = 17; // 5:30 PM
      latestHour = 20; // 8:30 PM
    } else {
      earliestHour = 18; // 6 PM
      latestHour = 21; // 9 PM (toddlers)
    }

    final earliest = DateTime(now.year, now.month, now.day, earliestHour, 30);
    final latest = DateTime(now.year, now.month, now.day, latestHour, 30);

    if (proposed.isBefore(earliest)) return earliest;
    if (proposed.isAfter(latest)) return latest;
    return proposed;
  }

  /// Parse historical sleep data into a SleepPattern
  static SleepPattern? analyzeHistory(List<Map<String, dynamic>> historyRecords) {
    if (historyRecords.isEmpty) return null;

    int totalBedtimeMinutes = 0;
    int totalWakeTimeMinutes = 0;
    int totalNaps = 0;
    int totalNapMinutes = 0;
    int napRecordCount = 0;
    int validRecords = 0;

    for (final record in historyRecords) {
      final bedtime = record['bedtime'] as String?;
      final wakeTime = record['wake_time'] as String?;
      final naps = record['naps'];

      if (bedtime != null && wakeTime != null) {
        try {
          final bedParts = bedtime.split(':');
          final wakeParts = wakeTime.split(':');

          if (bedParts.length >= 2 && wakeParts.length >= 2) {
            final bedMinutes = int.parse(bedParts[0]) * 60 + int.parse(bedParts[1]);
            final wakeMinutes = int.parse(wakeParts[0]) * 60 + int.parse(wakeParts[1]);

            totalBedtimeMinutes += bedMinutes;
            totalWakeTimeMinutes += wakeMinutes;
            validRecords++;
          }
        } catch (e) {
          debugPrint('Error parsing sleep time: $e');
        }
      }

      if (naps != null && naps is List) {
        totalNaps += naps.length;
        for (final nap in naps) {
          if (nap is Map && nap['start'] != null && nap['end'] != null) {
            try {
              final startParts = (nap['start'] as String).split(':');
              final endParts = (nap['end'] as String).split(':');

              if (startParts.length >= 2 && endParts.length >= 2) {
                final startMinutes =
                    int.parse(startParts[0]) * 60 + int.parse(startParts[1]);
                final endMinutes =
                    int.parse(endParts[0]) * 60 + int.parse(endParts[1]);
                totalNapMinutes += endMinutes - startMinutes;
                napRecordCount++;
              }
            } catch (e) {
              debugPrint('Error parsing nap time: $e');
            }
          }
        }
      }
    }

    if (validRecords == 0) return null;

    // Calculate night sleep duration
    final avgBedMinutes = totalBedtimeMinutes ~/ validRecords;
    final avgWakeMinutes = totalWakeTimeMinutes ~/ validRecords;

    // Handle overnight calculation (bedtime PM, wake time AM)
    int nightSleepMinutes;
    if (avgWakeMinutes < avgBedMinutes) {
      // Crosses midnight: e.g., 20:00 to 07:00
      nightSleepMinutes = (24 * 60 - avgBedMinutes) + avgWakeMinutes;
    } else {
      // Same day (unusual but possible)
      nightSleepMinutes = avgWakeMinutes - avgBedMinutes;
    }

    return SleepPattern(
      avgBedtime: Duration(minutes: avgBedMinutes),
      avgWakeTime: Duration(minutes: avgWakeMinutes),
      avgNapsPerDay: validRecords > 0 ? totalNaps ~/ validRecords : 0,
      avgNapDuration: napRecordCount > 0
          ? Duration(minutes: totalNapMinutes ~/ napRecordCount)
          : const Duration(hours: 1, minutes: 30),
      avgNightSleep: Duration(minutes: nightSleepMinutes),
      dataPoints: validRecords,
    );
  }

  /// Get typical bedtime from history or default for age
  static DateTime getTypicalBedtime(int ageInMonths, SleepPattern? history) {
    final now = DateTime.now();

    if (history != null && history.hasEnoughData) {
      final minutes = history.avgBedtime.inMinutes;
      return DateTime(now.year, now.month, now.day, minutes ~/ 60, minutes % 60);
    }

    // Default typical bedtimes by age
    if (ageInMonths < 6) {
      return DateTime(now.year, now.month, now.day, 19, 30); // 7:30 PM
    } else if (ageInMonths < 24) {
      return DateTime(now.year, now.month, now.day, 19, 0); // 7:00 PM
    } else {
      return DateTime(now.year, now.month, now.day, 19, 30); // 7:30 PM
    }
  }
}
