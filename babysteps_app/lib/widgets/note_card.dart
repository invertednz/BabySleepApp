import 'package:flutter/material.dart';
import 'package:babysteps_app/models/diary_entry.dart';
import 'package:babysteps_app/theme/app_theme.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:intl/intl.dart';

IconData getIconForNoteType(NoteType type) {
  switch (type) {
    case NoteType.note:
      return FeatherIcons.edit;
    case NoteType.activity:
      return FeatherIcons.activity;
    case NoteType.feeding:
      return FeatherIcons.coffee;
    case NoteType.sleep:
      return FeatherIcons.moon;
    case NoteType.diaper:
      return FeatherIcons.droplet;
    case NoteType.measurement:
      return FeatherIcons.barChart2;
    case NoteType.health:
      return FeatherIcons.heart;
    default:
      return FeatherIcons.fileText;
  }
}

class NoteCard extends StatelessWidget {
  final DiaryEntry entry;

  const NoteCard({required this.entry, super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(getIconForNoteType(entry.type), color: AppTheme.darkPurple, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    entry.title,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                Text(
                  DateFormat.jm().format(entry.timestamp),
                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (entry.content.isNotEmpty)
              Text(
                entry.content,
                style: const TextStyle(color: AppTheme.textSecondary, height: 1.5),
              ),
            if (entry.measurements != null)
              _buildMeasurements(entry.measurements!),
          ],
        ),
      ),
    );
  }

  Widget _buildMeasurements(Measurements measurements) {
    return Padding(
      padding: const EdgeInsets.only(top: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(),
          const SizedBox(height: 8),
          if (measurements.weight != null)
            Text('Weight: ${measurements.weight} kg'),
          if (measurements.height != null)
            Text('Height: ${measurements.height} cm'),
          if (measurements.headCircumference != null)
            Text('Head: ${measurements.headCircumference} cm'),
          if (measurements.chestCircumference != null)
            Text('Chest: ${measurements.chestCircumference} cm'),
        ],
      ),
    );
  }
}
