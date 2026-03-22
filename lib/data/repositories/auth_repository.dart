import 'package:supabase_flutter/supabase_flutter.dart';

class AuthRepository {
  final _supabase = Supabase.instance.client;

  // ฟังก์ชันสมัครสมาชิก
  Future<AuthResponse> signUp(String email, String password) async {
    return await _supabase.auth.signUp(email: email, password: password);
  }

  // ฟังก์ชันล็อกอิน
  Future<AuthResponse> signIn(String email, String password) async {
    return await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  // ฟังก์ชันล็อกเอาท์
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }
}
