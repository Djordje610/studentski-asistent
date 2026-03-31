import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../auth/auth_controller.dart';
import '../data/academy_repository.dart';
import '../models/academy_portal.dart';
import '../ui/widgets/soft_card.dart';

class StudentExamsPortalScreen extends StatefulWidget {
  const StudentExamsPortalScreen({super.key, required this.repo});

  final AcademyRepository repo;

  @override
  State<StudentExamsPortalScreen> createState() => _StudentExamsPortalScreenState();
}

class _StudentExamsPortalScreenState extends State<StudentExamsPortalScreen> {
  List<ExamOffer>? _offers;
  Object? _offersError;
  late Future<List<MyRegisteredExam>> _mine;

  Timer? _tick;
  int _segment = 0;

  @override
  void initState() {
    super.initState();
    _mine = widget.repo.studentMyExams();
    _loadOffers();
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
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

  Future<void> _loadOffers() async {
    try {
      final o = await widget.repo.studentExamOffers();
      if (mounted) {
        setState(() {
          _offers = o;
          _offersError = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _offers = null;
          _offersError = e;
        });
      }
    }
  }

  Future<void> _reloadAll() async {
    setState(() {
      _mine = widget.repo.studentMyExams();
    });
    await _loadOffers();
  }

  String _countdown(int examMs) {
    final now = DateTime.now().millisecondsSinceEpoch;
    final diff = examMs - now;
    if (diff <= 0) {
      return 'Polaganje je počelo ili je prošlo';
    }
    final d = Duration(milliseconds: diff);
    final days = d.inDays;
    final h = d.inHours % 24;
    final m = d.inMinutes % 60;
    final s = d.inSeconds % 60;
    if (days > 0) {
      return '$days d $h h $m min';
    }
    if (d.inHours > 0) {
      return '$h h $m min $s s';
    }
    if (d.inMinutes > 0) {
      return '$m min $s s';
    }
    return '$s s';
  }

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat.yMMMd('sr_Latn').add_Hm();
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _reloadAll,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverAppBar.large(
              pinned: true,
              title: const Text('Ispiti'),
              actions: [
                IconButton(
                  tooltip: 'Odjavi se',
                  icon: const Icon(Icons.logout),
                  onPressed: () => context.read<AuthController>().logout(),
                ),
                const SizedBox(width: 8),
              ],
              flexibleSpace: FlexibleSpaceBar(
                titlePadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                title: Text(
                  'Ispitni rok',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              sliver: SliverToBoxAdapter(
                child: SegmentedButton<int>(
                  segments: const [
                    ButtonSegment(value: 0, label: Text('Ponuda')),
                    ButtonSegment(value: 1, label: Text('Moji ispiti')),
                  ],
                  selected: {_segment},
                  showSelectedIcon: false,
                  style: ButtonStyle(
                    backgroundColor: WidgetStateProperty.resolveWith((states) {
                      if (states.contains(WidgetState.selected)) {
                        return scheme.primaryContainer.withValues(alpha: 0.55);
                      }
                      return Colors.white.withValues(alpha: 0.85);
                    }),
                    foregroundColor: WidgetStateProperty.resolveWith((states) {
                      if (states.contains(WidgetState.selected)) return scheme.onPrimaryContainer;
                      return scheme.onSurfaceVariant;
                    }),
                    shape: WidgetStatePropertyAll(
                      RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    padding: const WidgetStatePropertyAll(
                      EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    side: WidgetStatePropertyAll(
                      BorderSide(color: scheme.onSurface.withValues(alpha: 0.08)),
                    ),
                  ),
                  onSelectionChanged: (s) => setState(() => _segment = s.first),
                ),
              ),
            ),
            if (_segment == 0) ...[
              ..._buildOffersSlivers(context, fmt),
            ] else ...[
              ..._buildMineSlivers(context, fmt),
            ],
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildOffersSlivers(BuildContext context, DateFormat fmt) {
    final scheme = Theme.of(context).colorScheme;
    if (_offersError != null) {
      return [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          sliver: SliverToBoxAdapter(
            child: SoftCard(
              background: scheme.errorContainer.withValues(alpha: 0.55),
              child: Text(
                'Ponuda nije dostupna: $_offersError',
                style: TextStyle(color: scheme.onErrorContainer),
              ),
            ),
          ),
        ),
      ];
    }
    if (_offers == null) {
      return const [SliverFillRemaining(child: Center(child: CircularProgressIndicator()))];
    }
    if (_offers!.isEmpty) {
      return const [
        SliverToBoxAdapter(child: SizedBox(height: 120)),
        SliverToBoxAdapter(
          child: Center(
            child: Text(
              'Nema ponuda za vaš smer/godinu.\nProverite da je rok aktiviran i da su dodate ponude za vašu godinu.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ];
    }

    return [
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        sliver: SliverList.separated(
          itemCount: _offers!.length,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (context, i) {
            final o = _offers![i];
            return _ExamOfferCard(
              offer: o,
              subtitle: '${o.examPeriodName}\n${fmt.format(DateTime.fromMillisecondsSinceEpoch(o.examMs))}'
                  '${o.location != null ? '\n${o.location}' : ''}',
              onRegister: () async {
                try {
                  await widget.repo.registerExam(o.offeringId);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Prijavljeni ste.')),
                    );
                  }
                  await _reloadAll();
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
                  }
                }
              },
            );
          },
        ),
      ),
    ];
  }

  List<Widget> _buildMineSlivers(BuildContext context, DateFormat fmt) {
    return [
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        sliver: SliverToBoxAdapter(
          child: FutureBuilder<List<MyRegisteredExam>>(
            future: _mine,
            builder: (context, snap) {
              final scheme = Theme.of(context).colorScheme;
              if (snap.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.only(top: 16),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              if (snap.hasError) {
                return SoftCard(
                  background: scheme.errorContainer.withValues(alpha: 0.55),
                  child: Text(
                    '${snap.error}',
                    style: TextStyle(color: scheme.onErrorContainer),
                  ),
                );
              }
              final list = snap.data ?? [];
              if (list.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.only(top: 120),
                  child: Center(child: Text('Nema prijavljenih ispita.')),
                );
              }

              return Column(
                children: [
                  for (final e in list) ...[
                    _MyExamCard(
                      exam: e,
                      subtitle:
                          '${e.examPeriodName}\n${fmt.format(DateTime.fromMillisecondsSinceEpoch(e.examMs))}'
                          '${e.location != null ? '\n${e.location}' : ''}',
                      trailingTop: e.passed ? 'Položen' : 'Preostalo',
                      trailingBottom: e.passed ? null : _countdown(e.examMs),
                    ),
                    const SizedBox(height: 10),
                  ],
                ],
              );
            },
          ),
        ),
      ),
    ];
  }
}

class _ExamOfferCard extends StatelessWidget {
  const _ExamOfferCard({
    required this.offer,
    required this.subtitle,
    required this.onRegister,
  });

  final ExamOffer offer;
  final String subtitle;
  final VoidCallback onRegister;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    return SoftCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: scheme.primaryContainer.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(Icons.event_available, color: scheme.primary, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  offer.subjectName,
                  style: t.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Text(subtitle, style: t.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: FilledButton(
                    onPressed: onRegister,
                    child: const Text('Prijavi'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MyExamCard extends StatelessWidget {
  const _MyExamCard({
    required this.exam,
    required this.subtitle,
    required this.trailingTop,
    required this.trailingBottom,
  });

  final MyRegisteredExam exam;
  final String subtitle;
  final String trailingTop;
  final String? trailingBottom;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;

    return SoftCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: (exam.passed ? scheme.tertiaryContainer : scheme.secondaryContainer)
                  .withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              exam.passed ? Icons.check_circle : Icons.timer_outlined,
              color: exam.passed ? scheme.tertiary : scheme.secondary,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  exam.subjectName,
                  style: t.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Text(subtitle, style: t.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (exam.passed) ...[
                    Icon(Icons.check_circle, color: scheme.tertiary, size: 18),
                    const SizedBox(width: 6),
                  ],
                  Text(trailingTop, style: t.labelLarge?.copyWith(fontWeight: FontWeight.w800)),
                ],
              ),
              if (trailingBottom != null) ...[
                const SizedBox(height: 6),
                Text(
                  trailingBottom!,
                  style: t.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                  textAlign: TextAlign.right,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
