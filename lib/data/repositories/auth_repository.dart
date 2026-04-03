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

  // สร้างโปรไฟล์หลังสมัครสมาชิก
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

  // ดึง role ของผู้ใช้จากตาราง profiles
  Future<String?> fetchUserRole(String userId) async {
    final data = await _supabase
        .from('profiles')
        .select('role')
        .eq('id', userId)
        .single();
    return data['role'] as String?;
  }
}
