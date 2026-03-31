import '../data/json_utils.dart';

class ProgressSummary {
  const ProgressSummary({
    required this.totalEspb,
    required this.earnedEspbWithGrade,
    required this.weightedAverage,
    required this.simpleAverage,
    required this.subjectsWithGrade,
  });

  final int totalEspb;
  final int earnedEspbWithGrade;
  final double? weightedAverage;
  final double? simpleAverage;
  final int subjectsWithGrade;

  factory ProgressSummary.fromJson(Map<String, dynamic> json) {
    return ProgressSummary(
      totalEspb: asInt(json['totalEspb']),
      earnedEspbWithGrade: asInt(json['earnedEspbWithGrade']),
      weightedAverage: asDoubleNullable(json['weightedAverage']),
      simpleAverage: asDoubleNullable(json['simpleAverage']),
      subjectsWithGrade: asInt(json['subjectsWithGrade']),
    );
  }
}
