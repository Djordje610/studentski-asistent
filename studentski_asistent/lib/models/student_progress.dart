import '../data/json_utils.dart';

class StudentProgressSubject {
  const StudentProgressSubject({
    required this.catalogSubjectId,
    this.code,
    required this.name,
    required this.espb,
    required this.passed,
    this.grade,
    this.passedInPeriod,
  });

  final int catalogSubjectId;
  final String? code;
  final String name;
  final int espb;
  final bool passed;
  final int? grade;
  final String? passedInPeriod;

  factory StudentProgressSubject.fromJson(Map<String, dynamic> json) {
    return StudentProgressSubject(
      catalogSubjectId: asInt(json['catalogSubjectId']),
      code: json['code'] as String?,
      name: json['name'] as String,
      espb: asInt(json['espb']),
      passed: json['passed'] as bool? ?? false,
      grade: asIntNullable(json['grade']),
      passedInPeriod: json['passedInPeriod'] as String?,
    );
  }
}

class StudentProgressSummary {
  const StudentProgressSummary({
    required this.totalEspb,
    required this.earnedEspb,
    required this.weightedAverage,
    required this.passedCount,
  });

  final int totalEspb;
  final int earnedEspb;
  final double? weightedAverage;
  final int passedCount;

  factory StudentProgressSummary.fromJson(Map<String, dynamic> json) {
    return StudentProgressSummary(
      totalEspb: asInt(json['totalEspb']),
      earnedEspb: asInt(json['earnedEspb']),
      weightedAverage: asDoubleNullable(json['weightedAverage']),
      passedCount: asInt(json['passedCount']),
    );
  }
}
