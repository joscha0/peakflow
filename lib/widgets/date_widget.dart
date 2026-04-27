import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:peakflow/global/helper.dart';
import 'package:peakflow/l10n/l10n.dart';
import 'package:peakflow/models/day_entry_model.dart';
import 'package:peakflow/views/day_view.dart';

class DateWidget extends StatelessWidget {
  final DayEntry dayEntry;
  final int referenceMaxValue;

  const DateWidget({
    super.key,
    required this.dayEntry,
    required this.referenceMaxValue,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;
    final localeName = Localizations.localeOf(context).toLanguageTag();

    return Card(
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => DayView(dayEntry: dayEntry)),
          );
        },
        child: Padding(
          padding: const EdgeInsets.fromLTRB(6, 6, 6, 4),
          child: Column(
            children: [
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    DateFormat(
                      "EEE",
                      localeName,
                    ).format(dayEntry.date).toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: accent,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Center(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      DateFormat("d").format(dayEntry.date),
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        height: 1,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              SizedBox(
                height: 34,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    if (dayEntry.morningValue != -1)
                      _ValueIndicator(
                        icon: Icons.light_mode,
                        value: dayEntry.morningValue,
                        color: getColor(
                          dayEntry.morningValue,
                          referenceMaxValue,
                        ),
                      ),
                    if (dayEntry.eveningValue != -1)
                      _ValueIndicator(
                        icon: Icons.nights_stay,
                        value: dayEntry.eveningValue,
                        color: getColor(
                          dayEntry.eveningValue,
                          referenceMaxValue,
                        ),
                      ),
                    if (dayEntry.morningValue == -1 &&
                        dayEntry.eveningValue == -1)
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          decoration: BoxDecoration(
                            color: accent.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            context.l10n.noValues,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: accent,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ValueIndicator extends StatelessWidget {
  final IconData icon;
  final int value;
  final Color color;

  const _ValueIndicator({
    required this.icon,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 19, color: color),
        Text(
          value.toString(),
          style: TextStyle(
            color: color,
            fontSize: 14,
            fontWeight: FontWeight.w600,
            height: 1,
          ),
        ),
      ],
    );
  }
}
