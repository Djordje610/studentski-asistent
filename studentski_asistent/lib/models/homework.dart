import '../data/json_utils.dart';

class Homework {
  const Homework({
    required this.id,
    required this.subjectId,
    required this.title,
    this.maxPoints,
    this.points,
    this.dueDateMs,
    required this.completed,
  });

  final int id;
  final int subjectId;
  final String title;
  final double? maxPoints;
  final double? points;
  final int? dueDateMs;
  final bool completed;

  factory Homework.fromJson(Map<String, dynamic> json) {
    return Homework(
      id: asInt(json['id']),
      subjectId: asInt(json['subjectId']),
      title: json['title'] as String,
      maxPoints: asDoubleNullable(json['maxPoints']),
      points: asDoubleNullable(json['points']),
      dueDateMs: asIntNullable(json['dueDateMs']),
      completed: asBool(json['completed']),
    );
  }

  Map<String, dynamic> toJson() => {
        if (id != 0) 'id': id,
        'subjectId': subjectId,
        'title': title,
        'maxPoints': maxPoints,
        'points': points,
        'dueDateMs': dueDateMs,
        'completed': completed,
      };
}
