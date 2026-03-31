import '../data/json_utils.dart';

class Subject {
  const Subject({
    required this.id,
    required this.name,
    required this.espb,
    this.finalGrade,
  });

  final int id;
  final String name;
  final int espb;
  final double? finalGrade;

  Subject copyWith({
    int? id,
    String? name,
    int? espb,
    double? finalGrade,
    bool clearFinalGrade = false,
  }) {
    return Subject(
      id: id ?? this.id,
      name: name ?? this.name,
      espb: espb ?? this.espb,
      finalGrade: clearFinalGrade ? null : (finalGrade ?? this.finalGrade),
    );
  }

  factory Subject.fromJson(Map<String, dynamic> json) {
    return Subject(
      id: asInt(json['id']),
      name: json['name'] as String,
      espb: asInt(json['espb']),
      finalGrade: asDoubleNullable(json['finalGrade']),
    );
  }

  Map<String, dynamic> toJson() => {
        if (id != 0) 'id': id,
        'name': name,
        'espb': espb,
        'finalGrade': finalGrade,
      };
}
