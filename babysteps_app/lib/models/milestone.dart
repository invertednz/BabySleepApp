import 'package:babysteps_app/models/milestone_activity.dart';

class Milestone {
  final String id;
  final String category;
  final String title;
  final int firstNoticedWeeks;
  final int worryAfterWeeks;
  final List<MilestoneActivity> activities;
  bool isCompleted;

  Milestone({
    required this.id,
    required this.category,
    required this.title,
    required this.firstNoticedWeeks,
    required this.worryAfterWeeks,
    required this.activities,
    this.isCompleted = false,
  });

  factory Milestone.fromJson(Map<String, dynamic> json) {
    var activitiesList = json['milestone_activities'] as List? ?? [];
    List<MilestoneActivity> activities = activitiesList.map((i) => MilestoneActivity.fromJson(i)).toList();

    return Milestone(
      id: json['id'] as String,
      category: json['category'] as String,
      title: json['title'] as String,
      firstNoticedWeeks: json['first_noticed_weeks'] as int,
      worryAfterWeeks: json['worry_after_weeks'] as int,
      activities: activities,
    );
  }
}

