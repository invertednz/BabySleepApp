class Baby {
  final String id;
  final String userId;
  final String name;
  final DateTime birthdate;
  final String? gender;
  final String? profilePhotoUrl;
  final String? currentLanguageLevel;
  final DateTime createdAt;
  final DateTime updatedAt;

  Baby({
    required this.id,
    required this.userId,
    required this.name,
    required this.birthdate,
    this.gender,
    this.profilePhotoUrl,
    this.currentLanguageLevel,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  int get ageInMonths {
    final now = DateTime.now();
    int months = (now.year - birthdate.year) * 12;
    months += now.month - birthdate.month;
    if (now.day < birthdate.day) {
      months--;
    }
    return months < 0 ? 0 : months;
  }

  int get ageInDays {
    return DateTime.now().difference(birthdate).inDays;
  }

  factory Baby.fromJson(Map<String, dynamic> json) {
    return Baby(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      name: json['name'] as String,
      birthdate: DateTime.parse(json['birthdate'] as String),
      gender: json['gender'] as String?,
      profilePhotoUrl: json['profile_photo_url'] as String?,
      currentLanguageLevel: json['current_language_level'] as String?,
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
      'user_id': userId,
      'name': name,
      'birthdate': birthdate.toIso8601String(),
      if (gender != null) 'gender': gender,
      if (profilePhotoUrl != null) 'profile_photo_url': profilePhotoUrl,
      if (currentLanguageLevel != null) 'current_language_level': currentLanguageLevel,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
