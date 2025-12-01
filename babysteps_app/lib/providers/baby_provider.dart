import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:babysteps_app/models/baby.dart';
import 'package:babysteps_app/models/concern.dart';
import 'package:babysteps_app/services/notification_service.dart';
import 'package:babysteps_app/services/supabase_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class BabyProvider extends ChangeNotifier {
  final SupabaseService _supabaseService = SupabaseService();
  final _uuid = const Uuid();
  
  List<Baby> _babies = [];
  Baby? _selectedBaby;
  bool _isLoading = false;
  String? _error;
  String? _notificationPreference;

  List<Baby> get babies => _babies;
  Baby? get selectedBaby => _selectedBaby;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get notificationPreference => _notificationPreference;
  SupabaseService get supabaseService => _supabaseService;

  // Initialize provider and load babies from Supabase
  Future<void> initialize() async {
    _setLoading(true);
    try {
      await _loadBabies();
    } catch (e) {
      _setError('Failed to load babies: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Update entire baby record (e.g., to set gender/name/birthdate changes)
  Future<void> updateBabyRecord(Baby baby) async {
    _setLoading(true);
    try {
      await _supabaseService.updateBaby(baby);
      await _loadBabies();
    } catch (e) {
      _setError('Error updating baby: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // Delete a baby
  Future<void> deleteBaby(String babyId) async {
    _setLoading(true);
    try {
      await _supabaseService.deleteBaby(babyId);
      await _loadBabies();
      // If the deleted baby was selected, select another one
      if (_selectedBaby?.id == babyId) {
        _selectedBaby = _babies.isNotEmpty ? _babies.first : null;
      }
      notifyListeners();
    } catch (e) {
      _setError('Error deleting baby: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // Load babies from Supabase
  Future<void> _loadBabies() async {
    try {
      final babies = await _supabaseService.getBabies();
      _babies = babies;
      if (_babies.isNotEmpty && _selectedBaby == null) {
        _selectedBaby = _babies.first;
      }
      notifyListeners();
    } catch (e) {
      _setError('Error loading babies: $e');
    }
  }

  // Create a new baby
  Future<String> createBaby(Baby baby) async {
    _setLoading(true);
    try {
      await _supabaseService.createBaby(baby);
      await _loadBabies(); // Refresh the list of babies
      // Optionally, select the newly created baby
      if (_babies.any((b) => b.id == baby.id)) {
        _selectedBaby = _babies.firstWhere((b) => b.id == baby.id);
      } else if (_babies.isNotEmpty) {
        _selectedBaby = _babies.first;
      }
      notifyListeners();
      return baby.id;
    } catch (e) {
      _setError('Error creating baby: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // Select a baby
  void selectBaby(String babyId) {
    final baby = _babies.firstWhere((b) => b.id == babyId);
    _selectedBaby = baby;
    notifyListeners();
  }

  // Update baby measurements
  Future<void> updateMeasurements({
    required double weightKg,
    required double heightCm,
    double? headCircumferenceCm,
    double? chestCircumferenceCm,
  }) async {
    if (_selectedBaby == null) {
      _setError('No baby selected');
      return;
    }

    _setLoading(true);
    try {
      await _supabaseService.saveMeasurements(
        _selectedBaby!.id,
        weightKg: weightKg,
        heightCm: heightCm,
        headCircumferenceCm: headCircumferenceCm,
        chestCircumferenceCm: chestCircumferenceCm,
      );
      
      // Update local baby data
      _selectedBaby = _selectedBaby!.copyWith(
        weightKg: weightKg,
        heightCm: heightCm,
        headCircumferenceCm: headCircumferenceCm,
        chestCircumferenceCm: chestCircumferenceCm,
      );
      
      // Update the baby in the list
      final index = _babies.indexWhere((b) => b.id == _selectedBaby!.id);
      if (index != -1) {
        _babies[index] = _selectedBaby!;
      }
      
      notifyListeners();
    } catch (e) {
      _setError('Error updating measurements: $e');
    } finally {
      _setLoading(false);
    }
  }
  
  // Alias for updateMeasurements to match the method name used in onboarding screens
  Future<void> updateBabyMeasurements({
    required double weightKg,
    required double heightCm,
    double? headCircumferenceCm,
    double? chestCircumferenceCm,
  }) async {
    return updateMeasurements(
      weightKg: weightKg,
      heightCm: heightCm,
      headCircumferenceCm: headCircumferenceCm,
      chestCircumferenceCm: chestCircumferenceCm,
    );
  }

  // Save sleep schedule
  Future<void> saveSleepSchedule({
    required String bedtime,
    required String wakeTime,
    required List<Map<String, String>> naps,
  }) async {
    if (_selectedBaby == null) {
      _setError('No baby selected');
      return;
    }

    _setLoading(true);
    try {
      await _supabaseService.saveSleepSchedule(
        _selectedBaby!.id,
        bedtime: bedtime,
        wakeTime: wakeTime,
        naps: naps,
      );
      
      // Update local baby data
      _selectedBaby = _selectedBaby!.copyWith(
        bedtime: bedtime,
        wakeTime: wakeTime,
        naps: naps,
      );
      
      // Update the baby in the list
      final index = _babies.indexWhere((b) => b.id == _selectedBaby!.id);
      if (index != -1) {
        _babies[index] = _selectedBaby!;
      }
      
      notifyListeners();
    } catch (e) {
      _setError('Error saving sleep schedule: $e');
    } finally {
      _setLoading(false);
    }
  }
  
  // Alias for saveSleepSchedule to match the method name used in onboarding screens
  Future<void> updateBabySleepSchedule({
    required String bedtime,
    required String wakeTime,
    required List<Map<String, String>> naps,
  }) async {
    return saveSleepSchedule(
      bedtime: bedtime,
      wakeTime: wakeTime,
      naps: naps,
    );
  }

  // Save feeding preferences
  Future<void> saveFeedingPreferences({
    required String feedingMethod,
    required int feedingsPerDay,
    double? amountPerFeeding,
    int? feedingDuration,
  }) async {
    if (_selectedBaby == null) {
      _setError('No baby selected');
      return;
    }

    _setLoading(true);
    try {
      await _supabaseService.saveFeedingPreferences(
        _selectedBaby!.id,
        feedingMethod: feedingMethod,
        feedingsPerDay: feedingsPerDay,
        amountPerFeeding: amountPerFeeding,
        feedingDuration: feedingDuration,
      );
      
      // Update local baby data
      _selectedBaby = _selectedBaby!.copyWith(
        feedingMethod: feedingMethod,
        feedingsPerDay: feedingsPerDay,
        amountPerFeeding: amountPerFeeding,
        feedingDuration: feedingDuration,
      );
      
      // Update the baby in the list
      final index = _babies.indexWhere((b) => b.id == _selectedBaby!.id);
      if (index != -1) {
        _babies[index] = _selectedBaby!;
      }
      
      notifyListeners();
    } catch (e) {
      _setError('Error saving feeding preferences: $e');
    } finally {
      _setLoading(false);
    }
  }
  
  // Alias for saveFeedingPreferences to match the method name used in onboarding screens
  Future<void> updateBabyFeedingPreferences({
    required String feedingMethod,
    required int feedingsPerDay,
    double? amountPerFeeding,
    int? feedingDuration,
  }) async {
    return saveFeedingPreferences(
      feedingMethod: feedingMethod,
      feedingsPerDay: feedingsPerDay,
      amountPerFeeding: amountPerFeeding,
      feedingDuration: feedingDuration,
    );
  }

  // Save diaper preferences
  Future<void> updateBabyDiaperPreferences({
    required String babyId,
    int? wetDiapersPerDay,
    int? dirtyDiapersPerDay,
    String? stoolColor,
    String? diaperNotes,
  }) async {
    _setLoading(true);
    try {
      // Handle nullable types by providing default values for required parameters
      await _supabaseService.saveDiaperPreferences(
        babyId,
        wetDiapersPerDay: wetDiapersPerDay ?? 0,
        dirtyDiapersPerDay: dirtyDiapersPerDay ?? 0,
        stoolColor: stoolColor ?? 'Unknown',
        notes: diaperNotes,
      );
      
      // Find the baby in the list
      final index = _babies.indexWhere((b) => b.id == babyId);
      if (index != -1) {
        // Update the baby object
        _babies[index] = _babies[index].copyWith(
          // Add diaper preferences to the baby model if needed
        );
        
        // Update selected baby if it's the same
        if (_selectedBaby?.id == babyId) {
          _selectedBaby = _babies[index];
        }
      }
      
      notifyListeners();
    } catch (e) {
      _setError('Error updating diaper preferences: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // Save milestones for a specific baby
  Future<void> saveMilestonesForBaby(String babyId, List<String> completedMilestones) async {
    _setLoading(true);
    try {
      await _supabaseService.saveMilestones(babyId, completedMilestones);
      // Update local list
      final index = _babies.indexWhere((b) => b.id == babyId);
      if (index != -1) {
        _babies[index] = _babies[index].copyWith(completedMilestones: completedMilestones);
        // Keep selected baby in sync if matching
        if (_selectedBaby?.id == babyId) {
          _selectedBaby = _babies[index];
        }
      }
      notifyListeners();
    } catch (e) {
      _setError('Error saving milestones: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Back-compat: save milestones for the currently selected baby
  Future<void> saveMilestones(List<String> completedMilestones) async {
    if (_selectedBaby == null) {
      _setError('No baby selected');
      return;
    }
    await saveMilestonesForBaby(_selectedBaby!.id, completedMilestones);
  }

  // Add a milestone
  Future<void> addMilestone(String milestone) async {
    if (_selectedBaby == null) {
      _setError('No baby selected');
      return;
    }

    if (!_selectedBaby!.completedMilestones.contains(milestone)) {
      final updatedMilestones = List<String>.from(_selectedBaby!.completedMilestones)
        ..add(milestone);
      await saveMilestones(updatedMilestones);
    }
  }

  // Remove a milestone
  Future<void> removeMilestone(String milestone) async {
    if (_selectedBaby == null) {
      _setError('No baby selected');
      return;
    }

    if (_selectedBaby!.completedMilestones.contains(milestone)) {
      final updatedMilestones = List<String>.from(_selectedBaby!.completedMilestones)
        ..remove(milestone);
      await saveMilestones(updatedMilestones);
    }
  }

  // Create a concern
  Future<String> createConcern({
    required String babyId,
    required String text,
    required bool isResolved,
    required DateTime createdAt,
    DateTime? resolvedAt,
  }) async {
    _setLoading(true);
    try {
      final id = _uuid.v4();
      final concern = Concern(
        id: id,
        text: text,
        isResolved: isResolved,
        createdAt: createdAt,
        resolvedAt: resolvedAt,
      );
      
      await _supabaseService.createConcern(babyId, concern);
      return id;
    } catch (e) {
      _setError('Error creating concern: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // Get concerns
  Future<List<Concern>> getConcerns() async {
    if (_selectedBaby == null) {
      _setError('No baby selected');
      return [];
    }

    _setLoading(true);
    try {
      return await _supabaseService.getConcerns(_selectedBaby!.id);
    } catch (e) {
      _setError('Error getting concerns: $e');
      return [];
    } finally {
      _setLoading(false);
    }
  }

  Future<Map<String, dynamic>?> getOverallTrackingScore() async {
    if (_selectedBaby == null) {
      _setError('No baby selected');
      return null;
    }

    try {
      return await _supabaseService.getOverallTracking(_selectedBaby!.id);
    } catch (e) {
      _setError('Error fetching overall tracking: $e');
      return null;
    }
  }

  // Fetch overall tracking score for a specific baby
  Future<Map<String, dynamic>?> getOverallTrackingScoreForBaby(String babyId) async {
    try {
      return await _supabaseService.getOverallTracking(babyId);
    } catch (e) {
      _setError('Error fetching overall tracking: $e');
      return null;
    }
  }

  // Update a concern
  Future<void> updateConcern({
    required String concernId,
    required bool isResolved,
    DateTime? resolvedAt,
  }) async {
    if (_selectedBaby == null) {
      _setError('No baby selected');
      return;
    }

    _setLoading(true);
    try {
      final concern = Concern(
        id: concernId,
        text: '', // We only need the ID for updating resolution status
        isResolved: isResolved,
        createdAt: DateTime.now(), // This won't be used for update
        resolvedAt: resolvedAt,
      );
      
      await _supabaseService.updateConcern(_selectedBaby!.id, concern);
    } catch (e) {
      _setError('Error updating concern: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // Delete a concern
  Future<void> deleteConcern({required String concernId}) async {
    if (_selectedBaby == null) {
      _setError('No baby selected');
      return;
    }

    _setLoading(true);
    try {
      await _supabaseService.deleteConcern(_selectedBaby!.id, concernId);
    } catch (e) {
      _setError('Error deleting concern: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // Helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? errorMessage) {
    _error = errorMessage;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  String? _resolveReminderBabyName() {
    if (_selectedBaby != null) {
      final name = _selectedBaby!.name.trim();
      if (name.isNotEmpty) {
        return name;
      }
    }
    for (final baby in _babies) {
      final name = baby.name.trim();
      if (name.isNotEmpty) {
        return name;
      }
    }
    return null;
  }

  // Nurture priorities per baby
  Future<void> saveNurturePriorities({required String babyId, required List<String> priorities}) async {
    _setLoading(true);
    try {
      await _supabaseService.saveNurturePriorities(babyId, priorities);
    } catch (e) {
      _setError('Error saving nurture priorities: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<List<String>> getNurturePriorities({required String babyId}) async {
    _setLoading(true);
    try {
      return await _supabaseService.getNurturePriorities(babyId);
    } catch (e) {
      _setError('Error fetching nurture priorities: $e');
      return [];
    } finally {
      _setLoading(false);
    }
  }

  // Short-term focus per baby
  Future<void> saveShortTermFocus({required String babyId, required List<String> focus, DateTime? start, DateTime? end}) async {
    _setLoading(true);
    try {
      await _supabaseService.saveShortTermFocus(babyId, focus, start: start, end: end);
    } catch (e) {
      _setError('Error saving short-term focus: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<List<String>> getShortTermFocus({required String babyId}) async {
    _setLoading(true);
    try {
      return await _supabaseService.getShortTermFocus(babyId);
    } catch (e) {
      _setError('Error fetching short-term focus: $e');
      return [];
    } finally {
      _setLoading(false);
    }
  }

  // User-level preferences (global)
  Future<Map<String, dynamic>> getUserPreferences() async {
    _setLoading(true);
    try {
      final prefs = await _supabaseService.getUserPreferences();
      final notificationTime = prefs['notification_time'];
      if (notificationTime is String && notificationTime.isNotEmpty) {
        _notificationPreference = notificationTime;
        await NotificationService.instance.scheduleDailyReminder(
          preference: notificationTime,
          babyName: _resolveReminderBabyName(),
        );
      } else {
        _notificationPreference = null;
        await NotificationService.instance.cancelDailyReminder();
      }
      return prefs;
    } catch (e) {
      _setError('Error fetching user preferences: $e');
      return {'parenting_styles': <String>[], 'nurture_priorities': <String>[], 'goals': <String>[]};
    } finally {
      _setLoading(false);
    }
  }

  Future<void> saveUserParentingStyles(List<String> styles) async {
    _setLoading(true);
    try {
      await _supabaseService.saveUserParentingStyles(styles);
    } catch (e) {
      _setError('Error saving parenting styles: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> saveUserNurturePriorities(List<String> priorities) async {
    _setLoading(true);
    try {
      await _supabaseService.saveUserNurturePriorities(priorities);
    } catch (e) {
      _setError('Error saving nurture priorities: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> saveUserGoals(List<String> goals) async {
    _setLoading(true);
    try {
      await _supabaseService.saveUserGoals(goals);
    } catch (e) {
      _setError('Error saving goals: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> saveNotificationPreference(String time) async {
    _setLoading(true);
    try {
      await _supabaseService.saveNotificationPreference(time);
      _notificationPreference = time;
      await NotificationService.instance.scheduleDailyReminder(
        preference: time,
        babyName: _resolveReminderBabyName(),
      );
    } catch (e) {
      _setError('Error saving notification preference: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // Baby activities (loves/hates)
  Future<Map<String, List<String>>> getBabyActivities({required String babyId}) async {
    _setLoading(true);
    try {
      return await _supabaseService.getBabyActivities(babyId);
    } catch (e) {
      _setError('Error fetching baby activities: $e');
      return {'loves': <String>[], 'hates': <String>[]};
    } finally {
      _setLoading(false);
    }
  }

  Future<void> saveBabyActivities({required String babyId, required List<String> loves, required List<String> hates}) async {
    _setLoading(true);
    try {
      await _supabaseService.saveBabyActivities(babyId, loves: loves, hates: hates);
    } catch (e) {
      _setError('Error saving baby activities: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // New: fetch dated activity preferences (label, status, recorded_at)
  Future<List<Map<String, dynamic>>> getBabyActivityPreferences({required String babyId}) async {
    _setLoading(true);
    try {
      return await _supabaseService.getBabyActivityPreferences(babyId);
    } catch (e) {
      _setError('Error fetching activity preferences: $e');
      return <Map<String, dynamic>>[];
    } finally {
      _setLoading(false);
    }
  }

  // New: upsert dated activity preferences for loves/hates/neutral/skipped
  Future<void> upsertBabyActivityPreferences({
    required String babyId,
    required List<String> loves,
    required List<String> hates,
    List<String>? neutral,
    List<String>? skipped,
    DateTime? recordedAt,
  }) async {
    _setLoading(true);
    try {
      final now = recordedAt ?? DateTime.now();
      final entries = <Map<String, dynamic>>[
        ...loves.map((l) => {'label': l, 'status': 'love', 'recorded_at': now}),
        ...hates.map((h) => {'label': h, 'status': 'hate', 'recorded_at': now}),
        ...?neutral?.map((n) => {'label': n, 'status': 'neutral', 'recorded_at': now}),
        ...?skipped?.map((s) => {'label': s, 'status': 'skipped', 'recorded_at': now}),
      ];
      await _supabaseService.upsertBabyActivityPreferences(babyId, entries);
    } catch (e) {
      _setError('Error saving activity preferences: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // Home: log an activity suggestion result (dismiss, ok, meh, sad)
  Future<void> logActivityResult({
    required String title,
    required String result,
    DateTime? timestamp,
  }) async {
    if (_selectedBaby == null) {
      _setError('No baby selected');
      return;
    }
    _setLoading(true);
    try {
      await _supabaseService.logActivityResult(
        _selectedBaby!.id,
        title: title,
        result: result,
        timestamp: timestamp ?? DateTime.now(),
      );
    } catch (e) {
      _setError('Error logging activity: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // Tracking: upsert an achieved milestone (logs with optional date and source)
  Future<void> upsertAchievedMilestone({
    required String milestoneId,
    DateTime? achievedAt,
    String source = 'log',
  }) async {
    if (_selectedBaby == null) {
      _setError('No baby selected');
      return;
    }
    _setLoading(true);
    try {
      await _supabaseService.upsertBabyMilestone(
        babyId: _selectedBaby!.id,
        milestoneId: milestoneId,
        achievedAt: achievedAt,
        source: source,
      );
      // Optionally keep legacy JSONB in sync for back-compat if achievedAt provided
      if (achievedAt != null) {
        final current = List<String>.from(_selectedBaby!.completedMilestones);
        if (!current.contains(milestoneId)) {
          current.add(milestoneId);
          await saveMilestones(current);
        }
      }
    } catch (e) {
      _setError('Error logging milestone: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // Tracking: upsert an achieved milestone for a specific baby (used during onboarding)
  Future<void> upsertAchievedMilestoneForBaby({
    required String babyId,
    required String milestoneId,
    DateTime? achievedAt,
    String source = 'log',
  }) async {
    try {
      await _supabaseService.upsertBabyMilestone(
        babyId: babyId,
        milestoneId: milestoneId,
        achievedAt: achievedAt,
        source: source,
      );
    } catch (e) {
      // During onboarding milestone toggles we don't want to crash or
      // trigger ChangeNotifier assertions if persistence fails.
      // Log and continue; milestones are still reflected locally and
      // will be resynced on the main milestones screen.
      // ignore: avoid_print
      print('Error logging milestone for baby $babyId and milestone $milestoneId: $e');
    }
  }

  // Tracking: remove an achieved milestone for a specific baby (used during onboarding)
  Future<void> removeAchievedMilestoneForBaby({
    required String babyId,
    required String milestoneId,
  }) async {
    try {
      await _supabaseService.removeBabyMilestone(
        babyId: babyId,
        milestoneId: milestoneId,
      );
    } catch (e) {
      // Same rationale as above: avoid notifier churn while user is
      // toggling milestones in onboarding. Just log the error.
      // ignore: avoid_print
      print('Error removing milestone for baby $babyId and milestone $milestoneId: $e');
    }
  }

  // Tracking: fetch per-domain scores
  Future<List<Map<String, dynamic>>> getDomainTrackingScores() async {
    if (_selectedBaby == null) {
      throw Exception('No baby selected');
    }
    try {
      return await _supabaseService.getDomainScores(_selectedBaby!.id);
    } catch (e) {
      // Surface error to caller; dedicated UI handles messaging.
      throw Exception('Error fetching domain tracking: $e');
    }
  }

  // Tracking: fetch per-domain scores for a specific baby
  Future<List<Map<String, dynamic>>> getDomainTrackingScoresForBaby(String babyId) async {
    try {
      return await _supabaseService.getDomainScores(babyId);
    } catch (e) {
      throw Exception('Error fetching domain tracking: $e');
    }
  }

  // Tracking: fetch per-milestone assessments (excludes discounted onboarding by default)
  Future<List<Map<String, dynamic>>> getMilestoneAssessments({bool includeDiscounted = false}) async {
    if (_selectedBaby == null) {
      _setError('No baby selected');
      return [];
    }
    _setLoading(true);
    try {
      return await _supabaseService.getMilestoneAssessments(
        _selectedBaby!.id,
        includeDiscounted: includeDiscounted,
      );
    } catch (e) {
      _setError('Error fetching milestone assessments: $e');
      return [];
    } finally {
      _setLoading(false);
    }
  }

  // Tracking: fetch per-milestone assessments for a specific baby (used during onboarding)
  Future<List<Map<String, dynamic>>> getMilestoneAssessmentsForBaby(String babyId, {bool includeDiscounted = false}) async {
    try {
      return await _supabaseService.getMilestoneAssessments(
        babyId,
        includeDiscounted: includeDiscounted,
      );
    } catch (e) {
      _setError('Error fetching milestone assessments: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getBabyVocabulary({String? babyId}) async {
    final targetId = babyId ?? _selectedBaby?.id;
    if (targetId == null) {
      _setError('No baby selected');
      return [];
    }
    try {
      return await _supabaseService.getBabyVocabulary(targetId);
    } catch (e) {
      _setError('Error fetching baby vocabulary: $e');
      return [];
    }
  }

  Future<void> addBabyVocabularyWord(String word, {String? babyId, DateTime? recordedAt}) async {
    final targetId = babyId ?? _selectedBaby?.id;
    if (targetId == null) {
      _setError('No baby selected');
      return;
    }
    try {
      await _supabaseService.addBabyVocabularyWord(targetId, word, recordedAt: recordedAt);
    } catch (e) {
      _setError('Error adding vocabulary word: $e');
      rethrow;
    }
  }

  Future<void> deleteBabyVocabularyEntry(String entryId, {String? babyId}) async {
    final targetId = babyId ?? _selectedBaby?.id;
    if (targetId == null) {
      _setError('No baby selected');
      return;
    }
    try {
      await _supabaseService.deleteBabyVocabularyEntry(targetId, entryId);
    } catch (e) {
      _setError('Error deleting vocabulary word: $e');
      rethrow;
    }
  }

  // Milestone Moments: Upload photo to storage
  Future<String> uploadMilestonePhoto(String babyId, String fileName, List<int> bytes) async {
    try {
      return await _supabaseService.uploadMilestonePhoto(babyId, fileName, bytes);
    } catch (e) {
      _setError('Error uploading photo: $e');
      rethrow;
    }
  }

  // Milestone Moments: Save a new milestone moment
  Future<void> saveMilestoneMoment({
    required String babyId,
    required String title,
    required String description,
    required DateTime capturedAt,
    required int shareability,
    required int priority,
    required String location,
    String? shareContext,
    String? photoUrl,
    required List<String> stickers,
    required List<String> highlights,
    required List<Map<String, String>> delights,
    required bool isAnniversary,
  }) async {
    try {
      await _supabaseService.saveMilestoneMoment(
        babyId: babyId,
        title: title,
        description: description,
        capturedAt: capturedAt,
        shareability: shareability,
        priority: priority,
        location: location,
        shareContext: shareContext,
        photoUrl: photoUrl,
        stickers: stickers,
        highlights: highlights,
        delights: delights,
        isAnniversary: isAnniversary,
      );
    } catch (e) {
      _setError('Error saving milestone moment: $e');
      rethrow;
    }
  }

  // Milestone Moments: Get all milestone moments for a baby
  Future<List<dynamic>> getMilestoneMoments(String babyId) async {
    try {
      return await _supabaseService.getMilestoneMoments(babyId);
    } catch (e) {
      _setError('Error fetching milestone moments: $e');
      return [];
    }
  }

  // Milestone Moments: Delete a milestone moment
  Future<void> deleteMilestoneMoment(String momentId) async {
    try {
      await _supabaseService.deleteMilestoneMoment(momentId);
    } catch (e) {
      _setError('Error deleting milestone moment: $e');
      rethrow;
    }
  }

  // User Activity Tracking: Log an activity
  Future<void> logActivity(String activityType) async {
    try {
      await _supabaseService.logUserActivity(activityType);
    } catch (e) {
      // Silently fail - don't disrupt user experience
      print('Error logging activity: $e');
    }
  }

  // User Activity Tracking: Get current streak
  Future<int> getUserStreak() async {
    try {
      return await _supabaseService.getUserStreak();
    } catch (e) {
      _setError('Error getting user streak: $e');
      return 0;
    }
  }

  // Weekly Advice: fetch current plan (if any)
  Future<Map<String, dynamic>?> getWeeklyAdvicePlan() async {
    if (_selectedBaby == null) {
      _setError('No baby selected');
      return null;
    }
    try {
      return await _supabaseService.getWeeklyAdvice(_selectedBaby!.id);
    } catch (e) {
      _setError('Error fetching weekly advice: $e');
      return null;
    }
  }

  // Weekly Advice: generate or return cached plan via Edge Function
  Future<Map<String, dynamic>?> generateWeeklyAdvicePlan({bool forceRefresh = false}) async {
    if (_selectedBaby == null) {
      _setError('No baby selected');
      return null;
    }
    try {
      return await _supabaseService.generateWeeklyAdvice(_selectedBaby!.id, forceRefresh: forceRefresh);
    } catch (e) {
      _setError('Error generating weekly advice: $e');
      return null;
    }
  }

  // ============================================================
  // PENDING ONBOARDING DATA (stored locally during guest onboarding)
  // ============================================================

  static const String _pendingBabiesKey = 'pending_onboarding_babies';
  static const String _pendingPrefsKey = 'pending_onboarding_preferences';
  static const String _pendingActivitiesKey = 'pending_onboarding_activities';
  static const String _pendingShortTermFocusKey = 'pending_onboarding_short_term_focus';

  /// Store babies locally during onboarding (before account exists)
  Future<void> savePendingOnboardingBabies(List<Baby> babies) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = babies.map((b) => b.toJson()).toList();
      await prefs.setString(_pendingBabiesKey, jsonEncode(jsonList));
      // Also keep them in memory
      _babies = babies;
      if (_babies.isNotEmpty && _selectedBaby == null) {
        _selectedBaby = _babies.first;
      }
    } catch (e) {
      print('Error saving pending babies: $e');
    }
  }

  /// Retrieve pending babies stored locally
  Future<List<Baby>> getPendingOnboardingBabies() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_pendingBabiesKey);
      if (jsonStr == null || jsonStr.isEmpty) return [];
      final List<dynamic> jsonList = jsonDecode(jsonStr);
      return jsonList.map((j) => Baby.fromJson(j as Map<String, dynamic>)).toList();
    } catch (e) {
      print('Error retrieving pending babies: $e');
      return [];
    }
  }

  /// Store user preferences locally during onboarding
  Future<void> savePendingOnboardingPreferences(Map<String, dynamic> prefs) async {
    try {
      final sharedPrefs = await SharedPreferences.getInstance();
      // Merge with any existing pending prefs
      final existingStr = sharedPrefs.getString(_pendingPrefsKey);
      Map<String, dynamic> merged = {};
      if (existingStr != null && existingStr.isNotEmpty) {
        merged = Map<String, dynamic>.from(jsonDecode(existingStr));
      }
      merged.addAll(prefs);
      await sharedPrefs.setString(_pendingPrefsKey, jsonEncode(merged));
    } catch (e) {
      print('Error saving pending preferences: $e');
    }
  }

  /// Retrieve pending preferences stored locally
  Future<Map<String, dynamic>> getPendingOnboardingPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_pendingPrefsKey);
      if (jsonStr == null || jsonStr.isEmpty) return {};
      return Map<String, dynamic>.from(jsonDecode(jsonStr));
    } catch (e) {
      print('Error retrieving pending preferences: $e');
      return {};
    }
  }

  /// Store baby activities (loves/hates) locally during onboarding
  Future<void> savePendingBabyActivities(String babyId, List<String> loves, List<String> hates) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final existingStr = prefs.getString(_pendingActivitiesKey);
      Map<String, dynamic> all = {};
      if (existingStr != null && existingStr.isNotEmpty) {
        all = Map<String, dynamic>.from(jsonDecode(existingStr));
      }
      all[babyId] = {'loves': loves, 'hates': hates};
      await prefs.setString(_pendingActivitiesKey, jsonEncode(all));
    } catch (e) {
      print('Error saving pending activities: $e');
    }
  }

  /// Retrieve pending activities for a baby
  Future<Map<String, List<String>>> getPendingBabyActivities(String babyId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_pendingActivitiesKey);
      if (jsonStr == null || jsonStr.isEmpty) return {'loves': [], 'hates': []};
      final all = Map<String, dynamic>.from(jsonDecode(jsonStr));
      if (!all.containsKey(babyId)) return {'loves': [], 'hates': []};
      final babyActivities = all[babyId] as Map<String, dynamic>;
      return {
        'loves': List<String>.from(babyActivities['loves'] ?? []),
        'hates': List<String>.from(babyActivities['hates'] ?? []),
      };
    } catch (e) {
      print('Error retrieving pending activities: $e');
      return {'loves': [], 'hates': []};
    }
  }

  /// Store short-term focus locally during onboarding
  Future<void> savePendingShortTermFocus(String babyId, List<String> focus) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final existingStr = prefs.getString(_pendingShortTermFocusKey);
      Map<String, dynamic> all = {};
      if (existingStr != null && existingStr.isNotEmpty) {
        all = Map<String, dynamic>.from(jsonDecode(existingStr));
      }
      all[babyId] = focus;
      await prefs.setString(_pendingShortTermFocusKey, jsonEncode(all));
    } catch (e) {
      print('Error saving pending short-term focus: $e');
    }
  }

  /// Check if there is pending onboarding data
  Future<bool> hasPendingOnboardingData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final babiesStr = prefs.getString(_pendingBabiesKey);
      return babiesStr != null && babiesStr.isNotEmpty && babiesStr != '[]';
    } catch (e) {
      return false;
    }
  }

  /// Persist all pending onboarding data to Supabase (called after signup)
  Future<bool> persistPendingOnboardingData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // 1. Persist babies
      final pendingBabies = await getPendingOnboardingBabies();
      for (final baby in pendingBabies) {
        try {
          await _supabaseService.createBaby(baby);
        } catch (e) {
          print('Error persisting baby ${baby.name}: $e');
        }
      }
      
      // 2. Persist user preferences
      final pendingPrefs = await getPendingOnboardingPreferences();
      if (pendingPrefs.isNotEmpty) {
        try {
          // Notification time
          if (pendingPrefs['notification_time'] != null) {
            await _supabaseService.saveNotificationPreference(pendingPrefs['notification_time']);
          }
          // Parenting styles
          if (pendingPrefs['parenting_styles'] != null) {
            await _supabaseService.saveUserParentingStyles(
              List<String>.from(pendingPrefs['parenting_styles']),
            );
          }
          // Nurture priorities
          if (pendingPrefs['nurture_priorities'] != null) {
            await _supabaseService.saveUserNurturePriorities(
              List<String>.from(pendingPrefs['nurture_priorities']),
            );
          }
          // Goals
          if (pendingPrefs['goals'] != null) {
            await _supabaseService.saveUserGoals(
              List<String>.from(pendingPrefs['goals']),
            );
          }
          // Plan tier (mark onboarding as complete)
          if (pendingPrefs['plan_tier'] != null) {
            await _supabaseService.savePlanTier(pendingPrefs['plan_tier']);
          }
        } catch (e) {
          print('Error persisting preferences: $e');
        }
      }
      
      // 3. Persist baby activities
      final activitiesStr = prefs.getString(_pendingActivitiesKey);
      if (activitiesStr != null && activitiesStr.isNotEmpty) {
        try {
          final allActivities = Map<String, dynamic>.from(jsonDecode(activitiesStr));
          for (final entry in allActivities.entries) {
            final babyId = entry.key;
            final activities = entry.value as Map<String, dynamic>;
            await _supabaseService.saveBabyActivities(
              babyId,
              loves: List<String>.from(activities['loves'] ?? []),
              hates: List<String>.from(activities['hates'] ?? []),
            );
          }
        } catch (e) {
          print('Error persisting activities: $e');
        }
      }
      
      // 4. Persist short-term focus
      final focusStr = prefs.getString(_pendingShortTermFocusKey);
      if (focusStr != null && focusStr.isNotEmpty) {
        try {
          final allFocus = Map<String, dynamic>.from(jsonDecode(focusStr));
          for (final entry in allFocus.entries) {
            final babyId = entry.key;
            final focus = List<String>.from(entry.value);
            await _supabaseService.saveShortTermFocus(babyId, focus);
          }
        } catch (e) {
          print('Error persisting short-term focus: $e');
        }
      }
      
      // 5. Persist milestones for each baby
      for (final baby in pendingBabies) {
        if (baby.completedMilestones.isNotEmpty) {
          try {
            await _supabaseService.saveMilestones(baby.id, baby.completedMilestones);
            // Also save to baby_milestones table
            for (final milestoneId in baby.completedMilestones) {
              await _supabaseService.upsertBabyMilestone(
                babyId: baby.id,
                milestoneId: milestoneId,
                achievedAt: DateTime.now(),
                source: 'onboarding',
              );
            }
          } catch (e) {
            print('Error persisting milestones for baby ${baby.name}: $e');
          }
        }
      }
      
      // 6. Clear pending data
      await clearPendingOnboardingData();
      
      // 7. Reload babies from database
      await _loadBabies();
      
      return true;
    } catch (e) {
      print('Error persisting pending onboarding data: $e');
      return false;
    }
  }

  /// Clear all pending onboarding data from local storage
  Future<void> clearPendingOnboardingData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_pendingBabiesKey);
      await prefs.remove(_pendingPrefsKey);
      await prefs.remove(_pendingActivitiesKey);
      await prefs.remove(_pendingShortTermFocusKey);
    } catch (e) {
      print('Error clearing pending onboarding data: $e');
    }
  }
}
