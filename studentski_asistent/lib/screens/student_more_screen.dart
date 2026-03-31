import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../auth/auth_controller.dart';
import '../data/student_repository.dart';
import 'obligations_screen.dart';
import 'progress_screen.dart';
import 'schedule_screen.dart';

class StudentMoreScreen extends StatelessWidget {
  const StudentMoreScreen({super.key, required this.repo});

  final StudentRepository repo;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dodatno'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => context.read<AuthController>().logout(),
          ),
        ],
      ),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.calendar_month),
            title: const Text('Raspored (lični)'),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => ScheduleScreen(repo: repo)),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.fact_check),
            title: const Text('Obaveze (lične)'),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => ObligationsScreen(repo: repo)),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.school),
            title: const Text('Progres (lični)'),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => ProgressScreen(repo: repo)),
            ),
          ),
        ],
      ),
    );
  }
}
