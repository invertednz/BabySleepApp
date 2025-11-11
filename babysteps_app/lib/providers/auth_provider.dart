import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import 'package:babysteps_app/services/supabase_service.dart';
import 'package:babysteps_app/services/mixpanel_service.dart';

class AuthProvider extends ChangeNotifier {
  final SupabaseService _supabaseService = SupabaseService();
  final MixpanelService _mixpanelService = MixpanelService();
  
  bool _isLoading = false;
  bool _isLoggedIn = false;
  String? _error;
  supabase.User? _user;
  bool _isPaidUser = false;
  bool _isOnTrial = false;
  DateTime? _planStartedAt;

  bool get isLoading => _isLoading;
  bool get isLoggedIn => _isLoggedIn;
  String? get error => _error;
  supabase.User? get user => _user;
  bool get isPaidUser => _isPaidUser;
  bool get isOnTrial => _isOnTrial;
  DateTime? get planStartedAt => _planStartedAt;

  // Initialize the auth provider
  Future<void> initialize() async {
    _setLoading(true);
    try {
      final currentUser = supabase.Supabase.instance.client.auth.currentUser;
      if (currentUser != null) {
        _user = currentUser;
        _isLoggedIn = true;
        await _refreshPlanStatus();
        _identifyWithMixpanel();
        _trackEvent('Auth Session Restored');
      }
    } catch (e) {
      _setError('Error initializing auth: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> signInWithGoogle({String? redirectUrl}) async {
    _setLoading(true);
    _setError(null);
    try {
      await _supabaseService.signInWithGoogle(redirectUrl: redirectUrl);
      // For web, Supabase redirects; for native, we receive an AuthResponse immediately.
      final currentUser = supabase.Supabase.instance.client.auth.currentUser;
      if (currentUser != null) {
        _user = currentUser;
        _isLoggedIn = true;
        await _refreshPlanStatus();
        _identifyWithMixpanel();
        _trackEvent('Auth Sign In', properties: {'method': 'google'});
      }
      return true;
    } on supabase.AuthException catch (e) {
      _setError(e.message);
      return false;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> signInWithApple({String? redirectUrl}) async {
    _setLoading(true);
    _setError(null);
    try {
      await _supabaseService.signInWithApple(redirectUrl: redirectUrl);
      final currentUser = supabase.Supabase.instance.client.auth.currentUser;
      if (currentUser != null) {
        _user = currentUser;
        _isLoggedIn = true;
        await _refreshPlanStatus();
        _identifyWithMixpanel();
        _trackEvent('Auth Sign In', properties: {'method': 'apple'});
      }
      return true;
    } on supabase.AuthException catch (e) {
      _setError(e.message);
      return false;
    } catch (e) {
      _setError(e.toString());
      return false;
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
    _identifyWithMixpanel();
    final eventProps = <String, dynamic>{
      'is_paid_user': isPaid,
      'is_on_trial': isOnTrial,
    };
    if (planStartedAt != null) {
      eventProps['plan_started_at'] = planStartedAt.toIso8601String();
    }
    _trackEvent('Plan Status Updated', properties: eventProps);
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
        _identifyWithMixpanel();
        _trackEvent('Auth Sign Up', properties: {'method': 'email'});
        return await signIn(email: email, password: password);
      }

      return _isLoggedIn;
    } on supabase.AuthException catch (e) {
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
        _identifyWithMixpanel();
        _trackEvent('Auth Sign In', properties: {'method': 'email'});
      }
      return _isLoggedIn;
    } on supabase.AuthException catch (e) {
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
      _trackEvent('Auth Sign Out');
      _mixpanelService.reset();
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
        planTier: 'paid',
        isOnTrial: onTrial,
        planStartedAt: DateTime.now(),
      );
      await _refreshPlanStatus();
      _identifyWithMixpanel();
      final eventProps = <String, dynamic>{
        'is_paid_user': true,
        'is_on_trial': onTrial,
        'plan_started_at': DateTime.now().toIso8601String(),
      };
      _trackEvent('Plan Status Updated', properties: eventProps);
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
      _identifyWithMixpanel();
      _trackEvent('Plan Status Updated', properties: {
        'is_paid_user': false,
        'is_on_trial': false,
      });
    } catch (e) {
      _setError('Failed to update plan status: $e');
    }
  }

  void _identifyWithMixpanel() {
    final user = _user;
    if (user == null) {
      return;
    }
    _mixpanelService.identify(user.id);
    final properties = <String, dynamic>{
      'plan_tier': _isPaidUser ? 'paid' : 'free',
      'is_paid_user': _isPaidUser,
      'is_on_trial': _isOnTrial,
    };
    if (user.email != null && user.email!.isNotEmpty) {
      properties['email'] = user.email;
    }
    if (_planStartedAt != null) {
      properties['plan_started_at'] = _planStartedAt!.toIso8601String();
    }
    _mixpanelService.setPeopleProperties(properties);
  }

  void _trackEvent(String name, {Map<String, dynamic>? properties}) {
    _mixpanelService.trackEvent(name, properties: properties);
  }
}
