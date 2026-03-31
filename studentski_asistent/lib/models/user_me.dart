import '../data/json_utils.dart';

class UserMe {
  const UserMe({
    required this.userId,
    required this.email,
    required this.fullName,
    required this.role,
    this.studentIndex,
  });

  final int userId;
  final String email;
  final String fullName;
  final String role;
  final String? studentIndex;

  factory UserMe.fromJson(Map<String, dynamic> json) {
    return UserMe(
      userId: asInt(json['userId']),
      email: json['email'] as String,
      fullName: json['fullName'] as String,
      role: json['role'] as String? ?? 'STUDENT',
      studentIndex: json['studentIndex'] as String?,
    );
  }
}
