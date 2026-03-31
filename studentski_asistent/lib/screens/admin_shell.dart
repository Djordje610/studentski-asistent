import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../auth/auth_controller.dart';
import '../config/api_config.dart';
import '../data/academy_repository.dart';
import '../models/academy_admin.dart';

Future<List<({int id, String label})>> _allProgramYearOptions(AcademyRepository api) async {
  final programs = await api.adminListPrograms();
  final out = <({int id, String label})>[];
  for (final p in programs) {
    final ys = await api.adminListProgramYears(p.id);
    for (final y in ys) {
      out.add((id: y.id, label: '${p.code} · god. ${y.yearNumber}'));
    }
  }
  return out;
}

class AdminShell extends StatefulWidget {
  const AdminShell({super.key, required this.getToken});

  final Future<String?> Function() getToken;

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> with SingleTickerProviderStateMixin {
  late TabController _tc;
  late AcademyRepository _api;
  int _epoch = 0;

  void _bump() => setState(() => _epoch++);

  @override
  void initState() {
    super.initState();
    _tc = TabController(length: 6, vsync: this);
    _api = AcademyRepository(baseUrl: resolveGatewayUrl(), getToken: widget.getToken);
  }

  @override
  void dispose() {
    _tc.dispose();
    super.dispose();
  }

  Future<int?> _pickMs(BuildContext context) async {
    final now = DateTime.now();
    final d = await showDatePicker(
      context: context,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now.add(const Duration(days: 365 * 6)),
      initialDate: now,
    );
    if (d == null || !context.mounted) {
      return null;
    }
    final t = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(now));
    if (t == null) {
      return null;
    }
    return DateTime(d.year, d.month, d.day, t.hour, t.minute).millisecondsSinceEpoch;
  }

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('dd.MM.yyyy HH:mm');
    return Scaffold(
      appBar: AppBar(
        title: const Text('Administracija'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => context.read<AuthController>().logout(),
          ),
        ],
        bottom: TabBar(
          controller: _tc,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Smerovi'),
            Tab(text: 'Godine'),
            Tab(text: 'Predmeti'),
            Tab(text: 'Studenti'),
            Tab(text: 'Ispitni rok'),
            Tab(text: 'Domaći'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tc,
        children: [
          _ProgramsTab(key: ValueKey(_epoch), api: _api, onChanged: _bump),
          _YearsTab(key: ValueKey(_epoch), api: _api, onChanged: _bump),
          _SubjectsTab(key: ValueKey(_epoch), api: _api, onChanged: _bump),
          _StudentsTab(key: ValueKey(_epoch), api: _api, onChanged: _bump),
          _ExamPeriodsTab(key: ValueKey(_epoch), api: _api, onChanged: _bump, dateFmt: df, pickMs: _pickMs),
          _HomeworkTab(key: ValueKey(_epoch), api: _api, onChanged: _bump, dateFmt: df, pickMs: _pickMs),
        ],
      ),
    );
  }
}

class _ProgramsTab extends StatelessWidget {
  const _ProgramsTab({super.key, required this.api, required this.onChanged});

  final AcademyRepository api;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<StudyProgram>>(
      future: api.adminListPrograms(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final list = snap.data!;
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: FilledButton.icon(
                onPressed: () async {
                  final code = TextEditingController();
                  final name = TextEditingController();
                  final ok = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Novi smer'),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextField(controller: code, decoration: const InputDecoration(labelText: 'Kod')),
                          TextField(controller: name, decoration: const InputDecoration(labelText: 'Naziv')),
                        ],
                      ),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Otkaži')),
                        FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Sačuvaj')),
                      ],
                    ),
                  );
                  if (ok == true && context.mounted) {
                    try {
                      await api.adminCreateProgram(code: code.text.trim(), name: name.text.trim());
                      onChanged();
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
                      }
                    }
                  }
                },
                icon: const Icon(Icons.add),
                label: const Text('Dodaj smer'),
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: list.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (_, i) {
                  final p = list[i];
                  return ListTile(title: Text(p.name), subtitle: Text(p.code));
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class _YearsTab extends StatefulWidget {
  const _YearsTab({super.key, required this.api, required this.onChanged});

  final AcademyRepository api;
  final VoidCallback onChanged;

  @override
  State<_YearsTab> createState() => _YearsTabState();
}

class _YearsTabState extends State<_YearsTab> {
  int? _programId;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<StudyProgram>>(
      future: widget.api.adminListPrograms(),
      builder: (context, progSnap) {
        if (!progSnap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final programs = progSnap.data!;
        _programId ??= programs.isNotEmpty ? programs.first.id : null;
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: DropdownButton<int>(
                      isExpanded: true,
                      value: _programId,
                      hint: const Text('Smer'),
                      items: [for (final p in programs) DropdownMenuItem(value: p.id, child: Text('${p.code} — ${p.name}'))],
                      onChanged: (v) => setState(() => _programId = v),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: _programId == null
                        ? null
                        : () async {
                            final y = TextEditingController();
                            final ok = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('Nova godina'),
                                content: TextField(
                                  controller: y,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(labelText: 'Broj godine'),
                                ),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Otkaži')),
                                  FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Dodaj')),
                                ],
                              ),
                            );
                            if (ok == true && context.mounted) {
                              try {
                                final n = int.tryParse(y.text.trim());
                                if (n == null) {
                                  throw Exception('Unesite broj.');
                                }
                                await widget.api.adminCreateProgramYear(studyProgramId: _programId!, yearNumber: n);
                                widget.onChanged();
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
                                }
                              }
                            }
                          },
                  ),
                ],
              ),
            ),
            Expanded(
              child: _programId == null
                  ? const Center(child: Text('Nema smerova.'))
                  : FutureBuilder<List<ProgramYear>>(
                      future: widget.api.adminListProgramYears(_programId!),
                      builder: (context, snap) {
                        if (!snap.hasData) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        final list = snap.data!;
                        return ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: list.length,
                          separatorBuilder: (_, _) => const Divider(height: 1),
                          itemBuilder: (_, i) {
                            final y = list[i];
                            return ListTile(title: Text('Godina ${y.yearNumber}'), subtitle: Text('id: ${y.id}'));
                          },
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}

class _SubjectsTab extends StatefulWidget {
  const _SubjectsTab({super.key, required this.api, required this.onChanged});

  final AcademyRepository api;
  final VoidCallback onChanged;

  @override
  State<_SubjectsTab> createState() => _SubjectsTabState();
}

class _SubjectsTabState extends State<_SubjectsTab> {
  int? _programId;
  int? _yearId;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<StudyProgram>>(
      future: widget.api.adminListPrograms(),
      builder: (context, progSnap) {
        if (!progSnap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final programs = progSnap.data!;
        _programId ??= programs.isNotEmpty ? programs.first.id : null;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: DropdownButton<int>(
                isExpanded: true,
                value: _programId,
                hint: const Text('Smer'),
                items: [for (final p in programs) DropdownMenuItem(value: p.id, child: Text(p.code))],
                onChanged: (v) => setState(() {
                  _programId = v;
                  _yearId = null;
                }),
              ),
            ),
            if (_programId != null)
              FutureBuilder<List<ProgramYear>>(
                future: widget.api.adminListProgramYears(_programId!),
                builder: (context, ySnap) {
                  if (!ySnap.hasData) {
                    return const SizedBox.shrink();
                  }
                  final years = ySnap.data!;
                  _yearId ??= years.isNotEmpty ? years.first.id : null;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: DropdownButton<int>(
                            isExpanded: true,
                            value: _yearId,
                            hint: const Text('Godina studija'),
                            items: [
                              for (final y in years)
                                DropdownMenuItem(value: y.id, child: Text('Godina ${y.yearNumber}')),
                            ],
                            onChanged: (v) => setState(() => _yearId = v),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add),
                          onPressed: _yearId == null
                              ? null
                              : () async {
                                  final name = TextEditingController();
                                  final code = TextEditingController();
                                  final espb = TextEditingController(text: '6');
                                  final ok = await showDialog<bool>(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      title: const Text('Novi predmet'),
                                      content: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          TextField(controller: name, decoration: const InputDecoration(labelText: 'Naziv')),
                                          TextField(controller: code, decoration: const InputDecoration(labelText: 'Šifra (opc.)')),
                                          TextField(
                                            controller: espb,
                                            keyboardType: TextInputType.number,
                                            decoration: const InputDecoration(labelText: 'ESPB'),
                                          ),
                                        ],
                                      ),
                                      actions: [
                                        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Otkaži')),
                                        FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Dodaj')),
                                      ],
                                    ),
                                  );
                                  if (ok == true && context.mounted) {
                                    try {
                                      final e = int.tryParse(espb.text.trim()) ?? 6;
                                      await widget.api.adminCreateCatalogSubject(
                                        programYearId: _yearId!,
                                        code: code.text.trim().isEmpty ? null : code.text.trim(),
                                        name: name.text.trim(),
                                        espb: e,
                                      );
                                      widget.onChanged();
                                    } catch (ex) {
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$ex')));
                                      }
                                    }
                                  }
                                },
                        ),
                      ],
                    ),
                  );
                },
              ),
            Expanded(
              child: _yearId == null
                  ? const Center(child: Text('Izaberite godinu.'))
                  : FutureBuilder<List<CatalogSubjectAdmin>>(
                      future: widget.api.adminListCatalogSubjects(_yearId!),
                      builder: (context, snap) {
                        if (!snap.hasData) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        final list = snap.data!;
                        return ListView.separated(
                          itemCount: list.length,
                          separatorBuilder: (_, _) => const Divider(height: 1),
                          itemBuilder: (_, i) {
                            final s = list[i];
                            return ListTile(
                              title: Text(s.name),
                              subtitle: Text('ESPB ${s.espb}${s.code != null ? ' · ${s.code}' : ''}'),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete_outline),
                                onPressed: () async {
                                  try {
                                    await widget.api.adminDeleteCatalogSubject(s.id);
                                    widget.onChanged();
                                  } catch (ex) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$ex')));
                                    }
                                  }
                                },
                              ),
                            );
                          },
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}

class _StudentsTab extends StatelessWidget {
  const _StudentsTab({super.key, required this.api, required this.onChanged});

  final AcademyRepository api;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: FilledButton.icon(
            onPressed: () async {
              final opts = await _allProgramYearOptions(api);
              if (!context.mounted) {
                return;
              }
              if (opts.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Prvo dodajte smer i godinu studija.')),
                );
                return;
              }
              int? yid = opts.first.id;
              final email = TextEditingController();
              final pass = TextEditingController();
              final name = TextEditingController();
              final index = TextEditingController();
              final ok = await showDialog<bool>(
                context: context,
                builder: (ctx) => StatefulBuilder(
                  builder: (ctx, setSt) {
                    return AlertDialog(
                      title: const Text('Novi student'),
                      content: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            DropdownButton<int>(
                              isExpanded: true,
                              value: yid,
                              items: [for (final o in opts) DropdownMenuItem(value: o.id, child: Text(o.label))],
                              onChanged: (v) => setSt(() => yid = v),
                            ),
                            TextField(controller: email, decoration: const InputDecoration(labelText: 'Email')),
                            TextField(
                              controller: pass,
                              obscureText: true,
                              decoration: const InputDecoration(labelText: 'Lozinka'),
                            ),
                            TextField(controller: name, decoration: const InputDecoration(labelText: 'Ime i prezime')),
                            TextField(controller: index, decoration: const InputDecoration(labelText: 'Indeks (opc.)')),
                          ],
                        ),
                      ),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Otkaži')),
                        FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Kreiraj')),
                      ],
                    );
                  },
                ),
              );
              if (ok == true && context.mounted) {
                final em = email.text.trim();
                final pw = pass.text;
                final fn = name.text.trim();
                final emailOk = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(em);
                if (!emailOk) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Unesite ispravan email.')),
                  );
                  return;
                }
                if (pw.length < 8) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Lozinka mora imati najmanje 8 karaktera.')),
                  );
                  return;
                }
                if (fn.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Unesite ime i prezime studenta.')),
                  );
                  return;
                }
                try {
                  await api.adminCreateStudent(
                    email: em,
                    password: pw,
                    fullName: fn,
                    studentIndex: index.text.trim().isEmpty ? null : index.text.trim(),
                    programYearId: yid!,
                  );
                  onChanged();
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
                  }
                }
              }
            },
            icon: const Icon(Icons.person_add),
            label: const Text('Novi student'),
          ),
        ),
        Expanded(
          child: FutureBuilder<List<StudentProfileAdmin>>(
            future: api.adminListStudentProfiles(),
            builder: (context, snap) {
              if (!snap.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final list = snap.data!;
              return ListView.separated(
                itemCount: list.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (_, i) {
                  final p = list[i];
                  return ListTile(
                    title: Text(p.displayTitle),
                    subtitle: Text('${p.programName} · Godina ${p.yearNumber}'),
                    trailing: IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () async {
                        final opts = await _allProgramYearOptions(api);
                        if (!context.mounted) {
                          return;
                        }
                        int? sel = p.programYearId;
                        final ok = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => StatefulBuilder(
                            builder: (ctx, setSt) {
                              return AlertDialog(
                                title: const Text('Godina studija'),
                                content: DropdownButton<int>(
                                  isExpanded: true,
                                  value: sel,
                                  items: [for (final o in opts) DropdownMenuItem(value: o.id, child: Text(o.label))],
                                  onChanged: (v) => setSt(() => sel = v),
                                ),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Otkaži')),
                                  FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Sačuvaj')),
                                ],
                              );
                            },
                          ),
                        );
                        if (ok == true && context.mounted && sel != null) {
                          try {
                            await api.adminUpdateStudentProfile(userId: p.userId, programYearId: sel!);
                            onChanged();
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
                            }
                          }
                        }
                      },
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ExamPeriodsTab extends StatelessWidget {
  const _ExamPeriodsTab({
    super.key,
    required this.api,
    required this.onChanged,
    required this.dateFmt,
    required this.pickMs,
  });

  final AcademyRepository api;
  final VoidCallback onChanged;
  final DateFormat dateFmt;
  final Future<int?> Function(BuildContext) pickMs;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: FilledButton.icon(
            onPressed: () async {
              final name = TextEditingController();
              int? start;
              int? end;
              final ok = await showDialog<bool>(
                context: context,
                builder: (ctx) => StatefulBuilder(
                  builder: (ctx, setSt) {
                    return AlertDialog(
                      title: const Text('Novi ispitni rok'),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextField(controller: name, decoration: const InputDecoration(labelText: 'Naziv')),
                          ListTile(
                            title: Text(start == null ? 'Početak' : dateFmt.format(DateTime.fromMillisecondsSinceEpoch(start!))),
                            trailing: const Icon(Icons.schedule),
                            onTap: () async {
                              final ms = await pickMs(ctx);
                              if (ms != null) {
                                setSt(() => start = ms);
                              }
                            },
                          ),
                          ListTile(
                            title: Text(end == null ? 'Kraj' : dateFmt.format(DateTime.fromMillisecondsSinceEpoch(end!))),
                            trailing: const Icon(Icons.schedule),
                            onTap: () async {
                              final ms = await pickMs(ctx);
                              if (ms != null) {
                                setSt(() => end = ms);
                              }
                            },
                          ),
                        ],
                      ),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Otkaži')),
                        FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Dodaj')),
                      ],
                    );
                  },
                ),
              );
              if (ok == true && context.mounted && start != null && end != null) {
                try {
                  await api.adminCreateExamPeriod(name: name.text.trim(), startMs: start!, endMs: end!);
                  onChanged();
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
                  }
                }
              }
            },
            icon: const Icon(Icons.date_range),
            label: const Text('Novi rok'),
          ),
        ),
        Expanded(
          child: FutureBuilder<List<ExamPeriodAdmin>>(
            future: api.adminListExamPeriods(),
            builder: (context, snap) {
              if (!snap.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final periods = snap.data!;
              return ListView.builder(
                itemCount: periods.length,
                itemBuilder: (context, i) {
                  final ep = periods[i];
                  return ExpansionTile(
                    leading: ep.active ? const Icon(Icons.check_circle, color: Colors.green) : const Icon(Icons.circle_outlined),
                    title: Text(ep.name),
                    subtitle: Text('${dateFmt.format(DateTime.fromMillisecondsSinceEpoch(ep.startMs))} — ${dateFmt.format(DateTime.fromMillisecondsSinceEpoch(ep.endMs))}'),
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          TextButton(
                            onPressed: () async {
                              try {
                                await api.adminActivateExamPeriod(ep.id);
                                onChanged();
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
                                }
                              }
                            },
                            child: const Text('Postavi kao aktivan'),
                          ),
                        ],
                      ),
                      FutureBuilder<List<ExamOfferingAdmin>>(
                        future: api.adminListExamOfferings(ep.id),
                        builder: (context, os) {
                          if (!os.hasData) {
                            return const Padding(
                              padding: EdgeInsets.all(16),
                              child: CircularProgressIndicator(),
                            );
                          }
                          final offers = os.data!;
                          return Column(
                            children: [
                              for (final o in offers)
                                ListTile(
                                  title: Text(o.subjectName),
                                  subtitle: Text(dateFmt.format(DateTime.fromMillisecondsSinceEpoch(o.examMs))),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.delete_outline),
                                    onPressed: () async {
                                      try {
                                        await api.adminDeleteExamOffering(o.id);
                                        onChanged();
                                      } catch (e) {
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
                                        }
                                      }
                                    },
                                  ),
                                ),
                              Padding(
                                padding: const EdgeInsets.all(8),
                                child: FilledButton.icon(
                                  onPressed: () async {
                                    final subjects = await _allCatalogSubjects(api);
                                    if (!context.mounted) {
                                      return;
                                    }
                                    if (subjects.isEmpty) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Nema predmeta u katalogu.')),
                                      );
                                      return;
                                    }
                                    int? cid = subjects.first.id;
                                    int? examMs;
                                    final loc = TextEditingController();
                                    final ok2 = await showDialog<bool>(
                                      context: context,
                                      builder: (ctx) => StatefulBuilder(
                                        builder: (ctx, setSt) {
                                          return AlertDialog(
                                            title: const Text('Nova ponuda ispita'),
                                            content: SingleChildScrollView(
                                              child: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  DropdownButton<int>(
                                                    isExpanded: true,
                                                    value: cid,
                                                    items: [
                                                      for (final s in subjects)
                                                        DropdownMenuItem(
                                                          value: s.id,
                                                          child: Text(s.label),
                                                        ),
                                                    ],
                                                    onChanged: (v) => setSt(() => cid = v),
                                                  ),
                                                  ListTile(
                                                    title: Text(
                                                      examMs == null
                                                          ? 'Termin polaganja'
                                                          : dateFmt.format(DateTime.fromMillisecondsSinceEpoch(examMs!)),
                                                    ),
                                                    onTap: () async {
                                                      final ms = await pickMs(ctx);
                                                      if (ms != null) {
                                                        setSt(() => examMs = ms);
                                                      }
                                                    },
                                                  ),
                                                  TextField(
                                                    controller: loc,
                                                    decoration: const InputDecoration(labelText: 'Mesto (opc.)'),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            actions: [
                                              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Otkaži')),
                                              FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Dodaj')),
                                            ],
                                          );
                                        },
                                      ),
                                    );
                                    if (ok2 == true && context.mounted && examMs != null) {
                                      try {
                                        await api.adminCreateExamOffering(
                                          examPeriodId: ep.id,
                                          catalogSubjectId: cid!,
                                          examMs: examMs!,
                                          location: loc.text.trim().isEmpty ? null : loc.text.trim(),
                                        );
                                        onChanged();
                                      } catch (e) {
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
                                        }
                                      }
                                    }
                                  },
                                  icon: const Icon(Icons.add),
                                  label: const Text('Dodaj termin'),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

Future<List<({int id, String label})>> _allCatalogSubjects(AcademyRepository api) async {
  final programs = await api.adminListPrograms();
  final out = <({int id, String label})>[];
  for (final p in programs) {
    final ys = await api.adminListProgramYears(p.id);
    for (final y in ys) {
      final subs = await api.adminListCatalogSubjects(y.id);
      for (final s in subs) {
        out.add((id: s.id, label: '${p.code} · ${s.name} (${s.espb} ESPB)'));
      }
    }
  }
  return out;
}

class _HomeworkTab extends StatefulWidget {
  const _HomeworkTab({
    super.key,
    required this.api,
    required this.onChanged,
    required this.dateFmt,
    required this.pickMs,
  });

  final AcademyRepository api;
  final VoidCallback onChanged;
  final DateFormat dateFmt;
  final Future<int?> Function(BuildContext) pickMs;

  @override
  State<_HomeworkTab> createState() => _HomeworkTabState();
}

class _HomeworkTabState extends State<_HomeworkTab> {
  int? _catalogSubjectId;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<({int id, String label})>>(
      future: _allCatalogSubjects(widget.api),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final opts = snap.data!;
        _catalogSubjectId ??= opts.isNotEmpty ? opts.first.id : null;
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: DropdownButton<int>(
                isExpanded: true,
                value: _catalogSubjectId,
                hint: const Text('Predmet iz kataloga'),
                items: [for (final o in opts) DropdownMenuItem(value: o.id, child: Text(o.label))],
                onChanged: (v) => setState(() => _catalogSubjectId = v),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: FilledButton.icon(
                onPressed: _catalogSubjectId == null
                    ? null
                    : () async {
                        final title = TextEditingController();
                        final desc = TextEditingController();
                        int? due;
                        final ok = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => StatefulBuilder(
                            builder: (ctx, setSt) {
                              return AlertDialog(
                                title: const Text('Novi domaći'),
                                content: SingleChildScrollView(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      TextField(controller: title, decoration: const InputDecoration(labelText: 'Naslov')),
                                      TextField(controller: desc, decoration: const InputDecoration(labelText: 'Opis (opc.)')),
                                      ListTile(
                                        title: Text(
                                          due == null
                                              ? 'Rok (opc.)'
                                              : widget.dateFmt.format(DateTime.fromMillisecondsSinceEpoch(due!)),
                                        ),
                                        onTap: () async {
                                          final ms = await widget.pickMs(ctx);
                                          if (ms != null) {
                                            setSt(() => due = ms);
                                          }
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Otkaži')),
                                  FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Dodaj')),
                                ],
                              );
                            },
                          ),
                        );
                        if (ok == true && context.mounted) {
                          try {
                            await widget.api.adminCreateHomework(
                              catalogSubjectId: _catalogSubjectId!,
                              title: title.text.trim(),
                              description: desc.text.trim().isEmpty ? null : desc.text.trim(),
                              dueDateMs: due,
                            );
                            widget.onChanged();
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
                            }
                          }
                        }
                      },
                icon: const Icon(Icons.add),
                label: const Text('Dodaj zadatak'),
              ),
            ),
            Expanded(
              child: _catalogSubjectId == null
                  ? const Center(child: Text('Nema predmeta.'))
                  : FutureBuilder<List<HomeworkAssignmentAdmin>>(
                      future: widget.api.adminListHomeworkAssignments(_catalogSubjectId!),
                      builder: (context, hs) {
                        if (!hs.hasData) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        final list = hs.data!;
                        return ListView.separated(
                          itemCount: list.length,
                          separatorBuilder: (_, _) => const Divider(height: 1),
                          itemBuilder: (_, i) {
                            final h = list[i];
                            return ListTile(
                              title: Text(h.title),
                              subtitle: h.dueDateMs != null
                                  ? Text('Rok: ${widget.dateFmt.format(DateTime.fromMillisecondsSinceEpoch(h.dueDateMs!))}')
                                  : null,
                              trailing: IconButton(
                                icon: const Icon(Icons.delete_outline),
                                onPressed: () async {
                                  try {
                                    await widget.api.adminDeleteHomeworkAssignment(h.id);
                                    widget.onChanged();
                                  } catch (e) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
                                    }
                                  }
                                },
                              ),
                            );
                          },
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}
