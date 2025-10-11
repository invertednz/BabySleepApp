# App-Wide Animations Guide

## Overview
Consistent animations throughout the BabySteps app using the same guidelines applied to onboarding.

## Animation Utility
**File**: `lib/utils/app_animations.dart` (formerly `onboarding_animations.dart`)

The animation utility now supports the **entire app**, not just onboarding:
- ✅ Onboarding screens
- ✅ Main app screens (Home, Tracking, Milestones, etc.)
- ✅ Modals and dialogs
- ✅ Lists and grids
- ✅ Navigation transitions

---

## Animation Types

### 1. Page Transitions (300ms)
**Use for**: Navigating between any screens in the app

```dart
import 'package:babysteps_app/utils/app_animations.dart';

// Instead of:
Navigator.push(MaterialPageRoute(builder: (context) => NextScreen()));

// Use:
Navigator.of(context).pushWithFade(NextScreen());
```

**Where to apply**:
- ✅ Onboarding flow
- ✅ Home → Tracking screen
- ✅ Home → Milestones screen
- ✅ Home → Advice screen
- ✅ Settings navigation
- ✅ Any screen-to-screen navigation

---

### 2. Staggered Cards (600ms + 100ms delays)
**Use for**: Lists of cards, options, features, or grid items

```dart
import 'package:babysteps_app/utils/app_animations.dart';

class MyScreen extends StatefulWidget {
  // ... 
}

class _MyScreenState extends State<MyScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300), // Adjust based on item count
    );
    _loadData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    // Load your data
    setState(() { _loading = false; });
    _animationController.forward(); // Start animation
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: items.asMap().entries.map((entry) {
        return AppAnimations.createStaggeredCard(
          index: entry.key,
          controller: _animationController,
          maxElements: 7,
          child: YourCard(item: entry.value),
        );
      }).toList(),
    );
  }
}
```

**Where to apply**:
- ✅ Onboarding option grids
- ✅ Home screen activity cards
- ✅ Home screen recommendation cards
- ✅ Milestone cards in milestone screen
- ✅ Tracking domain cards
- ✅ Settings options
- ✅ Any grid or list of cards

---

### 3. Micro-interactions (200ms)
**Use for**: Button hovers, taps, small state changes

```dart
// Use built-in constants
AnimatedContainer(
  duration: AppAnimations.microInteractionDuration,
  curve: AppAnimations.microInteractionCurve,
  // ... your properties
)
```

**Where to apply**:
- Button press animations
- Icon state changes
- Toggle switches
- Checkbox/radio animations
- Small UI feedback

---

### 4. Modal/Dialog Animations (300ms)
**Use for**: Showing modals, dialogs, bottom sheets

```dart
showModalBottomSheet(
  context: context,
  transitionAnimationController: AnimationController(
    vsync: Navigator.of(context),
    duration: AppAnimations.modalDuration,
  ),
  builder: (context) => YourModal(),
);
```

**Where to apply**:
- Bottom sheets
- Dialogs
- Overlays
- Popups

---

## Main App Screen Examples

### Example 1: Home Screen Activities (Already Exists)
**File**: `lib/screens/home_screen.dart`

The home screen already has activities. Add stagger animation:

```dart
// In _HomeScreenState:
late AnimationController _activitiesAnimationController;

@override
void initState() {
  super.initState();
  _activitiesAnimationController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900), // 3 activities
  );
  _loadWeeklyAdvice(); // Existing method
}

@override
void dispose() {
  _activitiesAnimationController.dispose();
  super.dispose();
}

// In _loadWeeklyAdvice(), after setting activities:
setState(() {
  _activities = todayActivities;
  // ... other state
});
_activitiesAnimationController.forward(); // Start animation

// In _buildActivitiesSection():
..._activities.asMap().entries.map((entry) {
  return AppAnimations.createStaggeredCard(
    index: entry.key,
    controller: _activitiesAnimationController,
    maxElements: 7,
    child: _ActivityListCard(
      title: entry.value['title']!,
      desc: entry.value['desc']!,
      onAction: (result) => _handleActivityAction(
        title: entry.value['title']!,
        result: result,
      ),
    ),
  );
}),
```

### Example 2: Home Screen Recommendations (Already Exists)
**File**: `lib/screens/home_screen.dart`

```dart
// Add another controller for recommendations
late AnimationController _recommendationsAnimationController;

@override
void initState() {
  super.initState();
  // ... existing code
  _recommendationsAnimationController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );
}

// In _loadWeeklyAdvice():
_recommendationsAnimationController.forward();

// In _buildRecommendationsSection():
ListView.builder(
  itemCount: list.length,
  itemBuilder: (context, index) {
    final rec = list[index];
    return AppAnimations.createStaggeredCard(
      index: index,
      controller: _recommendationsAnimationController,
      maxElements: 7,
      child: Container(
        // ... existing recommendation card UI
      ),
    );
  },
)
```

### Example 3: Milestone Screen
**File**: `lib/screens/milestones_screen.dart` (or similar)

```dart
class MilestonesScreen extends StatefulWidget {
  // ...
}

class _MilestonesScreenState extends State<MilestonesScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  List<Milestone> _milestones = [];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    );
    _loadMilestones();
  }

  Future<void> _loadMilestones() async {
    // Load milestones
    setState(() { _milestones = loadedMilestones; });
    _animationController.forward();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: _milestones.asMap().entries.map((entry) {
        return AppAnimations.createStaggeredCard(
          index: entry.key,
          controller: _animationController,
          child: MilestoneCard(milestone: entry.value),
        );
      }).toList(),
    );
  }
}
```

### Example 4: Settings Screen
**File**: `lib/screens/settings_screen.dart`

Add page transitions for navigation:

```dart
// Replace MaterialPageRoute with:
Navigator.of(context).pushWithFade(SettingsDetailScreen());
```

---

## Quick Migration Checklist

### For Any Screen with Cards/Lists:
- [ ] Import `app_animations.dart`
- [ ] Add `SingleTickerProviderStateMixin`
- [ ] Create `AnimationController`
- [ ] Initialize in `initState()`
- [ ] Dispose in `dispose()`
- [ ] Start animation after data loads
- [ ] Wrap list items with `AppAnimations.createStaggeredCard()`

### For Any Screen with Navigation:
- [ ] Import `app_animations.dart`
- [ ] Replace `Navigator.push(MaterialPageRoute(...))` with `Navigator.of(context).pushWithFade(...)`

---

## Screens to Update

### ✅ Completed
- [x] Onboarding goals screen

### 🔄 High Priority Main App Screens

#### Home Screen
- [ ] Activities list (stagger animation)
- [ ] Recommendations list (stagger animation)
- [ ] Navigation to other screens (fade transitions)

#### Milestones Screen
- [ ] Milestone cards (stagger animation)
- [ ] Category filters (micro-interactions)
- [ ] Detail navigation (fade transitions)

#### Tracking Screen
- [ ] Domain cards (stagger animation)
- [ ] Detail navigation (fade transitions)

#### Advice Screen
- [ ] Advice cards (stagger animation)
- [ ] Navigation (fade transitions)

#### Settings Screen
- [ ] Settings options (stagger animation)
- [ ] Navigation (fade transitions)

### 🔄 Medium Priority

#### Diary/Journal Screens
- [ ] Entry cards (stagger animation)
- [ ] Navigation (fade transitions)

#### Profile/Baby Screens
- [ ] Baby cards (stagger animation)
- [ ] Navigation (fade transitions)

#### Moments Screen
- [ ] Moment cards (stagger animation)
- [ ] Photo uploads (micro-interactions)

---

## Animation Constants Reference

```dart
// Import
import 'package:babysteps_app/utils/app_animations.dart';

// Page transitions
AppAnimations.pageTransitionDuration    // 300ms
AppAnimations.pageTransitionCurve       // ease-in-out

// Staggered cards
AppAnimations.staggerElementDuration    // 600ms
AppAnimations.staggerDelay              // 100ms
AppAnimations.staggerCurve              // ease-out
AppAnimations.staggerSlideOffset        // 0.3 (30%)

// Micro-interactions
AppAnimations.microInteractionDuration  // 200ms
AppAnimations.microInteractionCurve     // ease-out

// Modals
AppAnimations.modalDuration             // 300ms
AppAnimations.modalCurve                // ease-out

// Toasts/Alerts
AppAnimations.toastDuration             // 250ms
AppAnimations.toastCurve                // ease-in-out
```

---

## Backward Compatibility

The old `OnboardingAnimations` class still works (with deprecation warnings):

```dart
// Old code (still works):
OnboardingAnimations.createStaggeredCard(...)
Navigator.of(context).pushWithFade(...) // via OnboardingNavigator

// New code (preferred):
AppAnimations.createStaggeredCard(...)
Navigator.of(context).pushWithFade(...) // via AppNavigator
```

No breaking changes - existing onboarding screens continue to work!

---

## Testing

### Visual Testing
- [ ] Animations are smooth (60fps)
- [ ] Stagger delay is consistent (100ms)
- [ ] Page transitions are smooth (300ms)
- [ ] No jank or stuttering

### Accessibility Testing
- [ ] Test with "Reduce Motion" enabled
- [ ] Animations are disabled/instant
- [ ] Content is still accessible
- [ ] Screen reader compatibility

### Performance Testing
- [ ] No dropped frames
- [ ] Controllers are disposed
- [ ] No memory leaks
- [ ] Smooth on low-end devices

---

## Best Practices

### Do's ✅
- Use `AppAnimations` for all new code
- Dispose animation controllers
- Start animations after data loads
- Limit stagger to 7 elements
- Test with reduced motion
- Use consistent timing across app

### Don'ts ❌
- Don't use `MaterialPageRoute` directly
- Don't forget to dispose controllers
- Don't animate on every `setState()`
- Don't stagger more than 7 elements
- Don't ignore accessibility
- Don't create custom durations (use constants)

---

## Examples in Codebase

**Onboarding Example**:
- `lib/screens/onboarding_goals_screen.dart` - Full stagger + transitions

**Main App Examples** (to be added):
- `lib/screens/home_screen.dart` - Activities + recommendations stagger
- `lib/screens/milestones_screen.dart` - Milestone cards stagger
- `lib/screens/tracking_screen.dart` - Domain cards stagger

---

## Support

### Quick Reference
- See `ANIMATION_QUICK_REFERENCE.md` for code snippets
- See `lib/utils/app_animations.dart` for implementation
- See `lib/screens/onboarding_goals_screen.dart` for working example

### Questions?
- How to add stagger? → See "Example 1: Home Screen Activities"
- How to add transitions? → Use `Navigator.of(context).pushWithFade()`
- How to test reduced motion? → Enable in device settings
- Performance issues? → Check controller disposal

---

**Status**: ✅ Utility updated for app-wide use
**Next**: Apply to main app screens (Home, Milestones, Tracking, etc.)
**Impact**: Consistent, polished animations throughout entire app
