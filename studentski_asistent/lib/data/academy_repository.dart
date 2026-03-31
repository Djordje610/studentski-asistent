import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/academy_admin.dart';
import '../models/academy_portal.dart';

typedef TokenGetter = Future<String?> Function();

class AcademyRepository {
  AcademyRepository({
    String? baseUrl,
    required this.getToken,
    http.Client? httpClient,
  })  : _base = baseUrl ?? resolveGatewayUrl(),
        _http = httpClient ?? http.Client();

  final String _base;
  final http.Client _http;
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
      throw Exception(_buildApiErrorMessage(r));
    }
  }

  String _buildApiErrorMessage(http.Response r) {
    String? message;
    String? path;
    try {
      if (r.body.isNotEmpty) {
        final decoded = jsonDecode(r.body);
        if (decoded is Map<String, dynamic>) {
          final rawMessage = decoded['message'];
          final rawError = decoded['error'];
          final rawPath = decoded['path'];
          if (rawPath is String && rawPath.isNotEmpty) {
            path = rawPath;
          }
          if (rawMessage is String && rawMessage.isNotEmpty) {
            message = rawMessage;
          } else if (rawError is String && rawError.isNotEmpty) {
            message = rawError;
          }
        }
      }
    } catch (_) {
      // Ako body nije JSON, koristi fallback ispod.
    }

    if (message?.isEmpty ?? true) {
      if (r.statusCode == 400 && path == '/api/student/exam-registrations') {
        message = 'Ispitni rok nije aktivan ili ponuda nije validna.';
      } else if (r.statusCode == 401) {
        message = 'Niste prijavljeni. Ulogujte se ponovo.';
      } else if (r.statusCode == 403) {
        message = 'Nemate dozvolu za ovu akciju.';
      } else if (r.statusCode >= 500) {
        message = 'Greška na serveru. Pokušajte ponovo.';
      } else {
        message = 'Došlo je do greške.';
      }
    }

    return 'API greška ${r.statusCode}: $message';
  }

  List<T> _decodeList<T>(String body, T Function(Map<String, dynamic>) fromJson) {
    final list = jsonDecode(body) as List<dynamic>;
    return list.map((e) => fromJson(e as Map<String, dynamic>)).toList();
  }

  // --- Student portal ---

  Future<List<CatalogSubjectRow>> studentCatalogSubjects() async {
    final r = await _http.get(_u('/api/student/catalog-subjects'), headers: await _headers());
    await _ensureOk(r);
    return _decodeList(r.body, CatalogSubjectRow.fromJson);
  }

  Future<List<PortalHomeworkRow>> studentHomework() async {
    final r = await _http.get(_u('/api/student/homework'), headers: await _headers());
    await _ensureOk(r);
    return _decodeList(r.body, PortalHomeworkRow.fromJson);
  }

  Future<void> setHomeworkCompleted(int assignmentId, bool completed) async {
    final r = await _http.patch(
      _u('/api/student/homework/$assignmentId/complete'),
      headers: await _headers(jsonBody: true),
      body: jsonEncode({'completed': completed}),
    );
    await _ensureOk(r, ok: const [200, 204]);
  }

  Future<List<ExamOffer>> studentExamOffers() async {
    final r = await _http.get(_u('/api/student/exam-offers'), headers: await _headers());
    await _ensureOk(r);
    return _decodeList(r.body, ExamOffer.fromJson);
  }

  Future<void> registerExam(int offeringId) async {
    final r = await _http.post(
      _u('/api/student/exam-registrations'),
      headers: await _headers(jsonBody: true),
      body: jsonEncode({'offeringId': offeringId}),
    );
    await _ensureOk(r, ok: const [200, 201, 204]);
  }

  Future<List<MyRegisteredExam>> studentMyExams() async {
    final r = await _http.get(_u('/api/student/my-exams'), headers: await _headers());
    await _ensureOk(r);
    return _decodeList(r.body, MyRegisteredExam.fromJson);
  }

  // --- Admin ---

  Future<List<StudyProgram>> adminListPrograms() async {
    final r = await _http.get(_u('/api/admin/study-programs'), headers: await _headers());
    await _ensureOk(r);
    return _decodeList(r.body, StudyProgram.fromJson);
  }

  Future<void> adminCreateProgram({required String code, required String name}) async {
    final r = await _http.post(
      _u('/api/admin/study-programs'),
      headers: await _headers(jsonBody: true),
      body: jsonEncode({'code': code, 'name': name}),
    );
    await _ensureOk(r, ok: const [201]);
  }

  Future<List<ProgramYear>> adminListProgramYears(int studyProgramId) async {
    final r = await _http.get(
      _u('/api/admin/program-years?studyProgramId=$studyProgramId'),
      headers: await _headers(),
    );
    await _ensureOk(r);
    return _decodeList(r.body, ProgramYear.fromJson);
  }

  Future<void> adminCreateProgramYear({required int studyProgramId, required int yearNumber}) async {
    final r = await _http.post(
      _u('/api/admin/program-years'),
      headers: await _headers(jsonBody: true),
      body: jsonEncode({'studyProgramId': studyProgramId, 'yearNumber': yearNumber}),
    );
    await _ensureOk(r, ok: const [201]);
  }

  Future<List<CatalogSubjectAdmin>> adminListCatalogSubjects(int programYearId) async {
    final r = await _http.get(
      _u('/api/admin/catalog-subjects?programYearId=$programYearId'),
      headers: await _headers(),
    );
    await _ensureOk(r);
    return _decodeList(r.body, CatalogSubjectAdmin.fromJson);
  }

  Future<void> adminCreateCatalogSubject({
    required int programYearId,
    String? code,
    required String name,
    required int espb,
  }) async {
    final r = await _http.post(
      _u('/api/admin/catalog-subjects'),
      headers: await _headers(jsonBody: true),
      body: jsonEncode({
        'programYearId': programYearId,
        if (code != null && code.isNotEmpty) 'code': code,
        'name': name,
        'espb': espb,
      }),
    );
    await _ensureOk(r, ok: const [201]);
  }

  Future<void> adminDeleteCatalogSubject(int id) async {
    final r = await _http.delete(_u('/api/admin/catalog-subjects/$id'), headers: await _headers());
    await _ensureOk(r, ok: const [204]);
  }

  Future<List<ExamPeriodAdmin>> adminListExamPeriods() async {
    final r = await _http.get(_u('/api/admin/exam-periods'), headers: await _headers());
    await _ensureOk(r);
    return _decodeList(r.body, ExamPeriodAdmin.fromJson);
  }

  Future<void> adminCreateExamPeriod({
    required String name,
    required int startMs,
    required int endMs,
  }) async {
    final r = await _http.post(
      _u('/api/admin/exam-periods'),
      headers: await _headers(jsonBody: true),
      body: jsonEncode({'name': name, 'startMs': startMs, 'endMs': endMs}),
    );
    await _ensureOk(r, ok: const [201]);
  }

  Future<void> adminActivateExamPeriod(int id) async {
    final r = await _http.patch(
      _u('/api/admin/exam-periods/$id/activate'),
      headers: await _headers(jsonBody: true),
      body: '{}',
    );
    await _ensureOk(r, ok: const [200]);
  }

  Future<void> adminCreateExamOffering({
    required int examPeriodId,
    required int catalogSubjectId,
    required int examMs,
    String? location,
  }) async {
    final r = await _http.post(
      _u('/api/admin/exam-offerings'),
      headers: await _headers(jsonBody: true),
      body: jsonEncode({
        'examPeriodId': examPeriodId,
        'catalogSubjectId': catalogSubjectId,
        'examMs': examMs,
        if (location != null && location.isNotEmpty) 'location': location,
      }),
    );
    await _ensureOk(r, ok: const [201]);
  }

  Future<List<ExamOfferingAdmin>> adminListExamOfferings(int examPeriodId) async {
    final r = await _http.get(
      _u('/api/admin/exam-offerings?examPeriodId=$examPeriodId'),
      headers: await _headers(),
    );
    await _ensureOk(r);
    return _decodeList(r.body, ExamOfferingAdmin.fromJson);
  }

  Future<void> adminDeleteExamOffering(int id) async {
    final r = await _http.delete(_u('/api/admin/exam-offerings/$id'), headers: await _headers());
    await _ensureOk(r, ok: const [204]);
  }

  Future<List<HomeworkAssignmentAdmin>> adminListHomeworkAssignments(int catalogSubjectId) async {
    final r = await _http.get(
      _u('/api/admin/homework-assignments?catalogSubjectId=$catalogSubjectId'),
      headers: await _headers(),
    );
    await _ensureOk(r);
    return _decodeList(r.body, HomeworkAssignmentAdmin.fromJson);
  }

  Future<void> adminCreateHomework({
    required int catalogSubjectId,
    required String title,
    String? description,
    int? dueDateMs,
  }) async {
    final r = await _http.post(
      _u('/api/admin/homework-assignments'),
      headers: await _headers(jsonBody: true),
      body: jsonEncode({
        'catalogSubjectId': catalogSubjectId,
        'title': title,
        if (description != null && description.isNotEmpty) 'description': description,
        'dueDateMs': ?dueDateMs,
      }),
    );
    await _ensureOk(r, ok: const [201]);
  }

  Future<void> adminDeleteHomeworkAssignment(int id) async {
    final r = await _http.delete(_u('/api/admin/homework-assignments/$id'), headers: await _headers());
    await _ensureOk(r, ok: const [204]);
  }

  Future<CreatedStudent> adminCreateStudent({
    required String email,
    required String password,
    required String fullName,
    String? studentIndex,
    required int programYearId,
  }) async {
    final r = await _http.post(
      _u('/api/admin/students'),
      headers: await _headers(jsonBody: true),
      body: jsonEncode({
        'email': email,
        'password': password,
        'fullName': fullName,
        if (studentIndex != null && studentIndex.isNotEmpty) 'studentIndex': studentIndex,
        'programYearId': programYearId,
      }),
    );
    await _ensureOk(r, ok: const [201]);
    return CreatedStudent.fromJson(jsonDecode(r.body) as Map<String, dynamic>);
  }

  Future<List<StudentProfileAdmin>> adminListStudentProfiles() async {
    final r = await _http.get(_u('/api/admin/student-profiles'), headers: await _headers());
    await _ensureOk(r);
    return _decodeList(r.body, StudentProfileAdmin.fromJson);
  }

  Future<void> adminUpdateStudentProfile({required int userId, required int programYearId}) async {
    final r = await _http.put(
      _u('/api/admin/student-profiles/$userId'),
      headers: await _headers(jsonBody: true),
      body: jsonEncode({'programYearId': programYearId}),
    );
    await _ensureOk(r, ok: const [200]);
  }
}
