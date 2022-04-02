import 'package:flutter/material.dart';

Color getColor(int value, int bestValue) {
  if (value > bestValue * 0.8) {
    return Colors.green;
  } else if (value < bestValue * 0.5) {
    return Colors.red;
  } else {
    return Colors.orange;
  }
}
