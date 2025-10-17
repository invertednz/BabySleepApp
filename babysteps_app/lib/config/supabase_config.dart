import 'package:flutter_dotenv/flutter_dotenv.dart';

class SupabaseConfig {
  // Get Supabase URL and anon key from environment variables
  static String get supabaseUrl => dotenv.env['SUPABASE_URL'] ?? '';
  static String get supabaseAnonKey => dotenv.env['SUPABASE_ANON_KEY'] ?? '';
  static String? get supabaseRedirectUrl {
    final value = dotenv.env['SUPABASE_REDIRECT_URL'];
    if (value == null || value.trim().isEmpty) {
      return null;
    }
    return value.trim();
  }
}
