import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class Reading {
  final TimeOfDay time;
  final int value;

  Reading({
    required this.time,
    required this.value,
  });

  Reading.fromJson(Map<String, dynamic> json)
      : time = TimeOfDay(
            hour: int.parse(json['time'].split(":")[0]),
            minute: int.parse(json['time'].split(":")[1])),
        value = json['value'];

  Map<String, dynamic> toJson() {
    return {
      'time': "${time.hour}:${time.minute}",
      'value': value,
    };
  }
}
