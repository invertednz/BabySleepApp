# Streak Tracking Implementation Guide

## Overview
The streak tracking system monitors daily user engagement across multiple activities in the BabySteps app. The streak is displayed on the Advice (Home) page with color-coded visual feedback.

## Database Setup

### Migration Required
Run this SQL migration in Supabase:
```sql
-- File: 0014_add_user_activity_log.sql
CREATE TABLE IF NOT EXISTS public.user_activity_log (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  activity_date date NOT NULL DEFAULT CURRENT_DATE,
  activity_types jsonb NOT NULL DEFAULT '[]'::jsonb,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE(user_id, activity_date)
);
```

## Activity Types Tracked

The system tracks these activity types:
1. **`focus`** - Changed short-term focus
2. **`sleep`** - Updated sleep schedule
3. **`milestones`** - Marked milestones as complete
4. **`progress`** - Updated progress tracking
5. **`moments`** - Created new milestone moment
6. **`words`** - Added vocabulary words
7. **`activities`** - Set activity preferences (loves/hates)
8. **`recommendations`** - Closed/dismissed recommendations

## Streak Color System

The streak icon changes color based on streak length:

| Streak Length | Color | Hex Code | Meaning |
|--------------|-------|----------|---------|
| 0 days | Gray | #9CA3AF | Not started |
| 1-2 days | Yellow | #FBBF24 | Getting started |
| 3-6 days | Green | #10B981 | Building habit |
| 7-13 days | Blue | #3B82F6 | Strong habit |
| 14-29 days | Purple | #8B5CF6 | Committed |
| 30+ days | Pink | #EC4899 | Champion! |

## How to Wire Up Activity Tracking

### 1. Focus Screen
When user updates short-term focus:

```dart
// In focus_screen.dart or wherever focus is updated
Future<void> _saveFocus() async {
  final babyProvider = Provider.of<BabyProvider>(context, listen: false);
  
  // Save the focus data
  await babyProvider.saveShortTermFocus(babyId, focusItems);
  
  // Log activity for streak
  await babyProvider.logActivity('focus');
}
```

### 2. Sleep Schedule Screen
When user updates sleep schedule:

```dart
// In sleep_schedule_screen.dart
Future<void> _saveSleepSchedule() async {
  final babyProvider = Provider.of<BabyProvider>(context, listen: false);
  
  // Save sleep schedule
  await babyProvider.updateBabySchedule(babyId, schedule);
  
  // Log activity for streak
  await babyProvider.logActivity('sleep');
}
```

### 3. Milestones Screen
When user marks milestone as complete:

```dart
// In milestones_screen.dart
Future<void> _toggleMilestone(String milestoneId) async {
  final babyProvider = Provider.of<BabyProvider>(context, listen: false);
  
  // Toggle milestone
  await babyProvider.toggleMilestone(babyId, milestoneId);
  
  // Log activity for streak
  await babyProvider.logActivity('milestones');
}
```

### 4. Progress Screen - Moments Tab
When user creates a new milestone moment:

```dart
// In progress_screen.dart - _MilestoneMomentsTab
Future<void> _addMoment() async {
  final babyProvider = Provider.of<BabyProvider>(context, listen: false);
  
  // Save moment
  await babyProvider.saveMilestoneMoment(babyId, momentData);
  
  // Log activity for streak
  await babyProvider.logActivity('moments');
}
```

### 5. Progress Screen - Vocabulary Tab
When user adds a new word:

```dart
// In progress_screen.dart - _VocabularyTab
Future<void> _addWord() async {
  final babyProvider = Provider.of<BabyProvider>(context, listen: false);
  
  // Add word
  await babyProvider.addBabyVocabularyWord(word, babyId: babyId);
  
  // Log activity for streak
  await babyProvider.logActivity('words');
}
```

### 6. Activities Screen
When user sets activity preferences:

```dart
// In activities_screen.dart or onboarding_activities_loves_hates_screen.dart
Future<void> _saveActivities() async {
  final babyProvider = Provider.of<BabyProvider>(context, listen: false);
  
  // Save activities
  await babyProvider.saveBabyActivities(babyId, loves: loves, hates: hates);
  
  // Log activity for streak
  await babyProvider.logActivity('activities');
}
```

### 7. Home/Advice Screen - Recommendations
When user dismisses/closes a recommendation:

```dart
// In home_screen.dart
Future<void> _dismissRecommendation(String recommendationId) async {
  final babyProvider = Provider.of<BabyProvider>(context, listen: false);
  
  setState(() {
    _dismissedRecommendationIds.add(recommendationId);
  });
  
  // Log activity for streak
  await babyProvider.logActivity('recommendations');
}
```

## Implementation Checklist

- [x] Database migration created (`0014_add_user_activity_log.sql`)
- [x] Supabase service methods added (`logUserActivity`, `getUserStreak`)
- [x] BabyProvider methods added (`logActivity`, `getUserStreak`)
- [x] Home screen updated with colored streak display
- [ ] Wire up Focus screen activity logging
- [ ] Wire up Sleep schedule activity logging
- [ ] Wire up Milestones activity logging
- [ ] Wire up Progress/Moments activity logging
- [ ] Wire up Progress/Vocabulary activity logging
- [ ] Wire up Activities activity logging
- [ ] Wire up Recommendations activity logging

## Testing

### Test Streak Calculation
1. **Day 0**: Open app → Streak shows "Start today!" in gray
2. **Day 1**: Complete any activity → Streak shows "1 day" in yellow
3. **Day 2**: Complete any activity → Streak shows "2 days" in yellow
4. **Day 3**: Complete any activity → Streak shows "3 days" in green
5. **Day 7**: Complete any activity → Streak shows "7 days" in blue
6. **Day 14**: Complete any activity → Streak shows "14 days" in purple
7. **Day 30**: Complete any activity → Streak shows "30 days" in pink

### Test Streak Breaking
1. Build a 5-day streak
2. Skip a day (don't complete any activities)
3. Next day → Streak resets to "1 day"

## Current Implementation Status

✅ **Completed:**
- Database schema
- Supabase service layer
- BabyProvider integration
- Home screen colored streak display
- Automatic streak loading on page load

⏳ **Pending:**
- Activity logging calls need to be added to each screen
- Testing across all activity types

## Notes

- Activity logging is **silent** - it won't disrupt the user experience if it fails
- Multiple activities on the same day count as one day for the streak
- Streak is calculated by checking consecutive days with at least one activity
- The system checks up to 365 days of history for streak calculation

---

**Last Updated:** 2025-10-10
**Version:** 1.0
**Status:** Ready for Integration
