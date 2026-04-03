import 'package:supabase_flutter/supabase_flutter.dart';

class AuthRepository {
  final _supabase = Supabase.instance.client;

  // Sign up function
  Future<AuthResponse> signUp(String email, String password) async {
    return await _supabase.auth.signUp(email: email, password: password);
  }

  // Sign in function
  Future<AuthResponse> signIn(String email, String password) async {
    return await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  // Sign out function
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  // Create profile after sign up
  Future<void> createProfile({
    required String userId,
    required String fullName,
    required String phoneNumber,
    required String role,
  }) async {
    // upsert handles both: new profile (no trigger) and existing profile (trigger already ran)
    await _supabase.from('profiles').upsert(
      {
        'id': userId,
        'full_name': fullName,
        'phone_number': phoneNumber,
        'role': role,
        'saved_addresses': <String>[],
      },
      onConflict: 'id',
    );
  }

  // Fetch user role from profiles table
  Future<String?> fetchUserRole(String userId) async {
    final data = await _supabase
        .from('profiles')
        .select('role')
        .eq('id', userId)
        .single();
    return data['role'] as String?;
  }
}
