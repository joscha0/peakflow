import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

bool _shouldUseCupertinoPicker(BuildContext context) {
  return Theme.of(context).platform == TargetPlatform.iOS;
}

DateTime _clampDate(DateTime date, DateTime firstDate, DateTime lastDate) {
  if (date.isBefore(firstDate)) {
    return firstDate;
  }
  if (date.isAfter(lastDate)) {
    return lastDate;
  }
  return date;
}

Future<DateTime?> showPlatformDatePicker({
  required BuildContext context,
  required DateTime initialDate,
  required DateTime firstDate,
  required DateTime lastDate,
}) {
  final effectiveInitialDate = _clampDate(initialDate, firstDate, lastDate);

  if (!_shouldUseCupertinoPicker(context)) {
    return showDatePicker(
      context: context,
      initialDate: effectiveInitialDate,
      firstDate: firstDate,
      lastDate: lastDate,
    );
  }

  return _showCupertinoPicker<DateTime>(
    context: context,
    initialValue: effectiveInitialDate,
    builder: (context, selectedValueChanged) {
      return CupertinoDatePicker(
        mode: CupertinoDatePickerMode.date,
        initialDateTime: effectiveInitialDate,
        minimumDate: firstDate,
        maximumDate: lastDate,
        onDateTimeChanged: selectedValueChanged,
      );
    },
  );
}

Future<TimeOfDay?> showPlatformTimePicker({
  required BuildContext context,
  required TimeOfDay initialTime,
}) {
  if (!_shouldUseCupertinoPicker(context)) {
    return showTimePicker(context: context, initialTime: initialTime);
  }

  final initialDateTime = DateTime(
    2000,
    1,
    1,
    initialTime.hour,
    initialTime.minute,
  );

  return _showCupertinoPicker<DateTime>(
    context: context,
    initialValue: initialDateTime,
    builder: (context, selectedValueChanged) {
      return CupertinoDatePicker(
        mode: CupertinoDatePickerMode.time,
        initialDateTime: initialDateTime,
        onDateTimeChanged: selectedValueChanged,
      );
    },
  ).then((pickedDateTime) {
    if (pickedDateTime == null) {
      return null;
    }
    return TimeOfDay(hour: pickedDateTime.hour, minute: pickedDateTime.minute);
  });
}

Future<T?> _showCupertinoPicker<T>({
  required BuildContext context,
  required T initialValue,
  required Widget Function(
    BuildContext context,
    ValueChanged<T> selectedValueChanged,
  )
  builder,
}) {
  T selectedValue = initialValue;
  final materialLocalizations = MaterialLocalizations.of(context);

  return showCupertinoModalPopup<T>(
    context: context,
    builder: (context) {
      return ColoredBox(
        color: CupertinoColors.systemBackground.resolveFrom(context),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 300,
            child: Column(
              children: [
                SizedBox(
                  height: 48,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      CupertinoButton(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text(materialLocalizations.cancelButtonLabel),
                      ),
                      CupertinoButton(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        onPressed: () =>
                            Navigator.of(context).pop(selectedValue),
                        child: Text(materialLocalizations.okButtonLabel),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: builder(context, (value) {
                    selectedValue = value;
                  }),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}
