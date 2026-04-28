import 'package:flutter/material.dart';

class TimelineSliderHandle extends StatelessWidget {
  final bool isDragging;

  const TimelineSliderHandle({super.key, required this.isDragging});

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

class TimelineSliderPill extends StatelessWidget {
  final String label;
  final bool isActive;
  final bool compact;

  const TimelineSliderPill({
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
