import 'package:babysteps_app/models/recommendation.dart';

class RecommendationService {
  // Sample recommendations for each category
  static List<Recommendation> getSampleRecommendations() {
    return [
      // Sleep recommendations
      Recommendation(
        id: 'sleep_1',
        title: 'Bedtime Routine',
        description: 'Establish a consistent bedtime routine with calming activities like reading, gentle music, or a warm bath.',
        category: RecommendationCategory.sleep,
        actionText: 'Learn more',
      ),
      Recommendation(
        id: 'sleep_2',
        title: 'Sleep Environment',
        description: 'Create a dark, quiet sleep environment with comfortable temperature between 68-72°F (20-22°C).',
        category: RecommendationCategory.sleep,
      ),
      
      // Feeding recommendations
      Recommendation(
        id: 'feeding_1',
        title: 'Introducing Solids',
        description: 'Start with single-ingredient purees and wait 3-5 days before introducing new foods to watch for allergies.',
        category: RecommendationCategory.feeding,
        actionText: 'Get tips',
      ),
      Recommendation(
        id: 'feeding_2',
        title: 'Mealtime Routine',
        description: 'Establish regular meal and snack times to help your baby develop healthy eating habits.',
        category: RecommendationCategory.feeding,
      ),
      
      // Activity recommendations
      Recommendation(
        id: 'activity_1',
        title: 'Tummy Time',
        description: 'Aim for 20-30 minutes of tummy time daily to strengthen neck, shoulder, and arm muscles.',
        category: RecommendationCategory.activity,
        actionText: 'See exercises',
      ),
      Recommendation(
        id: 'activity_2',
        title: 'Sensory Play',
        description: 'Engage in sensory play with different textures, sounds, and colors to stimulate development.',
        category: RecommendationCategory.activity,
      ),
      
      // Development recommendations
      Recommendation(
        id: 'development_1',
        title: 'Language Development',
        description: 'Talk, read, and sing to your baby regularly to support language development.',
        category: RecommendationCategory.development,
        actionText: 'Activity ideas',
      ),
      Recommendation(
        id: 'development_2',
        title: 'Motor Skills',
        description: 'Encourage reaching, grasping, and eventually crawling with age-appropriate toys.',
        category: RecommendationCategory.development,
      ),
      
      // Parent care recommendations
      Recommendation(
        id: 'parentcare_1',
        title: 'Self-Care Moments',
        description: 'Take short breaks when baby naps to rest, hydrate, or do something you enjoy.',
        category: RecommendationCategory.parentCare,
        actionText: 'Self-care tips',
      ),
      Recommendation(
        id: 'parentcare_2',
        title: 'Ask for Help',
        description: 'Don\'t hesitate to ask friends or family for help with meals, errands, or childcare.',
        category: RecommendationCategory.parentCare,
      ),
      
      // Milestone preparation recommendations
      Recommendation(
        id: 'milestoneprep_1',
        title: 'Preparing for Crawling',
        description: 'Create safe spaces for exploration and remove hazards before your baby starts crawling.',
        category: RecommendationCategory.milestonePrep,
        actionText: 'Safety checklist',
      ),
      Recommendation(
        id: 'milestoneprep_2',
        title: 'Preparing for Walking',
        description: 'Provide push toys and furniture to cruise along as your baby prepares to walk.',
        category: RecommendationCategory.milestonePrep,
      ),
      
      // Behavior recommendations
      Recommendation(
        id: 'behavior_1',
        title: 'Managing Tantrums',
        description: 'Stay calm and acknowledge feelings during tantrums while maintaining consistent boundaries.',
        category: RecommendationCategory.behavior,
        actionText: 'Strategies',
      ),
      Recommendation(
        id: 'behavior_2',
        title: 'Positive Reinforcement',
        description: 'Praise specific behaviors you want to encourage rather than general praise.',
        category: RecommendationCategory.behavior,
      ),
      
      // Health recommendations
      Recommendation(
        id: 'health_1',
        title: 'Vaccination Schedule',
        description: 'Keep track of upcoming vaccinations and schedule regular check-ups with your pediatrician.',
        category: RecommendationCategory.health,
        actionText: 'View schedule',
      ),
      Recommendation(
        id: 'health_2',
        title: 'Fever Management',
        description: 'Learn when to call the doctor and how to safely manage fevers at home.',
        category: RecommendationCategory.health,
      ),
      
      // Upcoming recommendations
      Recommendation(
        id: 'upcoming_1',
        title: 'First Words',
        description: 'Your baby may start saying their first words soon. Encourage language development by talking and reading together.',
        category: RecommendationCategory.upcoming,
        actionText: 'Prepare',
      ),
      Recommendation(
        id: 'upcoming_2',
        title: 'Teething',
        description: 'Teething may begin soon. Look for signs like drooling and irritability, and have teething toys ready.',
        category: RecommendationCategory.upcoming,
      ),
    ];
  }

  // Get recommendations by category
  static List<Recommendation> getRecommendationsByCategory(RecommendationCategory category) {
    return getSampleRecommendations()
        .where((recommendation) => recommendation.category == category)
        .toList();
  }

  // Get featured recommendations (a mix of different categories)
  static List<Recommendation> getFeaturedRecommendations() {
    final allRecommendations = getSampleRecommendations();
    final featured = <Recommendation>[];
    
    // Get one recommendation from each category in the specified order
    final categories = [
      RecommendationCategory.activity,
      RecommendationCategory.upcoming,
      RecommendationCategory.development,
      RecommendationCategory.sleep,
      RecommendationCategory.feeding,
      RecommendationCategory.health,
      RecommendationCategory.parentCare,
      RecommendationCategory.behavior,
      RecommendationCategory.milestonePrep,
      RecommendationCategory.family,
      RecommendationCategory.practical,
      RecommendationCategory.social,
    ];
    
    for (final category in categories) {
      final categoryRecommendations = allRecommendations
          .where((recommendation) => recommendation.category == category)
          .toList();
      
      if (categoryRecommendations.isNotEmpty) {
        featured.add(categoryRecommendations.first);
      }
    }
    
    return featured;
  }
}
