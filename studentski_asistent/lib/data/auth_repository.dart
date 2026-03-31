import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/auth_response.dart';
import '../models/user_me.dart';

class AuthRepository {
  AuthRepository({String? baseUrl}) : _base = baseUrl ?? resolveGatewayUrl();

  final String _base;

  Future<AuthResponse> login({
    required String email,
    required String password,
  }) async {
    final r = await http.post(
      Uri.parse('$_base/auth/login'),
      headers: {'Content-Type': 'application/json; charset=utf-8'},
      body: jsonEncode({'email': email, 'password': password}),
    );
    if (r.statusCode != 200) {
      throw Exception(_bodyMessage(r));
    }
    return AuthResponse.fromJson(jsonDecode(r.body) as Map<String, dynamic>);
  }

  Future<UserMe> fetchMe({required String accessToken}) async {
    final r = await http.get(
      Uri.parse('$_base/auth/me'),
      headers: {'Authorization': 'Bearer $accessToken'},
    );
    if (r.statusCode != 200) {
      throw Exception(_bodyMessage(r));
    }
    return UserMe.fromJson(jsonDecode(r.body) as Map<String, dynamic>);
  }

  String _bodyMessage(http.Response r) {
    try {
      final m = jsonDecode(r.body);
      if (m is Map) {
        final msg = m['message'] ?? m['detail'] ?? m['error'];
        if (msg != null) {
          return '${r.statusCode}: $msg';
        }
      }
    } catch (_) {}
    return 'Greška ${r.statusCode}: ${r.body}';
  }
}
