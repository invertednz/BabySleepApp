import 'package:flutter/foundation.dart';
import 'package:babysteps_app/models/milestone.dart';
import 'package:babysteps_app/services/supabase_service.dart';

class MilestoneProvider with ChangeNotifier {
  final SupabaseService _supabaseService = SupabaseService();
  List<Milestone> _milestones = [];
  bool _isLoading = false;

  List<Milestone> get milestones => _milestones;
  bool get isLoading => _isLoading;

  Future<void> loadMilestones() async {
    if (_milestones.isNotEmpty) return;

    _isLoading = true;
    notifyListeners();

    try {
      _milestones = await _supabaseService.getMilestones();
    } catch (e) {
      // Handle error appropriately
      print('Error loading milestones: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
