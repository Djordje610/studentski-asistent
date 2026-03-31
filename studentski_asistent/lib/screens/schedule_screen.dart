import 'package:flutter/material.dart';

import '../constants.dart';
import '../data/student_repository.dart';
import '../models/schedule_entry.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key, required this.repo});

  final StudentRepository repo;

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  int _day = 1;
  List<ScheduleEntry> _items = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await widget.repo.getScheduleForDay(_day);
      setState(() {
        _items = list;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _openEditor({ScheduleEntry? entry}) async {
    final titleCtrl = TextEditingController(text: entry?.title ?? '');
    final roomCtrl = TextEditingController(text: entry?.room ?? '');
    final notesCtrl = TextEditingController(text: entry?.notes ?? '');
    var day = entry?.dayOfWeek ?? _day;
    var type = entry?.activityType ?? 'predavanje';
    TimeOfDay start = _parseTime(entry?.startTime ?? '08:00');
    TimeOfDay end = _parseTime(entry?.endTime ?? '09:30');

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setLocal) {
          return AlertDialog(
            title: Text(entry == null ? 'Novi termin' : 'Izmeni termin'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<int>(
                    key: ValueKey(day),
                    initialValue: day,
                    decoration: const InputDecoration(labelText: 'Dan'),
                    items: List.generate(
                      7,
                      (i) => DropdownMenuItem(
                        value: i + 1,
                        child: Text(kDaniUNedelji[i]),
                      ),
                    ),
                    onChanged: (v) => setLocal(() => day = v ?? 1),
                  ),
                  TextField(
                    controller: titleCtrl,
                    decoration: const InputDecoration(labelText: 'Predmet / naslov'),
                  ),
                  DropdownButtonFormField<String>(
                    key: ValueKey(type),
                    initialValue: type,
                    decoration: const InputDecoration(labelText: 'Tip'),
                    items: const [
                      DropdownMenuItem(value: 'predavanje', child: Text('Predavanje')),
                      DropdownMenuItem(value: 'vezba', child: Text('Vežba')),
                    ],
                    onChanged: (v) => setLocal(() => type = v ?? 'predavanje'),
                  ),
                  ListTile(
                    title: const Text('Početak'),
                    trailing: Text(_fmtTime(start)),
                    onTap: () async {
                      final t = await showTimePicker(context: context, initialTime: start);
                      if (t != null) {
                        setLocal(() => start = t);
                      }
                    },
                  ),
                  ListTile(
                    title: const Text('Kraj'),
                    trailing: Text(_fmtTime(end)),
                    onTap: () async {
                      final t = await showTimePicker(context: context, initialTime: end);
                      if (t != null) {
                        setLocal(() => end = t);
                      }
                    },
                  ),
                  TextField(
                    controller: roomCtrl,
                    decoration: const InputDecoration(labelText: 'Učionica (opciono)'),
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
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Sačuvaj'),
              ),
            ],
          );
        },
      ),
    );

    if (ok != true || !mounted) {
      return;
    }

    final model = ScheduleEntry(
      id: entry?.id ?? 0,
      dayOfWeek: day,
      title: titleCtrl.text.trim().isEmpty ? 'Bez naslova' : titleCtrl.text.trim(),
      activityType: type,
      startTime: _fmtTime(start),
      endTime: _fmtTime(end),
      room: roomCtrl.text.trim().isEmpty ? null : roomCtrl.text.trim(),
      notes: notesCtrl.text.trim().isEmpty ? null : notesCtrl.text.trim(),
    );

    try {
      if (entry == null) {
        await widget.repo.insertSchedule(model);
      } else {
        await widget.repo.updateSchedule(model);
      }
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  TimeOfDay _parseTime(String s) {
    final p = s.split(':');
    final h = int.tryParse(p[0]) ?? 8;
    final m = int.tryParse(p.length > 1 ? p[1] : '0') ?? 0;
    return TimeOfDay(hour: h, minute: m);
  }

  String _fmtTime(TimeOfDay t) {
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Raspored'),
      ),
      body: Column(
        children: [
          SizedBox(
            height: 48,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              itemCount: 7,
              itemBuilder: (context, i) {
                final d = i + 1;
                final sel = d == _day;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                  child: ChoiceChip(
                    label: Text(kDaniUNedelji[i]),
                    selected: sel,
                    onSelected: (_) {
                      setState(() => _day = d);
                      _load();
                    },
                  ),
                );
              },
            ),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Ne mogu da se povežem sa serverom.\nPokreni Spring Boot (port 8080).\n$_error',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _items.length,
                    itemBuilder: (context, i) {
                      final e = _items[i];
                      final chip = e.activityType == 'vezba' ? 'Vežba' : 'Predavanje';
                      return Card(
                        child: ListTile(
                          title: Text(e.title),
                          subtitle: Text('${e.startTime}–${e.endTime} · $chip${e.room != null ? ' · ${e.room}' : ''}'),
                          isThreeLine: e.notes != null && e.notes!.isNotEmpty,
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit_outlined),
                                onPressed: () => _openEditor(entry: e),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline),
                                onPressed: () async {
                                  await widget.repo.deleteSchedule(e.id);
                                  await _load();
                                },
                              ),
                            ],
                          ),
                          onTap: () => _openEditor(entry: e),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openEditor(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
