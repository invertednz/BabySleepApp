import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:babysteps_app/services/supabase_service.dart';

class AuthProvider extends ChangeNotifier {
  final SupabaseService _supabaseService = SupabaseService();
  
  bool _isLoading = false;
  bool _isLoggedIn = false;
  String? _error;
  User? _user;
  bool _isPaidUser = false;
  bool _isOnTrial = false;
  DateTime? _planStartedAt;

  bool get isLoading => _isLoading;
  bool get isLoggedIn => _isLoggedIn;
  String? get error => _error;
  User? get user => _user;
  bool get isPaidUser => _isPaidUser;
  bool get isOnTrial => _isOnTrial;
  DateTime? get planStartedAt => _planStartedAt;

  // Initialize the auth provider
  Future<void> initialize() async {
    _setLoading(true);
    try {
      final currentUser = Supabase.instance.client.auth.currentUser;
      if (currentUser != null) {
        _user = currentUser;
        _isLoggedIn = true;
        await _refreshPlanStatus();
      }
    } catch (e) {
      _setError('Error initializing auth: $e');
    } finally {
      _setLoading(false);
    }
  }

  void updatePaidStatus(bool isPaid) {
    updatePlanInfo(
      isPaid: isPaid,
      isOnTrial: _isOnTrial,
      planStartedAt: _planStartedAt,
    );
  }

  void updatePlanInfo({
    required bool isPaid,
    required bool isOnTrial,
    DateTime? planStartedAt,
  }) {
    final bool planChanged =
        _isPaidUser != isPaid || _isOnTrial != isOnTrial || _planStartedAt != planStartedAt;
    if (!planChanged) {
      return;
    }
    _isPaidUser = isPaid;
    _isOnTrial = isOnTrial;
    _planStartedAt = planStartedAt;
    notifyListeners();
  }
  // Sign up with email and password
  Future<bool> signUp({required String email, required String password}) async {
    _setLoading(true);
    _setError(null);
    try {
      final response = await _supabaseService.signUp(
        email: email,
        password: password,
      );

      _user = response.user;
      _isLoggedIn = _user != null;

      if (_isLoggedIn) {
        // Automatically sign in after sign up to create a session
        return await signIn(email: email, password: password);
      }

      return _isLoggedIn;
    } on AuthException catch (e) {
      _setError(e.message);
      return false;
    } catch (e) {
      // Surface the actual error to the UI (e.g., network/DNS issues)
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Sign in with email and password
  Future<bool> signIn({required String email, required String password}) async {
    _setLoading(true);
    _setError(null);
    try {
      final response = await _supabaseService.signIn(
        email: email,
        password: password,
      );
      
      _user = response.user;
      _isLoggedIn = _user != null;
      if (_isLoggedIn) {
        await _refreshPlanStatus();
      }
      return _isLoggedIn;
    } on AuthException catch (e) {
      _setError(e.message);
      return false;
    } catch (e) {
      // Surface the actual error to the UI (e.g., network/DNS issues)
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Sign out
  Future<void> signOut() async {
    _setLoading(true);
    _setError(null);
    try {
      await _supabaseService.signOut();
      _user = null;
      _isLoggedIn = false;
    } catch (e) {
      _setError('Error signing out: $e');
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

  Future<void> _refreshPlanStatus() async {
    if (_user == null) return;
    try {
      final prefs = await _supabaseService.getUserPreferences();
      final tier = (prefs['plan_tier'] as String?)?.toLowerCase() ?? 'free';
      final isOnTrial = prefs['is_on_trial'] == true;
      final planStartedAtStr = prefs['plan_started_at'] as String?;
      DateTime? planStartedAt;
      if (planStartedAtStr != null && planStartedAtStr.isNotEmpty) {
        planStartedAt = DateTime.tryParse(planStartedAtStr);
      }
      final isPaid = tier != 'free' || isOnTrial;
      updatePlanInfo(isPaid: isPaid, isOnTrial: isOnTrial, planStartedAt: planStartedAt);
    } catch (e) {
      // ignore: avoid_print
      print('Failed to refresh plan status: $e');
    }
  }

  // Mark user as paid (with optional trial)
  Future<void> markUserAsPaid({bool onTrial = false}) async {
    if (_user == null) return;
    try {
      await _supabaseService.updateUserPlanStatus(
        planTier: 'premium',
        isOnTrial: onTrial,
        planStartedAt: DateTime.now(),
      );
      await _refreshPlanStatus();
    } catch (e) {
      _setError('Failed to update plan status: $e');
    }
  }

  // Mark user as free
  Future<void> markUserAsFree() async {
    if (_user == null) return;
    try {
      await _supabaseService.updateUserPlanStatus(
        planTier: 'free',
        isOnTrial: false,
        planStartedAt: null,
      );
      await _refreshPlanStatus();
    } catch (e) {
      _setError('Failed to update plan status: $e');
    }
  }
}
