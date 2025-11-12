import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/activity_log.dart';

class ActivityService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final String _collection = 'activity_logs';

  // Log a new activity
  Future<String?> logActivity(ActivityLog activity) async {
    try {
      final docRef = await _firestore.collection(_collection).add(activity.toJson());
      return docRef.id;
    } catch (e) {
      print('Error logging activity: $e');
      return null;
    }
  }

  // Get activities for a baby
  Future<List<ActivityLog>> getActivitiesForBaby(
    String babyId, {
    int? limitCount,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      Query query = _firestore
          .collection(_collection)
          .where('baby_id', isEqualTo: babyId)
          .orderBy('completed_at', descending: true);

      if (startDate != null) {
        query = query.where('completed_at', isGreaterThanOrEqualTo: startDate);
      }

      if (endDate != null) {
        query = query.where('completed_at', isLessThanOrEqualTo: endDate);
      }

      if (limitCount != null) {
        query = query.limit(limitCount);
      }

      final snapshot = await query.get();

      return snapshot.docs
          .map((doc) => ActivityLog.fromJson({...doc.data() as Map<String, dynamic>, 'id': doc.id}))
          .toList();
    } catch (e) {
      print('Error fetching activities for baby $babyId: $e');
      return [];
    }
  }

  // Get activities by category
  Future<List<ActivityLog>> getActivitiesByCategory(
    String babyId,
    String category,
  ) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('baby_id', isEqualTo: babyId)
          .where('activity_category', isEqualTo: category)
          .orderBy('completed_at', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => ActivityLog.fromJson({...doc.data(), 'id': doc.id}))
          .toList();
    } catch (e) {
      print('Error fetching activities by category: $e');
      return [];
    }
  }

  // Get activity count for date range
  Future<int> getActivityCount(
    String babyId, {
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('baby_id', isEqualTo: babyId)
          .where('completed_at', isGreaterThanOrEqualTo: startDate)
          .where('completed_at', isLessThanOrEqualTo: endDate)
          .get();

      return snapshot.docs.length;
    } catch (e) {
      print('Error getting activity count: $e');
      return 0;
    }
  }

  // Stream activities for real-time updates
  Stream<List<ActivityLog>> streamActivities(String babyId, {int? limit}) {
    Query query = _firestore
        .collection(_collection)
        .where('baby_id', isEqualTo: babyId)
        .orderBy('completed_at', descending: true);

    if (limit != null) {
      query = query.limit(limit);
    }

    return query.snapshots().map((snapshot) => snapshot.docs
        .map((doc) => ActivityLog.fromJson({...doc.data() as Map<String, dynamic>, 'id': doc.id}))
        .toList());
  }

  // Delete activity
  Future<bool> deleteActivity(String activityId) async {
    try {
      await _firestore.collection(_collection).doc(activityId).delete();
      return true;
    } catch (e) {
      print('Error deleting activity: $e');
      return false;
    }
  }

  // Update activity
  Future<bool> updateActivity(String activityId, Map<String, dynamic> updates) async {
    try {
      await _firestore.collection(_collection).doc(activityId).update(updates);
      return true;
    } catch (e) {
      print('Error updating activity: $e');
      return false;
    }
  }
}
