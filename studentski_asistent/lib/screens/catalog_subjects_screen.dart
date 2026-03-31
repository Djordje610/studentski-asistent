import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../auth/auth_controller.dart';
import '../data/academy_repository.dart';
import '../models/academy_portal.dart';
import '../ui/widgets/soft_card.dart';

class CatalogSubjectsScreen extends StatefulWidget {
  const CatalogSubjectsScreen({super.key, required this.repo});

  final AcademyRepository repo;

  @override
  State<CatalogSubjectsScreen> createState() => _CatalogSubjectsScreenState();
}

class _CatalogSubjectsScreenState extends State<CatalogSubjectsScreen> {
  late Future<List<CatalogSubjectRow>> _future;
  int _filterIndex = 0;

  @override
  void initState() {
    super.initState();
    _future = widget.repo.studentCatalogSubjects();
  }

  Future<void> _reload() async {
    setState(() {
      _future = widget.repo.studentCatalogSubjects();
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _reload,
        child: FutureBuilder<List<CatalogSubjectRow>>(
          future: _future,
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snap.hasError) {
              return CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  _buildHeader(context, scheme),
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
                  _buildHeader(context, scheme),
                  const SliverToBoxAdapter(child: SizedBox(height: 120)),
                  const SliverToBoxAdapter(
                    child: Center(child: Text('Nema predmeta za vašu godinu.')),
                  ),
                ],
              );
            }

            final filtered = _applyFilter(list);
            return CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                _buildHeader(context, scheme),
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
                    itemBuilder: (context, i) => _SubjectCard(row: filtered[i]),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  List<CatalogSubjectRow> _applyFilter(List<CatalogSubjectRow> list) {
    if (_filterIndex == 0) return list;
    if (_filterIndex == 1) {
      return list.where((s) => (s.espb) >= 6).toList(growable: false);
    }
    return list.where((s) => (s.espb) < 6).toList(growable: false);
  }

  SliverAppBar _buildHeader(BuildContext context, ColorScheme scheme) {
    return SliverAppBar.large(
      floating: false,
      pinned: true,
      title: const Text('Predmeti'),
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
          'Predmeti na godini',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: scheme.onSurface,
              ),
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
    return Row(
      children: [
        Expanded(
          child: SegmentedButton<int>(
            segments: const [
              ButtonSegment(value: 0, label: Text('Svi')),
              ButtonSegment(value: 1, label: Text('6+ ESPB')),
              ButtonSegment(value: 2, label: Text('<6 ESPB')),
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
          ),
        ),
      ],
    );
  }
}

class _SubjectCard extends StatelessWidget {
  const _SubjectCard({required this.row});

  final CatalogSubjectRow row;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    final subtitle = '${row.programCode} · Godina ${row.yearNumber} · ${row.espb} ESPB';
    final code = (row.code ?? '').trim();

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
            child: Icon(Icons.menu_book, color: scheme.primary, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  row.name,
                  style: t.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(subtitle, style: t.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
                if (code.isNotEmpty) ...[
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
                        code,
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
          const SizedBox(width: 8),
          Icon(Icons.chevron_right, color: scheme.onSurfaceVariant),
        ],
      ),
    );
  }
}
