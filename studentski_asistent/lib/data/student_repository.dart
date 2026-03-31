import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/attendance.dart';
import '../models/academy_portal.dart';
import '../models/colloquium.dart';
import '../models/exam.dart';
import '../models/homework.dart';
import '../models/progress_summary.dart';
import '../models/schedule_entry.dart';
import '../models/student_progress.dart';
import '../models/subject.dart';

typedef TokenGetter = Future<String?> Function();

class StudentRepository {
  StudentRepository({
    String? baseUrl,
    required this.getToken,
  }) : _base = baseUrl ?? resolveGatewayUrl();

  final String _base;
  final TokenGetter getToken;

  Uri _u(String path) => Uri.parse('$_base$path');

  Future<Map<String, String>> _headers({bool jsonBody = false}) async {
    final t = await getToken();
    final h = <String, String>{};
    if (jsonBody) {
      h['Content-Type'] = 'application/json; charset=utf-8';
    }
    if (t != null && t.isNotEmpty) {
      h['Authorization'] = 'Bearer $t';
    }
    return h;
  }

  Future<void> _ensureOk(http.Response r, {Iterable<int> ok = const [200, 201, 204]}) async {
    if (!ok.contains(r.statusCode)) {
      throw Exception('API greška ${r.statusCode}: ${r.body}');
    }
  }

  List<T> _decodeList<T>(String body, T Function(Map<String, dynamic>) fromJson) {
    final list = jsonDecode(body) as List<dynamic>;
    return list.map((e) => fromJson(e as Map<String, dynamic>)).toList();
  }

  // --- Subjects ---
  Future<List<Subject>> getSubjects() async {
    final r = await http.get(_u('/api/subjects'), headers: await _headers());
    await _ensureOk(r);
    return _decodeList(r.body, Subject.fromJson);
  }

  Future<int> insertSubject(Subject s) async {
    final r = await http.post(
      _u('/api/subjects'),
      headers: await _headers(jsonBody: true),
      body: jsonEncode(s.toJson()),
    );
    await _ensureOk(r, ok: const [201]);
    final created = Subject.fromJson(jsonDecode(r.body) as Map<String, dynamic>);
    return created.id;
  }

  Future<void> updateSubject(Subject s) async {
    final r = await http.put(
      _u('/api/subjects/${s.id}'),
      headers: await _headers(jsonBody: true),
      body: jsonEncode(s.toJson()),
    );
    await _ensureOk(r);
  }

  Future<void> deleteSubject(int id) async {
    final r = await http.delete(_u('/api/subjects/$id'), headers: await _headers());
    await _ensureOk(r, ok: const [204]);
  }

  // --- Schedule ---
  Future<List<ScheduleEntry>> getScheduleForDay(int dayOfWeek) async {
    final r = await http.get(_u('/api/schedule?dayOfWeek=$dayOfWeek'), headers: await _headers());
    await _ensureOk(r);
    return _decodeList(r.body, ScheduleEntry.fromJson);
  }

  Future<int> insertSchedule(ScheduleEntry e) async {
    final r = await http.post(
      _u('/api/schedule'),
      headers: await _headers(jsonBody: true),
      body: jsonEncode(e.toJson()),
    );
    await _ensureOk(r, ok: const [201]);
    final created = ScheduleEntry.fromJson(jsonDecode(r.body) as Map<String, dynamic>);
    return created.id;
  }

  Future<void> updateSchedule(ScheduleEntry e) async {
    final r = await http.put(
      _u('/api/schedule/${e.id}'),
      headers: await _headers(jsonBody: true),
      body: jsonEncode(e.toJson()),
    );
    await _ensureOk(r);
  }

  Future<void> deleteSchedule(int id) async {
    final r = await http.delete(_u('/api/schedule/$id'), headers: await _headers());
    await _ensureOk(r, ok: const [204]);
  }

  // --- Colloquiums ---
  Future<List<Colloquium>> getColloquiums() async {
    final r = await http.get(_u('/api/colloquiums'), headers: await _headers());
    await _ensureOk(r);
    return _decodeList(r.body, Colloquium.fromJson);
  }

  Future<int> insertColloquium(Colloquium c) async {
    final r = await http.post(
      _u('/api/colloquiums'),
      headers: await _headers(jsonBody: true),
      body: jsonEncode(c.toJson()),
    );
    await _ensureOk(r, ok: const [201]);
    final created = Colloquium.fromJson(jsonDecode(r.body) as Map<String, dynamic>);
    return created.id;
  }

  Future<void> updateColloquium(Colloquium c) async {
    final r = await http.put(
      _u('/api/colloquiums/${c.id}'),
      headers: await _headers(jsonBody: true),
      body: jsonEncode(c.toJson()),
    );
    await _ensureOk(r);
  }

  Future<void> deleteColloquium(int id) async {
    final r = await http.delete(_u('/api/colloquiums/$id'), headers: await _headers());
    await _ensureOk(r, ok: const [204]);
  }

  // --- Attendance ---
  Future<Attendance?> getAttendanceForSubject(int subjectId) async {
    final r = await http.get(_u('/api/attendance/by-subject/$subjectId'), headers: await _headers());
    if (r.statusCode == 404) {
      return null;
    }
    await _ensureOk(r);
    return Attendance.fromJson(jsonDecode(r.body) as Map<String, dynamic>);
  }

  Future<void> upsertAttendance(Attendance a) async {
    final r = await http.put(
      _u('/api/attendance'),
      headers: await _headers(jsonBody: true),
      body: jsonEncode(a.toJson()),
    );
    await _ensureOk(r);
  }

  Future<void> deleteAttendance(int id) async {
    final r = await http.delete(_u('/api/attendance/$id'), headers: await _headers());
    await _ensureOk(r, ok: const [204]);
  }

  // --- Homework ---
  Future<List<Homework>> getHomeworks() async {
    final r = await http.get(_u('/api/homework'), headers: await _headers());
    await _ensureOk(r);
    return _decodeList(r.body, Homework.fromJson);
  }

  Future<int> insertHomework(Homework h) async {
    final r = await http.post(
      _u('/api/homework'),
      headers: await _headers(jsonBody: true),
      body: jsonEncode(h.toJson()),
    );
    await _ensureOk(r, ok: const [201]);
    final created = Homework.fromJson(jsonDecode(r.body) as Map<String, dynamic>);
    return created.id;
  }

  Future<void> updateHomework(Homework h) async {
    final r = await http.put(
      _u('/api/homework/${h.id}'),
      headers: await _headers(jsonBody: true),
      body: jsonEncode(h.toJson()),
    );
    await _ensureOk(r);
  }

  Future<void> deleteHomework(int id) async {
    final r = await http.delete(_u('/api/homework/$id'), headers: await _headers());
    await _ensureOk(r, ok: const [204]);
  }

  // --- Exams ---
  Future<List<Exam>> getUpcomingExams() async {
    final r = await http.get(_u('/api/exams/upcoming'), headers: await _headers());
    await _ensureOk(r);
    return _decodeList(r.body, Exam.fromJson);
  }

  Future<List<Exam>> getAllExams() async {
    final r = await http.get(_u('/api/exams'), headers: await _headers());
    await _ensureOk(r);
    return _decodeList(r.body, Exam.fromJson);
  }

  Future<int> insertExam(Exam e) async {
    final r = await http.post(
      _u('/api/exams'),
      headers: await _headers(jsonBody: true),
      body: jsonEncode(e.toJson()),
    );
    await _ensureOk(r, ok: const [201]);
    final created = Exam.fromJson(jsonDecode(r.body) as Map<String, dynamic>);
    return created.id;
  }

  Future<void> updateExam(Exam e) async {
    final r = await http.put(
      _u('/api/exams/${e.id}'),
      headers: await _headers(jsonBody: true),
      body: jsonEncode(e.toJson()),
    );
    await _ensureOk(r);
  }

  Future<void> deleteExam(int id) async {
    final r = await http.delete(_u('/api/exams/$id'), headers: await _headers());
    await _ensureOk(r, ok: const [204]);
  }

  Future<ProgressSummary> computeProgress() async {
    final r = await http.get(_u('/api/progress'), headers: await _headers());
    await _ensureOk(r);
    return ProgressSummary.fromJson(jsonDecode(r.body) as Map<String, dynamic>);
  }

  Future<List<StudentProgressSubject>> studentProgressSubjects() async {
    final r = await http.get(_u('/api/student/progress/subjects'), headers: await _headers());
    await _ensureOk(r);
    return _decodeList(r.body, StudentProgressSubject.fromJson);
  }

  Future<StudentProgressSummary> studentProgressSummary() async {
    final r = await http.get(_u('/api/student/progress/summary'), headers: await _headers());
    await _ensureOk(r);
    return StudentProgressSummary.fromJson(jsonDecode(r.body) as Map<String, dynamic>);
  }

  Future<void> updateStudentSubjectResult({
    required int catalogSubjectId,
    required bool passed,
    int? grade,
    String? passedInPeriod,
  }) async {
    final r = await http.put(
      _u('/api/student/progress/subjects/$catalogSubjectId/result'),
      headers: await _headers(jsonBody: true),
      body: jsonEncode({
        'passed': passed,
        'grade': grade,
        'passedInPeriod': passedInPeriod,
      }),
    );
    await _ensureOk(r, ok: const [200, 204]);
  }

  Future<List<PortalHomeworkRow>> studentCurrentHomework() async {
    final r = await http.get(_u('/api/student/homework'), headers: await _headers());
    await _ensureOk(r);
    return _decodeList(r.body, PortalHomeworkRow.fromJson);
  }

  Future<void> setStudentCurrentHomeworkCompleted(int assignmentId, bool completed) async {
    final r = await http.patch(
      _u('/api/student/homework/$assignmentId/complete'),
      headers: await _headers(jsonBody: true),
      body: jsonEncode({'completed': completed}),
    );
    await _ensureOk(r, ok: const [200, 204]);
  }

  Future<Map<int, String>> subjectNameMap() async {
    final list = await getSubjects();
    return {for (final s in list) s.id: s.name};
  }
}
