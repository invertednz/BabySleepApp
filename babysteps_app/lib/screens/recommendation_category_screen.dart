import 'package:flutter/material.dart';
import 'package:babysteps_app/models/recommendation.dart';
import 'package:babysteps_app/services/recommendation_service.dart';
import 'package:babysteps_app/theme/app_theme.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:babysteps_app/screens/recommendation_detail_screen.dart';
import 'package:babysteps_app/widgets/recommendation_card.dart';

class RecommendationCategoryScreen extends StatelessWidget {
  final RecommendationCategory category;
  final String title;
  final String subtitle;

  const RecommendationCategoryScreen({
    required this.category,
    required this.title,
    required this.subtitle,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final recommendations = RecommendationService.getRecommendationsByCategory(category);
    final featuredRecommendation = recommendations.isNotEmpty ? recommendations.first : null;
    final otherRecommendations = recommendations.length > 1 
        ? recommendations.sublist(1) 
        : <Recommendation>[];

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
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                background: Padding(
                  padding: const EdgeInsets.only(left: 16, bottom: 50, right: 16),
                  child: Align(
                    alignment: Alignment.bottomLeft,
                    child: Text(
                      subtitle,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
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
          
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Featured recommendation if available
                  if (featuredRecommendation != null) ...[
                    _buildFeaturedCard(context, featuredRecommendation),
                    const SizedBox(height: 24),
                    const Text(
                      'All Recommendations',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ],
              ),
            ),
          ),
          
          // List of other recommendations
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                return Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: _buildRecommendationItem(context, otherRecommendations[index]),
                );
              },
              childCount: otherRecommendations.length,
            ),
          ),
          
          // Add some bottom padding
          const SliverToBoxAdapter(
            child: SizedBox(height: 24),
          ),
        ],
              ),
            ),
          ),
        );
      },
    );
  }

  // Featured recommendation card with image
  Widget _buildFeaturedCard(BuildContext context, Recommendation recommendation) {
    // Get color based on category
    final categoryColor = _getCategoryColor(recommendation.category);
    
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RecommendationDetailScreen(recommendation: recommendation),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Category header with featured badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: categoryColor.withOpacity(0.15),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        FeatherIcons.star,
                        color: categoryColor,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Featured',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: categoryColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '3-4 months',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: categoryColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    recommendation.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    recommendation.description,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppTheme.textSecondary,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Placeholder image
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      _getImageForCategory(recommendation.category),
                      height: 160,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 160,
                          width: double.infinity,
                          color: Colors.grey.shade200,
                          child: Icon(
                            getIconForCategory(recommendation.category),
                            size: 48,
                            color: Colors.grey.shade400,
                          ),
                        );
                      },
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: categoryColor.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          FeatherIcons.clock,
                          size: 14,
                          color: categoryColor,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '5 min read',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
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

  // Regular recommendation item
  Widget _buildRecommendationItem(BuildContext context, Recommendation recommendation) {
    final categoryColor = _getCategoryColor(recommendation.category);
    
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RecommendationDetailScreen(recommendation: recommendation),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
          border: Border.all(color: Colors.grey.shade200),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              recommendation.title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              recommendation.description,
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: categoryColor.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        getIconForCategory(recommendation.category),
                        size: 14,
                        color: categoryColor,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _getMetadataForCategory(recommendation.category),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
                Icon(
                  FeatherIcons.chevronRight,
                  size: 20,
                  color: Colors.grey.shade400,
                ),
              ],
            ),
          ],
        ),
      ),
    );
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

  // Helper method to get metadata text based on category
  String _getMetadataForCategory(RecommendationCategory category) {
    switch (category) {
      case RecommendationCategory.sleep:
        return 'Improve sleep quality';
      case RecommendationCategory.feeding:
        return 'Feeding tips';
      case RecommendationCategory.activity:
        return 'Daily activity';
      case RecommendationCategory.development:
        return 'Age-appropriate';
      case RecommendationCategory.health:
        return 'Health tip';
      case RecommendationCategory.parentCare:
        return 'Self-care';
      case RecommendationCategory.upcoming:
        return 'Coming soon';
      default:
        return 'Helpful tip';
    }
  }

  // Helper method to get placeholder image for category
  String _getImageForCategory(RecommendationCategory category) {
    switch (category) {
      case RecommendationCategory.sleep:
        return 'https://images.unsplash.com/photo-1566004100631-35d015d6a99b?ixlib=rb-1.2.1&auto=format&fit=crop&w=600&q=80';
      case RecommendationCategory.feeding:
        return 'https://images.unsplash.com/photo-1544829099-b9a0c07fad1a?ixlib=rb-1.2.1&auto=format&fit=crop&w=600&q=80';
      case RecommendationCategory.activity:
        return 'https://images.unsplash.com/photo-1596461010724-8e4e08d9b0e7?ixlib=rb-1.2.1&auto=format&fit=crop&w=600&q=80';
      case RecommendationCategory.development:
        return 'https://images.unsplash.com/photo-1596240898242-d5e83fd8e3a7?ixlib=rb-1.2.1&auto=format&fit=crop&w=600&q=80';
      case RecommendationCategory.upcoming:
        return 'https://images.unsplash.com/photo-1555252333-9f8e92e65df9?ixlib=rb-1.2.1&auto=format&fit=crop&w=600&q=80';
      default:
        return 'https://images.unsplash.com/photo-1492725764893-90b379c2b6e7?ixlib=rb-1.2.1&auto=format&fit=crop&w=600&q=80';
    }
  }
}
