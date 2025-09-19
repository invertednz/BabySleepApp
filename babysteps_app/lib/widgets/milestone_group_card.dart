import 'package:flutter/material.dart';
import 'package:babysteps_app/models/milestone_group.dart';
import 'package:babysteps_app/theme/app_theme.dart';
import 'package:babysteps_app/widgets/milestone_item.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';

class MilestoneGroupCard extends StatefulWidget {
  final MilestoneGroup group;
  final Function(String, bool) onMilestoneChanged;
  final ValueChanged<bool>? onExpansionChanged;

  const MilestoneGroupCard({
    required this.group,
    required this.onMilestoneChanged,
    this.onExpansionChanged,
    super.key,
  });

  @override
  State<MilestoneGroupCard> createState() => _MilestoneGroupCardState();
}

class _MilestoneGroupCardState extends State<MilestoneGroupCard> {
  late bool _isExpanded;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.group.isExpanded;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          InkWell(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
                widget.group.isExpanded = _isExpanded;
              });
              // Notify parent about expansion state change
              widget.onExpansionChanged?.call(_isExpanded);
            },
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFFF8F2FC),
                    Color(0xFFF1E9F8),
                  ],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(
                        FeatherIcons.smile,
                        size: 20,
                        color: Color(0xFFA67EB7),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        widget.group.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                    ],
                  ),
                  AnimatedRotation(
                    turns: _isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(
                      FeatherIcons.chevronDown,
                      size: 20,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Milestone List
          AnimatedCrossFade(
            firstChild: Container(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: widget.group.milestones.map((milestone) {
                  return MilestoneItem(
                    milestone: milestone,
                    onChanged: (value) {
                      widget.onMilestoneChanged(milestone.id, value);
                    },
 // Make all milestones unselectable
                  );
                }).toList(),
              ),
            ),
            secondChild: const SizedBox(height: 0),
            crossFadeState: _isExpanded ? CrossFadeState.showFirst : CrossFadeState.showSecond,
            duration: const Duration(milliseconds: 200),
          ),
        ],
      ),
    );
  }
}
