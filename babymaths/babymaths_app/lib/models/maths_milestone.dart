class MathsMilestone {
  final String id;
  final String category;
  final String title;
  final String description;
  final int ageMonthsMin;
  final int ageMonthsMax;
  final int difficultyLevel;
  final List<MathsActivity> activities;
  final List<String> indicators;
  final List<String> nextSteps;
  final int sortOrder;
  final DateTime createdAt;
  final DateTime updatedAt;

  MathsMilestone({
    required this.id,
    required this.category,
    required this.title,
    required this.description,
    required this.ageMonthsMin,
    required this.ageMonthsMax,
    this.difficultyLevel = 1,
    required this.activities,
    this.indicators = const [],
    this.nextSteps = const [],
    this.sortOrder = 0,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  factory MathsMilestone.fromJson(Map<String, dynamic> json) {
    return MathsMilestone(
      id: json['id'] as String,
      category: json['category'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      ageMonthsMin: json['age_months_min'] as int,
      ageMonthsMax: json['age_months_max'] as int,
      difficultyLevel: json['difficulty_level'] as int? ?? 1,
      activities: (json['activities'] as List<dynamic>?)
              ?.map((a) => MathsActivity.fromJson(a as Map<String, dynamic>))
              .toList() ??
          [],
      indicators: (json['indicators'] as List<dynamic>?)
              ?.map((i) => i as String)
              .toList() ??
          [],
      nextSteps: (json['next_steps'] as List<dynamic>?)
              ?.map((n) => n as String)
              .toList() ??
          [],
      sortOrder: json['sort_order'] as int? ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'category': category,
      'title': title,
      'description': description,
      'age_months_min': ageMonthsMin,
      'age_months_max': ageMonthsMax,
      'difficulty_level': difficultyLevel,
      'activities': activities.map((a) => a.toJson()).toList(),
      'indicators': indicators,
      'next_steps': nextSteps,
      'sort_order': sortOrder,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

class MathsActivity {
  final String title;
  final int durationMinutes;
  final List<String> materials;
  final List<String> instructions;
  final List<String>? variations;
  final List<String>? tips;

  MathsActivity({
    required this.title,
    required this.durationMinutes,
    this.materials = const [],
    this.instructions = const [],
    this.variations,
    this.tips,
  });

  factory MathsActivity.fromJson(Map<String, dynamic> json) {
    return MathsActivity(
      title: json['title'] as String,
      durationMinutes: json['duration_minutes'] as int,
      materials: (json['materials'] as List<dynamic>?)
              ?.map((m) => m as String)
              .toList() ??
          [],
      instructions: (json['instructions'] as List<dynamic>?)
              ?.map((i) => i as String)
              .toList() ??
          [],
      variations: (json['variations'] as List<dynamic>?)
          ?.map((v) => v as String)
          .toList(),
      tips: (json['tips'] as List<dynamic>?)?.map((t) => t as String).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'duration_minutes': durationMinutes,
      'materials': materials,
      'instructions': instructions,
      if (variations != null) 'variations': variations,
      if (tips != null) 'tips': tips,
    };
  }
}
