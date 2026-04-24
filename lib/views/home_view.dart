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
    final yearSections = _buildSections(entries);
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
              for (
                int yearIndex = 0;
                yearIndex < yearSections.length;
                yearIndex++
              )
                SliverMainAxisGroup(
                  slivers: [
                    SliverPersistentHeader(
                      pinned: true,
                      delegate: _SectionHeaderDelegate(
                        height: 44,
                        child: _SectionTitle(
                          title: yearSections[yearIndex].year.toString(),
                          fontSize: 28,
                          topPadding: yearIndex == 0 ? 8 : 14,
                          bottomPadding: 2,
                        ),
                      ),
                    ),
                    for (final monthSection in yearSections[yearIndex].months)
                      SliverMainAxisGroup(
                        slivers: [
                          SliverPersistentHeader(
                            pinned: true,
                            delegate: _SectionHeaderDelegate(
                              height: 34,
                              child: _SectionTitle(
                                title: DateFormat(
                                  "MMMM",
                                ).format(monthSection.month),
                                fontSize: 18,
                                topPadding: 8,
                                bottomPadding: 6,
                              ),
                            ),
                          ),
                          SliverPadding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            sliver: SliverGrid(
                              delegate: SliverChildBuilderDelegate((
                                context,
                                itemIndex,
                              ) {
                                final item = monthSection.items[itemIndex];
                                if (item.dayEntry != null) {
                                  return DateWidget(
                                    dayEntry: item.dayEntry!,
                                    referenceMaxValue: referenceMaxValue,
                                  );
                                }
                                return _GapIndicatorTile(
                                  gapDays: item.gapDays!,
                                );
                              }, childCount: monthSection.items.length),
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: crossAxisCount,
                                    mainAxisSpacing: 8,
                                    crossAxisSpacing: 8,
                                    childAspectRatio: 0.84,
                                  ),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
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

  List<_HomeYearSection> _buildSections(List<DayEntry> entries) {
    final sections = <_HomeYearSection>[];
    DayEntry? previousEntry;

    for (final entry in entries) {
      if (sections.isEmpty || sections.last.year != entry.date.year) {
        sections.add(_HomeYearSection(year: entry.date.year, months: []));
      }

      final months = sections.last.months;
      if (months.isEmpty || !_isSameMonth(months.last.month, entry.date)) {
        months.add(
          _HomeMonthSection(
            month: DateTime(entry.date.year, entry.date.month),
            items: [],
          ),
        );
      }

      final gapDays = previousEntry == null
          ? 0
          : entry.date.difference(previousEntry.date).inDays.abs() - 1;
      if (gapDays > 0) {
        months.last.items.add(_HomeSectionItem.gap(gapDays));
      }

      months.last.items.add(_HomeSectionItem.entry(entry));
      previousEntry = entry;
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

class _HomeYearSection {
  final int year;
  final List<_HomeMonthSection> months;

  _HomeYearSection({required this.year, required this.months});
}

class _HomeMonthSection {
  final DateTime month;
  final List<_HomeSectionItem> items;

  _HomeMonthSection({required this.month, required this.items});
}

class _HomeSectionItem {
  final DayEntry? dayEntry;
  final int? gapDays;

  const _HomeSectionItem._({this.dayEntry, this.gapDays});

  factory _HomeSectionItem.entry(DayEntry dayEntry) {
    return _HomeSectionItem._(dayEntry: dayEntry);
  }

  factory _HomeSectionItem.gap(int gapDays) {
    return _HomeSectionItem._(gapDays: gapDays);
  }
}

class _GapIndicatorTile extends StatelessWidget {
  final int gapDays;

  const _GapIndicatorTile({required this.gapDays});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isSingleDayGap = gapDays == 1;
    const indicatorColor = Colors.white;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (isSingleDayGap)
            Container(
              width: 26,
              height: 3,
              decoration: BoxDecoration(
                color: indicatorColor,
                borderRadius: BorderRadius.circular(999),
              ),
            )
          else
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(3, (index) {
                return Container(
                  width: 6,
                  height: 6,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: const BoxDecoration(
                    color: indicatorColor,
                    shape: BoxShape.circle,
                  ),
                );
              }),
            ),
          const SizedBox(height: 8),
          Text(
            isSingleDayGap ? "1 day" : "$gapDays days",
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
          Text(
            isSingleDayGap ? "between" : "missing",
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
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
