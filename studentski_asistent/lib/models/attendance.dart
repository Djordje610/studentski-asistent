import '../data/json_utils.dart';

class Attendance {
  const Attendance({
    required this.id,
    required this.subjectId,
    required this.present,
    required this.total,
  });

  final int id;
  final int subjectId;
  final int present;
  final int total;

  double get ratio => total > 0 ? present / total : 0;

  factory Attendance.fromJson(Map<String, dynamic> json) {
    return Attendance(
      id: asInt(json['id']),
      subjectId: asInt(json['subjectId']),
      present: asInt(json['present']),
      total: asInt(json['total']),
    );
  }

  Map<String, dynamic> toJson() => {
        if (id != 0) 'id': id,
        'subjectId': subjectId,
        'present': present,
        'total': total,
      };
}
