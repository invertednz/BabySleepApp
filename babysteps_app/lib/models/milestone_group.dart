import 'package:babysteps_app/models/milestone.dart';

class MilestoneGroup {
  final String id;
  final String title;
  final List<Milestone> milestones;
  bool isExpanded;

  MilestoneGroup({
    required this.id,
    required this.title,
    required this.milestones,
    this.isExpanded = true, // Default to expanded
  });
}
