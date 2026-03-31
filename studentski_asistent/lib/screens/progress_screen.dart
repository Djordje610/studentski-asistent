import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../auth/auth_controller.dart';
import '../data/student_repository.dart';
import '../models/student_progress.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key, required this.repo});

  final StudentRepository repo;

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  bool _loading = true;
  StudentProgressSummary? _summary;
  List<StudentProgressSubject> _subjects = [];

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final s = await widget.repo.studentProgressSubjects();
      final p = await widget.repo.studentProgressSummary();
      setState(() {
        _subjects = s;
        _summary = p;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _editProgress(StudentProgressSubject s) async {
    bool passed = s.passed;
    int grade = s.grade ?? 6;
    final periodCtrl = TextEditingController(text: s.passedInPeriod ?? '');

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) => AlertDialog(
          title: Text(s.name),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: passed,
                  title: const Text('Predmet je polozen'),
                  onChanged: (v) => setSt(() => passed = v ?? false),
                ),
                if (passed) ...[
                  DropdownButtonFormField<int>(
                    initialValue: grade,
                    decoration: const InputDecoration(labelText: 'Ocena'),
                    items: List.generate(
                      5,
                      (i) => DropdownMenuItem(value: i + 6, child: Text('${i + 6}')),
                    ),
                    onChanged: (v) => grade = v ?? 6,
                  ),
                  TextField(
                    controller: periodCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Ispitni rok',
                      hintText: 'npr. Jun 2026',
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Otkazi')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Sacuvaj')),
          ],
        ),
      ),
    );

    if (ok != true || !mounted) {
      return;
    }

    try {
      await widget.repo.updateStudentSubjectResult(
        catalogSubjectId: s.catalogSubjectId,
        passed: passed,
        grade: passed ? grade : null,
        passedInPeriod: passed ? periodCtrl.text.trim() : null,
      );
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Akademski progres'),
        actions: [
          IconButton(
            tooltip: 'Odjavi se',
            icon: const Icon(Icons.logout),
            onPressed: () => context.read<AuthController>().logout(),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (_summary != null) ...[
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Pregled', style: theme.textTheme.titleMedium),
                            const SizedBox(height: 8),
                            Text(
                              'Ukupno ESPB (godina): ${_summary!.totalEspb}',
                              style: theme.textTheme.bodyLarge,
                            ),
                            Text('Trenutno osvojeni ESPB: ${_summary!.earnedEspb}'),
                            const SizedBox(height: 8),
                            Text(
                              'Prosek (ponderisan): ${_summary!.weightedAverage != null ? _summary!.weightedAverage!.toStringAsFixed(2) : '-'}',
                              style: theme.textTheme.titleMedium,
                            ),
                            Text('Polozeni predmeti: ${_summary!.passedCount}'),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  Text('Predmeti sa godine', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 8),
                  ..._subjects.map(
                    (s) => Card(
                      child: ListTile(
                        title: Text(s.name),
                        subtitle: Text(
                          '${s.espb} ESPB'
                          '${s.passed ? ' - polozen${s.grade != null ? ' (ocena ${s.grade})' : ''}' : ' - nije polozen'}'
                          '${s.passedInPeriod != null && s.passedInPeriod!.isNotEmpty ? ' - rok: ${s.passedInPeriod}' : ''}',
                        ),
                        trailing: Checkbox(
                          value: s.passed,
                          onChanged: (_) => _editProgress(s),
                        ),
                        onTap: () => _editProgress(s),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
