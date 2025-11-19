import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/baby.dart';

class BabyService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final String _collection = 'babies';

  // Create a new baby profile
  Future<String?> createBaby(Baby baby) async {
    final user = _auth.currentUser;
    if (user == null) {
      return null;
    }
    try {
      final data = Map<String, dynamic>.from(baby.toJson());
      data['user_id'] = user.uid;
      data['created_at'] = DateTime.now().toIso8601String();
      final docRef = await _firestore.collection(_collection).add(data);
      return docRef.id;
    } catch (e) {
      print('Error creating baby: $e');
      return null;
    }
  }

  // Get all babies for current user
  Future<List<Baby>> getBabiesForUser(String userId) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('user_id', isEqualTo: userId)
          .orderBy('created_at', descending: false)
          .get();

      return snapshot.docs
          .map((doc) => Baby.fromJson({...doc.data(), 'id': doc.id}))
          .toList();
    } catch (e) {
      print('Error fetching babies: $e');
      return [];
    }
  }

  // Get baby by ID
  Future<Baby?> getBabyById(String babyId) async {
    try {
      final doc = await _firestore.collection(_collection).doc(babyId).get();
      if (doc.exists) {
        return Baby.fromJson({...doc.data()!, 'id': doc.id});
      }
      return null;
    } catch (e) {
      print('Error fetching baby: $e');
      return null;
    }
  }

  // Update baby profile
  Future<bool> updateBaby(String babyId, Map<String, dynamic> updates) async {
    final user = _auth.currentUser;
    if (user == null) {
      return false;
    }
    try {
      updates['updated_at'] = DateTime.now().toIso8601String();
      await _firestore.collection(_collection).doc(babyId).update(updates);
      return true;
    } catch (e) {
      print('Error updating baby: $e');
      return false;
    }
  }

  // Delete baby profile
  Future<bool> deleteBaby(String babyId) async {
    final user = _auth.currentUser;
    if (user == null) {
      return false;
    }
    try {
      await _firestore.collection(_collection).doc(babyId).delete();
      return true;
    } catch (e) {
      print('Error deleting baby: $e');
      return false;
    }
  }

  // Stream baby data for real-time updates
  Stream<Baby?> streamBaby(String babyId) {
    return _firestore
        .collection(_collection)
        .doc(babyId)
        .snapshots()
        .map((doc) {
      if (doc.exists) {
        return Baby.fromJson({...doc.data()!, 'id': doc.id});
      }
      return null;
    });
  }

  // Stream all babies for user
  Stream<List<Baby>> streamBabiesForUser(String userId) {
    return _firestore
        .collection(_collection)
        .where('user_id', isEqualTo: userId)
        .orderBy('created_at', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Baby.fromJson({...doc.data(), 'id': doc.id}))
            .toList());
  }
}
