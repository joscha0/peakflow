import 'package:flutter/material.dart';

Color getColor(int value, int referenceMaxValue) {
  final safeReferenceMaxValue = referenceMaxValue > 0 ? referenceMaxValue : 1;

  if (value >= safeReferenceMaxValue * 0.8) {
    return Colors.green;
  } else if (value < safeReferenceMaxValue * 0.5) {
    return Colors.red;
  } else {
    return Colors.orange;
  }
}
