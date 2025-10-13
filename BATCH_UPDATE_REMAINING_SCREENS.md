# Batch Update Remaining Onboarding Screens

## ✅ Completed So Far (6/30)
1. onboarding_goals_screen.dart
2. onboarding_nurture_global_screen.dart
3. onboarding_baby_screen.dart
4. onboarding_welcome_screen.dart
5. onboarding_gender_screen.dart
6. onboarding_activities_loves_hates_screen.dart

## 🔄 Remaining Screens (24/30)

### Batch 1: Multi-Baby Screens (1 screen)
These follow the same pattern as activities/gender screens.

**onboarding_milestones_screen.dart**
```dart
// 1. Add imports
import 'package:babysteps_app/utils/app_animations.dart';
import 'package:babysteps_app/widgets/onboarding_app_bar.dart';

// 2. Replace header (around line 200-220)
// Find: Padding with Icon(FeatherIcons.sunrise...
// Replace with:
OnboardingAppBar(
  onBackPressed: _back,
),
const OnboardingProgressBar(progress: 0.7),

// 3. Remove bottom back button (around line 350-380)
// Find: Row with OutlinedButton('Back') and ElevatedButton('Next')
// Replace with:
ElevatedButton(
  onPressed: hasSelection ? _next : null,
  style: ElevatedButton.styleFrom(
    minimumSize: const Size(double.infinity, 50),
    // ... other styles
  ),
  child: Text(_currentIndex < widget.babies.length - 1 ? 'Next Baby' : 'Next'),
)

// 4. Update navigation calls
// Find: MaterialPageRoute
// Replace with: pushWithFade or pushReplacementWithFade
```

### Batch 2: Standard Form Screens (11 screens)
These have standard header + progress + form + back/next buttons.

**Screens**:
- onboarding_measurements_screen.dart
- onboarding_feeding_screen.dart
- onboarding_sleep_screen.dart
- onboarding_diaper_screen.dart
- onboarding_parenting_style_screen.dart
- onboarding_concerns_screen.dart
- onboarding_short_term_focus_screen.dart
- onboarding_nurture_priorities_screen.dart
- onboarding_measurements_screen_fixed.dart
- onboarding_notifications_screen.dart
- onboarding_results_screen.dart

**Standard Pattern**:
```dart
// 1. Add imports at top
import 'package:babysteps_app/utils/app_animations.dart';
import 'package:babysteps_app/widgets/onboarding_app_bar.dart';

// 2. Replace header container (usually around line 60-100)
// OLD:
Container(
  margin: const EdgeInsets.all(20),
  padding: const EdgeInsets.all(20),
  decoration: BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(16),
    // ...
  ),
  child: Row(
    children: const [
      Icon(FeatherIcons.sunrise, ...),
      SizedBox(width: 12),
      Text('BabySteps', ...),
    ],
  ),
),

// NEW:
OnboardingAppBar(),

// 3. Replace progress bar (usually right after header)
// OLD:
Padding(
  padding: const EdgeInsets.symmetric(horizontal: 20),
  child: ClipRRect(
    borderRadius: BorderRadius.circular(3),
    child: const LinearProgressIndicator(
      value: 0.X,
      // ...
    ),
  ),
),

// NEW:
const OnboardingProgressBar(progress: 0.X),

// 4. Remove bottom back button (usually at end of build method)
// OLD:
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

// NEW:
ElevatedButton(
  onPressed: _onNext,
  style: ElevatedButton.styleFrom(
    minimumSize: const Size(double.infinity, 50),
    // ... keep other existing styles
  ),
  child: const Text('Next'),
)

// 5. Update all Navigator.push calls
// OLD:
Navigator.of(context).push(
  MaterialPageRoute(builder: (context) => NextScreen()),
);

// NEW:
Navigator.of(context).pushWithFade(NextScreen());

// OLD:
Navigator.of(context).pushReplacement(
  MaterialPageRoute(builder: (context) => NextScreen()),
);

// NEW:
Navigator.of(context).pushReplacementWithFade(NextScreen());
```

### Batch 3: Payment/Offer Screens (6 screens)
These may have different layouts but follow similar pattern.

**Screens**:
- onboarding_trial_offer_screen.dart
- onboarding_payment_screen_new.dart
- onboarding_special_discount_screen_new.dart
- onboarding_trial_timeline_screen.dart
- onboarding_payment_screen.dart
- onboarding_special_discount_screen.dart

**Pattern**: Same as Batch 2, but may not have back buttons at bottom.

### Batch 4: Secondary Screens (6 screens)
These may have unique layouts.

**Screens**:
- onboarding_app_tour_screen.dart
- onboarding_baby_progress_screen.dart
- onboarding_before_after_screen.dart
- onboarding_growth_chart_screen.dart
- onboarding_progress_preview_screen.dart
- onboarding_thank_you_screen.dart (last screen - back button optional)

**Pattern**: Add imports and update navigation only. May not need full header replacement.

---

## 🚀 Quick Find/Replace Patterns

### Pattern 1: Add Imports
**Find** (at top of file after existing imports):
```dart
import 'package:babysteps_app/screens/...';
```

**Add after**:
```dart
import 'package:babysteps_app/utils/app_animations.dart';
import 'package:babysteps_app/widgets/onboarding_app_bar.dart';
```

### Pattern 2: Replace Header
**Find**:
```dart
Container(
  margin: const EdgeInsets.all(20),
  padding: const EdgeInsets.all(20),
  decoration: BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(16),
```

**Replace with**:
```dart
OnboardingAppBar(),
```

### Pattern 3: Replace Progress Bar
**Find**:
```dart
Padding(
  padding: const EdgeInsets.symmetric(horizontal: 20),
  child: ClipRRect(
    borderRadius: BorderRadius.circular(3),
    child: const LinearProgressIndicator(
```

**Replace with**:
```dart
const OnboardingProgressBar(progress:
```

### Pattern 4: Remove Back Button
**Find**:
```dart
Expanded(
  child: OutlinedButton(
    onPressed:
```

**Check**: If it's a "Back" button in a Row with Next button, delete the entire Row and keep only the ElevatedButton with `minimumSize: const Size(double.infinity, 50)`.

### Pattern 5: Update Navigation
**Find**: `MaterialPageRoute(builder: (context) =>`
**Replace with**: `pushWithFade(` or `pushReplacementWithFade(`

---

## 📋 Progress Tracking

Update this as you complete each screen:

### Batch 1: Multi-Baby (1 screen)
- [ ] onboarding_milestones_screen.dart

### Batch 2: Standard Forms (11 screens)
- [ ] onboarding_measurements_screen.dart
- [ ] onboarding_feeding_screen.dart
- [ ] onboarding_sleep_screen.dart
- [ ] onboarding_diaper_screen.dart
- [ ] onboarding_parenting_style_screen.dart
- [ ] onboarding_concerns_screen.dart
- [ ] onboarding_short_term_focus_screen.dart
- [ ] onboarding_nurture_priorities_screen.dart
- [ ] onboarding_measurements_screen_fixed.dart
- [ ] onboarding_notifications_screen.dart
- [ ] onboarding_results_screen.dart

### Batch 3: Payment/Offers (6 screens)
- [ ] onboarding_trial_offer_screen.dart
- [ ] onboarding_payment_screen_new.dart
- [ ] onboarding_special_discount_screen_new.dart
- [ ] onboarding_trial_timeline_screen.dart
- [ ] onboarding_payment_screen.dart
- [ ] onboarding_special_discount_screen.dart

### Batch 4: Secondary (6 screens)
- [ ] onboarding_app_tour_screen.dart
- [ ] onboarding_baby_progress_screen.dart
- [ ] onboarding_before_after_screen.dart
- [ ] onboarding_growth_chart_screen.dart
- [ ] onboarding_progress_preview_screen.dart
- [ ] onboarding_thank_you_screen.dart

---

## ⚡ Automated Script (Optional)

If you want to automate this, here's a PowerShell script pattern:

```powershell
# Example for one screen
$file = "c:\Trae Apps\BabySleepApp\babysteps_app\lib\screens\onboarding_measurements_screen.dart"

# Read file
$content = Get-Content $file -Raw

# Add imports if not present
if ($content -notmatch "app_animations") {
    $content = $content -replace "(import 'package:babysteps_app/screens/[^']+';)", "`$1`nimport 'package:babysteps_app/utils/app_animations.dart';`nimport 'package:babysteps_app/widgets/onboarding_app_bar.dart';"
}

# Replace header
$content = $content -replace "Container\(\s+margin: const EdgeInsets\.all\(20\),\s+padding: const EdgeInsets\.all\(20\),\s+decoration: BoxDecoration\([^)]+\),\s+child: Row\(\s+children: const \[\s+Icon\(FeatherIcons\.sunrise[^\]]+\],\s+\),\s+\),", "OnboardingAppBar(),"

# Save file
Set-Content $file $content
```

---

## 🎯 Estimated Time

- **Batch 1**: 30 minutes (1 complex screen)
- **Batch 2**: 2 hours (11 standard screens @ 10 min each)
- **Batch 3**: 1 hour (6 payment screens @ 10 min each)
- **Batch 4**: 1 hour (6 secondary screens @ 10 min each)

**Total**: ~4.5 hours

---

## ✅ Testing After Each Batch

1. Run `flutter analyze` to check for errors
2. Run `flutter run -d chrome` to test compilation
3. Navigate through onboarding to verify:
   - Back arrows appear
   - No duplicate back buttons
   - Animations work
   - Progress bars show

---

**Current Status**: 6/30 complete (20%)
**Next**: Start with Batch 1 (milestones screen)
