# Onboarding Back Button Implementation Guide

## Overview
Add a consistent back arrow to all onboarding screens using the reusable `OnboardingAppBar` component.

## ✅ What Was Created

### 1. Reusable Component
**File**: `lib/widgets/onboarding_app_bar.dart`

Two widgets created:
- **`OnboardingAppBar`** - App bar with back arrow and BabySteps branding
- **`OnboardingProgressBar`** - Progress indicator (extracted for reusability)

### 2. Example Implementation
**File**: `lib/screens/onboarding_goals_screen.dart` ✅

Updated to use the new components with:
- Back arrow in app bar
- Custom back navigation logic
- Removed duplicate back button at bottom
- Full-width "Next" button

---

## 🎯 How to Update Other Screens

### Step 1: Import the Widget

```dart
import 'package:babysteps_app/widgets/onboarding_app_bar.dart';
```

### Step 2: Replace Existing App Bar

**Before**:
```dart
Container(
  margin: const EdgeInsets.all(20),
  padding: const EdgeInsets.all(20),
  decoration: BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(16),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.05),
        blurRadius: 8,
        offset: const Offset(0, 2),
      ),
    ],
  ),
  child: Row(
    children: const [
      Icon(FeatherIcons.sunrise, color: AppTheme.primaryPurple, size: 32),
      SizedBox(width: 12),
      Text('BabySteps', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Color(0xFF1F2937))),
    ],
  ),
),
```

**After**:
```dart
OnboardingAppBar(
  onBackPressed: () {
    // Optional: custom back logic
    Navigator.of(context).pop();
  },
),
```

### Step 3: Replace Progress Bar (Optional)

**Before**:
```dart
Padding(
  padding: const EdgeInsets.symmetric(horizontal: 20),
  child: ClipRRect(
    borderRadius: BorderRadius.circular(3),
    child: const LinearProgressIndicator(
      value: 0.3,
      minHeight: 6,
      backgroundColor: Color(0xFFE5E7EB),
      valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryPurple),
    ),
  ),
),
```

**After**:
```dart
const OnboardingProgressBar(progress: 0.3),
```

### Step 4: Remove Bottom Back Button (Optional)

If your screen has a "Back" button at the bottom, you can remove it since the back arrow is now at the top.

**Before**:
```dart
Row(
  children: [
    Expanded(
      child: OutlinedButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Back'),
      ),
    ),
    const SizedBox(width: 16),
    Expanded(
      child: ElevatedButton(
        onPressed: _onNext,
        child: const Text('Next'),
      ),
    ),
  ],
)
```

**After**:
```dart
ElevatedButton(
  onPressed: _onNext,
  style: ElevatedButton.styleFrom(
    minimumSize: const Size(double.infinity, 50),
  ),
  child: const Text('Next'),
)
```

---

## 📋 Screen-by-Screen Checklist

### ✅ Completed
- [x] `onboarding_goals_screen.dart` - Back arrow + full-width Next button

### 🔄 To Update (29 screens)

#### High Priority - User-Facing Screens
- [ ] `onboarding_welcome_screen.dart` - First screen (hide back button)
- [ ] `onboarding_nurture_global_screen.dart`
- [ ] `onboarding_baby_screen.dart`
- [ ] `onboarding_gender_screen.dart`
- [ ] `onboarding_measurements_screen.dart`
- [ ] `onboarding_milestones_screen.dart`
- [ ] `onboarding_short_term_focus_screen.dart`
- [ ] `onboarding_nurture_priorities_screen.dart`
- [ ] `onboarding_concerns_screen.dart`
- [ ] `onboarding_parenting_style_screen.dart`
- [ ] `onboarding_activities_loves_hates_screen.dart`
- [ ] `onboarding_feeding_screen.dart`
- [ ] `onboarding_sleep_screen.dart`
- [ ] `onboarding_diaper_screen.dart`

#### Medium Priority - Results & Offers
- [ ] `onboarding_results_screen.dart`
- [ ] `onboarding_trial_offer_screen.dart`
- [ ] `onboarding_payment_screen_new.dart`
- [ ] `onboarding_special_discount_screen_new.dart`
- [ ] `onboarding_trial_timeline_screen.dart`

#### Low Priority - Secondary Screens
- [ ] `onboarding_app_tour_screen.dart`
- [ ] `onboarding_baby_progress_screen.dart`
- [ ] `onboarding_before_after_screen.dart`
- [ ] `onboarding_growth_chart_screen.dart`
- [ ] `onboarding_measurements_screen_fixed.dart`
- [ ] `onboarding_notifications_screen.dart`
- [ ] `onboarding_payment_screen.dart`
- [ ] `onboarding_progress_preview_screen.dart`
- [ ] `onboarding_special_discount_screen.dart`
- [ ] `onboarding_thank_you_screen.dart` - Last screen (back arrow optional)

---

## 🎨 Component API

### OnboardingAppBar

```dart
OnboardingAppBar({
  VoidCallback? onBackPressed,  // Custom back action (default: Navigator.pop)
  bool showBackButton = true,   // Hide back button on first screen
})
```

**Examples**:

```dart
// Default behavior (Navigator.pop)
OnboardingAppBar()

// Custom back action
OnboardingAppBar(
  onBackPressed: () {
    Navigator.of(context).pushReplacementWithFade(PreviousScreen());
  },
)

// Hide back button (first screen)
OnboardingAppBar(showBackButton: false)
```

### OnboardingProgressBar

```dart
OnboardingProgressBar({
  required double progress,  // 0.0 to 1.0
})
```

**Example**:
```dart
const OnboardingProgressBar(progress: 0.3)  // 30% complete
```

---

## 🎯 Special Cases

### First Screen (Welcome)
Hide the back button:
```dart
OnboardingAppBar(showBackButton: false)
```

### Last Screen (Thank You)
Back button optional - user shouldn't go back after completion.

### Screens with Custom Navigation
Provide custom `onBackPressed`:
```dart
OnboardingAppBar(
  onBackPressed: () {
    // Save state before going back
    _saveProgress();
    Navigator.of(context).pop();
  },
)
```

### Screens with Multiple Steps
Update progress value:
```dart
OnboardingProgressBar(
  progress: _currentStep / _totalSteps,
)
```

---

## 🎨 Design Specs

### Back Arrow
- **Icon**: `FeatherIcons.arrowLeft`
- **Size**: 20px
- **Color**: `AppTheme.primaryPurple`
- **Background**: `AppTheme.primaryPurple.withOpacity(0.1)`
- **Padding**: 8px
- **Border Radius**: 8px

### App Bar Container
- **Background**: White
- **Border Radius**: 16px
- **Margin**: 20px all sides
- **Padding**: 20px all sides
- **Shadow**: Black 5% opacity, 8px blur, 2px offset

### Progress Bar
- **Height**: 6px
- **Border Radius**: 3px
- **Background**: `Color(0xFFE5E7EB)` (light gray)
- **Fill Color**: `AppTheme.primaryPurple`
- **Margin**: 20px horizontal

---

## ✅ Testing Checklist

For each updated screen:
- [ ] Back arrow appears in top left
- [ ] Back arrow navigates to previous screen
- [ ] Progress bar shows correct percentage
- [ ] No duplicate back buttons
- [ ] Animations work smoothly
- [ ] Reduced motion is respected

---

## 🚀 Quick Migration Script

For screens with standard layout:

1. Add import:
   ```dart
   import 'package:babysteps_app/widgets/onboarding_app_bar.dart';
   ```

2. Find and replace app bar container with:
   ```dart
   OnboardingAppBar(),
   ```

3. Find and replace progress bar with:
   ```dart
   const OnboardingProgressBar(progress: YOUR_VALUE),
   ```

4. (Optional) Remove bottom back button and make Next full-width

---

## 📊 Progress Tracking

**Total Screens**: 30
**Updated**: 1 (Goals screen)
**Remaining**: 29

**Estimated Time**: ~2-3 hours for all screens (5-10 min per screen)

---

## 📁 Files

### Implementation
- ✅ `lib/widgets/onboarding_app_bar.dart` - Reusable components
- ✅ `lib/screens/onboarding_goals_screen.dart` - Example implementation

### Documentation
- ✅ `ONBOARDING_BACK_BUTTON_GUIDE.md` - This file

---

## 🎯 Benefits

### User Experience
- ✅ **Consistent navigation** - Back arrow on every screen
- ✅ **Intuitive** - Users know how to go back
- ✅ **Professional** - Polished, cohesive design
- ✅ **Accessible** - Clear navigation affordance

### Developer Experience
- ✅ **Reusable** - One component for all screens
- ✅ **Maintainable** - Update once, applies everywhere
- ✅ **Consistent** - Same design across all screens
- ✅ **Flexible** - Easy to customize per screen

---

**Status**: ✅ Component created, example implemented  
**Next**: Update remaining 29 onboarding screens  
**Timeline**: 2-3 hours for full implementation
