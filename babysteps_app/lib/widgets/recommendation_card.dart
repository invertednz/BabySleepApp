import 'package:flutter/material.dart';
import 'package:babysteps_app/models/recommendation.dart';
import 'package:babysteps_app/theme/app_theme.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:babysteps_app/screens/recommendation_detail_screen.dart';
import 'package:babysteps_app/screens/recommendation_category_screen.dart';

// Helper class for category styling information
class _CategoryInfo {
  final IconData icon;
  final Color color;
  
  _CategoryInfo(this.icon, this.color);
}

// Helper to get icon for category
IconData getIconForCategory(RecommendationCategory category) {
  switch (category) {
    case RecommendationCategory.sleep:
      return FeatherIcons.moon;
    case RecommendationCategory.feeding:
      return FeatherIcons.coffee;
    case RecommendationCategory.activity:
      return FeatherIcons.activity;
    case RecommendationCategory.development:
      return FeatherIcons.trendingUp;
    case RecommendationCategory.parentCare:
      return FeatherIcons.heart;
    case RecommendationCategory.milestonePrep:
      return FeatherIcons.flag;
    case RecommendationCategory.behavior:
      return FeatherIcons.smile;
    case RecommendationCategory.family:
      return FeatherIcons.users;
    case RecommendationCategory.practical:
      return FeatherIcons.briefcase;
    case RecommendationCategory.social:
      return FeatherIcons.userPlus;
    case RecommendationCategory.health:
      return FeatherIcons.activity;
    case RecommendationCategory.upcoming:
      return FeatherIcons.calendar;
    default:
      return FeatherIcons.gift;
  }
}

class RecommendationCard extends StatelessWidget {
  final Recommendation recommendation;
  final bool showViewAll;
  
  const RecommendationCard({
    Key? key,
    required this.recommendation,
    this.showViewAll = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Get category color and icon
    final categoryInfo = _getCategoryInfo(recommendation.category);
    
    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(
          builder: (context) => RecommendationDetailScreen(recommendation: recommendation),
        ));
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.05),
              spreadRadius: 1,
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Category header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: categoryInfo.color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      categoryInfo.icon,
                      size: 16,
                      color: categoryInfo.color,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _getCategoryName(recommendation.category).toUpperCase(),
                    style: TextStyle(
                      color: categoryInfo.color,
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
            
            // Content
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    recommendation.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    recommendation.description,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 14,
                      height: 1.4,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 16),
                  
                  // Action row with optional View All button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Time or age indicator
                      Row(
                        children: [
                          Container(
                            height: 24,
                            width: 24,
                            decoration: BoxDecoration(
                              color: _getActivityIconColor().withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              _getActivityIcon(),
                              size: 12,
                              color: _getActivityIconColor(),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _getActivityText(),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                      
                      // View All button - only show if requested
                      if (showViewAll)
                        TextButton(
                          onPressed: () {
                            Navigator.push(context, MaterialPageRoute(
                              builder: (context) => RecommendationCategoryScreen(
                                category: recommendation.category,
                                title: _getCategoryName(recommendation.category),
                                subtitle: _getCategorySubtitle(recommendation.category),
                              ),
                            ));
                          },
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Row(
                            children: [
                              Text(
                                'View All',
                                style: TextStyle(
                                  color: AppTheme.primaryPurple,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                FeatherIcons.chevronRight,
                                size: 14,
                                color: AppTheme.primaryPurple,
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  // Helper method to get activity icon based on category
  IconData _getActivityIcon() {
    switch (recommendation.category) {
      case RecommendationCategory.sleep:
        return FeatherIcons.clock;
      case RecommendationCategory.activity:
        return FeatherIcons.clock;
      case RecommendationCategory.development:
        return FeatherIcons.award;
      case RecommendationCategory.feeding:
        return FeatherIcons.clock;
      case RecommendationCategory.health:
        return FeatherIcons.activity;
      case RecommendationCategory.upcoming:
        return FeatherIcons.calendar;
      default:
        return FeatherIcons.clock;
    }
  }
  
  // Helper method to get activity text based on category
  String _getActivityText() {
    switch (recommendation.category) {
      case RecommendationCategory.sleep:
        return '5 min activity';
      case RecommendationCategory.activity:
        return '5 min activity';
      case RecommendationCategory.development:
        return 'Key milestone';
      case RecommendationCategory.feeding:
        return '10 min activity';
      case RecommendationCategory.health:
        return 'Health tip';
      case RecommendationCategory.upcoming:
        return 'Coming in 2 weeks';
      default:
        return '5 min activity';
    }
  }
  
  // Helper method to get activity icon color based on category
  Color _getActivityIconColor() {
    switch (recommendation.category) {
      case RecommendationCategory.sleep:
        return Colors.green;
      case RecommendationCategory.activity:
        return Colors.green;
      case RecommendationCategory.development:
        return Colors.blue;
      case RecommendationCategory.feeding:
        return Colors.green;
      case RecommendationCategory.health:
        return Colors.red;
      case RecommendationCategory.upcoming:
        return Colors.amber;
      default:
        return Colors.green;
    }
  }
  
  // Helper method to get category info
  _CategoryInfo _getCategoryInfo(RecommendationCategory category) {
    switch (category) {
      case RecommendationCategory.sleep:
        return _CategoryInfo(FeatherIcons.moon, const Color(0xFF9C7BB5));
      case RecommendationCategory.feeding:
        return _CategoryInfo(FeatherIcons.coffee, const Color(0xFF7BA5B5));
      case RecommendationCategory.activity:
        return _CategoryInfo(FeatherIcons.activity, const Color(0xFF7BB57F));
      case RecommendationCategory.development:
        return _CategoryInfo(FeatherIcons.trendingUp, const Color(0xFFB57B7B));
      case RecommendationCategory.parentCare:
        return _CategoryInfo(FeatherIcons.heart, const Color(0xFF7B8FB5));
      case RecommendationCategory.health:
        return _CategoryInfo(FeatherIcons.activity, const Color(0xFFB5A77B));
      case RecommendationCategory.upcoming:
        return _CategoryInfo(FeatherIcons.calendar, const Color(0xFFE67E22));
      default:
        return _CategoryInfo(FeatherIcons.gift, AppTheme.darkPurple);
    }
  }
  
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
  
  // Helper method to get category subtitle
  String _getCategorySubtitle(RecommendationCategory category) {
    switch (category) {
      case RecommendationCategory.sleep:
        return 'For babies 3-4 months';
      case RecommendationCategory.feeding:
        return 'Nutrition tips for your baby';
      case RecommendationCategory.activity:
        return 'Age-appropriate activities';
      case RecommendationCategory.development:
        return 'Support your baby\'s growth';
      case RecommendationCategory.upcoming:
        return 'What\'s coming in the next weeks';
      default:
        return 'Personalized for your baby';
    }
  }
}
