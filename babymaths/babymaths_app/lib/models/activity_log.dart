class ActivityLog {
  final String id;
  final String babyId;
  final String userId;
  final String? milestoneId;
  final String activityTitle;
  final String activityCategory;
  final DateTime completedAt;
  final int? durationMinutes;
  final int? engagementLevel; // 1-5 scale
  final String? notes;
  final List<String>? mediaUrls;

  ActivityLog({
    required this.id,
    required this.babyId,
    required this.userId,
    this.milestoneId,
    required this.activityTitle,
    required this.activityCategory,
    required this.completedAt,
    this.durationMinutes,
    this.engagementLevel,
    this.notes,
    this.mediaUrls,
  });

  factory ActivityLog.fromJson(Map<String, dynamic> json) {
    return ActivityLog(
      id: json['id'] as String,
      babyId: json['baby_id'] as String,
      userId: json['user_id'] as String,
      milestoneId: json['milestone_id'] as String?,
      activityTitle: json['activity_title'] as String,
      activityCategory: json['activity_category'] as String,
      completedAt: DateTime.parse(json['completed_at'] as String),
      durationMinutes: json['duration_minutes'] as int?,
      engagementLevel: json['engagement_level'] as int?,
      notes: json['notes'] as String?,
      mediaUrls: (json['media_urls'] as List<dynamic>?)
          ?.map((u) => u as String)
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'baby_id': babyId,
      'user_id': userId,
      if (milestoneId != null) 'milestone_id': milestoneId,
      'activity_title': activityTitle,
      'activity_category': activityCategory,
      'completed_at': completedAt.toIso8601String(),
      if (durationMinutes != null) 'duration_minutes': durationMinutes,
      if (engagementLevel != null) 'engagement_level': engagementLevel,
      if (notes != null) 'notes': notes,
      if (mediaUrls != null) 'media_urls': mediaUrls,
    };
  }
}
