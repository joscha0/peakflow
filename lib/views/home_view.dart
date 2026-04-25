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
  final ScrollController _scrollController = ScrollController();
  int referenceMaxValue = defaultMaxVolume;
  bool sortUp = true;
  bool isListLoading = true;
  bool isTimelineDragging = false;

  @override
  void initState() {
    super.initState();
    _refreshHomeData();
  }

  Future<void> _refreshHomeData() async {
    if (!isListLoading && mounted) {
      setState(() {
        isListLoading = true;
      });
    }

    final entriesFuture = ref.read(entryListProvider.notifier).loadEntries();

    try {
      final values = await Future.wait<Object>([
        getColorReferenceMaxValue(),
        getSortValue(),
      ]);
      if (!mounted) {
        return;
      }
      setState(() {
        referenceMaxValue = values[0] as int;
        sortUp = values[1] as bool;
      });
      await entriesFuture;
    } finally {
      if (mounted) {
        setState(() {
          isListLoading = false;
        });
      } else {
        isListLoading = false;
      }
    }
  }

  void changeSort() {
    ref.read(entryListProvider.notifier).changeSort();
    setState(() {
      sortUp = !sortUp;
    });
    setSortValue(sortUp);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
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
                  await _refreshHomeData();
                },
                icon: const Icon(Icons.bar_chart),
              ),
              IconButton(
                onPressed: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const SettingsView()),
                  );
                  await _refreshHomeData();
                },
                icon: const Icon(Icons.settings),
              ),
            ],
          ),
          body: Stack(
            children: [
              CustomScrollView(
                controller: _scrollController,
                slivers: [
                  if (isListLoading && entries.isEmpty)
                    const SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: SizedBox(
                          width: 28,
                          height: 28,
                          child: CircularProgressIndicator(),
                        ),
                      ),
                    )
                  else if (entries.isEmpty)
                    const SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(child: Text('No data available yet.')),
                    )
                  else ...[
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
                          for (final monthSection
                              in yearSections[yearIndex].months)
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
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                  ),
                                  sliver: SliverGrid(
                                    delegate: SliverChildBuilderDelegate((
                                      context,
                                      itemIndex,
                                    ) {
                                      final item =
                                          monthSection.items[itemIndex];
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
                ],
              ),
              if (entries.isNotEmpty)
                _TimelineScrollOverlay(
                  controller: _scrollController,
                  yearSections: yearSections,
                  crossAxisCount: crossAxisCount,
                  viewportWidth: constraints.maxWidth,
                  isDragging: isTimelineDragging,
                  onDragStateChanged: (isDragging) {
                    if (isTimelineDragging == isDragging) {
                      return;
                    }
                    setState(() {
                      isTimelineDragging = isDragging;
                    });
                  },
                ),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () async {
              await Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const AddView()));
              await _refreshHomeData();
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

class _TimelineScrollOverlay extends StatefulWidget {
  final ScrollController controller;
  final List<_HomeYearSection> yearSections;
  final int crossAxisCount;
  final double viewportWidth;
  final bool isDragging;
  final ValueChanged<bool> onDragStateChanged;

  const _TimelineScrollOverlay({
    required this.controller,
    required this.yearSections,
    required this.crossAxisCount,
    required this.viewportWidth,
    required this.isDragging,
    required this.onDragStateChanged,
  });

  @override
  State<_TimelineScrollOverlay> createState() => _TimelineScrollOverlayState();
}

class _TimelineScrollOverlayState extends State<_TimelineScrollOverlay> {
  static const double _handleHeight = 44;
  static const double _handleWidth = 12;
  static const double _railWidth = 56;
  static const double _rightInset = 6;

  late _TimelineIndex _timeline;
  final ValueNotifier<int?> _activeYear = ValueNotifier<int?>(null);
  bool _layoutRefreshScheduled = false;

  @override
  void initState() {
    super.initState();
    _timeline = _buildTimeline();
    widget.controller.addListener(_updateActiveYear);
    _scheduleLayoutRefresh();
  }

  @override
  void didUpdateWidget(covariant _TimelineScrollOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_updateActiveYear);
      widget.controller.addListener(_updateActiveYear);
    }

    if (oldWidget.yearSections != widget.yearSections ||
        oldWidget.crossAxisCount != widget.crossAxisCount ||
        oldWidget.viewportWidth != widget.viewportWidth) {
      _timeline = _buildTimeline();
    }

    _scheduleLayoutRefresh();
  }

  @override
  void dispose() {
    widget.controller.removeListener(_updateActiveYear);
    _activeYear.dispose();
    super.dispose();
  }

  _TimelineIndex _buildTimeline() {
    return _TimelineIndex.fromSections(
      yearSections: widget.yearSections,
      crossAxisCount: widget.crossAxisCount,
      viewportWidth: widget.viewportWidth,
    );
  }

  void _scheduleLayoutRefresh() {
    if (_layoutRefreshScheduled) {
      return;
    }

    _layoutRefreshScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _layoutRefreshScheduled = false;
      if (!mounted) {
        return;
      }

      _updateActiveYear();
      setState(() {});
    });
  }

  void _updateActiveYear() {
    if (!widget.controller.hasClients ||
        widget.controller.position.maxScrollExtent <= 0) {
      return;
    }

    final maxScrollExtent = widget.controller.position.maxScrollExtent;
    final fraction = (widget.controller.offset / maxScrollExtent)
        .clamp(0.0, 1.0)
        .toDouble();
    final year = _timeline.monthForFraction(fraction).date.year;
    if (_activeYear.value != year) {
      _activeYear.value = year;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Positioned.fill(
      child: Align(
        alignment: Alignment.centerRight,
        child: LayoutBuilder(
          builder: (context, constraints) {
            if (!widget.controller.hasClients ||
                widget.controller.position.maxScrollExtent <= 0) {
              return const SizedBox.shrink();
            }

            final availableHeight = constraints.maxHeight - _handleHeight;

            return SizedBox(
              width: _railWidth,
              height: constraints.maxHeight,
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTapDown: (details) => _jumpToLocalPosition(
                  details.localPosition.dy,
                  constraints.maxHeight,
                ),
                onVerticalDragStart: (details) {
                  widget.onDragStateChanged(true);
                  _jumpToLocalPosition(
                    details.localPosition.dy,
                    constraints.maxHeight,
                  );
                },
                onVerticalDragUpdate: (details) => _jumpToLocalPosition(
                  details.localPosition.dy,
                  constraints.maxHeight,
                ),
                onVerticalDragEnd: (_) => widget.onDragStateChanged(false),
                onVerticalDragCancel: () => widget.onDragStateChanged(false),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned(
                      top: 8,
                      bottom: 8,
                      right: _rightInset + (_handleWidth / 2) - 1,
                      child: AnimatedOpacity(
                        opacity: widget.isDragging ? 0.28 : 0.16,
                        duration: const Duration(milliseconds: 140),
                        child: Container(
                          width: 2,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.onSurface,
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ),
                    ),
                    for (final marker in _timeline.yearMarkers)
                      Positioned(
                        top: (marker.fraction * availableHeight)
                            .clamp(0.0, availableHeight)
                            .toDouble(),
                        right: 28,
                        child: ValueListenableBuilder<int?>(
                          valueListenable: _activeYear,
                          builder: (context, activeYear, child) {
                            return AnimatedOpacity(
                              opacity: widget.isDragging ? 1 : 0,
                              duration: const Duration(milliseconds: 120),
                              child: _TimelinePill(
                                key: ValueKey(
                                  'homeTimelineYearMarker-${marker.year}',
                                ),
                                label: marker.year.toString(),
                                isActive: activeYear == marker.year,
                                compact: true,
                              ),
                            );
                          },
                        ),
                      ),
                    _TimelineHandlePosition(
                      controller: widget.controller,
                      timeline: _timeline,
                      availableHeight: availableHeight,
                      isDragging: widget.isDragging,
                      rightInset: _rightInset,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _jumpToLocalPosition(double localY, double height) {
    if (!widget.controller.hasClients ||
        widget.controller.position.maxScrollExtent <= 0) {
      return;
    }

    final availableHeight = height - _handleHeight;
    final handleTop = (localY - (_handleHeight / 2))
        .clamp(0.0, availableHeight)
        .toDouble();
    final fraction = availableHeight == 0 ? 0.0 : handleTop / availableHeight;
    widget.controller.jumpTo(
      widget.controller.position.maxScrollExtent * fraction,
    );
  }
}

class _TimelineHandlePosition extends StatelessWidget {
  final ScrollController controller;
  final _TimelineIndex timeline;
  final double availableHeight;
  final bool isDragging;
  final double rightInset;

  const _TimelineHandlePosition({
    required this.controller,
    required this.timeline,
    required this.availableHeight,
    required this.isDragging,
    required this.rightInset,
  });

  static final DateFormat _monthYearFormat = DateFormat('MMM yyyy');

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        if (!controller.hasClients ||
            controller.position.maxScrollExtent <= 0) {
          return const SizedBox.shrink();
        }

        final maxScrollExtent = controller.position.maxScrollExtent;
        final fraction = (controller.offset / maxScrollExtent)
            .clamp(0.0, 1.0)
            .toDouble();
        final handleTop = availableHeight * fraction;
        final currentMonth = timeline.monthForFraction(fraction);

        return Positioned(
          top: handleTop,
          right: rightInset,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedOpacity(
                opacity: isDragging ? 1 : 0,
                duration: const Duration(milliseconds: 120),
                child: _TimelinePill(
                  key: const ValueKey('homeTimelineMonthLabel'),
                  label: _monthYearFormat.format(currentMonth.date),
                ),
              ),
              const SizedBox(width: 8),
              _TimelineHandle(
                key: const ValueKey('homeTimelineHandle'),
                isDragging: isDragging,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TimelineIndex {
  final List<_TimelineMonthMarker> monthMarkers;
  final List<_TimelineYearMarker> yearMarkers;

  const _TimelineIndex({required this.monthMarkers, required this.yearMarkers});

  factory _TimelineIndex.fromSections({
    required List<_HomeYearSection> yearSections,
    required int crossAxisCount,
    required double viewportWidth,
  }) {
    const yearHeaderHeight = 44.0;
    const monthHeaderHeight = 34.0;
    const gridSpacing = 8.0;
    const horizontalPadding = 16.0;
    const bottomPadding = 84.0;

    final usableWidth = viewportWidth - horizontalPadding;
    final tileWidth =
        (usableWidth - (gridSpacing * (crossAxisCount - 1))) / crossAxisCount;
    final tileHeight = tileWidth / 0.84;
    final weightedMonths = <_WeightedTimelineMonth>[];
    var totalHeight = 0.0;

    for (final yearSection in yearSections) {
      totalHeight += yearHeaderHeight;
      for (final monthSection in yearSection.months) {
        final start = totalHeight;
        final rowCount = (monthSection.items.length / crossAxisCount).ceil();
        final gridHeight = rowCount == 0
            ? 0.0
            : (rowCount * tileHeight) + ((rowCount - 1) * gridSpacing);
        final sectionHeight = monthHeaderHeight + gridHeight;
        weightedMonths.add(
          _WeightedTimelineMonth(
            month: monthSection.month,
            start: start,
            center: start + (sectionHeight / 2),
          ),
        );
        totalHeight += sectionHeight;
      }
    }

    totalHeight += bottomPadding;
    final safeTotalHeight = totalHeight <= 0 ? 1.0 : totalHeight;
    final monthMarkers = [
      for (final weightedMonth in weightedMonths)
        _TimelineMonthMarker(
          date: weightedMonth.month,
          fraction: (weightedMonth.center / safeTotalHeight).clamp(0.0, 1.0),
        ),
    ];

    final yearMarkers = <_TimelineYearMarker>[];
    int? previousYear;
    for (final weightedMonth in weightedMonths) {
      if (previousYear == weightedMonth.month.year) {
        continue;
      }
      previousYear = weightedMonth.month.year;
      yearMarkers.add(
        _TimelineYearMarker(
          year: weightedMonth.month.year,
          fraction: (weightedMonth.start / safeTotalHeight).clamp(0.0, 1.0),
        ),
      );
    }

    return _TimelineIndex(monthMarkers: monthMarkers, yearMarkers: yearMarkers);
  }

  _TimelineMonthMarker monthForFraction(double fraction) {
    if (monthMarkers.isEmpty) {
      final now = DateTime.now();
      return _TimelineMonthMarker(
        date: DateTime(now.year, now.month),
        fraction: 0,
      );
    }

    var selectedMonth = monthMarkers.first;
    for (final monthMarker in monthMarkers) {
      if (monthMarker.fraction > fraction) {
        break;
      }
      selectedMonth = monthMarker;
    }
    return selectedMonth;
  }
}

class _WeightedTimelineMonth {
  final DateTime month;
  final double start;
  final double center;

  const _WeightedTimelineMonth({
    required this.month,
    required this.start,
    required this.center,
  });
}

class _TimelineMonthMarker {
  final DateTime date;
  final double fraction;

  const _TimelineMonthMarker({required this.date, required this.fraction});
}

class _TimelineYearMarker {
  final int year;
  final double fraction;

  const _TimelineYearMarker({required this.year, required this.fraction});
}

class _TimelineHandle extends StatelessWidget {
  final bool isDragging;

  const _TimelineHandle({super.key, required this.isDragging});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      width: 12,
      height: 44,
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(
          alpha: isDragging ? 0.95 : 0.72,
        ),
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          if (isDragging)
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
        ],
      ),
    );
  }
}

class _TimelinePill extends StatelessWidget {
  final String label;
  final bool isActive;
  final bool compact;

  const _TimelinePill({
    super.key,
    required this.label,
    this.isActive = false,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final backgroundColor = isActive
        ? theme.colorScheme.primary
        : theme.colorScheme.surface;
    final foregroundColor = isActive
        ? theme.colorScheme.onPrimary
        : theme.colorScheme.onSurface;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: compact ? 0.12 : 0.22),
            blurRadius: compact ? 4 : 10,
            offset: Offset(0, compact ? 1 : 3),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 8 : 12,
          vertical: compact ? 4 : 8,
        ),
        child: Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            color: foregroundColor,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _GapIndicatorTile extends StatelessWidget {
  final int gapDays;

  const _GapIndicatorTile({required this.gapDays});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isSingleDayGap = gapDays == 1;
    final indicatorColor = theme.brightness == Brightness.light
        ? Colors.black
        : Colors.white;

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
                  decoration: BoxDecoration(
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
