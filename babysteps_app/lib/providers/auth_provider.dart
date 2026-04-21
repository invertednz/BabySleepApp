import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import 'package:babysteps_app/services/supabase_service.dart';
import 'package:babysteps_app/services/mixpanel_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthProvider extends ChangeNotifier {
  final SupabaseService _supabaseService = SupabaseService();
  final MixpanelService _mixpanelService = MixpanelService();
  
  bool _isLoading = false;
  bool _isLoggedIn = false;
  bool _needsEmailConfirmation = false;
  String? _error;
  supabase.User? _user;
  bool _isPaidUser = false;
  bool _isOnTrial = false;
  DateTime? _planStartedAt;
  String _planTier = 'free';

  bool get isLoading => _isLoading;
  bool get isLoggedIn => _isLoggedIn;
  bool get needsEmailConfirmation => _needsEmailConfirmation;
  String? get error => _error;
  supabase.User? get user => _user;
  // Client-side trial expiration guard: trial is 3 days from plan_started_at.
  // If trial has expired, ignore the is_on_trial flag (server never flips it back).
  // If planStartedAt is null, fall back to stored flag (don't lock out users with
  // missing metadata).
  bool get isPaidUser {
    if (_isOnTrial && _planStartedAt != null) {
      final trialAge = DateTime.now().difference(_planStartedAt!);
      if (trialAge > const Duration(days: 3)) {
        return _planTier != 'free';
      }
    }
    return _isPaidUser;
  }
  bool get isOnTrial => _isOnTrial;
  DateTime? get planStartedAt => _planStartedAt;
  String get planTier => _planTier;

  static const String _pendingPlanTierKey = 'pending_plan_tier';
  static const String _pendingPlanIsTrialKey = 'pending_plan_is_trial';
  static const String _pendingPlanTimestampKey = 'pending_plan_upgrade_timestamp_ms';
  static const int _pendingPlanMaxAgeMs = 30 * 60 * 1000; // 30 minutes

  // Initialize the auth provider
  Future<void> initialize() async {
    _setLoading(true);
    try {
      final currentUser = supabase.Supabase.instance.client.auth.currentUser;
      if (currentUser != null) {
        _user = currentUser;
        _isLoggedIn = true;
        await _refreshPlanStatus();
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
        await applyPendingPlanUpgradeIfAny();
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
        await applyPendingPlanUpgradeIfAny();
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
    _needsEmailConfirmation = false;
    try {
      final response = await _supabaseService.signUp(
        email: email,
        password: password,
      );

      _user = response.user;
      _trackEvent('Auth Sign Up', properties: {'method': 'email'});

      // Check if email confirmation is required
      // When autoconfirm is off, user is created but email_confirmed_at is null
      // and there's no active session
      if (_user != null && response.session == null) {
        // Email confirmation required - don't try to sign in
        _needsEmailConfirmation = true;
        _isLoggedIn = false;
        notifyListeners();
        return false; // Login screen will check needsEmailConfirmation
      }

      // If session exists, user is auto-confirmed (autoconfirm enabled)
      _isLoggedIn = response.session != null;
      if (_isLoggedIn) {
        await _refreshPlanStatus();
        await applyPendingPlanUpgradeIfAny();
      }

      return _isLoggedIn;
    } on supabase.AuthException catch (e) {
      _setError(_friendlyAuthError(e.message));
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
    _needsEmailConfirmation = false;
    try {
      final response = await _supabaseService.signIn(
        email: email,
        password: password,
      );

      _user = response.user;
      _isLoggedIn = _user != null;
      if (_isLoggedIn) {
        await _refreshPlanStatus();
        await applyPendingPlanUpgradeIfAny();
        _trackEvent('Auth Sign In', properties: {'method': 'email'});
      }
      return _isLoggedIn;
    } on supabase.AuthException catch (e) {
      _setError(_friendlyAuthError(e.message));
      return false;
    } catch (e) {
      // Surface the actual error to the UI (e.g., network/DNS issues)
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Maps Supabase error codes to user-friendly messages
  String _friendlyAuthError(String message) {
    final lower = message.toLowerCase();
    if (lower.contains('invalid login credentials') || lower.contains('invalid_credentials')) {
      return 'Incorrect email or password. Please try again.';
    }
    if (lower.contains('email not confirmed')) {
      _needsEmailConfirmation = true;
      notifyListeners();
      return 'Please check your email and click the confirmation link before signing in.';
    }
    if (lower.contains('email_address_invalid') || lower.contains('email address') && lower.contains('invalid')) {
      return 'Unable to verify that email address right now. Please check the spelling or try again in a moment.';
    }
    if (lower.contains('user already registered') || lower.contains('already_exists')) {
      return 'An account with this email already exists. Try logging in instead.';
    }
    if (lower.contains('email_send_rate_limit') || lower.contains('rate limit')) {
      return 'Too many attempts. Please wait a minute and try again.';
    }
    return message;
  }

  // Sign out
  Future<void> signOut() async {
    _setLoading(true);
    _setError(null);
    try {
      await _supabaseService.signOut();
      _user = null;
      _isLoggedIn = false;
      // Clear any pending plan upgrade so it cannot be applied to a
      // different user who signs in next on a shared device.
      await clearPendingPlanUpgrade();
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
      _planTier = tier;
      updatePlanInfo(isPaid: isPaid, isOnTrial: isOnTrial, planStartedAt: planStartedAt);
    } catch (e) {
      // Silently ignored
    }
  }

  // Mark user as paid (with optional trial)
  Future<void> markUserAsPaid({bool onTrial = false, String planTier = 'paid'}) async {
    if (_user == null) return;
    try {
      await _supabaseService.updateUserPlanStatus(
        planTier: planTier,
        isOnTrial: onTrial,
        planStartedAt: DateTime.now(),
      );
      await _refreshPlanStatus();
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

  // Store a pending upgrade locally so that a payment made before login
  // can be applied once a user account exists.
  Future<void> savePendingPlanUpgrade({
    required String planTier,
    required bool isOnTrial,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_pendingPlanTierKey, planTier);
    await prefs.setBool(_pendingPlanIsTrialKey, isOnTrial);
    await prefs.setInt(
      _pendingPlanTimestampKey,
      DateTime.now().millisecondsSinceEpoch,
    );
  }

  // Clear any pending plan upgrade keys from local storage.
  Future<void> clearPendingPlanUpgrade() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_pendingPlanTierKey);
    await prefs.remove(_pendingPlanIsTrialKey);
    await prefs.remove(_pendingPlanTimestampKey);
  }

  // Apply any pending plan upgrade now that a user is logged in.
  Future<void> applyPendingPlanUpgradeIfAny() async {
    final prefs = await SharedPreferences.getInstance();
    final pendingTier = prefs.getString(_pendingPlanTierKey);
    if (pendingTier == null || pendingTier.isEmpty) {
      return;
    }

    // If the pending upgrade is too old (>30 minutes), discard it.
    // This prevents User A's upgrade from being applied to User B on a
    // shared device when there is a long gap between purchase and login.
    final timestampMs = prefs.getInt(_pendingPlanTimestampKey);
    if (timestampMs != null) {
      final ageMs = DateTime.now().millisecondsSinceEpoch - timestampMs;
      if (ageMs > _pendingPlanMaxAgeMs) {
        await clearPendingPlanUpgrade();
        return;
      }
    }

    final isOnTrial = prefs.getBool(_pendingPlanIsTrialKey) ?? false;

    // Only apply if we have a logged-in user
    if (_user == null) {
      return;
    }

    try {
      await markUserAsPaid(onTrial: isOnTrial, planTier: pendingTier);
    } finally {
      await clearPendingPlanUpgrade();
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
      _trackEvent('Plan Status Updated', properties: {
        'is_paid_user': false,
        'is_on_trial': false,
      });
    } catch (e) {
      _setError('Failed to update plan status: $e');
    }
  }

  Future<void> requestAccountDeletion() async {
    _setLoading(true);
    _setError(null);
    try {
      await _supabaseService.requestAccountDeletion();
      _trackEvent('Account Deletion Requested');
      await signOut();
    } catch (e) {
      _setError('Failed to request account deletion: $e');
    } finally {
      _setLoading(false);
    }
  }

  void _trackEvent(String name, {Map<String, dynamic>? properties}) {
    _mixpanelService.trackEvent(name, properties: properties);
  }
}
