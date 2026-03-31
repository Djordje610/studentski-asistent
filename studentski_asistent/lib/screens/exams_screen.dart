import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../data/student_repository.dart';
import '../models/exam.dart';
import '../models/subject.dart';

class ExamsScreen extends StatefulWidget {
  const ExamsScreen({super.key, required this.repo});

  final StudentRepository repo;

  @override
  State<ExamsScreen> createState() => _ExamsScreenState();
}

class _ExamsScreenState extends State<ExamsScreen> {
  List<Exam> _exams = [];
  Map<int, String> _names = {};
  bool _loading = true;
  StreamSubscription<void>? _tick;

  @override
  void initState() {
    super.initState();
    _load();
    _tick = Stream.periodic(const Duration(seconds: 1)).listen((_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final e = await widget.repo.getUpcomingExams();
      final n = await widget.repo.subjectNameMap();
      setState(() {
        _exams = e;
        _names = n;
        _loading = false;
      });
    } catch (err) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$err')));
      }
    }
  }

  static String _countdown(int examMs) {
    final now = DateTime.now();
    final target = DateTime.fromMillisecondsSinceEpoch(examMs);
    if (!target.isAfter(now)) {
      return 'Danas / prošlo';
    }
    var diff = target.difference(now);
    final days = diff.inDays;
    diff = diff - Duration(days: days);
    final h = diff.inHours;
    diff = diff - Duration(hours: h);
    final m = diff.inMinutes;
    diff = diff - Duration(minutes: m);
    final s = diff.inSeconds;
    if (days > 0) {
      return '$days d $h h $m min $s s';
    }
    if (h > 0) {
      return '$h h $m min $s s';
    }
    if (m > 0) {
      return '$m min $s s';
    }
    return '$s s';
  }

  Future<void> _edit({Exam? exam, required List<Subject> subjects}) async {
    final titleCtrl = TextEditingController(text: exam?.title ?? '');
    final locCtrl = TextEditingController(text: exam?.location ?? '');
    final notesCtrl = TextEditingController(text: exam?.notes ?? '');
    int? sid = exam?.subjectId;
    var dt = exam != null
        ? DateTime.fromMillisecondsSinceEpoch(exam.examMs)
        : DateTime.now().add(const Duration(days: 7));

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setLocal) {
          return AlertDialog(
            title: Text(exam == null ? 'Novi ispit' : 'Izmeni ispit'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleCtrl,
                    decoration: const InputDecoration(labelText: 'Naziv / predmet ispita'),
                  ),
                  DropdownButtonFormField<int?>(
                    key: ValueKey(sid),
                    initialValue: sid,
                    decoration: const InputDecoration(labelText: 'Povezani predmet (opciono)'),
                    items: [
                      const DropdownMenuItem<int?>(value: null, child: Text('—')),
                      ...subjects.map(
                        (s) => DropdownMenuItem<int?>(value: s.id, child: Text(s.name)),
                      ),
                    ],
                    onChanged: (v) => setLocal(() => sid = v),
                  ),
                  ListTile(
                    title: const Text('Datum i vreme'),
                    subtitle: Text(DateFormat.yMMMd().add_Hm().format(dt)),
                    onTap: () async {
                      final d = await showDatePicker(
                        context: ctx,
                        initialDate: dt,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2100),
                      );
                      if (d == null) {
                        return;
                      }
                      if (!ctx.mounted) {
                        return;
                      }
                      final t = await showTimePicker(
                        context: ctx,
                        initialTime: TimeOfDay.fromDateTime(dt),
                      );
                      if (t != null) {
                        setLocal(() {
                          dt = DateTime(d.year, d.month, d.day, t.hour, t.minute);
                        });
                      }
                    },
                  ),
                  TextField(
                    controller: locCtrl,
                    decoration: const InputDecoration(labelText: 'Mesto (opciono)'),
                  ),
                  TextField(
                    controller: notesCtrl,
                    decoration: const InputDecoration(labelText: 'Napomena'),
                    maxLines: 2,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Otkaži')),
              FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Sačuvaj')),
            ],
          );
        },
      ),
    );

    if (ok != true || !mounted) {
      return;
    }

    final model = Exam(
      id: exam?.id ?? 0,
      subjectId: sid,
      title: titleCtrl.text.trim().isEmpty ? 'Ispit' : titleCtrl.text.trim(),
      examMs: dt.millisecondsSinceEpoch,
      location: locCtrl.text.trim().isEmpty ? null : locCtrl.text.trim(),
      notes: notesCtrl.text.trim().isEmpty ? null : notesCtrl.text.trim(),
    );

    try {
      if (exam == null) {
        await widget.repo.insertExam(model);
      } else {
        await widget.repo.updateExam(model);
      }
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Planer ispita')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: FutureBuilder<List<Subject>>(
                future: widget.repo.getSubjects(),
                builder: (context, snap) {
                  final subjects = snap.data ?? [];
                  if (_exams.isEmpty) {
                    return ListView(
                      children: [
                        const SizedBox(height: 48),
                        Center(
                          child: Text(
                            'Nema predstojećih ispita.\nDodaj ispit ili pokreni backend.',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        ),
                      ],
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _exams.length,
                    itemBuilder: (context, i) {
                      final e = _exams[i];
                      final sub = e.subjectId != null ? _names[e.subjectId!] : null;
                      final when = DateTime.fromMillisecondsSinceEpoch(e.examMs);
                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      e.title,
                                      style: Theme.of(context).textTheme.titleMedium,
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.edit_outlined),
                                    onPressed: () => _edit(exam: e, subjects: subjects),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline),
                                    onPressed: () async {
                                      await widget.repo.deleteExam(e.id);
                                      await _load();
                                    },
                                  ),
                                ],
                              ),
                              if (sub != null) Text(sub),
                              Text(DateFormat.yMMMEd().add_Hm().format(when)),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.primaryContainer,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.timer_outlined,
                                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Preostalo: ${_countdown(e.examMs)}',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (e.location != null && e.location!.isNotEmpty)
                                Text('Mesto: ${e.location}'),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final subjects = await widget.repo.getSubjects();
          if (!mounted) {
            return;
          }
          await _edit(subjects: subjects);
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
