import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
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

  // Fetch dated activity preferences from baby_activities (four JSONB maps: label -> ISO timestamp)
  Future<List<Map<String, dynamic>>> getBabyActivityPreferences(String babyId) async {
    final userId = supabase.Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');
    final row = await _client
        .from('baby_activities')
        .select('loves, hates, neutral, skipped')
        .eq('user_id', userId)
        .eq('baby_id', babyId)
        .maybeSingle();
    if (row == null) return <Map<String, dynamic>>[];
    Map<String, dynamic> asMap(dynamic v) {
      if (v == null) return <String, dynamic>{};
      if (v is Map) return Map<String, dynamic>.from(v);
      if (v is List) {
        // legacy arrays; convert to map with null timestamps
        return { for (final e in v) (e as String): null };
      }
      return <String, dynamic>{};
    }
    final loves = asMap(row['loves']);
    final hates = asMap(row['hates']);
    final neutral = asMap(row['neutral']);
    final skipped = asMap(row['skipped']);
    List<Map<String, dynamic>> toEntries(Map<String, dynamic> m, String status) {
      return m.entries.map((e) => {
        'label': e.key,
        'status': status,
        'recorded_at': e.value is String && (e.value as String).isNotEmpty ? DateTime.tryParse(e.value as String) : null,
      }).toList();
    }
    return [
      ...toEntries(loves, 'love'),
      ...toEntries(hates, 'hate'),
      ...toEntries(neutral, 'neutral'),
      ...toEntries(skipped, 'skipped'),
    ];
  }

  // Upsert dated activity preferences into baby_activities JSONB maps
  Future<void> upsertBabyActivityPreferences(String babyId, List<Map<String, dynamic>> entries) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');
    if (entries.isEmpty) return;
    final existing = await _client
        .from('baby_activities')
        .select('loves, hates, neutral, skipped')
        .eq('user_id', userId)
        .eq('baby_id', babyId)
        .maybeSingle();
    Map<String, dynamic> asMap(dynamic v) {
      if (v == null) return <String, dynamic>{};
      if (v is Map) return Map<String, dynamic>.from(v);
      if (v is List) return { for (final e in v) (e as String): null };
      return <String, dynamic>{};
    }
    final loves = asMap(existing?['loves']);
    final hates = asMap(existing?['hates']);
    final neutral = asMap(existing?['neutral']);
    final skipped = asMap(existing?['skipped']);
    String ts(dynamic d) => (d is DateTime ? d : DateTime.now()).toIso8601String();
    for (final e in entries) {
      final label = (e['label'] as String).trim();
      if (label.isEmpty) continue;
      final status = (e['status'] as String).toLowerCase();
      final recordedAt = ts(e['recorded_at']);
      // remove from all first
      loves.remove(label); hates.remove(label); neutral.remove(label); skipped.remove(label);
      switch (status) {
        case 'love': loves[label] = recordedAt; break;
        case 'hate': hates[label] = recordedAt; break;
        case 'neutral': neutral[label] = recordedAt; break;
        case 'skipped': skipped[label] = recordedAt; break;
        default: break;
      }
    }
    await _client.from('baby_activities').upsert({
      'user_id': userId,
      'baby_id': babyId,
      'loves': loves,
      'hates': hates,
      'neutral': neutral,
      'skipped': skipped,
      'updated_at': DateTime.now().toIso8601String(),
    }, onConflict: 'user_id,baby_id');
  }

  // Home: log an activity suggestion result into baby_activities
  // Mapping: ok => love, sad => hate, meh => neutral, dismiss => skipped
  Future<void> logActivityResult(
    String babyId, {
    required String title,
    required String result,
    required DateTime timestamp,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    // Fetch current four-state maps
    final existing = await _client
        .from('baby_activities')
        .select('loves, hates, neutral, skipped, updated_at')
        .eq('user_id', userId)
        .eq('baby_id', babyId)
        .maybeSingle();
    Map<String, dynamic> asMap(dynamic v) {
      if (v == null) return <String, dynamic>{};
      if (v is Map) return Map<String, dynamic>.from(v);
      if (v is List) return { for (final e in v) (e as String): null };
      return <String, dynamic>{};
    }
    final loves = asMap(existing?['loves']);
    final hates = asMap(existing?['hates']);
    final neutral = asMap(existing?['neutral']);
    final skipped = asMap(existing?['skipped']);
    final ts = timestamp.toIso8601String();
    // Remove any previous state for this title
    loves.remove(title); hates.remove(title); neutral.remove(title); skipped.remove(title);
    switch (result) {
      case 'ok': loves[title] = ts; break;
      case 'sad': hates[title] = ts; break;
      case 'meh': neutral[title] = ts; break;
      case 'dismiss': skipped[title] = ts; break;
      default: break;
    }
    await _client.from('baby_activities').upsert({
      'user_id': userId,
      'baby_id': babyId,
      'loves': loves,
      'hates': hates,
      'neutral': neutral,
      'skipped': skipped,
      'updated_at': DateTime.now().toIso8601String(),
    }, onConflict: 'user_id,baby_id');
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

  Future<void> saveNotificationPreference(String time) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');
    await _client.from('user_preferences').upsert({
      'user_id': userId,
      'notification_time': time,
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  Future<void> updateUserPlanStatus({
    required String planTier,
    required bool isOnTrial,
    DateTime? planStartedAt,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');
    await _client.from('user_preferences').upsert({
      'user_id': userId,
      'plan_tier': planTier,
      'is_on_trial': isOnTrial,
      'plan_started_at': planStartedAt?.toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  // Baby activities (back-compat arrays derived from keys)
  Future<Map<String, List<String>>> getBabyActivities(String babyId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');
    final resp = await _client
        .from('baby_activities')
        .select('loves, hates, neutral, skipped, updated_at')
        .eq('user_id', userId)
        .eq('baby_id', babyId)
        .order('updated_at', ascending: false)
        .limit(1)
        .maybeSingle();
    List<String> asList(dynamic v) {
      if (v == null) return <String>[];
      if (v is List) return List<String>.from(v);
      if (v is Map) return List<String>.from(v.keys);
      return <String>[];
    }
    final loves = resp != null ? asList(resp['loves']) : <String>[];
    final hates = resp != null ? asList(resp['hates']) : <String>[];
    // Neutral/skipped are returned for future use if needed
    return {'loves': loves, 'hates': hates};
  }

  Future<void> saveBabyActivities(String babyId, {required List<String> loves, required List<String> hates}) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');
    final nowIso = DateTime.now().toIso8601String();
    // Store as maps with timestamps for consistency
    final lovesMap = { for (final l in loves) l: nowIso };
    final hatesMap = { for (final h in hates) h: nowIso };
    await _client.from('baby_activities').upsert({
      'user_id': userId,
      'baby_id': babyId,
      'loves': lovesMap,
      'hates': hatesMap,
      'updated_at': nowIso,
    }, onConflict: 'user_id,baby_id');
  }
  
  SupabaseService._internal();

  final supabase.SupabaseClient _client = supabase.Supabase.instance.client;
  final _uuid = const Uuid();
  
  supabase.SupabaseClient get client => _client;
  
  // Authentication methods
  Future<supabase.AuthResponse> signUp({required String email, required String password}) async {
    return await _client.auth.signUp(
      email: email,
      password: password,
    );
  }

  Future<supabase.AuthResponse> signIn({required String email, required String password}) async {
    return await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<bool> signInWithGoogle({String? redirectUrl}) {
    return _client.auth.signInWithOAuth(
      supabase.Provider.google,
      redirectTo: redirectUrl,
    );
  }

  Future<bool> signInWithApple({String? redirectUrl}) {
    return _client.auth.signInWithOAuth(
      supabase.Provider.apple,
      redirectTo: redirectUrl,
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
      'gender': (baby.gender == null || (baby.gender is String && (baby.gender as String).isEmpty)) ? 'Unknown' : baby.gender,
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

  Future<void> deleteBaby(String babyId) async {
    final userId = _client.auth.currentUser?.id;
    
    if (userId == null) {
      throw Exception('User not authenticated');
    }
    
    await _client
        .from('babies')
        .delete()
        .eq('id', babyId)
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

  Future<void> saveMeasurements(
    String babyId, {
    required double weightKg,
    required double heightCm,
    double? headCircumferenceCm,
    double? chestCircumferenceCm,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    // Upsert measurement history entry if table exists; fail silently if not.
    try {
      await _client.from('measurements').insert({
        'id': _uuid.v4(),
        'baby_id': babyId,
        'user_id': userId,
        'weight_kg': weightKg,
        'height_cm': heightCm,
        'head_circumference_cm': headCircumferenceCm,
        'chest_circumference_cm': chestCircumferenceCm,
        'recorded_at': DateTime.now().toIso8601String(),
      });
    } catch (_) {
      // Table may not exist in early schema; ignore errors for compatibility.
    }

    final updateData = <String, dynamic>{
      'weight_kg': weightKg,
      'height_cm': heightCm,
      'head_circumference_cm': headCircumferenceCm,
      'chest_circumference_cm': chestCircumferenceCm,
      'updated_at': DateTime.now().toIso8601String(),
    }..removeWhere((key, value) => value == null);

    await _client
        .from('babies')
        .update(updateData)
        .eq('id', babyId)
        .eq('user_id', userId);
  }

  Future<List<Map<String, dynamic>>> getBabyVocabulary(String babyId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');
    final response = await _client
        .from('baby_vocabulary')
        .select('id, word, recorded_at, created_at')
        .eq('user_id', userId)
        .eq('baby_id', babyId)
        .order('recorded_at', ascending: false)
        .order('created_at', ascending: false);
    if (response is List) {
      return response.map<Map<String, dynamic>>((row) => Map<String, dynamic>.from(row as Map)).toList();
    }
    return <Map<String, dynamic>>[];
  }

  Future<void> addBabyVocabularyWord(String babyId, String word, {DateTime? recordedAt}) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');
    final trimmed = word.trim();
    if (trimmed.isEmpty) return;
    await _client.from('baby_vocabulary').insert({
      'user_id': userId,
      'baby_id': babyId,
      'word': trimmed,
      if (recordedAt != null) 'recorded_at': recordedAt.toIso8601String(),
    });
  }

  Future<void> deleteBabyVocabularyEntry(String babyId, String entryId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');
    await _client
        .from('baby_vocabulary')
        .delete()
        .eq('id', entryId)
        .eq('baby_id', babyId)
        .eq('user_id', userId);
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

  // Tracking scores and milestones (new)
  // Upsert a baby milestone achievement with optional achievedAt and source.
  // Default source is 'log'. The DB layer will discount onboarding-only entries
  // outside window from percentile calculations via the view logic.
  Future<void> upsertBabyMilestone({
    required String babyId,
    required String milestoneId,
    DateTime? achievedAt,
    String source = 'log',
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');
    await _client
        .from('baby_milestones')
        .upsert({
          'baby_id': babyId,
          'milestone_id': milestoneId,
          'achieved_at': achievedAt?.toIso8601String(),
          'source': source,
        }, onConflict: 'baby_id,milestone_id');
  }

  // Remove a baby milestone achievement (used when unchecking during onboarding)
  Future<void> removeBabyMilestone({
    required String babyId,
    required String milestoneId,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');
    await _client
        .from('baby_milestones')
        .delete()
        .eq('baby_id', babyId)
        .eq('milestone_id', milestoneId);
  }

  // Fetch overall tracking score (overall_percentile and domains JSON)
  Future<Map<String, dynamic>?> getOverallTracking(String babyId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');
    final resp = await _client
        .from('v_baby_overall_score')
        .select()
        .eq('baby_id', babyId)
        .maybeSingle();
    return resp;
  }

  // Fetch per-domain scores with coverage and confidence
  Future<List<Map<String, dynamic>>> getDomainScores(String babyId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');
    final resp = await _client
        .from('v_baby_domain_scores')
        .select()
        .eq('baby_id', babyId);
    return (resp as List).map((e) => Map<String, dynamic>.from(e)).toList();
  }

  // Fetch per-milestone assessments. By default exclude discounted onboarding-only items.
  Future<List<Map<String, dynamic>>> getMilestoneAssessments(String babyId, {bool includeDiscounted = false}) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');
    var query = _client
        .from('v_baby_milestone_assessment')
        .select()
        .eq('baby_id', babyId);
    if (!includeDiscounted) {
      query = query.neq('status', 'discounted');
    }
    final resp = await query;
    return (resp as List).map((e) => Map<String, dynamic>.from(e)).toList();
  }

  // Milestone Moments: Upload photo to Supabase Storage
  Future<String> uploadMilestonePhoto(String babyId, String fileName, List<int> bytes) async {
    try {
      final path = 'milestone_photos/$babyId/$fileName';
      final uint8List = Uint8List.fromList(bytes);
      await _client.storage.from('baby-photos').uploadBinary(path, uint8List);
      final publicUrl = _client.storage.from('baby-photos').getPublicUrl(path);
      return publicUrl;
    } catch (e) {
      throw Exception('Failed to upload photo: $e');
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
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    try {
      await _client.from('milestone_moments').insert({
        'baby_id': babyId,
        'user_id': userId,
        'title': title,
        'description': description,
        'captured_at': capturedAt.toIso8601String(),
        'shareability': shareability,
        'priority': priority,
        'location': location,
        'share_context': shareContext,
        'photo_url': photoUrl,
        'stickers': stickers,
        'highlights': highlights,
        'delights': delights,
        'is_anniversary': isAnniversary,
      });
    } catch (e) {
      throw Exception('Failed to save milestone moment: $e');
    }
  }

  // Milestone Moments: Get all milestone moments for a baby
  Future<List<Map<String, dynamic>>> getMilestoneMoments(String babyId) async {
    try {
      final response = await _client
          .from('milestone_moments')
          .select()
          .eq('baby_id', babyId)
          .order('captured_at', ascending: false);
      
      return (response as List).map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (e) {
      throw Exception('Failed to fetch milestone moments: $e');
    }
  }

  // Milestone Moments: Delete a milestone moment
  Future<void> deleteMilestoneMoment(String momentId) async {
    try {
      await _client.from('milestone_moments').delete().eq('id', momentId);
    } catch (e) {
      throw Exception('Failed to delete milestone moment: $e');
    }
  }

  // User Activity Tracking: Log an activity
  Future<void> logUserActivity(String activityType) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    try {
      final today = DateTime.now().toIso8601String().split('T')[0];
      
      // Get today's activity log
      final existing = await _client
          .from('user_activity_log')
          .select()
          .eq('user_id', userId)
          .eq('activity_date', today)
          .maybeSingle();

      if (existing == null) {
        // Create new entry
        await _client.from('user_activity_log').insert({
          'user_id': userId,
          'activity_date': today,
          'activity_types': [activityType],
        });
      } else {
        // Update existing entry
        final List<dynamic> types = existing['activity_types'] ?? [];
        if (!types.contains(activityType)) {
          types.add(activityType);
          await _client
              .from('user_activity_log')
              .update({
                'activity_types': types,
                'updated_at': DateTime.now().toIso8601String(),
              })
              .eq('id', existing['id']);
        }
      }
    } catch (e) {
      // Silently fail - don't disrupt user experience
      print('Failed to log activity: $e');
    }
  }

  // User Activity Tracking: Get current streak
  Future<int> getUserStreak() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return 0;

    try {
      final logs = await _client
          .from('user_activity_log')
          .select()
          .eq('user_id', userId)
          .order('activity_date', ascending: false)
          .limit(365); // Check up to a year

      if (logs.isEmpty) return 0;

      final List<Map<String, dynamic>> activities = 
          (logs as List).map((e) => Map<String, dynamic>.from(e)).toList();

      int streak = 0;
      DateTime checkDate = DateTime.now();

      for (final activity in activities) {
        final activityDate = DateTime.parse(activity['activity_date']);
        final daysDiff = checkDate.difference(activityDate).inDays;

        if (daysDiff == streak) {
          streak++;
          checkDate = activityDate;
        } else if (daysDiff > streak) {
          break;
        }
      }

      return streak;
    } catch (e) {
      print('Failed to get user streak: $e');
      return 0;
    }
  }

  // Weekly Advice: fetch current plan from table
  Future<Map<String, dynamic>?> getWeeklyAdvice(String babyId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');
    final resp = await _client
        .from('baby_weekly_advice')
        .select('plan, valid_from, valid_to, model_version, generated_at')
        .eq('baby_id', babyId)
        .maybeSingle();
    if (resp == null) return null;
    return Map<String, dynamic>.from(resp as Map);
  }

  // Weekly Advice: invoke Edge Function to generate or return cached plan
  Future<Map<String, dynamic>?> generateWeeklyAdvice(String babyId, {bool forceRefresh = false}) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');
    final res = await _client.functions.invoke('generate_weekly_advice', body: {
      'baby_id': babyId,
      'force_refresh': forceRefresh,
    });
    if (res.data == null) return null;
    if (res.data is Map<String, dynamic>) {
      return Map<String, dynamic>.from(res.data as Map);
    }
    // Fallback: wrap non-map response
    return {'plan': res.data};
  }
}
