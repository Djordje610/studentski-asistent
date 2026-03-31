import '../data/json_utils.dart';

class Colloquium {
  const Colloquium({
    required this.id,
    required this.subjectId,
    required this.title,
    required this.maxPoints,
    required this.points,
    this.dateMs,
  });

  final int id;
  final int subjectId;
  final String title;
  final double maxPoints;
  final double points;
  final int? dateMs;

  factory Colloquium.fromJson(Map<String, dynamic> json) {
    return Colloquium(
      id: asInt(json['id']),
      subjectId: asInt(json['subjectId']),
      title: json['title'] as String,
      maxPoints: asDouble(json['maxPoints']),
      points: asDouble(json['points']),
      dateMs: asIntNullable(json['dateMs']),
    );
  }

  Map<String, dynamic> toJson() => {
        if (id != 0) 'id': id,
        'subjectId': subjectId,
        'title': title,
        'maxPoints': maxPoints,
        'points': points,
        'dateMs': dateMs,
      };
}
