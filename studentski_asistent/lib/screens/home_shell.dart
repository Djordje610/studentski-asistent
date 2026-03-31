import 'package:flutter/material.dart';

import '../data/student_repository.dart';
import 'exams_screen.dart';
import 'obligations_screen.dart';
import 'progress_screen.dart';
import 'schedule_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key, required this.repo});

  final StudentRepository repo;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final repo = widget.repo;
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: [
          ScheduleScreen(repo: repo),
          ObligationsScreen(repo: repo),
          ProgressScreen(repo: repo),
          ExamsScreen(repo: repo),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month),
            label: 'Raspored',
          ),
          NavigationDestination(
            icon: Icon(Icons.fact_check_outlined),
            selectedIcon: Icon(Icons.fact_check),
            label: 'Obaveze',
          ),
          NavigationDestination(
            icon: Icon(Icons.school_outlined),
            selectedIcon: Icon(Icons.school),
            label: 'Progres',
          ),
          NavigationDestination(
            icon: Icon(Icons.event_note_outlined),
            selectedIcon: Icon(Icons.event_note),
            label: 'Ispiti',
          ),
        ],
      ),
    );
  }
}
