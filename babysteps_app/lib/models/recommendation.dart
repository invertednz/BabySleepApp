enum RecommendationCategory { 
  sleep, 
  feeding, 
  activity, 
  development, 
  upcoming, 
  parentCare, 
  milestonePrep, 
  behavior, 
  family, 
  practical, 
  social,
  health
}

class Recommendation {
  final String id;
  final String title;
  final String description;
  final RecommendationCategory category;
  final String? iconPath; // Optional icon path
  final String? actionText; // Optional action text for buttons

  Recommendation({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    this.iconPath,
    this.actionText,
  });
}
