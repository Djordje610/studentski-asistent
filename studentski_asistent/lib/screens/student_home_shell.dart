import 'package:flutter/material.dart';

import '../config/api_config.dart';
import '../data/academy_repository.dart';
import '../data/student_repository.dart';
import 'catalog_subjects_screen.dart';
import 'portal_homework_screen.dart';
import 'student_exams_portal_screen.dart';
import 'student_more_screen.dart';

class StudentHomeShell extends StatefulWidget {
  const StudentHomeShell({
    super.key,
    required this.repo,
    required this.getToken,
  });

  final StudentRepository repo;
  final Future<String?> Function() getToken;

  @override
  State<StudentHomeShell> createState() => _StudentHomeShellState();
}

class _StudentHomeShellState extends State<StudentHomeShell> {
  late final AcademyRepository _academy;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _academy = AcademyRepository(
      baseUrl: resolveGatewayUrl(),
      getToken: widget.getToken,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: [
          CatalogSubjectsScreen(repo: _academy),
          PortalHomeworkScreen(repo: _academy),
          StudentExamsPortalScreen(repo: _academy),
          StudentMoreScreen(repo: widget.repo),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.menu_book_outlined),
            selectedIcon: Icon(Icons.menu_book),
            label: 'Predmeti',
          ),
          NavigationDestination(
            icon: Icon(Icons.assignment_outlined),
            selectedIcon: Icon(Icons.assignment),
            label: 'Domaći',
          ),
          NavigationDestination(
            icon: Icon(Icons.event_available_outlined),
            selectedIcon: Icon(Icons.event_available),
            label: 'Ispiti',
          ),
          NavigationDestination(
            icon: Icon(Icons.more_horiz),
            selectedIcon: Icon(Icons.more_horiz),
            label: 'Više',
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    // IndexedStack gradi sve tabove odjednom; ovde prikazujemo samo aktivnu tab stranicu
    // da bismo izbegli pad aplikacije zbog grešaka u nevidljivim ekranima.
    switch (_index) {
      case 0:
        return CatalogSubjectsScreen(repo: _academy);
      case 1:
        return PortalHomeworkScreen(repo: _academy);
      case 2:
        return StudentExamsPortalScreen(repo: _academy);
      default:
        return StudentMoreScreen(repo: widget.repo);
    }
  }
}
