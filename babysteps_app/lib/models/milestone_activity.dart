class MilestoneActivity {
  final String id;
  final String description;

  MilestoneActivity({
    required this.id,
    required this.description,
  });

  factory MilestoneActivity.fromJson(Map<String, dynamic> json) {
    return MilestoneActivity(
      id: json['id'] as String,
      description: json['description'] as String,
    );
  }
}
