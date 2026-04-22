import 'package:flutter/material.dart';
import 'package:peakflow/db/prefs.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:peakflow/providers/day_entries_provider.dart';
import 'package:peakflow/views/add_view.dart';
import 'package:peakflow/views/graph_view.dart';
import 'package:peakflow/views/settings_view.dart';
import 'package:peakflow/widgets/date_widget.dart';
import 'package:peakflow/models/day_entry_model.dart';

class HomeView extends ConsumerStatefulWidget {
  const HomeView({super.key});

  @override
  ConsumerState<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends ConsumerState<HomeView> {
  int referenceMaxValue = defaultMaxVolume;
  bool sortUp = true;

  @override
  void initState() {
    super.initState();
    init();
  }

  Future<void> init() async {
    final loadedReferenceMaxValue = await getColorReferenceMaxValue();
    final loadedSortUp = await getSortValue();
    if (!mounted) {
      return;
    }
    setState(() {
      referenceMaxValue = loadedReferenceMaxValue;
      sortUp = loadedSortUp;
    });
    ref.read(entryListProvider.notifier).loadEntries();
  }

  void changeSort() {
    ref.read(entryListProvider.notifier).changeSort();
    setState(() {
      sortUp = !sortUp;
    });
    setSortValue(sortUp);
  }

  @override
  Widget build(BuildContext context) {
    final entries = ref.watch(entryListProvider);
    final sections = _buildSections(entries);
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = _getCrossAxisCount(constraints.maxWidth);
        return Scaffold(
          appBar: AppBar(
            centerTitle: true,
            title: const Text("PEAK FLOW"),
            actions: [
              IconButton(
                onPressed: changeSort,
                icon: Icon(sortUp ? Icons.arrow_upward : Icons.arrow_downward),
              ),
              IconButton(
                onPressed: () async {
                  await Navigator.of(
                    context,
                  ).push(MaterialPageRoute(builder: (_) => const GraphView()));
                  await init();
                },
                icon: const Icon(Icons.bar_chart),
              ),
              IconButton(
                onPressed: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const SettingsView()),
                  );
                  await init();
                },
                icon: const Icon(Icons.settings),
              ),
            ],
          ),
          body: CustomScrollView(
            slivers: [
              for (int index = 0; index < sections.length; index++) ...[
                if (index == 0 ||
                    sections[index].year != sections[index - 1].year)
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: _SectionHeaderDelegate(
                      height: 44,
                      child: _SectionTitle(
                        title: sections[index].year.toString(),
                        fontSize: 28,
                        topPadding: index == 0 ? 8 : 14,
                        bottomPadding: 2,
                      ),
                    ),
                  ),
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _SectionHeaderDelegate(
                    height: 34,
                    child: _SectionTitle(
                      title: DateFormat("MMMM").format(sections[index].month),
                      fontSize: 18,
                      topPadding: 8,
                      bottomPadding: 6,
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  sliver: SliverGrid(
                    delegate: SliverChildBuilderDelegate((context, itemIndex) {
                      return DateWidget(
                        dayEntry: sections[index].entries[itemIndex],
                        referenceMaxValue: referenceMaxValue,
                      );
                    }, childCount: sections[index].entries.length),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                      childAspectRatio: 0.84,
                    ),
                  ),
                ),
              ],
              const SliverToBoxAdapter(child: SizedBox(height: 84)),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () async {
              await Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const AddView()));
              await init();
            },
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }

  List<_HomeSection> _buildSections(List<DayEntry> entries) {
    final sections = <_HomeSection>[];
    for (final entry in entries) {
      if (sections.isEmpty || !_isSameMonth(sections.last.month, entry.date)) {
        sections.add(
          _HomeSection(
            year: entry.date.year,
            month: DateTime(entry.date.year, entry.date.month),
            entries: [entry],
          ),
        );
      } else {
        sections.last.entries.add(entry);
      }
    }
    return sections;
  }

  bool _isSameMonth(DateTime first, DateTime second) {
    return first.year == second.year && first.month == second.month;
  }

  int _getCrossAxisCount(double width) {
    const horizontalPadding = 16.0;
    const desiredCardWidth = 96.0;
    final usableWidth = width - horizontalPadding;
    return (usableWidth / desiredCardWidth).floor().clamp(2, 8);
  }
}

class _HomeSection {
  final int year;
  final DateTime month;
  final List<DayEntry> entries;

  _HomeSection({
    required this.year,
    required this.month,
    required this.entries,
  });
}

class _SectionHeaderDelegate extends SliverPersistentHeaderDelegate {
  final double height;
  final Widget child;

  const _SectionHeaderDelegate({required this.height, required this.child});

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return SizedBox.expand(
      child: ColoredBox(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: child,
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _SectionHeaderDelegate oldDelegate) {
    return oldDelegate.height != height || oldDelegate.child != child;
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final double fontSize;
  final double topPadding;
  final double bottomPadding;

  const _SectionTitle({
    required this.title,
    required this.fontSize,
    required this.topPadding,
    required this.bottomPadding,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(12, topPadding, 12, bottomPadding),
      child: Text(
        title,
        style: theme.textTheme.titleLarge?.copyWith(
          fontSize: fontSize,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
