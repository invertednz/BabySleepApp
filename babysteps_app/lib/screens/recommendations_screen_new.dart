import 'package:flutter/material.dart';
import 'package:babysteps_app/models/recommendation.dart';
import 'package:babysteps_app/services/recommendation_service.dart';
import 'package:babysteps_app/theme/app_theme.dart';
import 'package:babysteps_app/widgets/recommendation_card.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';

class RecommendationsScreen extends StatefulWidget {
  const RecommendationsScreen({super.key});

  @override
  State<RecommendationsScreen> createState() => _RecommendationsScreenState();
}

class _RecommendationsScreenState extends State<RecommendationsScreen> {
  // Get recommendations from service
  final List<Recommendation> _recommendations = RecommendationService.getSampleRecommendations();
  
  // Track selected category filter
  RecommendationCategory? _selectedCategory;
  
  // Get all categories in the specified order
  final List<RecommendationCategory> _categories = [
    RecommendationCategory.activity,
    RecommendationCategory.upcoming,
    RecommendationCategory.development,
    RecommendationCategory.sleep,
    RecommendationCategory.feeding,
    RecommendationCategory.health,
    RecommendationCategory.parentCare,
  ];
  
  // Get filtered recommendations
  List<Recommendation> get _filteredRecommendations {
    if (_selectedCategory == null) {
      return _recommendations;
    }
    return _recommendations.where((r) => r.category == _selectedCategory).toList();
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
      case RecommendationCategory.health:
        return 'Health';
      case RecommendationCategory.upcoming:
        return 'Upcoming';
      default:
        return 'Other';
    }
  }

  @override
  Widget build(BuildContext context) {
    final babyName = 'Luna'; // This would come from a provider or service
    final babyAge = '3 months'; // This would come from a provider or service
    
    // Set constraints to match mobile design (375x812)
    return LayoutBuilder(
      builder: (context, constraints) {
        // Use mobile width if screen is wider than 375
        final effectiveWidth = constraints.maxWidth > 375 ? 375.0 : constraints.maxWidth;
        
        return Scaffold(
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
                  // Gradient app bar with personalized greeting
                  SliverAppBar(
                    expandedHeight: 100,
                    pinned: true,
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    flexibleSpace: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppTheme.lightPurple, AppTheme.primaryPurple],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: FlexibleSpaceBar(
                        titlePadding: const EdgeInsets.only(left: 24, bottom: 16),
                        title: const Text(
                          'Recommendations',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        ),
                        background: Padding(
                          padding: const EdgeInsets.only(left: 24, bottom: 50, right: 16),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Personalized for $babyName, $babyAge',
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
                    actions: [
                      // Search button
                      Container(
                        margin: const EdgeInsets.only(right: 16),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(50),
                          ),
                          child: IconButton(
                            icon: const Icon(FeatherIcons.search, color: Colors.white, size: 20),
                            onPressed: () {
                              // TODO: Implement search functionality
                            },
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                              minWidth: 20,
                              minHeight: 20,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
          
                  // Category filter chips
                  SliverToBoxAdapter(
                    child: Container(
                      height: 50,
                      margin: const EdgeInsets.only(top: 8),
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        children: [
                          // All categories chip
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: FilterChip(
                              label: const Text('All'),
                              selected: _selectedCategory == null,
                              onSelected: (selected) {
                                setState(() {
                                  _selectedCategory = null;
                                });
                              },
                              backgroundColor: Colors.white,
                              selectedColor: AppTheme.lightPurple.withOpacity(0.15),
                              checkmarkColor: AppTheme.darkPurple,
                              showCheckmark: false,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(50),
                                side: BorderSide(
                                  color: _selectedCategory == null
                                      ? Colors.transparent
                                      : Colors.grey.shade300,
                                  width: 1,
                                ),
                              ),
                              elevation: 1,
                              pressElevation: 0,
                              labelStyle: TextStyle(
                                color: _selectedCategory == null 
                                    ? AppTheme.darkPurple 
                                    : AppTheme.textSecondary,
                                fontWeight: _selectedCategory == null 
                                    ? FontWeight.w500 
                                    : FontWeight.normal,
                                fontSize: 13,
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                          ),
                          // Category chips
                          ..._categories.map((category) {
                            final String categoryName = _getCategoryName(category);
                            final bool isSelected = _selectedCategory == category;
                            
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: FilterChip(
                                label: Text(categoryName),
                                selected: isSelected,
                                onSelected: (selected) {
                                  setState(() {
                                    _selectedCategory = selected ? category : null;
                                  });
                                },
                                backgroundColor: Colors.white,
                                selectedColor: AppTheme.lightPurple.withOpacity(0.15),
                                checkmarkColor: AppTheme.darkPurple,
                                showCheckmark: false,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(50),
                                  side: BorderSide(
                                    color: isSelected
                                        ? Colors.transparent
                                        : Colors.grey.shade300,
                                    width: 1,
                                  ),
                                ),
                                elevation: 1,
                                pressElevation: 0,
                                labelStyle: TextStyle(
                                  color: isSelected
                                      ? AppTheme.darkPurple 
                                      : AppTheme.textSecondary,
                                  fontWeight: isSelected
                                      ? FontWeight.w500 
                                      : FontWeight.normal,
                                  fontSize: 13,
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              ),
                            );
                          }).toList(),
                        ],
                      ),
                    ),
                  ),
                  
                  // Empty state or recommendations list
                  _filteredRecommendations.isEmpty
                      ? SliverFillRemaining(
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  FeatherIcons.alertCircle,
                                  size: 48,
                                  color: Colors.grey.shade400,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No recommendations found',
                                  style: TextStyle(color: Colors.grey.shade600),
                                ),
                              ],
                            ),
                          ),
                        )
                      // Mobile layout with vertical list (always use this layout for consistency)
                      : SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              return Padding(
                                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                                child: RecommendationCard(
                                  recommendation: _filteredRecommendations[index],
                                  showViewAll: false, // Don't show View All button on main list
                                ),
                              );
                            },
                            childCount: _filteredRecommendations.length,
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
          // Bottom navigation bar
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
        );
      },
    );
  }
}
