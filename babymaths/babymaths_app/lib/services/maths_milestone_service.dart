import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/maths_milestone.dart';

class MathsMilestoneService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'maths_milestones';

  // Get all milestones
  Future<List<MathsMilestone>> getAllMilestones() async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .orderBy('age_months_min')
          .orderBy('sort_order')
          .get();

      return snapshot.docs
          .map((doc) => MathsMilestone.fromJson({...doc.data(), 'id': doc.id}))
          .toList();
    } catch (e) {
      print('Error fetching milestones: $e');
      return [];
    }
  }

  // Get milestones for specific age range
  Future<List<MathsMilestone>> getMilestonesForAge(int ageInMonths) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('age_months_min', isLessThanOrEqualTo: ageInMonths)
          .where('age_months_max', isGreaterThanOrEqualTo: ageInMonths)
          .orderBy('age_months_min')
          .orderBy('age_months_max')
          .orderBy('sort_order')
          .get();

      return snapshot.docs
          .map((doc) => MathsMilestone.fromJson({...doc.data(), 'id': doc.id}))
          .toList();
    } catch (e) {
      print('Error fetching milestones for age $ageInMonths: $e');
      return [];
    }
  }

  // Get milestones by category
  Future<List<MathsMilestone>> getMilestonesByCategory(String category) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('category', isEqualTo: category)
          .orderBy('age_months_min')
          .orderBy('sort_order')
          .get();

      return snapshot.docs
          .map((doc) => MathsMilestone.fromJson({...doc.data(), 'id': doc.id}))
          .toList();
    } catch (e) {
      print('Error fetching milestones for category $category: $e');
      return [];
    }
  }

  // Get milestone by ID
  Future<MathsMilestone?> getMilestoneById(String id) async {
    try {
      final doc = await _firestore.collection(_collection).doc(id).get();
      if (doc.exists) {
        return MathsMilestone.fromJson({...doc.data()!, 'id': doc.id});
      }
      return null;
    } catch (e) {
      print('Error fetching milestone $id: $e');
      return null;
    }
  }

  // Stream milestones for real-time updates
  Stream<List<MathsMilestone>> streamMilestones() {
    return _firestore
        .collection(_collection)
        .orderBy('age_months_min')
        .orderBy('sort_order')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MathsMilestone.fromJson({...doc.data(), 'id': doc.id}))
            .toList());
  }

  // Stream milestones by category
  Stream<List<MathsMilestone>> streamMilestonesByCategory(String category) {
    return _firestore
        .collection(_collection)
        .where('category', isEqualTo: category)
        .orderBy('age_months_min')
        .orderBy('sort_order')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MathsMilestone.fromJson({...doc.data(), 'id': doc.id}))
            .toList());
  }
}
