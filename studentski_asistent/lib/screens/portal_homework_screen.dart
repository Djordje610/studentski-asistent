import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../auth/auth_controller.dart';
import '../data/academy_repository.dart';
import '../models/academy_portal.dart';
import '../ui/widgets/soft_card.dart';

class PortalHomeworkScreen extends StatefulWidget {
  const PortalHomeworkScreen({super.key, required this.repo});

  final AcademyRepository repo;

  @override
  State<PortalHomeworkScreen> createState() => _PortalHomeworkScreenState();
}

class _PortalHomeworkScreenState extends State<PortalHomeworkScreen> {
  late Future<List<PortalHomeworkRow>> _future;
  int _filterIndex = 0;

  @override
  void initState() {
    super.initState();
    _future = widget.repo.studentHomework();
  }

  Future<void> _reload() async {
    setState(() {
      _future = widget.repo.studentHomework();
    });
  }

  String? _due(PortalHomeworkRow h) {
    final ms = h.dueDateMs;
    if (ms == null) {
      return null;
    }
    return DateFormat.yMMMd('sr_Latn').add_Hm().format(
          DateTime.fromMillisecondsSinceEpoch(ms),
        );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _reload,
        child: FutureBuilder<List<PortalHomeworkRow>>(
          future: _future,
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snap.hasError) {
              return CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  _buildHeader(context),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                    sliver: SliverToBoxAdapter(
                      child: SoftCard(
                        background: scheme.errorContainer.withValues(alpha: 0.55),
                        child: Text(
                          '${snap.error}',
                          style: TextStyle(color: scheme.onErrorContainer),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            }
            final list = snap.data ?? [];
            if (list.isEmpty) {
              return CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  _buildHeader(context),
                  const SliverToBoxAdapter(child: SizedBox(height: 120)),
                  const SliverToBoxAdapter(
                    child: Center(child: Text('Nema dodeljenih domaćih.')),
                  ),
                ],
              );
            }

            final filtered = _applyFilter(list);
            return CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                _buildHeader(context),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  sliver: SliverToBoxAdapter(
                    child: _Filters(
                      selectedIndex: _filterIndex,
                      onSelected: (i) => setState(() => _filterIndex = i),
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  sliver: SliverList.separated(
                    itemCount: filtered.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, i) => _HomeworkCard(
                      row: filtered[i],
                      dueText: _due(filtered[i]),
                      onToggle: (v) async {
                        try {
                          await widget.repo.setHomeworkCompleted(filtered[i].assignmentId, v);
                          await _reload();
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context)
                                .showSnackBar(SnackBar(content: Text('$e')));
                          }
                        }
                      },
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  List<PortalHomeworkRow> _applyFilter(List<PortalHomeworkRow> list) {
    if (_filterIndex == 0) return list;
    if (_filterIndex == 1) {
      return list.where((h) => !h.completed).toList(growable: false);
    }
    return list.where((h) => h.completed).toList(growable: false);
  }

  SliverAppBar _buildHeader(BuildContext context) {
    return SliverAppBar.large(
      pinned: true,
      title: const Text('Domaći'),
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
          'Domaći zadaci',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
      ),
    );
  }
}

class _Filters extends StatelessWidget {
  const _Filters({required this.selectedIndex, required this.onSelected});

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SegmentedButton<int>(
      segments: const [
        ButtonSegment(value: 0, label: Text('Svi')),
        ButtonSegment(value: 1, label: Text('Aktivni')),
        ButtonSegment(value: 2, label: Text('Završeni')),
      ],
      selected: {selectedIndex},
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
      onSelectionChanged: (s) => onSelected(s.first),
    );
  }
}

class _HomeworkCard extends StatelessWidget {
  const _HomeworkCard({
    required this.row,
    required this.dueText,
    required this.onToggle,
  });

  final PortalHomeworkRow row;
  final String? dueText;
  final ValueChanged<bool> onToggle;

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
              color: (row.completed ? scheme.tertiaryContainer : scheme.primaryContainer)
                  .withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              row.completed ? Icons.check_circle : Icons.assignment_outlined,
              color: row.completed ? scheme.tertiary : scheme.primary,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        row.title,
                        style: t.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Checkbox(
                      value: row.completed,
                      onChanged: (v) {
                        if (v == null) return;
                        onToggle(v);
                      },
                    ),
                  ],
                ),
                Text(
                  row.subjectName,
                  style: t.labelLarge?.copyWith(color: scheme.onSurface),
                ),
                if (row.description != null && row.description!.trim().isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    row.description!.trim(),
                    style: t.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                if (dueText != null) ...[
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: scheme.secondaryContainer.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        'Rok: $dueText',
                        style: t.labelMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: scheme.onSecondaryContainer,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
