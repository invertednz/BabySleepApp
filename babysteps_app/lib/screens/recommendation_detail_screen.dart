import 'package:flutter/material.dart';
import 'package:babysteps_app/models/recommendation.dart';
import 'package:babysteps_app/theme/app_theme.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:babysteps_app/widgets/recommendation_card.dart';

class RecommendationDetailScreen extends StatelessWidget {
  final Recommendation recommendation;

  const RecommendationDetailScreen({
    required this.recommendation,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Get color based on category
    final categoryColor = _getCategoryColor(recommendation.category);
    final categoryName = _getCategoryName(recommendation.category);

    return LayoutBuilder(
      builder: (context, constraints) {
        // Use mobile width if screen is wider than 375
        final effectiveWidth = constraints.maxWidth > 375 ? 375.0 : constraints.maxWidth;
        
        return Scaffold(
          bottomNavigationBar: BottomNavigationBar(
            selectedItemColor: AppTheme.primaryPurple,
            unselectedItemColor: Colors.grey.shade600,
            showUnselectedLabels: true,
            currentIndex: 1, // Recommendations tab
            type: BottomNavigationBarType.fixed,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(FeatherIcons.home),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(FeatherIcons.list),
                label: 'Recommend',
              ),
              BottomNavigationBarItem(
                icon: Icon(FeatherIcons.clock),
                label: 'Track',
              ),
              BottomNavigationBarItem(
                icon: Icon(FeatherIcons.barChart2),
                label: 'Insights',
              ),
              BottomNavigationBarItem(
                icon: Icon(FeatherIcons.user),
                label: 'Profile',
              ),
            ],
          ),
          body: Center(
            child: Container(
              width: effectiveWidth,
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: constraints.maxWidth > 375 ? [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.3),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ] : null,
              ),
              child: CustomScrollView(
        slivers: [
          // Gradient app bar
          SliverAppBar(
            expandedHeight: 120,
            pinned: true,
            flexibleSpace: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.lightPurple, AppTheme.primaryPurple],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: FlexibleSpaceBar(
                title: Text(
                  recommendation.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                background: Padding(
                  padding: const EdgeInsets.only(left: 16, bottom: 50, right: 16),
                  child: Align(
                    alignment: Alignment.bottomLeft,
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Icon(
                            getIconForCategory(recommendation.category),
                            color: Colors.white,
                            size: 14,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          categoryName,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            leading: IconButton(
              icon: const Icon(FeatherIcons.arrowLeft, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          
          // Content
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Metadata row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: categoryColor.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  FeatherIcons.clock,
                                  size: 16,
                                  color: categoryColor,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '5 min read',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: categoryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              '3-4 months',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: categoryColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Title and description
                      Text(
                        _getDetailTitle(recommendation),
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _getDetailDescription(recommendation),
                        style: const TextStyle(
                          fontSize: 15,
                          color: AppTheme.textSecondary,
                          height: 1.5,
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Recommended approaches section
                      const Text(
                        'Recommended Approaches:',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Steps
                      ..._buildSteps(recommendation),
                      
                      const SizedBox(height: 24),
                      
                      // Expert tip
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.lightPurple.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  FeatherIcons.info,
                                  size: 18,
                                  color: categoryColor,
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'Expert Tip',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _getExpertTip(recommendation),
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppTheme.textSecondary,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // When to seek help section
                      const Text(
                        'When to Seek Help',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _getWhenToSeekHelp(recommendation),
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppTheme.textSecondary,
                          height: 1.5,
                        ),
                      ),
                      
                      const SizedBox(height: 32),

                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
              ),
            ),
          ),
        );
      },
    );
  }

  // Build step widgets based on recommendation category
  List<Widget> _buildSteps(Recommendation recommendation) {
    final steps = _getSteps(recommendation);
    final widgets = <Widget>[];
    
    for (int i = 0; i < steps.length; i++) {
      final step = steps[i];
      widgets.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: _getCategoryColor(recommendation.category).withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '${i + 1}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _getCategoryColor(recommendation.category),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      step.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      step.description,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppTheme.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    return widgets;
  }

  // Helper method to get category color
  Color _getCategoryColor(RecommendationCategory category) {
    switch (category) {
      case RecommendationCategory.sleep:
        return const Color(0xFF9C7BB5); // Purple
      case RecommendationCategory.feeding:
        return const Color(0xFFD9A6A6); // Pink
      case RecommendationCategory.activity:
        return const Color(0xFF7BB57F); // Green
      case RecommendationCategory.development:
        return const Color(0xFFA2B3C8); // Blue
      case RecommendationCategory.health:
        return const Color(0xFFB5A77B); // Yellow
      case RecommendationCategory.parentCare:
        return const Color(0xFF7B8FB5); // Blue-gray
      case RecommendationCategory.upcoming:
        return const Color(0xFFE6C8A2); // Orange
      default:
        return AppTheme.darkPurple;
    }
  }

  // Helper method to get category name
  String _getCategoryName(RecommendationCategory category) {
    switch (category) {
      case RecommendationCategory.sleep:
        return 'Sleep';
      case RecommendationCategory.feeding:
        return 'Feeding';
      case RecommendationCategory.activity:
        return 'Activity';
      case RecommendationCategory.development:
        return 'Development';
      case RecommendationCategory.parentCare:
        return 'Parent Care';
      case RecommendationCategory.milestonePrep:
        return 'Milestones';
      case RecommendationCategory.behavior:
        return 'Behavior';
      case RecommendationCategory.family:
        return 'Family';
      case RecommendationCategory.practical:
        return 'Practical';
      case RecommendationCategory.social:
        return 'Social';
      case RecommendationCategory.health:
        return 'Health';
      case RecommendationCategory.upcoming:
        return 'Upcoming';
      default:
        return 'Tip';
    }
  }

  // Helper method to get detailed title
  String _getDetailTitle(Recommendation recommendation) {
    if (recommendation.category == RecommendationCategory.sleep) {
      return 'Gentle Sleep Training for 3-Month-Olds';
    }
    return recommendation.title;
  }

  // Helper method to get detailed description
  String _getDetailDescription(Recommendation recommendation) {
    if (recommendation.category == RecommendationCategory.sleep) {
      return 'At 3 months, your baby is starting to develop more predictable sleep patterns. While it\'s still early for formal sleep training, you can begin establishing healthy sleep habits.';
    }
    return recommendation.description;
  }

  // Helper method to get steps for the recommendation
  List<_RecommendationStep> _getSteps(Recommendation recommendation) {
    if (recommendation.category == RecommendationCategory.sleep) {
      return [
        _RecommendationStep(
          title: 'Consistent Bedtime Routine',
          description: 'Create a 20-30 minute routine that signals sleep time: bath, massage, feeding, lullaby, then bed.',
        ),
        _RecommendationStep(
          title: 'Put Down Drowsy But Awake',
          description: 'Start placing your baby in the crib when drowsy but not fully asleep to develop self-soothing skills.',
        ),
        _RecommendationStep(
          title: 'Pause Before Responding',
          description: 'When your baby fusses, wait a moment before responding. They may settle themselves back to sleep.',
        ),
      ];
    } else if (recommendation.category == RecommendationCategory.activity) {
      return [
        _RecommendationStep(
          title: 'Start Slowly',
          description: 'Begin with 1-2 minute sessions, 2-3 times per day.',
        ),
        _RecommendationStep(
          title: 'Use Props',
          description: 'Place colorful toys just out of reach to encourage movement.',
        ),
        _RecommendationStep(
          title: 'Join In',
          description: 'Get down on the floor at eye level with your baby to encourage interaction.',
        ),
      ];
    } else if (recommendation.category == RecommendationCategory.upcoming) {
      return [
        _RecommendationStep(
          title: 'Talk Frequently',
          description: 'Narrate your activities throughout the day to expose your baby to language.',
        ),
        _RecommendationStep(
          title: 'Respond to Sounds',
          description: 'When your baby makes sounds, respond as if having a conversation to encourage communication.',
        ),
        _RecommendationStep(
          title: 'Read Daily',
          description: 'Even at this young age, reading to your baby helps develop language skills and bonding.',
        ),
      ];
    }
    
    // Default steps
    return [
      _RecommendationStep(
        title: 'Step 1',
        description: 'Follow the recommended guidelines for your baby\'s age and development stage.',
      ),
      _RecommendationStep(
        title: 'Step 2',
        description: 'Observe your baby\'s response and adjust your approach as needed.',
      ),
      _RecommendationStep(
        title: 'Step 3',
        description: 'Maintain consistency while being flexible to your baby\'s changing needs.',
      ),
    ];
  }

  // Helper method to get expert tip
  String _getExpertTip(Recommendation recommendation) {
    if (recommendation.category == RecommendationCategory.sleep) {
      return 'Consistency is key. It may take 5-7 days of consistent routine before you see improvements in your baby\'s sleep patterns.';
    } else if (recommendation.category == RecommendationCategory.activity) {
      return 'Don\'t force tummy time if your baby is upset. Try again later or modify the position by placing baby on your chest while you recline.';
    } else if (recommendation.category == RecommendationCategory.upcoming) {
      return 'Babies learn language best from live interaction with caregivers, not from screens or recordings. Face-to-face communication is most effective.';
    }
    
    return 'Every baby develops at their own pace. What works for one baby may not work for another. Trust your instincts and adjust recommendations to fit your baby\'s unique needs.';
  }

  // Helper method to get when to seek help text
  String _getWhenToSeekHelp(Recommendation recommendation) {
    if (recommendation.category == RecommendationCategory.sleep) {
      return 'If your baby consistently wakes more than 3-4 times per night after 3 months of age, or if naps are consistently under 30 minutes, consider consulting with your pediatrician.';
    } else if (recommendation.category == RecommendationCategory.activity) {
      return 'If your baby seems uncomfortable during tummy time or shows no improvement in head control after several weeks of regular practice, consult your pediatrician.';
    } else if (recommendation.category == RecommendationCategory.upcoming) {
      return 'If your baby doesn\'t respond to sounds or voices by 4 months, or isn\'t making any vocal sounds by 5-6 months, discuss this with your pediatrician.';
    }
    
    return 'If you notice any concerning symptoms or if your baby isn\'t meeting expected milestones, consult with your pediatrician for personalized guidance.';
  }
}

// Helper class for recommendation steps
class _RecommendationStep {
  final String title;
  final String description;
  
  _RecommendationStep({
    required this.title,
    required this.description,
  });
}
