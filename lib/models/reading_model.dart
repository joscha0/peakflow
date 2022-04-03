import 'package:flutter/material.dart';

class Reading {
  final TimeOfDay time;
  final int value;
  final String note;

  Reading({
    required this.time,
    required this.value,
    this.note = "",
  });

  Reading.fromJson(Map<String, dynamic> json)
      : time = TimeOfDay(
            hour: int.parse(json['time'].split(":")[0]),
            minute: int.parse(json['time'].split(":")[1])),
        value = json['value'],
        note = json['note'] ?? "";

  Map<String, dynamic> toJson() {
    return {
      'time': "${time.hour}:${time.minute}",
      'value': value,
      'note': note,
    };
  }
}
