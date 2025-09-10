import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:babysteps_app/services/supabase_service.dart';

class AuthProvider extends ChangeNotifier {
  final SupabaseService _supabaseService = SupabaseService();
  
  bool _isLoading = false;
  bool _isLoggedIn = false;
  String? _error;
  User? _user;

  bool get isLoading => _isLoading;
  bool get isLoggedIn => _isLoggedIn;
  String? get error => _error;
  User? get user => _user;

  // Initialize the auth provider
  Future<void> initialize() async {
    _setLoading(true);
    try {
      final currentUser = Supabase.instance.client.auth.currentUser;
      if (currentUser != null) {
        _user = currentUser;
        _isLoggedIn = true;
      }
    } catch (e) {
      _setError('Error initializing auth: $e');
    } finally {
      _setLoading(false);
    }
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
      _setError('An unexpected error occurred during sign up.');
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
      return _isLoggedIn;
    } on AuthException catch (e) {
      _setError(e.message);
      return false;
    } catch (e) {
      _setError('An unexpected error occurred during sign in.');
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
}
