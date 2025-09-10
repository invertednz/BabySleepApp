import 'package:flutter/material.dart';
import 'package:babysteps_app/models/milestone.dart';
import 'package:babysteps_app/theme/app_theme.dart';

class MilestoneCard extends StatelessWidget {
  final Milestone milestone;
  final ValueChanged<bool?> onChanged;

  const MilestoneCard({required this.milestone, required this.onChanged, super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
        child: Row(
          children: [
            Checkbox(
              value: milestone.isCompleted,
              onChanged: onChanged,
              activeColor: AppTheme.darkPurple,
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    milestone.title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      decoration: milestone.isCompleted ? TextDecoration.lineThrough : TextDecoration.none,
                    ),
                  ),
                  if (milestone.description.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text(
                        milestone.description,
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 12,
                          decoration: milestone.isCompleted ? TextDecoration.lineThrough : TextDecoration.none,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
