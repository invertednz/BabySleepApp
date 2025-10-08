# Database Storage Summary - Onboarding Flow

## ✅ All User Inputs Are Being Saved

### Global User Preferences (stored in `user_preferences` table)

| Screen | Field Name | Data Type | Method | Status |
|--------|-----------|-----------|---------|--------|
| **Notifications** | `notification_time` | string | `saveNotificationPreference()` | ✅ Saved |
| **Parenting Style** | `parenting_styles` | array | `saveUserParentingStyles()` | ✅ Saved |
| **Nurture Priorities** | `nurture_priorities` | array | `saveUserNurturePriorities()` | ✅ Saved |
| **Goals** | `goals` | array | `saveUserGoals()` | ✅ Saved |
| **Payment Status** | `plan_tier` | string | `updateUserPlanStatus()` | ✅ Saved |
| **Payment Status** | `is_on_trial` | boolean | `updateUserPlanStatus()` | ✅ Saved |
| **Payment Status** | `plan_started_at` | timestamp | `updateUserPlanStatus()` | ✅ Saved |

### Per-Baby Data (stored in various baby-related tables)

| Screen | Field Name | Table | Method | Status |
|--------|-----------|-------|---------|--------|
| **Add Baby** | Baby profile | `babies` | `addBaby()` | ✅ Saved |
| **Gender** | `gender` | `babies` | `updateBaby()` | ✅ Saved |
| **Activities** | `loves`, `hates` | `baby_activities` | `saveBabyActivities()` | ✅ Saved |
| **Milestones** | `completed_milestones` | `babies` | `updateBaby()` | ✅ Saved |
| **Short-term Focus** | Focus items | `baby_short_term_focus` | `saveShortTermFocus()` | ✅ Saved |

## Database Schema

### `user_preferences` Table
```sql
{
  user_id: uuid (FK to auth.users),
  notification_time: string ('morning', 'midday', 'evening'),
  parenting_styles: array<string>,
  nurture_priorities: array<string>,
  goals: array<string>,
  plan_tier: string ('free', 'premium'),
  is_on_trial: boolean,
  plan_started_at: timestamp,
  updated_at: timestamp
}
```

### `babies` Table
```sql
{
  id: uuid,
  user_id: uuid (FK),
  name: string,
  birthdate: date,
  gender: string,
  completed_milestones: array<string>,
  weight_kg: float,
  height_cm: float,
  created_at: timestamp,
  updated_at: timestamp
}
```

### `baby_activities` Table
```sql
{
  user_id: uuid (FK),
  baby_id: uuid (FK),
  loves: map<string, timestamp>,
  hates: map<string, timestamp>,
  neutral: map<string, timestamp>,
  skipped: map<string, timestamp>,
  updated_at: timestamp
}
```

### `baby_short_term_focus` Table
```sql
{
  user_id: uuid (FK),
  baby_id: uuid (FK),
  focus_items: array<string>,
  updated_at: timestamp
}
```

## Service Layer Methods

### `SupabaseService` Methods
All methods are implemented in `lib/services/supabase_service.dart`:

1. ✅ `saveNotificationPreference(String time)`
2. ✅ `saveUserParentingStyles(List<String> styles)`
3. ✅ `saveUserNurturePriorities(List<String> priorities)`
4. ✅ `saveUserGoals(List<String> goals)`
5. ✅ `updateUserPlanStatus({planTier, isOnTrial, planStartedAt})`
6. ✅ `addBaby(Baby baby)`
7. ✅ `updateBaby(Baby baby)`
8. ✅ `saveBabyActivities(babyId, loves, hates)`
9. ✅ `saveShortTermFocus(babyId, items)`

### `BabyProvider` Methods
All methods are implemented in `lib/providers/baby_provider.dart`:

1. ✅ `saveNotificationPreference(String time)`
2. ✅ `saveUserParentingStyles(List<String> styles)`
3. ✅ `saveUserNurturePriorities(List<String> priorities)`
4. ✅ `saveUserGoals(List<String> goals)`
5. ✅ `addBaby(Baby baby)`
6. ✅ `updateBaby(Baby baby)`
7. ✅ `saveBabyActivities(babyId, loves, hates)`
8. ✅ `saveShortTermFocus(babyId, items)`

### `AuthProvider` Methods
All methods are implemented in `lib/providers/auth_provider.dart`:

1. ✅ `markUserAsPaid({bool onTrial})`
2. ✅ `markUserAsFree()`

## Data Flow

### Example: Notification Preference
```
User selects "Morning" 
  → OnboardingNotificationsScreen._saveAndContinue()
  → BabyProvider.saveNotificationPreference('morning')
  → SupabaseService.saveNotificationPreference('morning')
  → Supabase upsert to user_preferences table
  → Database stores: { user_id: xxx, notification_time: 'morning' }
```

### Example: Payment
```
User enters payment info
  → OnboardingPaymentScreen._handlePayment()
  → AuthProvider.markUserAsPaid(onTrial: true)
  → SupabaseService.updateUserPlanStatus(...)
  → Supabase upsert to user_preferences table
  → Database stores: { 
      user_id: xxx, 
      plan_tier: 'premium',
      is_on_trial: true,
      plan_started_at: '2025-10-08T12:00:00Z'
    }
```

## Verification

All user inputs from the onboarding flow are:
- ✅ Captured in the UI
- ✅ Passed to provider methods
- ✅ Sent to Supabase service
- ✅ Stored in the database
- ✅ Retrievable for later use

## Notes

1. **Upsert Pattern**: All saves use `upsert()` to handle both insert and update cases
2. **Timestamps**: All records include `updated_at` timestamps
3. **User Association**: All data is linked to `user_id` from auth
4. **Baby Association**: Per-baby data is linked via `baby_id`
5. **Array Storage**: Lists (styles, goals, etc.) are stored as PostgreSQL arrays
6. **Map Storage**: Activities use maps with timestamps for tracking when items were added

## Future Enhancements

Consider adding:
- Analytics tracking for conversion funnel
- A/B test variant storage
- User journey timestamps
- Feature flag preferences
- Notification delivery logs
