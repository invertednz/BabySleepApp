# App Animations - Quick Start

## 🚀 5-Minute Setup

### 1. Import the Utility
```dart
import 'package:babysteps_app/utils/app_animations.dart';
```

### 2. Choose Your Use Case

---

## 📱 Use Case 1: Add Page Transitions

**When**: Navigating between any screens

**Before**:
```dart
Navigator.push(
  context,
  MaterialPageRoute(builder: (context) => NextScreen()),
);
```

**After**:
```dart
Navigator.of(context).pushWithFade(NextScreen());
```

**That's it!** ✅ 300ms cross-fade transition applied.

---

## 🎴 Use Case 2: Add Staggered Card Animations

**When**: Displaying lists/grids of cards

**Step 1**: Add mixin and controller
```dart
class _MyScreenState extends State<MyScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
```

**Step 2**: Initialize
```dart
@override
void initState() {
  super.initState();
  _animationController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1300), // (7 cards * 100ms) + 600ms
  );
  _loadData();
}

@override
void dispose() {
  _animationController.dispose();
  super.dispose();
}
```

**Step 3**: Start animation after data loads
```dart
Future<void> _loadData() async {
  // Load your data
  setState(() { _loading = false; });
  _animationController.forward(); // ← Start animation
}
```

**Step 4**: Wrap your cards
```dart
ListView(
  children: items.asMap().entries.map((entry) {
    return AppAnimations.createStaggeredCard(
      index: entry.key,
      controller: _animationController,
      maxElements: 7,
      child: YourCard(item: entry.value),
    );
  }).toList(),
)
```

**Done!** ✅ Cards now fade in and slide up with 100ms stagger.

---

## 🎯 Common Screens

### Home Screen - Activities List

```dart
// In _HomeScreenState:
late AnimationController _activitiesController;

@override
void initState() {
  super.initState();
  _activitiesController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900), // 3 activities
  );
}

// After loading activities:
_activitiesController.forward();

// In build:
..._activities.asMap().entries.map((entry) {
  return AppAnimations.createStaggeredCard(
    index: entry.key,
    controller: _activitiesController,
    child: _ActivityListCard(...),
  );
}),
```

### Home Screen - Recommendations List

```dart
// Same pattern as activities
late AnimationController _recommendationsController;

// Initialize, start, and wrap cards
```

### Milestones Screen - Milestone Cards

```dart
class _MilestonesScreenState extends State<MilestonesScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    );
    _loadMilestones();
  }
  
  Future<void> _loadMilestones() async {
    // Load milestones
    setState(() { _milestones = data; });
    _controller.forward();
  }
  
  @override
  Widget build(BuildContext context) {
    return ListView(
      children: _milestones.asMap().entries.map((entry) {
        return AppAnimations.createStaggeredCard(
          index: entry.key,
          controller: _controller,
          child: MilestoneCard(milestone: entry.value),
        );
      }).toList(),
    );
  }
}
```

---

## 📊 Duration Calculator

```dart
// Formula: (number_of_cards * 100ms) + 600ms

3 cards  = 900ms
5 cards  = 1100ms
7 cards  = 1300ms (max recommended)
10 cards = 1600ms (too slow, limit to 7)
```

---

## ⚡ Quick Tips

### Do's ✅
- Use `pushWithFade()` for all navigation
- Limit stagger to 7 cards max
- Start animation after data loads
- Always dispose controllers
- Test with reduced motion enabled

### Don'ts ❌
- Don't use `MaterialPageRoute` directly
- Don't forget to dispose controllers
- Don't stagger more than 7 elements
- Don't animate on every `setState()`
- Don't create custom durations

---

## 🧪 Quick Test

### Test Animations
1. Run app
2. Navigate to your screen
3. Cards should fade in and slide up
4. Delay should be 100ms between cards
5. Total animation < 1.5 seconds

### Test Reduced Motion
1. Enable "Reduce Motion" in device settings
2. Run app
3. Navigate to your screen
4. Cards should appear instantly (no animation)
5. Content should still be readable

---

## 📚 Full Documentation

- **Complete Guide**: `APP_ANIMATIONS_GUIDE.md`
- **Code Examples**: `lib/screens/onboarding_goals_screen.dart`
- **Implementation**: `lib/utils/app_animations.dart`

---

## 🆘 Troubleshooting

| Issue | Solution |
|-------|----------|
| Cards don't animate | Check `_controller.forward()` is called |
| Animation too slow | Reduce number of cards or check duration |
| Memory leak | Ensure `dispose()` is called |
| Jank/stuttering | Profile with DevTools, check for rebuilds |
| Reduced motion not working | Check `MediaQuery.disableAnimations` |

---

## 🎨 Animation Constants

```dart
// Page transitions
AppAnimations.pageTransitionDuration    // 300ms

// Staggered cards
AppAnimations.staggerElementDuration    // 600ms
AppAnimations.staggerDelay              // 100ms

// Micro-interactions
AppAnimations.microInteractionDuration  // 200ms

// Modals
AppAnimations.modalDuration             // 300ms

// Toasts
AppAnimations.toastDuration             // 250ms
```

---

## ✅ Checklist

### For Screens with Cards:
- [ ] Import `app_animations.dart`
- [ ] Add `SingleTickerProviderStateMixin`
- [ ] Create `AnimationController`
- [ ] Initialize in `initState()`
- [ ] Dispose in `dispose()`
- [ ] Start animation after data loads
- [ ] Wrap cards with `createStaggeredCard()`
- [ ] Test animations
- [ ] Test reduced motion

### For All Screens:
- [ ] Import `app_animations.dart`
- [ ] Replace `MaterialPageRoute` with `pushWithFade()`
- [ ] Test transitions

---

**Ready to go!** Start with page transitions (easiest), then add stagger to cards.
