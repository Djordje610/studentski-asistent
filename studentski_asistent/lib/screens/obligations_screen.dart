import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../data/student_repository.dart';
import '../models/academy_portal.dart';
import '../models/attendance.dart';
import '../models/colloquium.dart';
import '../models/subject.dart';

class ObligationsScreen extends StatefulWidget {
  const ObligationsScreen({super.key, required this.repo});

  final StudentRepository repo;

  @override
  State<ObligationsScreen> createState() => _ObligationsScreenState();
}

class _ObligationsScreenState extends State<ObligationsScreen> with SingleTickerProviderStateMixin {
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Predispitne obaveze'),
        bottom: TabBar(
          controller: _tab,
          tabs: const [
            Tab(text: 'Kolokvijumi'),
            Tab(text: 'Domaći'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: [
          _ColloquiumsTab(repo: widget.repo),
          _HomeworkTab(repo: widget.repo),
        ],
      ),
    );
  }
}

class _ColloquiumsTab extends StatefulWidget {
  const _ColloquiumsTab({required this.repo});

  final StudentRepository repo;

  @override
  State<_ColloquiumsTab> createState() => _ColloquiumsTabState();
}

class _ColloquiumsTabState extends State<_ColloquiumsTab> {
  List<Colloquium> _list = [];
  Map<int, String> _names = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final c = await widget.repo.getColloquiums();
      final n = await widget.repo.subjectNameMap();
      setState(() {
        _list = c;
        _names = n;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  Future<void> _edit({Colloquium? item, required List<Subject> subjects}) async {
    if (subjects.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Prvo dodaj predmet u kartici Progres.')),
        );
      }
      return;
    }

    final titleCtrl = TextEditingController(text: item?.title ?? '');
    final maxCtrl = TextEditingController(text: item?.maxPoints.toString() ?? '100');
    final ptsCtrl = TextEditingController(text: item?.points.toString() ?? '0');
    var sid = item?.subjectId ?? subjects.first.id;
    DateTime? date = item?.dateMs != null
        ? DateTime.fromMillisecondsSinceEpoch(item!.dateMs!)
        : null;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setLocal) {
          return AlertDialog(
            title: Text(item == null ? 'Novi kolokvijum' : 'Izmena kolokvijuma'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<int>(
                    key: ValueKey(sid),
                    initialValue: sid,
                    decoration: const InputDecoration(labelText: 'Predmet'),
                    items: subjects
                        .map((s) => DropdownMenuItem(value: s.id, child: Text(s.name)))
                        .toList(),
                    onChanged: (v) => setLocal(() => sid = v ?? sid),
                  ),
                  TextField(
                    controller: titleCtrl,
                    decoration: const InputDecoration(labelText: 'Naziv'),
                  ),
                  TextField(
                    controller: maxCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Maks. bodova'),
                  ),
                  TextField(
                    controller: ptsCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Osvojeno'),
                  ),
                  ListTile(
                    title: const Text('Datum'),
                    subtitle: Text(date == null ? '—' : DateFormat.yMMMd().format(date!)),
                    onTap: () async {
                      final d = await showDatePicker(
                        context: context,
                        initialDate: date ?? DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2100),
                      );
                      if (d != null) {
                        setLocal(() => date = d);
                      }
                    },
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

    final max = double.tryParse(maxCtrl.text.replaceAll(',', '.')) ?? 100;
    final pts = double.tryParse(ptsCtrl.text.replaceAll(',', '.')) ?? 0;

    final model = Colloquium(
      id: item?.id ?? 0,
      subjectId: sid,
      title: titleCtrl.text.trim().isEmpty ? 'Kolokvijum' : titleCtrl.text.trim(),
      maxPoints: max,
      points: pts.clamp(0, max),
      dateMs: date?.millisecondsSinceEpoch,
    );

    try {
      if (item == null) {
        await widget.repo.insertColloquium(model);
      } else {
        await widget.repo.updateColloquium(model);
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
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    return FutureBuilder<List<Subject>>(
      future: widget.repo.getSubjects(),
      builder: (context, snap) {
        final subjects = snap.data ?? [];
        return Scaffold(
          body: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _list.length + 1,
            itemBuilder: (context, i) {
              if (i == 0) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    'Bodovi sa kolokvijuma',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                );
              }
              final c = _list[i - 1];
              final name = _names[c.subjectId] ?? 'Predmet #${c.subjectId}';
              return Card(
                child: ListTile(
                  title: Text(c.title),
                  subtitle: Text('$name · ${c.points.toStringAsFixed(1)} / ${c.maxPoints.toStringAsFixed(1)}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_outlined),
                        onPressed: () => _edit(item: c, subjects: subjects),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () async {
                          await widget.repo.deleteColloquium(c.id);
                          await _load();
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => _edit(subjects: subjects),
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }
}

class _AttendanceTab extends StatefulWidget {
  const _AttendanceTab({required this.repo});

  final StudentRepository repo;

  @override
  State<_AttendanceTab> createState() => _AttendanceTabState();
}

class _AttendanceTabState extends State<_AttendanceTab> {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Subject>>(
      future: widget.repo.getSubjects(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final subjects = snap.data!;
        if (subjects.isEmpty) {
          return const Center(child: Text('Dodaj predmete u kartici Progres.'));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: subjects.length,
          itemBuilder: (context, i) {
            final s = subjects[i];
            return FutureBuilder<Attendance?>(
              future: widget.repo.getAttendanceForSubject(s.id),
              builder: (context, aSnap) {
                final a = aSnap.data;
                final pct = a == null ? null : (100 * a.ratio).round();
                return Card(
                  child: ListTile(
                    title: Text(s.name),
                    subtitle: Text(a == null ? 'Nije uneto' : '${a.present} / ${a.total} ($pct%)'),
                    trailing: const Icon(Icons.edit_outlined),
                    onTap: () async {
                      final t = await _showAttendanceDialog(context, s, a);
                      if (t != null) {
                        await widget.repo.upsertAttendance(t);
                        setState(() {});
                      }
                    },
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Future<Attendance?> _showAttendanceDialog(
    BuildContext context,
    Subject s,
    Attendance? existing,
  ) async {
    final pCtrl = TextEditingController(text: existing?.present.toString() ?? '0');
    final tCtrl = TextEditingController(text: existing?.total.toString() ?? '15');

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Prisustvo · ${s.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: pCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Prisustvovao/la'),
            ),
            TextField(
              controller: tCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Ukupno časova'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Otkaži')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Sačuvaj')),
        ],
      ),
    );

    if (ok != true) {
      return null;
    }

    final pr = int.tryParse(pCtrl.text) ?? 0;
    final tot = int.tryParse(tCtrl.text) ?? 1;
    return Attendance(
      id: existing?.id ?? 0,
      subjectId: s.id,
      present: pr.clamp(0, tot),
      total: tot.clamp(1, 9999),
    );
  }
}

class _HomeworkTab extends StatefulWidget {
  const _HomeworkTab({required this.repo});

  final StudentRepository repo;

  @override
  State<_HomeworkTab> createState() => _HomeworkTabState();
}

class _HomeworkTabState extends State<_HomeworkTab> {
  List<PortalHomeworkRow> _list = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final h = await widget.repo.studentCurrentHomework();
      setState(() {
        _list = h;
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
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_list.isEmpty) {
      return RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 120),
            Center(child: Text('Nema trenutnih domaćih zadataka.')),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _list.length,
        separatorBuilder: (_, _) => const SizedBox(height: 8),
        itemBuilder: (context, i) {
          final h = _list[i];
          return Card(
            child: CheckboxListTile(
              value: h.completed,
              onChanged: (v) async {
                if (v == null) return;
                final messenger = ScaffoldMessenger.of(context);
                try {
                  await widget.repo.setStudentCurrentHomeworkCompleted(h.assignmentId, v);
                  await _load();
                } catch (e) {
                  messenger.showSnackBar(SnackBar(content: Text('$e')));
                }
              },
              title: Text(h.title),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(h.subjectName, style: Theme.of(context).textTheme.labelLarge),
                  if (h.description != null && h.description!.isNotEmpty) Text(h.description!),
                  if (h.dueDateMs != null)
                    Text('Rok: ${DateFormat.yMMMd().add_Hm().format(DateTime.fromMillisecondsSinceEpoch(h.dueDateMs!))}'),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
