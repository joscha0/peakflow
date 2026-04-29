import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:peakflow/db/prefs.dart';
import 'package:peakflow/global/consts.dart';
import 'package:peakflow/l10n/l10n.dart';
import 'package:peakflow/models/day_entry_model.dart';
import 'package:peakflow/providers/day_entries_provider.dart';
import 'package:peakflow/views/day_view.dart';

class EditDayView extends ConsumerStatefulWidget {
  final DayEntry dayEntry;

  const EditDayView({super.key, required this.dayEntry});

  @override
  ConsumerState<EditDayView> createState() => _EditDayViewState();
}

class _EditDayViewState extends ConsumerState<EditDayView> {
  final noteDayController = TextEditingController();
  Map<String, bool> checkboxValues = Map<String, bool>.from(
    defaultCheckboxValues,
  );

  @override
  void initState() {
    super.initState();
    getDay();
  }

  Future<void> getDay() async {
    final entry = await getDayEntry(widget.dayEntry.date);
    if (!mounted) {
      return;
    }
    if (entry != null) {
      setState(() {
        noteDayController.text = entry.note;
        checkboxValues = entry.checkboxValues;
      });
    } else {
      setState(() {
        noteDayController.text = "";
        checkboxValues = Map<String, bool>.from(defaultCheckboxValues);
      });
    }
  }

  @override
  void dispose() {
    noteDayController.dispose();
    super.dispose();
  }

  Widget _buildSectionLabel(
    BuildContext context,
    String title,
    String description,
  ) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 14.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionDivider(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24.0),
      child: Divider(
        height: 1,
        thickness: 1,
        color: Theme.of(context).dividerColor.withValues(alpha: 0.55),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final localeName = Localizations.localeOf(context).toLanguageTag();
    final dateText = DateFormat(
      "dd.MM.yyyy",
      localeName,
    ).format(widget.dayEntry.date);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.editDayTitle), centerTitle: true),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 110),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.editDayIntro(dateText),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.72),
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 24),
              _buildSectionLabel(
                context,
                l10n.symptomsOfTheDayTitle,
                l10n.editDaySymptomsDescription(dateText),
              ),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (final checkBox in checkboxValues.keys)
                    FilterChip(
                      label: Text(l10n.symptomLabel(checkBox)),
                      selected: checkboxValues[checkBox] ?? false,
                      showCheckmark: true,
                      checkmarkColor: theme.colorScheme.primary,
                      selectedColor: theme.colorScheme.primary.withValues(
                        alpha: 0.16,
                      ),
                      side: BorderSide(
                        color: (checkboxValues[checkBox] ?? false)
                            ? theme.colorScheme.primary
                            : theme.dividerColor.withValues(alpha: 0.85),
                      ),
                      labelStyle: theme.textTheme.bodyMedium?.copyWith(
                        color: (checkboxValues[checkBox] ?? false)
                            ? theme.colorScheme.primary
                            : null,
                        fontWeight: (checkboxValues[checkBox] ?? false)
                            ? FontWeight.w700
                            : FontWeight.w500,
                      ),
                      onSelected: (value) {
                        setState(() {
                          checkboxValues[checkBox] = value;
                        });
                      },
                    ),
                ],
              ),
              _buildSectionDivider(context),
              _buildSectionLabel(
                context,
                l10n.dayNotesTitle,
                l10n.editDayNotesDescription,
              ),
              TextFormField(
                controller: noteDayController,
                maxLines: 3,
                onTapOutside: (_) {
                  FocusScope.of(context).unfocus();
                },
                decoration: InputDecoration(
                  labelText: l10n.dayNotesLabel,
                  hintText: l10n.dayNotesHint,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          DayEntry newEntry = await updateDay(
            widget.dayEntry,
            noteDayController.text,
            checkboxValues,
          );
          ref.read(entryListProvider.notifier).loadEntries();
          if (!context.mounted) {
            return;
          }
          Navigator.pop(context);
          Navigator.pushReplacement(
            context,
            PageRouteBuilder(
              pageBuilder: (context, animation1, animation2) =>
                  DayView(dayEntry: newEntry),
              transitionDuration: const Duration(seconds: 0),
            ),
          );
        },
        label: Text(l10n.saveUpper),
        icon: const Icon(Icons.save),
      ),
    );
  }
}
