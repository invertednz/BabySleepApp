import 'package:flutter/material.dart';
import 'package:babysteps_app/models/baby.dart';
import 'package:babysteps_app/models/concern.dart';
import 'package:babysteps_app/services/supabase_service.dart';
import 'package:uuid/uuid.dart';

class BabyProvider extends ChangeNotifier {
  final SupabaseService _supabaseService = SupabaseService();
  final _uuid = const Uuid();
  
  List<Baby> _babies = [];
  Baby? _selectedBaby;
  bool _isLoading = false;
  String? _error;

  List<Baby> get babies => _babies;
  Baby? get selectedBaby => _selectedBaby;
  bool get isLoading => _isLoading;
  String? get error => _error;

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

  // Save milestones
  Future<void> saveMilestones(List<String> completedMilestones) async {
    if (_selectedBaby == null) {
      _setError('No baby selected');
      return;
    }

    _setLoading(true);
    try {
      await _supabaseService.saveMilestones(
        _selectedBaby!.id,
        completedMilestones,
      );
      
      // Update local baby data
      _selectedBaby = _selectedBaby!.copyWith(
        completedMilestones: completedMilestones,
      );
      
      // Update the baby in the list
      final index = _babies.indexWhere((b) => b.id == _selectedBaby!.id);
      if (index != -1) {
        _babies[index] = _selectedBaby!;
      }
      
      notifyListeners();
    } catch (e) {
      _setError('Error saving milestones: $e');
    } finally {
      _setLoading(false);
    }
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
      return await _supabaseService.getUserPreferences();
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
}
