import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:peakflow/db/prefs.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:peakflow/l10n/l10n.dart';
import 'package:peakflow/providers/day_entries_provider.dart';
import 'package:peakflow/views/add_view.dart';
import 'package:peakflow/views/graph_view.dart';
import 'package:peakflow/views/settings_view.dart';
import 'package:peakflow/widgets/date_widget.dart';
import 'package:peakflow/widgets/timeline_slider_parts.dart';
import 'package:peakflow/models/day_entry_model.dart';

class HomeView extends ConsumerStatefulWidget {
  const HomeView({super.key});

  @override
  ConsumerState<HomeView> createState() => _HomeViewState();
}

enum _HomePage { timeline, graph }

class _HomeViewState extends ConsumerState<HomeView> {
  final ScrollController _scrollController = ScrollController();
  bool isListLoading = true;
  bool isTimelineDragging = false;
  int dataPageRevision = 0;
  _HomePage selectedPage = _HomePage.timeline;

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
      await entriesFuture;
      if (!mounted) {
        return;
      }
      ref.invalidate(colorReferenceMaxValueProvider);
      setState(() {
        dataPageRevision++;
      });
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

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  int get _selectedPageIndex {
    return selectedPage == _HomePage.timeline ? 0 : 1;
  }

  void _selectPage(_HomePage page) {
    if (selectedPage == page) {
      return;
    }

    setState(() {
      selectedPage = page;
    });
  }

  Future<void> _openSettings() async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const SettingsView()));
    await _refreshHomeData();
  }

  @override
  Widget build(BuildContext context) {
    final timelineEntries = ref.watch(timelineEntryListProvider);
    final referenceMaxValue = ref
        .watch(colorReferenceMaxValueProvider)
        .maybeWhen(data: (value) => value, orElse: () => defaultMaxVolume);
    final yearSections = _buildSections(timelineEntries);
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = _getCrossAxisCount(constraints.maxWidth);
        return Scaffold(
          body: SafeArea(
            bottom: false,
            child: Stack(
              children: [
                Positioned.fill(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    switchInCurve: Curves.easeOut,
                    switchOutCurve: Curves.easeIn,
                    transitionBuilder: (child, animation) {
                      return FadeTransition(opacity: animation, child: child);
                    },
                    child: selectedPage == _HomePage.timeline
                        ? _TimelinePage(
                            key: const ValueKey('timelinePage'),
                            scrollController: _scrollController,
                            entries: timelineEntries,
                            yearSections: yearSections,
                            crossAxisCount: crossAxisCount,
                            viewportWidth: constraints.maxWidth,
                            referenceMaxValue: referenceMaxValue,
                            isListLoading: isListLoading,
                            isTimelineDragging: isTimelineDragging,
                            onDragStateChanged: (isDragging) {
                              if (isTimelineDragging == isDragging) {
                                return;
                              }
                              setState(() {
                                isTimelineDragging = isDragging;
                              });
                            },
                          )
                        : GraphView(
                            key: ValueKey(dataPageRevision),
                            showScaffold: false,
                          ),
                  ),
                ),
                Positioned(
                  top: 0,
                  right: 4,
                  child: Material(
                    color: Colors.transparent,
                    shape: const CircleBorder(),
                    clipBehavior: Clip.antiAlias,
                    child: IconButton(
                      onPressed: _openSettings,
                      icon: const Icon(Icons.settings),
                    ),
                  ),
                ),
                Positioned(
                  left: 16,
                  bottom: 16,
                  child: SafeArea(
                    top: false,
                    child: _FloatingPageNav(
                      selectedPageIndex: _selectedPageIndex,
                      onSelected: (page) {
                        _selectPage(page);
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () async {
              await showAddReadingDrawer(context);
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
    final desiredCardWidth = width < 600 ? 96.0 : 136.0;
    final usableWidth = width - horizontalPadding;
    return (usableWidth / desiredCardWidth).floor().clamp(2, 64);
  }
}

class _TimelinePage extends StatelessWidget {
  final ScrollController scrollController;
  final List<DayEntry> entries;
  final List<_HomeYearSection> yearSections;
  final int crossAxisCount;
  final double viewportWidth;
  final int referenceMaxValue;
  final bool isListLoading;
  final bool isTimelineDragging;
  final ValueChanged<bool> onDragStateChanged;

  const _TimelinePage({
    super.key,
    required this.scrollController,
    required this.entries,
    required this.yearSections,
    required this.crossAxisCount,
    required this.viewportWidth,
    required this.referenceMaxValue,
    required this.isListLoading,
    required this.isTimelineDragging,
    required this.onDragStateChanged,
  });

  @override
  Widget build(BuildContext context) {
    final localeName = Localizations.localeOf(context).toLanguageTag();
    return Stack(
      children: [
        CustomScrollView(
          key: const ValueKey('homeTimelineScrollView'),
          controller: scrollController,
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
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: Text(context.l10n.noDataAvailable)),
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
                                  localeName,
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
          ],
        ),
        if (entries.isNotEmpty)
          _TimelineScrollOverlay(
            controller: scrollController,
            yearSections: yearSections,
            crossAxisCount: crossAxisCount,
            viewportWidth: viewportWidth,
            isDragging: isTimelineDragging,
            onDragStateChanged: onDragStateChanged,
          ),
      ],
    );
  }
}

class _FloatingPageNav extends StatelessWidget {
  static const double _itemWidth = 104;
  static const double _itemHeight = 44;

  final int selectedPageIndex;
  final ValueChanged<_HomePage> onSelected;

  const _FloatingPageNav({
    required this.selectedPageIndex,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final inactiveForeground = theme.colorScheme.onSurface.withValues(
      alpha: 0.72,
    );
    final activeForeground = theme.colorScheme.onPrimary;
    const duration = Duration(milliseconds: 240);
    const curve = Curves.easeOutCubic;

    return Material(
      color: theme.colorScheme.surface,
      elevation: 6,
      shadowColor: theme.shadowColor.withValues(alpha: 0.18),
      borderRadius: BorderRadius.circular(999),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: SizedBox(
          width: _itemWidth * 2,
          height: _itemHeight,
          child: TweenAnimationBuilder<double>(
            tween: Tween<double>(end: selectedPageIndex.toDouble()),
            duration: duration,
            curve: curve,
            builder: (context, thumbPosition, _) {
              final thumbLeft = thumbPosition * _itemWidth;

              return Stack(
                children: [
                  Positioned(
                    left: thumbLeft,
                    top: 0,
                    bottom: 0,
                    width: _itemWidth,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  _FloatingPageNavItems(
                    selectedPageIndex: selectedPageIndex,
                    foreground: inactiveForeground,
                    onSelected: onSelected,
                  ),
                  Positioned(
                    left: thumbLeft,
                    top: 0,
                    bottom: 0,
                    width: _itemWidth,
                    child: ExcludeSemantics(
                      child: IgnorePointer(
                        child: ClipRect(
                          child: OverflowBox(
                            minWidth: _itemWidth * 2,
                            maxWidth: _itemWidth * 2,
                            alignment: Alignment.centerLeft,
                            child: Transform.translate(
                              offset: Offset(-thumbLeft, 0),
                              child: SizedBox(
                                width: _itemWidth * 2,
                                height: _itemHeight,
                                child: _FloatingPageNavItems(
                                  selectedPageIndex: selectedPageIndex,
                                  foreground: activeForeground,
                                  onSelected: onSelected,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _FloatingPageNavItems extends StatelessWidget {
  final int selectedPageIndex;
  final Color foreground;
  final ValueChanged<_HomePage> onSelected;

  const _FloatingPageNavItems({
    required this.selectedPageIndex,
    required this.foreground,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _FloatingPageNavItem(
          width: _FloatingPageNav._itemWidth,
          icon: Icons.calendar_today_outlined,
          label: context.l10n.timelineTab,
          foreground: foreground,
          isSelected: selectedPageIndex == 0,
          onTap: () => onSelected(_HomePage.timeline),
        ),
        _FloatingPageNavItem(
          width: _FloatingPageNav._itemWidth,
          icon: Icons.show_chart,
          label: context.l10n.graphTab,
          foreground: foreground,
          isSelected: selectedPageIndex == 1,
          onTap: () => onSelected(_HomePage.graph),
        ),
      ],
    );
  }
}

class _FloatingPageNavItem extends StatelessWidget {
  final double width;
  final IconData icon;
  final String label;
  final Color foreground;
  final bool isSelected;
  final VoidCallback onTap;

  const _FloatingPageNavItem({
    required this.width,
    required this.icon,
    required this.label,
    required this.foreground,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      button: true,
      selected: isSelected,
      label: label,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: SizedBox(
          width: width,
          height: _FloatingPageNav._itemHeight,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRect(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOut,
                  width: isSelected ? 32 : 0,
                  height: 24,
                  alignment: Alignment.centerLeft,
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: Center(
                      child: Icon(icon, size: 20, color: foreground),
                    ),
                  ),
                ),
              ),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.fade,
                  softWrap: false,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: foreground,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
  static const double _topInset = 52;

  late _TimelineIndex _timeline;
  final ValueNotifier<int?> _activeYear = ValueNotifier<int?>(null);
  double? _pendingScrollOffset;
  bool _layoutRefreshScheduled = false;
  bool _scrollJumpScheduled = false;

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

    return Positioned(
      top: _topInset,
      right: 0,
      bottom: 0,
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
                              child: TimelineSliderPill(
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
    _scheduleScrollJump(widget.controller.position.maxScrollExtent * fraction);
  }

  void _scheduleScrollJump(double targetOffset) {
    _pendingScrollOffset = targetOffset;
    if (_scrollJumpScheduled) {
      return;
    }

    _scrollJumpScheduled = true;
    SchedulerBinding.instance.scheduleFrameCallback((_) {
      _scrollJumpScheduled = false;
      if (!mounted || !widget.controller.hasClients) {
        _pendingScrollOffset = null;
        return;
      }

      final offset = _pendingScrollOffset;
      _pendingScrollOffset = null;
      if (offset == null) {
        return;
      }

      final position = widget.controller.position;
      final target = offset
          .clamp(position.minScrollExtent, position.maxScrollExtent)
          .toDouble();
      if ((widget.controller.offset - target).abs() < 0.5) {
        return;
      }

      widget.controller.jumpTo(target);
    });
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

  @override
  Widget build(BuildContext context) {
    final localeName = Localizations.localeOf(context).toLanguageTag();
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
                child: TimelineSliderPill(
                  key: const ValueKey('homeTimelineMonthLabel'),
                  label: DateFormat(
                    'MMM yyyy',
                    localeName,
                  ).format(currentMonth.date),
                ),
              ),
              const SizedBox(width: 8),
              TimelineSliderHandle(
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

class _GapIndicatorTile extends StatelessWidget {
  final int gapDays;

  const _GapIndicatorTile({required this.gapDays});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
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
            isSingleDayGap ? l10n.gapOneDay : l10n.gapDays(gapDays),
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
          Text(
            isSingleDayGap ? l10n.gapBetween : l10n.gapMissing,
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
