import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  bool get isAuthenticated => _supabase.auth.currentSession != null;

  Future<AuthResponse> signInWithEmailPassword(
    String email,
    String password,
  ) async {
    return _supabase.auth.signInWithPassword(email: email, password: password);
  }

  Future<AuthResponse> signUpWithEmailPassword(
    String email,
    String password, {
    String? fullName,
  }) async {
    return _supabase.auth.signUp(
      email: email,
      password: password,
      data: fullName != null && fullName.isNotEmpty
          ? {'full_name': fullName}
          : null,
      emailRedirectTo: kIsWeb
          ? null
          : 'io.supabase.flutterquickstart://login-callback/',
    );
  }

  Future<void> resendConfirmationEmail(String email) async {
    final response = await http.post(
      Uri.parse('https://wubpgzfvovhzmyxtbxms.supabase.co/auth/v1/resend'),
      headers: {..._supabase.auth.headers, 'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'type': 'signup',
        'redirect_to': kIsWeb
            ? null
            : 'io.supabase.flutterquickstart://login-callback/',
      }),
    );

    if (response.statusCode >= 400) {
      final body = response.body.isNotEmpty ? response.body : '{}';
      final decoded = jsonDecode(body);
      final message = decoded is Map<String, dynamic>
          ? (decoded['msg'] ?? decoded['message'] ?? response.body)
          : response.body;
      throw AuthException(message.toString());
    }
  }

  Future<void> resetPassword(String email) async {
    final response = await http.post(
      Uri.parse('https://wubpgzfvovhzmyxtbxms.supabase.co/auth/v1/recover'),
      headers: {..._supabase.auth.headers, 'Content-Type': 'application/json'},
      body: jsonEncode({'email': email}),
    );

    if (response.statusCode >= 400) {
      final body = response.body.isNotEmpty ? response.body : '{}';
      final decoded = jsonDecode(body);
      final message = decoded is Map<String, dynamic>
          ? (decoded['msg'] ?? decoded['message'] ?? response.body)
          : response.body;
      throw AuthException(message.toString());
    }
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  String? getCurrentUserEmail() {
    final session = _supabase.auth.currentSession;
    final user = session?.user;
    return user?.email;
  }
}
