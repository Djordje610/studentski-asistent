import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:studentski_asistent/data/academy_repository.dart';

void main() {
  const base = 'http://test.local';

  group('AcademyRepository (mock HTTP)', () {
    test('adminListStudentProfiles — GET /api/admin/student-profiles i parsiranje', () async {
      final payload = [
        {
          'userId': 10,
          'fullName': 'Petar Petrović',
          'studyProgram': {'id': 1, 'code': 'RTSI', 'name': 'RTSI'},
          'programYear': {
            'id': 2,
            'yearNumber': 1,
            'studyProgram': {'id': 1, 'code': 'RTSI', 'name': 'RTSI'},
          },
        },
      ];
      final client = MockClient((request) async {
        expect(request.method, 'GET');
        expect(request.url.toString(), '$base/api/admin/student-profiles');
        expect(request.headers['Authorization'], 'Bearer admin-jwt');
        final body = jsonEncode(payload);
        return http.Response.bytes(
          utf8.encode(body),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });

      final repo = AcademyRepository(
        baseUrl: base,
        getToken: () async => 'admin-jwt',
        httpClient: client,
      );

      final list = await repo.adminListStudentProfiles();
      expect(list, hasLength(1));
      expect(list.first.userId, 10);
      expect(list.first.fullName, 'Petar Petrović');
      expect(list.first.programCode, 'RTSI');
      expect(list.first.displayTitle, 'Student: Petar Petrović');
    });

    test('adminListPrograms — lista smerova', () async {
      final client = MockClient((request) async {
        expect(request.url.path, '/api/admin/study-programs');
        return http.Response(
          jsonEncode([
            {'id': 1, 'code': 'A', 'name': 'Smer A'},
          ]),
          200,
        );
      });

      final repo = AcademyRepository(
        baseUrl: base,
        getToken: () async => 't',
        httpClient: client,
      );

      final programs = await repo.adminListPrograms();
      expect(programs.single.code, 'A');
      expect(programs.single.name, 'Smer A');
    });

    test('studentCatalogSubjects — student portal', () async {
      final client = MockClient((request) async {
        expect(request.url.path, '/api/student/catalog-subjects');
        return http.Response(
          jsonEncode([
            {
              'id': 1,
              'code': 'P1',
              'name': 'Predmet',
              'espb': 6,
              'programYearId': 2,
              'programCode': 'RTSI',
              'yearNumber': 1,
            },
          ]),
          200,
        );
      });

      final repo = AcademyRepository(
        baseUrl: base,
        getToken: () async => 'student-token',
        httpClient: client,
      );

      final rows = await repo.studentCatalogSubjects();
      expect(rows.single.name, 'Predmet');
      expect(rows.single.programCode, 'RTSI');
    });

    test('API greška — baca Exception sa statusom', () async {
      final client = MockClient((request) async => http.Response('fail', 500));

      final repo = AcademyRepository(
        baseUrl: base,
        getToken: () async => 't',
        httpClient: client,
      );

      expect(
        () => repo.adminListPrograms(),
        throwsA(isA<Exception>().having((e) => e.toString(), 'message', contains('500'))),
      );
    });

    test('bez tokena — nema Authorization headera', () async {
      final client = MockClient((request) async {
        expect(request.headers.containsKey('Authorization'), false);
        return http.Response('[]', 200);
      });

      final repo = AcademyRepository(
        baseUrl: base,
        getToken: () async => null,
        httpClient: client,
      );

      await repo.adminListPrograms();
    });

    test('adminCreateStudent — POST telo i CreatedStudent odgovor', () async {
      final client = MockClient((request) async {
        expect(request.method, 'POST');
        expect(request.url.path, '/api/admin/students');
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['email'], 'novi@student.rs');
        expect(body['fullName'], 'Novi Student');
        expect(body['programYearId'], 3);
        return http.Response(
          jsonEncode({'userId': 99, 'email': 'novi@student.rs'}),
          201,
        );
      });

      final repo = AcademyRepository(
        baseUrl: base,
        getToken: () async => 'jwt',
        httpClient: client,
      );

      final created = await repo.adminCreateStudent(
        email: 'novi@student.rs',
        password: 'secret',
        fullName: 'Novi Student',
        programYearId: 3,
      );
      expect(created.userId, 99);
      expect(created.email, 'novi@student.rs');
    });
  });
}
