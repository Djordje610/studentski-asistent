import '../data/json_utils.dart';

class StudyProgram {
  const StudyProgram({required this.id, required this.code, required this.name});

  final int id;
  final String code;
  final String name;

  factory StudyProgram.fromJson(Map<String, dynamic> json) {
    return StudyProgram(
      id: asInt(json['id']),
      code: json['code'] as String,
      name: json['name'] as String,
    );
  }
}

class ProgramYear {
  const ProgramYear({
    required this.id,
    required this.yearNumber,
    required this.studyProgramId,
  });

  final int id;
  final int yearNumber;
  final int studyProgramId;

  factory ProgramYear.fromJson(Map<String, dynamic> json) {
    final sp = json['studyProgram'] as Map<String, dynamic>?;
    return ProgramYear(
      id: asInt(json['id']),
      yearNumber: asInt(json['yearNumber']),
      studyProgramId: sp != null ? asInt(sp['id']) : asInt(json['studyProgramId']),
    );
  }
}

class CatalogSubjectAdmin {
  const CatalogSubjectAdmin({
    required this.id,
    this.code,
    required this.name,
    required this.espb,
    required this.programYearId,
  });

  final int id;
  final String? code;
  final String name;
  final int espb;
  final int programYearId;

  factory CatalogSubjectAdmin.fromJson(Map<String, dynamic> json) {
    final py = json['programYear'] as Map<String, dynamic>?;
    return CatalogSubjectAdmin(
      id: asInt(json['id']),
      code: json['code'] as String?,
      name: json['name'] as String,
      espb: asInt(json['espb']),
      programYearId: py != null ? asInt(py['id']) : asInt(json['programYearId']),
    );
  }
}

class StudentProfileAdmin {
  const StudentProfileAdmin({
    required this.userId,
    this.fullName,
    required this.programCode,
    required this.programName,
    required this.yearNumber,
    required this.programYearId,
  });

  final int userId;
  /// Ime i prezime iz studentski-api (kolona full_name), usklađeno sa auth korisnikom pri kreiranju.
  final String? fullName;
  final String programCode;
  final String programName;
  final int yearNumber;
  final int programYearId;

  String get displayTitle {
    final n = fullName?.trim();
    if (n != null && n.isNotEmpty) {
      return 'Student: $n';
    }
    return 'Student';
  }

  factory StudentProfileAdmin.fromJson(Map<String, dynamic> json) {
    final sp = json['studyProgram'] as Map<String, dynamic>;
    final py = json['programYear'] as Map<String, dynamic>;
    return StudentProfileAdmin(
      userId: asInt(json['userId']),
      fullName: json['fullName'] as String?,
      programCode: sp['code'] as String,
      programName: sp['name'] as String,
      yearNumber: asInt(py['yearNumber']),
      programYearId: asInt(py['id']),
    );
  }
}

class ExamPeriodAdmin {
  const ExamPeriodAdmin({
    required this.id,
    required this.name,
    required this.startMs,
    required this.endMs,
    required this.active,
  });

  final int id;
  final String name;
  final int startMs;
  final int endMs;
  final bool active;

  factory ExamPeriodAdmin.fromJson(Map<String, dynamic> json) {
    return ExamPeriodAdmin(
      id: asInt(json['id']),
      name: json['name'] as String,
      startMs: asInt(json['startMs']),
      endMs: asInt(json['endMs']),
      active: json['active'] as bool? ?? false,
    );
  }
}

class ExamOfferingAdmin {
  const ExamOfferingAdmin({
    required this.id,
    required this.examMs,
    this.location,
    required this.subjectName,
    required this.catalogSubjectId,
  });

  final int id;
  final int examMs;
  final String? location;
  final String subjectName;
  final int catalogSubjectId;

  factory ExamOfferingAdmin.fromJson(Map<String, dynamic> json) {
    final cs = json['catalogSubject'] as Map<String, dynamic>;
    return ExamOfferingAdmin(
      id: asInt(json['id']),
      examMs: asInt(json['examMs']),
      location: json['location'] as String?,
      subjectName: cs['name'] as String,
      catalogSubjectId: asInt(cs['id']),
    );
  }
}

class HomeworkAssignmentAdmin {
  const HomeworkAssignmentAdmin({
    required this.id,
    required this.title,
    this.description,
    this.dueDateMs,
  });

  final int id;
  final String title;
  final String? description;
  final int? dueDateMs;

  factory HomeworkAssignmentAdmin.fromJson(Map<String, dynamic> json) {
    return HomeworkAssignmentAdmin(
      id: asInt(json['id']),
      title: json['title'] as String,
      description: json['description'] as String?,
      dueDateMs: asIntNullable(json['dueDateMs']),
    );
  }
}

class CreatedStudent {
  const CreatedStudent({required this.userId, required this.email});

  final int userId;
  final String email;

  factory CreatedStudent.fromJson(Map<String, dynamic> json) {
    return CreatedStudent(
      userId: asInt(json['userId']),
      email: json['email'] as String,
    );
  }
}
