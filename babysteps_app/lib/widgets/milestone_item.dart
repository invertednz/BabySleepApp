import 'package:flutter/material.dart';
import 'package:babysteps_app/models/milestone.dart';
import 'package:babysteps_app/theme/app_theme.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';

class MilestoneItem extends StatelessWidget {
  final Milestone milestone;
  final Function(bool) onChanged;
  final bool isDisabled;

  const MilestoneItem({
    required this.milestone,
    required this.onChanged,
    this.isDisabled = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: isDisabled ? 0.75 : 1.0,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: InkWell(
          onTap: isDisabled ? null : () => onChanged(!milestone.isCompleted),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Container(
                  height: 24,
                  width: 24,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: milestone.isCompleted ? const Color(0xFFC8A2C8) : Colors.grey.shade300,
                      width: 2,
                    ),
                    color: milestone.isCompleted ? const Color(0xFFC8A2C8) : Colors.transparent,
                  ),
                  child: milestone.isCompleted
                      ? const Icon(
                          FeatherIcons.check,
                          size: 14,
                          color: Colors.white,
                        )
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    milestone.title,
                    style: TextStyle(
                      fontSize: 14,
                      color: isDisabled ? const Color(0xFF9CA3AF) : const Color(0xFF4B5563),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
