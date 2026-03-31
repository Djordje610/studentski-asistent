import '../data/json_utils.dart';

class AuthResponse {
  const AuthResponse({
    required this.accessToken,
    required this.expiresInSeconds,
    required this.userId,
    required this.email,
    required this.fullName,
    required this.role,
  });

  final String accessToken;
  final int expiresInSeconds;
  final int userId;
  final String email;
  final String fullName;
  final String role;

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      accessToken: json['accessToken'] as String,
      expiresInSeconds: asInt(json['expiresInSeconds']),
      userId: asInt(json['userId']),
      email: json['email'] as String,
      fullName: json['fullName'] as String,
      role: json['role'] as String? ?? 'STUDENT',
    );
  }
}
