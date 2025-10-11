# Onboarding Animations Implementation Guide

## Overview
This guide explains how to apply the animation guidelines to all onboarding screens in the BabySteps app.

## Animation Guidelines Summary

### 1. Page Transitions (300ms cross-fade)
- **When**: Navigating between onboarding screens
- **Duration**: 300ms
- **Curve**: ease-in-out
- **Effect**: Old screen fades out while new screen fades in

### 2. Staggered Card Animations (600ms + 100ms delays)
- **When**: Displaying multiple cards, options, or list items
- **Duration**: 600ms per element
- **Curve**: ease-out
- **Stagger Delay**: 100ms between elements
- **Movement**: Fade in + slide up from 30% below final position
- **Limit**: Max 7 elements to avoid long waits

## Implementation

### Utility File Created
**Location**: `lib/utils/onboarding_animations.dart`

This file provides:
- `OnboardingAnimations.createPageRoute()` - Cross-fade page transitions
- `OnboardingAnimations.createStaggeredCard()` - Staggered card animations
- `StaggeredAnimationList` - Widget for automatic staggering
- `OnboardingNavigator` extension - Easy navigation methods

### Example: Goals Screen (Completed ✅)
**File**: `lib/screens/onboarding_goals_screen.dart`

**Changes made**:
1. Added `SingleTickerProviderStateMixin`
2. Created `AnimationController` with calculated duration
3. Wrapped grid items with `OnboardingAnimations.createStaggeredCard()`
4. Replaced `Navigator.push()` with `Navigator.pushWithFade()`
5. Started animation after data loads

**Code pattern**:
```dart
class _OnboardingGoalsScreenState extends State<OnboardingGoalsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    // Calculate duration: (num_items * 100ms) + 600ms
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300), // 7 items
    );
    _loadData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    // ... load data ...
    setState(() {
      _loading = false;
    });
    // Start animation after data loads
    _animationController.forward();
  }

  // In build method - wrap each card:
  OnboardingAnimations.createStaggeredCard(
    index: index,
    controller: _animationController,
    maxElements: 7,
    child: YourCardWidget(),
  )

  // For navigation:
  Navigator.of(context).pushWithFade(NextScreen());
}
```

## Screens to Update

### ✅ Completed
- [x] `onboarding_goals_screen.dart` - 7 goal cards with stagger + page transitions

### 🔄 Needs Animation

#### High Priority (Multiple Cards/Options)
- [ ] `onboarding_nurture_priorities_screen.dart` - Multiple priority cards
- [ ] `onboarding_short_term_focus_screen.dart` - Focus area cards
- [ ] `onboarding_concerns_screen.dart` - Concern option cards
- [ ] `onboarding_parenting_style_screen.dart` - Style option cards
- [ ] `onboarding_activities_loves_hates_screen.dart` - Activity cards
- [ ] `onboarding_milestones_screen.dart` - Milestone cards

#### Medium Priority (Feature Lists/Benefits)
- [ ] `onboarding_welcome_screen.dart` - Feature list (if any)
- [ ] `onboarding_results_screen.dart` - Results/benefits cards
- [ ] `onboarding_trial_offer_screen.dart` - Feature/benefit list
- [ ] `onboarding_payment_screen_new.dart` - Plan features
- [ ] `onboarding_app_tour_screen.dart` - Feature highlights

#### Low Priority (Simple Forms/Single Elements)
- [ ] `onboarding_baby_screen.dart` - Just add page transitions
- [ ] `onboarding_gender_screen.dart` - Just add page transitions
- [ ] `onboarding_measurements_screen.dart` - Just add page transitions
- [ ] `onboarding_feeding_screen.dart` - Just add page transitions
- [ ] `onboarding_sleep_screen.dart` - Just add page transitions
- [ ] `onboarding_diaper_screen.dart` - Just add page transitions
- [ ] `onboarding_notifications_screen.dart` - Just add page transitions
- [ ] `onboarding_thank_you_screen.dart` - Just add page transitions

## Step-by-Step Implementation

### For Screens with Multiple Cards (e.g., Priorities, Focus Areas)

**1. Import the utility**
```dart
import 'package:babysteps_app/utils/onboarding_animations.dart';
```

**2. Add mixin and controller**
```dart
class _YourScreenState extends State<YourScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
```

**3. Initialize in initState**
```dart
@override
void initState() {
  super.initState();
  // Calculate: (number_of_cards * 100ms) + 600ms
  final numCards = 5; // adjust based on your screen
  final durationMs = (numCards * 100) + 600;
  _animationController = AnimationController(
    vsync: this,
    duration: Duration(milliseconds: durationMs),
  );
  _loadData();
}
```

**4. Dispose controller**
```dart
@override
void dispose() {
  _animationController.dispose();
  super.dispose();
}
```

**5. Start animation after data loads**
```dart
Future<void> _loadData() async {
  // ... your data loading ...
  setState(() {
    _loading = false;
  });
  // Trigger stagger animation
  _animationController.forward();
}
```

**6. Wrap cards with animation**
```dart
// In your GridView/ListView builder:
children: items.asMap().entries.map((entry) {
  final index = entry.key;
  final item = entry.value;
  
  return OnboardingAnimations.createStaggeredCard(
    index: index,
    controller: _animationController,
    maxElements: 7, // limit stagger
    child: YourCardWidget(item: item),
  );
}).toList(),
```

**7. Update navigation**
```dart
// Replace MaterialPageRoute with:
Navigator.of(context).pushWithFade(NextScreen());

// Or for replacement:
Navigator.of(context).pushReplacementWithFade(NextScreen());
```

### For Simple Screens (Just Forms/Single Elements)

**1. Import the utility**
```dart
import 'package:babysteps_app/utils/onboarding_animations.dart';
```

**2. Update navigation only**
```dart
// Replace:
Navigator.of(context).push(
  MaterialPageRoute(builder: (context) => NextScreen()),
);

// With:
Navigator.of(context).pushWithFade(NextScreen());
```

## Alternative: Using StaggeredAnimationList Widget

For simpler implementation, use the `StaggeredAnimationList` widget:

```dart
StaggeredAnimationList(
  maxStaggerElements: 7,
  children: [
    YourCard1(),
    YourCard2(),
    YourCard3(),
    // ... more cards
  ],
)
```

This automatically handles:
- Animation controller creation
- Timing calculations
- Stagger application
- Disposal

## Accessibility

The animations automatically respect `MediaQuery.disableAnimations`, which includes:
- `prefers-reduced-motion` system setting
- Accessibility settings

When reduced motion is enabled:
- Page transitions become instant
- Staggered animations are disabled
- All content appears immediately

## Testing Checklist

For each updated screen:
- [ ] Cards/elements fade in and slide up smoothly
- [ ] Stagger delay is 100ms between elements
- [ ] Total animation doesn't exceed ~1.3 seconds
- [ ] Page transitions are smooth 300ms cross-fades
- [ ] Animations respect reduced motion settings
- [ ] No jank or performance issues
- [ ] Content is readable even if animations fail

## Performance Tips

1. **Use `const` constructors** where possible to reduce rebuilds
2. **Limit stagger to 7 elements** - longer lists feel slow
3. **Don't animate on every setState** - only on initial load
4. **Dispose controllers** - prevents memory leaks
5. **Test on low-end devices** - ensure smooth 60fps

## Common Patterns

### Pattern 1: Grid of Options (Goals, Priorities, Focus)
```dart
GridView.count(
  crossAxisCount: 2,
  children: items.asMap().entries.map((entry) {
    return OnboardingAnimations.createStaggeredCard(
      index: entry.key,
      controller: _animationController,
      maxElements: 7,
      child: OptionCard(item: entry.value),
    );
  }).toList(),
)
```

### Pattern 2: Vertical List of Features
```dart
StaggeredAnimationList(
  children: [
    FeatureCard(title: 'Feature 1', ...),
    FeatureCard(title: 'Feature 2', ...),
    FeatureCard(title: 'Feature 3', ...),
  ],
)
```

### Pattern 3: Simple Form Navigation
```dart
ElevatedButton(
  onPressed: () {
    Navigator.of(context).pushWithFade(NextScreen());
  },
  child: Text('Next'),
)
```

## Migration Priority

**Week 1**: High priority screens (multiple cards)
- Nurture priorities
- Short-term focus
- Concerns
- Parenting style

**Week 2**: Medium priority screens (feature lists)
- Welcome screen
- Results screen
- Trial offer
- Payment screen

**Week 3**: Low priority screens (simple forms)
- All remaining screens - just add page transitions

## Questions?

See the animation utility file for implementation details:
`lib/utils/onboarding_animations.dart`

Or refer to the completed example:
`lib/screens/onboarding_goals_screen.dart`
