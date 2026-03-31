import '../data/json_utils.dart';

class CatalogSubjectRow {
  const CatalogSubjectRow({
    required this.id,
    this.code,
    required this.name,
    required this.espb,
    required this.programYearId,
    required this.programCode,
    required this.yearNumber,
  });

  final int id;
  final String? code;
  final String name;
  final int espb;
  final int programYearId;
  final String programCode;
  final int yearNumber;

  factory CatalogSubjectRow.fromJson(Map<String, dynamic> json) {
    return CatalogSubjectRow(
      id: asInt(json['id']),
      code: json['code'] as String?,
      name: json['name'] as String,
      espb: asInt(json['espb']),
      programYearId: asInt(json['programYearId']),
      programCode: json['programCode'] as String,
      yearNumber: asInt(json['yearNumber']),
    );
  }
}

class PortalHomeworkRow {
  const PortalHomeworkRow({
    required this.assignmentId,
    required this.title,
    this.description,
    this.dueDateMs,
    required this.catalogSubjectId,
    required this.subjectName,
    required this.completed,
  });

  final int assignmentId;
  final String title;
  final String? description;
  final int? dueDateMs;
  final int catalogSubjectId;
  final String subjectName;
  final bool completed;

  factory PortalHomeworkRow.fromJson(Map<String, dynamic> json) {
    return PortalHomeworkRow(
      assignmentId: asInt(json['assignmentId']),
      title: json['title'] as String,
      description: json['description'] as String?,
      dueDateMs: asIntNullable(json['dueDateMs']),
      catalogSubjectId: asInt(json['catalogSubjectId']),
      subjectName: json['subjectName'] as String,
      completed: json['completed'] as bool? ?? false,
    );
  }
}

class ExamOffer {
  const ExamOffer({
    required this.offeringId,
    required this.examPeriodName,
    required this.catalogSubjectId,
    required this.subjectName,
    required this.examMs,
    this.location,
  });

  final int offeringId;
  final String examPeriodName;
  final int catalogSubjectId;
  final String subjectName;
  final int examMs;
  final String? location;

  factory ExamOffer.fromJson(Map<String, dynamic> json) {
    return ExamOffer(
      offeringId: asInt(json['offeringId']),
      examPeriodName: json['examPeriodName'] as String,
      catalogSubjectId: asInt(json['catalogSubjectId']),
      subjectName: json['subjectName'] as String,
      examMs: asInt(json['examMs']),
      location: json['location'] as String?,
    );
  }
}

class MyRegisteredExam {
  const MyRegisteredExam({
    required this.registrationId,
    required this.offeringId,
    required this.subjectName,
    required this.examMs,
    this.location,
    required this.examPeriodName,
    required this.passed,
  });

  final int registrationId;
  final int offeringId;
  final String subjectName;
  final int examMs;
  final String? location;
  final String examPeriodName;
  final bool passed;

  factory MyRegisteredExam.fromJson(Map<String, dynamic> json) {
    return MyRegisteredExam(
      registrationId: asInt(json['registrationId']),
      offeringId: asInt(json['offeringId']),
      subjectName: json['subjectName'] as String,
      examMs: asInt(json['examMs']),
      location: json['location'] as String?,
      examPeriodName: json['examPeriodName'] as String,
      passed: json['passed'] as bool? ?? false,
    );
  }
}
