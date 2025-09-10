import 'package:flutter/material.dart';

enum NoteType { note, activity, feeding, sleep, diaper, measurement, health }

class DiaryEntry {
  final String id;
  final NoteType type;
  final String title;
  final String content;
  final DateTime timestamp;
  final Measurements? measurements;

  DiaryEntry({
    required this.id,
    required this.type,
    required this.title,
    required this.content,
    required this.timestamp,
    this.measurements,
  });
}

class Measurements {
  final double? weight;
  final double? height;
  final double? headCircumference;
  final double? chestCircumference;

  Measurements({
    this.weight,
    this.height,
    this.headCircumference,
    this.chestCircumference,
  });
}

IconData getIconForNoteType(NoteType type) {
  switch (type) {
    case NoteType.activity:
      return Icons.directions_run;
    case NoteType.feeding:
      return Icons.local_drink;
    case NoteType.diaper:
      return Icons.baby_changing_station;
    case NoteType.sleep:
      return Icons.nightlight_round;
    case NoteType.measurement:
      return Icons.monitor_weight;
    case NoteType.health:
      return Icons.favorite;
    case NoteType.note:
    default:
      return Icons.edit_note;
  }
}
