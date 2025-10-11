# Onboarding Animations - Quick Reference

## 📦 Import
```dart
import 'package:babysteps_app/utils/onboarding_animations.dart';
```

## 🎬 Page Transitions (300ms cross-fade)

### Replace This:
```dart
Navigator.of(context).push(
  MaterialPageRoute(builder: (context) => NextScreen()),
);
```

### With This:
```dart
Navigator.of(context).pushWithFade(NextScreen());
```

### Or for Replacement:
```dart
Navigator.of(context).pushReplacementWithFade(NextScreen());
```

---

## 🎴 Staggered Cards (600ms + 100ms delays)

### Method 1: Manual Control (More Flexible)

**1. Add Mixin**
```dart
class _YourScreenState extends State<YourScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
```

**2. Initialize**
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

**3. Start Animation**
```dart
Future<void> _loadData() async {
  // ... load data ...
  setState(() { _loading = false; });
  _animationController.forward(); // ← Start here
}
```

**4. Wrap Cards**
```dart
children: items.asMap().entries.map((entry) {
  return OnboardingAnimations.createStaggeredCard(
    index: entry.key,
    controller: _animationController,
    maxElements: 7,
    child: YourCard(item: entry.value),
  );
}).toList(),
```

### Method 2: Auto Widget (Simpler)

```dart
StaggeredAnimationList(
  maxStaggerElements: 7,
  children: [
    Card1(),
    Card2(),
    Card3(),
  ],
)
```

---

## 📋 Animation Specs

| Type | Duration | Delay | Curve | Movement |
|------|----------|-------|-------|----------|
| **Page Transition** | 300ms | - | ease-in-out | Fade only |
| **Staggered Card** | 600ms | 100ms/card | ease-out | Fade + slide up 30% |

---

## ✅ Checklist

### For Screens with Multiple Cards:
- [ ] Import `onboarding_animations.dart`
- [ ] Add `SingleTickerProviderStateMixin`
- [ ] Create `AnimationController`
- [ ] Initialize in `initState()`
- [ ] Dispose in `dispose()`
- [ ] Start animation after data loads
- [ ] Wrap cards with `createStaggeredCard()`
- [ ] Update navigation to `pushWithFade()`

### For Simple Screens:
- [ ] Import `onboarding_animations.dart`
- [ ] Update navigation to `pushWithFade()`

---

## 🎯 Duration Calculator

```dart
// Formula: (number_of_cards * 100ms) + 600ms
final durationMs = (numCards * 100) + 600;

// Examples:
3 cards  = 900ms
5 cards  = 1100ms
7 cards  = 1300ms (max recommended)
```

---

## 🚫 Common Mistakes

### ❌ Don't:
```dart
// Don't use MaterialPageRoute
Navigator.push(MaterialPageRoute(...));

// Don't forget to dispose
// Missing dispose() causes memory leaks

// Don't animate too many items
maxElements: 20 // Too slow!
```

### ✅ Do:
```dart
// Use fade transitions
Navigator.of(context).pushWithFade(NextScreen());

// Always dispose
@override
void dispose() {
  _animationController.dispose();
  super.dispose();
}

// Limit stagger
maxElements: 7 // Good!
```

---

## 🔍 Example: Complete Screen

```dart
import 'package:flutter/material.dart';
import 'package:babysteps_app/utils/onboarding_animations.dart';

class OnboardingExampleScreen extends StatefulWidget {
  const OnboardingExampleScreen({super.key});

  @override
  State<OnboardingExampleScreen> createState() => _OnboardingExampleScreenState();
}

class _OnboardingExampleScreenState extends State<OnboardingExampleScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  bool _loading = true;
  final List<String> _items = ['Item 1', 'Item 2', 'Item 3'];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900), // 3 items
    );
    _loadData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    await Future.delayed(const Duration(milliseconds: 500));
    setState(() { _loading = false; });
    _animationController.forward();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const CircularProgressIndicator();
    
    return Scaffold(
      body: Column(
        children: _items.asMap().entries.map((entry) {
          return OnboardingAnimations.createStaggeredCard(
            index: entry.key,
            controller: _animationController,
            maxElements: 7,
            child: Card(child: Text(entry.value)),
          );
        }).toList(),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).pushWithFade(NextScreen());
        },
        child: const Icon(Icons.arrow_forward),
      ),
    );
  }
}
```

---

## 📱 Accessibility

Animations automatically respect:
- ✅ `prefers-reduced-motion` system setting
- ✅ Flutter accessibility settings
- ✅ `MediaQuery.disableAnimations`

No extra code needed!

---

## 🎨 Customization

### Custom Duration
```dart
OnboardingAnimations.createPageRoute(
  page: NextScreen(),
  // Uses default 300ms - not customizable per guidelines
);
```

### Custom Stagger Delay
```dart
// Not recommended - breaks consistency
// Stick to 100ms delay per guidelines
```

### Disable Reduced Motion Check
```dart
OnboardingAnimations.createStaggeredCard(
  index: 0,
  controller: _animationController,
  respectReducedMotion: false, // Not recommended
  child: YourCard(),
);
```

---

## 📚 See Also

- **Full Guide**: `ONBOARDING_ANIMATIONS_GUIDE.md`
- **Implementation**: `lib/utils/onboarding_animations.dart`
- **Example**: `lib/screens/onboarding_goals_screen.dart`
