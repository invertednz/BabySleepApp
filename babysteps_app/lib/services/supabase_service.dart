import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:babysteps_app/config/supabase_config.dart';
import 'package:babysteps_app/models/baby.dart';
import 'package:babysteps_app/models/concern.dart';
import 'package:babysteps_app/models/milestone.dart';
import 'package:uuid/uuid.dart';

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  
  factory SupabaseService() {
    return _instance;
  }

  // Nurture Priorities (per-baby)
  Future<void> saveNurturePriorities(String babyId, List<String> priorities) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');
    await _client.from('baby_nurture_priorities').upsert({
      'baby_id': babyId,
      'user_id': userId,
      'priorities': priorities,
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  Future<List<String>> getNurturePriorities(String babyId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');
    final resp = await _client
        .from('baby_nurture_priorities')
        .select('priorities')
        .eq('baby_id', babyId)
        .eq('user_id', userId)
        .maybeSingle();
    if (resp == null || resp['priorities'] == null) return [];
    return List<String>.from(resp['priorities']);
  }

  // Short-Term Focus (per-baby)
  Future<void> saveShortTermFocus(String babyId, List<String> focus, {DateTime? start, DateTime? end}) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');
    await _client.from('baby_short_term_focus').upsert({
      'baby_id': babyId,
      'user_id': userId,
      'focus': focus,
      'timeframe_start': start?.toIso8601String(),
      'timeframe_end': end?.toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  Future<List<String>> getShortTermFocus(String babyId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');
    final resp = await _client
        .from('baby_short_term_focus')
        .select('focus')
        .eq('baby_id', babyId)
        .eq('user_id', userId)
        .maybeSingle();
    if (resp == null || resp['focus'] == null) return [];
    return List<String>.from(resp['focus']);
  }
  
  // User-level preferences (global)
  Future<Map<String, dynamic>> getUserPreferences() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');
    final resp = await _client
        .from('user_preferences')
        .select()
        .eq('user_id', userId)
        .maybeSingle();
    return resp ?? <String, dynamic>{
      'user_id': userId,
      'parenting_styles': <String>[],
      'nurture_priorities': <String>[],
      'goals': <String>[],
    };
  }

  Future<void> saveUserParentingStyles(List<String> styles) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');
    await _client.from('user_preferences').upsert({
      'user_id': userId,
      'parenting_styles': styles,
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  Future<void> saveUserNurturePriorities(List<String> priorities) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');
    await _client.from('user_preferences').upsert({
      'user_id': userId,
      'nurture_priorities': priorities,
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  Future<void> saveUserGoals(List<String> goals) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');
    await _client.from('user_preferences').upsert({
      'user_id': userId,
      'goals': goals,
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  // Baby activities (loves/hates)
  Future<Map<String, List<String>>> getBabyActivities(String babyId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');
    final resp = await _client
        .from('baby_activities')
        .select('loves, hates')
        .eq('user_id', userId)
        .eq('baby_id', babyId)
        .maybeSingle();
    final loves = resp != null && resp['loves'] != null ? List<String>.from(resp['loves']) : <String>[];
    final hates = resp != null && resp['hates'] != null ? List<String>.from(resp['hates']) : <String>[];
    return {'loves': loves, 'hates': hates};
  }

  Future<void> saveBabyActivities(String babyId, {required List<String> loves, required List<String> hates}) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');
    await _client.from('baby_activities').upsert({
      'user_id': userId,
      'baby_id': babyId,
      'loves': loves,
      'hates': hates,
      'updated_at': DateTime.now().toIso8601String(),
    });
  }
  
  SupabaseService._internal();

  final SupabaseClient _client = Supabase.instance.client;
  final _uuid = const Uuid();
  
  SupabaseClient get client => _client;
  
  // Authentication methods
  Future<AuthResponse> signUp({required String email, required String password}) async {
    return await _client.auth.signUp(
      email: email,
      password: password,
    );
  }
  
  Future<AuthResponse> signIn({required String email, required String password}) async {
    return await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }
  
  Future<void> signOut() async {
    await _client.auth.signOut();
  }
  
  // Baby methods
  Future<String> createBaby(Baby baby) async {
    // Use provided baby.id if present to keep IDs consistent across onboarding
    final String id = baby.id.isNotEmpty ? baby.id : _uuid.v4();
    final userId = _client.auth.currentUser?.id;
    
    if (userId == null) {
      throw Exception('User not authenticated');
    }
    
    final babyData = {
      'id': id,
      'user_id': userId,
      'name': baby.name,
      'birthdate': baby.birthdate.toIso8601String(),
      'gender': baby.gender,
      'weight_kg': baby.weightKg,
      'height_cm': baby.heightCm,
      'head_circumference_cm': baby.headCircumferenceCm,
      'chest_circumference_cm': baby.chestCircumferenceCm,
      'completed_milestones': baby.completedMilestones,
      'created_at': DateTime.now().toIso8601String(),
    };
    
    await _client.from('babies').insert(babyData);
    return id;
  }
  
  Future<List<Baby>> getBabies() async {
    final userId = _client.auth.currentUser?.id;
    
    if (userId == null) {
      throw Exception('User not authenticated');
    }
    
    final response = await _client
        .from('babies')
        .select()
        .eq('user_id', userId)
        .order('created_at');
    
    return (response as List).map((data) => Baby.fromJson(data)).toList();
  }
  
  Future<void> updateBaby(Baby baby) async {
    final userId = _client.auth.currentUser?.id;
    
    if (userId == null) {
      throw Exception('User not authenticated');
    }
    
    final babyData = {
      'name': baby.name,
      'birthdate': baby.birthdate.toIso8601String(),
      'gender': baby.gender,
      'weight_kg': baby.weightKg,
      'height_cm': baby.heightCm,
      'head_circumference_cm': baby.headCircumferenceCm,
      'chest_circumference_cm': baby.chestCircumferenceCm,
      'completed_milestones': baby.completedMilestones,
      'updated_at': DateTime.now().toIso8601String(),
    };
    
    await _client
        .from('babies')
        .update(babyData)
        .eq('id', baby.id)
        .eq('user_id', userId);
  }
  
  // Milestone methods
  Future<void> saveMilestones(String babyId, List<String> completedMilestones) async {
    final userId = _client.auth.currentUser?.id;
    
    if (userId == null) {
      throw Exception('User not authenticated');
    }
    
    await _client
        .from('babies')
        .update({'completed_milestones': completedMilestones})
        .eq('id', babyId)
        .eq('user_id', userId);
  }
  
  // Measurement methods
  Future<void> saveMeasurements(String babyId, {
    double? weightKg,
    double? heightCm,
    double? headCircumferenceCm,
    double? chestCircumferenceCm,
  }) async {
    final userId = _client.auth.currentUser?.id;
    
    if (userId == null) {
      throw Exception('User not authenticated');
    }
    
    final measurementData = {
      'id': _uuid.v4(),
      'baby_id': babyId,
      'user_id': userId,
      'weight_kg': weightKg,
      'height_cm': heightCm,
      'head_circumference_cm': headCircumferenceCm,
      'chest_circumference_cm': chestCircumferenceCm,
      'date': DateTime.now().toIso8601String(),
    };
    
    await _client.from('measurements').insert(measurementData);
    
    // Update the latest measurements in the baby record
    final updateData = {};
    if (weightKg != null) updateData['weight_kg'] = weightKg;
    if (heightCm != null) updateData['height_cm'] = heightCm;
    if (headCircumferenceCm != null) updateData['head_circumference_cm'] = headCircumferenceCm;
    if (chestCircumferenceCm != null) updateData['chest_circumference_cm'] = chestCircumferenceCm;
    
    if (updateData.isNotEmpty) {
      await _client
          .from('babies')
          .update(updateData)
          .eq('id', babyId)
          .eq('user_id', userId);
    }
  }
  
  // Sleep methods
  Future<void> saveSleepSchedule(String babyId, {
    required String bedtime,
    required String wakeTime,
    required List<Map<String, String>> naps,
  }) async {
    final userId = _client.auth.currentUser?.id;
    
    if (userId == null) {
      throw Exception('User not authenticated');
    }
    
    final sleepData = {
      'id': _uuid.v4(),
      'baby_id': babyId,
      'user_id': userId,
      'bedtime': bedtime,
      'wake_time': wakeTime,
      'naps': naps,
      'date': DateTime.now().toIso8601String(),
    };
    
    await _client.from('sleep_schedules').insert(sleepData);
  }
  
  // Feeding methods
  Future<void> saveFeedingPreferences(String babyId, {
    required String feedingMethod,
    required int feedingsPerDay,
    double? amountPerFeeding,
    int? feedingDuration,
  }) async {
    final userId = _client.auth.currentUser?.id;
    
    if (userId == null) {
      throw Exception('User not authenticated');
    }
    
    final feedingData = {
      'id': _uuid.v4(),
      'baby_id': babyId,
      'user_id': userId,
      'feeding_method': feedingMethod,
      'feedings_per_day': feedingsPerDay,
      'amount_per_feeding': amountPerFeeding,
      'feeding_duration': feedingDuration,
      'date': DateTime.now().toIso8601String(),
    };
    
    await _client.from('feeding_preferences').insert(feedingData);
  }
  
  // Diaper methods
  Future<void> saveDiaperPreferences(String babyId, {
    required int wetDiapersPerDay,
    required int dirtyDiapersPerDay,
    required String stoolColor,
    String? notes,
  }) async {
    final userId = _client.auth.currentUser?.id;
    
    if (userId == null) {
      throw Exception('User not authenticated');
    }
    
    final diaperData = {
      'id': _uuid.v4(),
      'baby_id': babyId,
      'user_id': userId,
      'wet_diapers_per_day': wetDiapersPerDay,
      'dirty_diapers_per_day': dirtyDiapersPerDay,
      'stool_color': stoolColor,
      'notes': notes,
      'date': DateTime.now().toIso8601String(),
    };
    
    await _client.from('diaper_preferences').insert(diaperData);
  }
  
  // Concern methods
  Future<String> createConcern(String babyId, Concern concern) async {
    final userId = _client.auth.currentUser?.id;
    
    if (userId == null) {
      throw Exception('User not authenticated');
    }
    
    final concernData = {
      'id': concern.id,
      'baby_id': babyId,
      'user_id': userId,
      'text': concern.text,
      'is_resolved': concern.isResolved,
      'created_at': concern.createdAt.toIso8601String(),
      'resolved_at': concern.resolvedAt?.toIso8601String(),
    };
    
    await _client.from('concerns').insert(concernData);
    return concern.id;
  }
  
  Future<List<Concern>> getConcerns(String babyId) async {
    final userId = _client.auth.currentUser?.id;
    
    if (userId == null) {
      throw Exception('User not authenticated');
    }
    
    final response = await _client
        .from('concerns')
        .select()
        .eq('baby_id', babyId)
        .eq('user_id', userId)
        .order('created_at');
    
    return (response as List).map((data) {
      return Concern(
        id: data['id'],
        text: data['text'],
        isResolved: data['is_resolved'],
        createdAt: DateTime.parse(data['created_at']),
        resolvedAt: data['resolved_at'] != null ? DateTime.parse(data['resolved_at']) : null,
      );
    }).toList();
  }
  
  Future<void> updateConcern(String babyId, Concern concern) async {
    final userId = _client.auth.currentUser?.id;
    
    if (userId == null) {
      throw Exception('User not authenticated');
    }
    
    final concernData = {
      'text': concern.text,
      'is_resolved': concern.isResolved,
      'resolved_at': concern.resolvedAt?.toIso8601String(),
    };
    
    await _client
        .from('concerns')
        .update(concernData)
        .eq('id', concern.id)
        .eq('baby_id', babyId)
        .eq('user_id', userId);
  }
  
  Future<void> deleteConcern(String babyId, String concernId) async {
    final userId = _client.auth.currentUser?.id;
    
    if (userId == null) {
      throw Exception('User not authenticated');
    }
    
    await _client
        .from('concerns')
        .delete()
        .eq('id', concernId)
        .eq('baby_id', babyId)
        .eq('user_id', userId);
  }

  // Milestone methods
  Future<List<Milestone>> getMilestones() async {
    final response = await _client
        .from('milestones')
        .select('*, milestone_activities(*)');

    return (response as List).map((data) => Milestone.fromJson(data)).toList();
  }
}
