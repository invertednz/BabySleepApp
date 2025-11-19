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
    if (_milestones.isNotEmpty) {
      print('[MilestoneProvider] loadMilestones() skipped; already have ${_milestones.length} milestones');
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      print('[MilestoneProvider] loadMilestones() starting...');
      _milestones = await _supabaseService.getMilestones();
      print('[MilestoneProvider] loadMilestones() completed: loaded ${_milestones.length} milestones');
    } catch (e) {
      // Handle error appropriately
      print('[MilestoneProvider] Error loading milestones: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
