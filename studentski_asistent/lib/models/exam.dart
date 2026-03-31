import '../data/json_utils.dart';

class Exam {
  const Exam({
    required this.id,
    this.subjectId,
    required this.title,
    required this.examMs,
    this.location,
    this.notes,
  });

  final int id;
  final int? subjectId;
  final String title;
  final int examMs;
  final String? location;
  final String? notes;

  factory Exam.fromJson(Map<String, dynamic> json) {
    return Exam(
      id: asInt(json['id']),
      subjectId: asIntNullable(json['subjectId']),
      title: json['title'] as String,
      examMs: asInt(json['examMs']),
      location: json['location'] as String?,
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        if (id != 0) 'id': id,
        'subjectId': subjectId,
        'title': title,
        'examMs': examMs,
        'location': location,
        'notes': notes,
      };
}
