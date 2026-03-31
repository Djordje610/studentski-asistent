import 'package:flutter_test/flutter_test.dart';
import 'package:studentski_asistent/models/academy_admin.dart';
import 'package:studentski_asistent/models/academy_portal.dart';

void main() {
  group('StudentProfileAdmin', () {
    test('fromJson mapira API odgovor (nested studyProgram / programYear)', () {
      final p = StudentProfileAdmin.fromJson({
        'userId': 42,
        'fullName': 'Ana Anić',
        'studyProgram': {'id': 1, 'code': 'RTSI', 'name': 'Računarska tehnika'},
        'programYear': {
          'id': 7,
          'yearNumber': 2,
          'studyProgram': {'id': 1, 'code': 'RTSI', 'name': 'Računarska tehnika'},
        },
      });
      expect(p.userId, 42);
      expect(p.fullName, 'Ana Anić');
      expect(p.programCode, 'RTSI');
      expect(p.programName, 'Računarska tehnika');
      expect(p.yearNumber, 2);
      expect(p.programYearId, 7);
    });

    test('displayTitle koristi fullName kada postoji', () {
      final p = StudentProfileAdmin.fromJson({
        'userId': 1,
        'fullName': 'Marko Marković',
        'studyProgram': {'id': 1, 'code': 'X', 'name': 'Smer'},
        'programYear': {'id': 2, 'yearNumber': 1, 'studyProgram': {'id': 1}},
      });
      expect(p.displayTitle, 'Student: Marko Marković');
    });

    test('displayTitle bez imena — samo Student', () {
      final p = StudentProfileAdmin.fromJson({
        'userId': 1,
        'studyProgram': {'id': 1, 'code': 'X', 'name': 'Smer'},
        'programYear': {'id': 2, 'yearNumber': 1, 'studyProgram': {'id': 1}},
      });
      expect(p.fullName, isNull);
      expect(p.displayTitle, 'Student');
    });
  });

  group('StudyProgram / ProgramYear', () {
    test('StudyProgram.fromJson', () {
      final sp = StudyProgram.fromJson({'id': 5, 'code': 'SI', 'name': 'Softver'});
      expect(sp.id, 5);
      expect(sp.code, 'SI');
      expect(sp.name, 'Softver');
    });

    test('ProgramYear.fromJson sa nested studyProgram', () {
      final py = ProgramYear.fromJson({
        'id': 9,
        'yearNumber': 3,
        'studyProgram': {'id': 2, 'code': 'A', 'name': 'B'},
      });
      expect(py.id, 9);
      expect(py.yearNumber, 3);
      expect(py.studyProgramId, 2);
    });
  });

  group('CreatedStudent', () {
    test('fromJson', () {
      final c = CreatedStudent.fromJson({'userId': 100, 'email': 'a@b.rs'});
      expect(c.userId, 100);
      expect(c.email, 'a@b.rs');
    });
  });

  group('Portal modeli', () {
    test('CatalogSubjectRow.fromJson', () {
      final row = CatalogSubjectRow.fromJson({
        'id': 1,
        'code': 'P1',
        'name': 'Programiranje',
        'espb': 6,
        'programYearId': 3,
        'programCode': 'RTSI',
        'yearNumber': 1,
      });
      expect(row.name, 'Programiranje');
      expect(row.programCode, 'RTSI');
      expect(row.yearNumber, 1);
    });

    test('PortalHomeworkRow.fromJson — completed podrazumevano false', () {
      final h = PortalHomeworkRow.fromJson({
        'assignmentId': 1,
        'title': 'Zadatak',
        'catalogSubjectId': 2,
        'subjectName': 'Predmet',
      });
      expect(h.completed, false);
    });
  });
}
