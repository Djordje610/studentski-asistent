import '../data/json_utils.dart';

class ScheduleEntry {
  const ScheduleEntry({
    required this.id,
    required this.dayOfWeek,
    required this.title,
    required this.activityType,
    required this.startTime,
    required this.endTime,
    this.room,
    this.notes,
  });

  /// 1 = ponedeljak … 7 = nedelja
  final int dayOfWeek;
  final int id;
  final String title;
  final String activityType;
  final String startTime;
  final String endTime;
  final String? room;
  final String? notes;

  factory ScheduleEntry.fromJson(Map<String, dynamic> json) {
    return ScheduleEntry(
      id: asInt(json['id']),
      dayOfWeek: asInt(json['dayOfWeek']),
      title: json['title'] as String,
      activityType: json['activityType'] as String,
      startTime: json['startTime'] as String,
      endTime: json['endTime'] as String,
      room: json['room'] as String?,
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        if (id != 0) 'id': id,
        'dayOfWeek': dayOfWeek,
        'title': title,
        'activityType': activityType,
        'startTime': startTime,
        'endTime': endTime,
        'room': room,
        'notes': notes,
      };
}
