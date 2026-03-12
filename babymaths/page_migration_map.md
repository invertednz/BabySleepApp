# Baby Maths App - Page Migration Map

This document maps every screen from BabySleepApp to its fate in Baby Maths App.

## Legend

- **✅ KEEP** - Use as-is or with minor modifications
- **🔄 MODIFY** - Significant changes needed
- **🆕 REPLACE** - Delete and create new version
- **❌ DELETE** - Remove entirely

---

## Main Application Screens

| Original Screen                       | Status     | New Name/Purpose                 | Changes Needed                                                                             |
| ------------------------------------- | ---------- | -------------------------------- | ------------------------------------------------------------------------------------------ |
| `splash_screen.dart`                  | ✅ KEEP    | Same                             | Update branding/logo                                                                       |
| `login_screen.dart`                   | ✅ KEEP    | Same                             | Update copy to mention maths                                                               |
| `app_container.dart`                  | 🔄 MODIFY  | Same                             | Remove sleep/feeding navigation                                                            |
| `main_screen.dart`                    | 🔄 MODIFY  | Same                             | Update bottom nav to 2 tabs only (Dashboard/Advice, Milestones); Settings via profile menu |
| `home_screen.dart`                    | 🆕 REPLACE | `home_screen.dart`               | Complete redesign for maths activities and weekly advice                                   |
| `milestones_screen.dart`              | 🔄 MODIFY  | `milestones_screen.dart`         | Adapt for maths milestones                                                                 |
| `progress_screen.dart`                | 🆕 REPLACE | `progress_dashboard_screen.dart` | New progress view opened from Home (not a bottom tab)                                      |
| `settings_screen.dart`                | 🔄 MODIFY  | Same                             | Remove from bottom nav; open from Home profile/avatar menu                                 |
| `diary_screen.dart`                   | ❌ DELETE  | N/A                              | Not needed for maths app                                                                   |
| `concerns_screen.dart`                | ❌ DELETE  | N/A                              | Not needed for maths app                                                                   |
| `focus_screen.dart`                   | ❌ DELETE  | N/A                              | Not needed for maths app                                                                   |
| `ask_ai_screen.dart`                  | ❌ DELETE  | N/A                              | Could repurpose but not MVP                                                                |
| `ask_screen.dart`                     | ❌ DELETE  | N/A                              | Not needed                                                                                 |
| `recommendations_screen.dart`         | ❌ DELETE  | N/A                              | Replaced by activity cards                                                                 |
| `recommendation_category_screen.dart` | ❌ DELETE  | N/A                              | Not needed                                                                                 |
| `recommendation_detail_screen.dart`   | ❌ DELETE  | N/A                              | Not needed                                                                                 |
| `home_mockups_screen.dart`            | ❌ DELETE  | N/A                              | Development only                                                                           |
| `sleep_schedule_screen.dart`          | ❌ DELETE  | N/A                              | Not needed for maths app                                                                   |
| `premium_required_screen.dart`        | ✅ KEEP    | Same                             | Update copy for maths features                                                             |

---

## New Screens to Create

| Screen Name                      | Purpose                                                             |
| -------------------------------- | ------------------------------------------------------------------- |
| `milestone_detail_screen.dart`   | Drill-down view of a single milestone with all activities           |
| `activity_detail_screen.dart`    | Full detail view of a single activity with instructions             |
| `progress_dashboard_screen.dart` | Charts and insights about child's maths progress (opened from Home) |

---

## Onboarding Screens

### Screens to KEEP/MODIFY

| Original Screen                               | Status    | New Purpose   | Changes                                   |
| --------------------------------------------- | --------- | ------------- | ----------------------------------------- |
| `onboarding_welcome_screen.dart`              | 🔄 MODIFY | Welcome       | Update copy for maths focus               |
| `onboarding_baby_screen.dart`                 | 🔄 MODIFY | Child details | Remove measurements, keep name/DOB/gender |
| `onboarding_gender_screen.dart`               | ✅ KEEP   | Gender        | Minor copy updates                        |
| `onboarding_goals_screen.dart`                | 🔄 MODIFY | Parent goals  | Replace with maths-focused goals          |
| `onboarding_payment_screen.dart`              | 🔄 MODIFY | Payment       | Update pricing and feature list           |
| `onboarding_payment_screen_new.dart`          | 🔄 MODIFY | Payment       | Use this version, update content          |
| `onboarding_trial_offer_screen.dart`          | 🔄 MODIFY | Trial offer   | Update copy                               |
| `onboarding_special_discount_screen.dart`     | ✅ KEEP   | Discount      | Update copy if used                       |
| `onboarding_special_discount_screen_new.dart` | ✅ KEEP   | Discount      | Update copy if used                       |
| `onboarding_annual_plan_screen.dart`          | ✅ KEEP   | Annual plan   | Update copy                               |
| `onboarding_thank_you_screen.dart`            | ✅ KEEP   | Thank you     | Update copy                               |
| `onboarding_notifications_screen.dart`        | ✅ KEEP   | Notifications | Minor updates                             |
| `onboarding_app_tour_screen.dart`             | 🔄 MODIFY | App tour      | Show maths features                       |

### Screens to CREATE

| New Screen                               | Purpose                                            |
| ---------------------------------------- | -------------------------------------------------- |
| `onboarding_maths_readiness_screen.dart` | Quick assessment of child's current maths exposure |
| `onboarding_how_it_works_screen.dart`    | Explain the app's core features                    |

### Screens to DELETE

| Screen to Delete                                | Reason                            |
| ----------------------------------------------- | --------------------------------- |
| `onboarding_sleep_screen.dart`                  | Sleep tracking not in maths app   |
| `onboarding_feeding_screen.dart`                | Feeding tracking not in maths app |
| `onboarding_diaper_screen.dart`                 | Diaper tracking not in maths app  |
| `onboarding_measurements_screen.dart`           | Physical measurements not needed  |
| `onboarding_measurements_screen_fixed.dart`     | Not needed                        |
| `onboarding_concerns_screen.dart`               | Concerns not in maths app         |
| `onboarding_activities_loves_hates_screen.dart` | Not needed for maths app          |
| `onboarding_baby_progress_screen.dart`          | Not needed in this format         |
| `onboarding_growth_chart_screen.dart`           | Not needed                        |
| `onboarding_progress_preview_screen.dart`       | Will use different approach       |
| `onboarding_nurture_global_screen.dart`         | Not relevant                      |
| `onboarding_nurture_priorities_screen.dart`     | Not relevant                      |
| `onboarding_before_after_screen.dart`           | Not needed                        |
| `onboarding_gift_received_screen.dart`          | Not needed                        |
| `onboarding_results_screen.dart`                | Not needed                        |
| `onboarding_short_term_focus_screen.dart`       | Not needed                        |
| `onboarding_trial_timeline_screen.dart`         | Not needed                        |
| `onboarding_parenting_style_screen.dart`        | Not relevant to maths             |
| `onboarding_milestones_screen.dart`             | Handled differently               |

---

## Simplified Onboarding Flow

**Old Flow:** 20+ screens
**New Flow:** 6 screens

1. ✅ Welcome Screen (modified)
2. ✅ Child Details Screen (modified - name, DOB, gender only)
3. 🆕 Maths Readiness Assessment (new)
4. ✅ Goals Screen (modified for maths goals)
5. 🆕 How It Works Screen (new)
6. ✅ Payment/Trial Screen (modified)

---

## Widgets to Modify/Create

### Widgets to KEEP with Modifications

| Widget                    | Changes Needed                                                             |
| ------------------------- | -------------------------------------------------------------------------- |
| `app_header.dart`         | Update for maths context                                                   |
| `bottom_nav_bar.dart`     | Reduce to 2 tabs: Dashboard/Advice, Milestones (Settings via profile menu) |
| `onboarding_app_bar.dart` | Minor updates                                                              |

### Widgets to MODIFY Significantly

| Widget                     | New Purpose                    |
| -------------------------- | ------------------------------ |
| `home_card.dart`           | Adapt for maths activity cards |
| `recommendation_card.dart` | Might repurpose or delete      |

### Widgets to DELETE

| Widget                       | Reason         |
| ---------------------------- | -------------- |
| `recommended_time_item.dart` | Sleep-specific |

### Widgets to CREATE

| New Widget                         | Purpose                         |
| ---------------------------------- | ------------------------------- |
| `activity_card.dart`               | Display daily maths activity    |
| `milestone_card.dart`              | Display maths milestone in list |
| `progress_chart.dart`              | Charts for progress dashboard   |
| `metric_card.dart`                 | Display key metrics             |
| `streak_indicator.dart`            | Show current streak             |
| `category_filter_tabs.dart`        | Filter milestones by category   |
| `activity_completion_dialog.dart`  | Quick log after activity        |
| `milestone_completion_dialog.dart` | Mark milestone complete         |

---

## Models to Modify/Create

### Models to MODIFY

| Model       | Changes                                                      |
| ----------- | ------------------------------------------------------------ |
| `baby.dart` | Remove: weight, height, measurements. Add: currentMathsLevel |

### Models to KEEP

| Model               | Notes                       |
| ------------------- | --------------------------- |
| `chat_message.dart` | Keep if repurposing AI chat |
| `referral.dart`     | Keep for referral program   |

### Models to DELETE

| Model                 | Reason                              |
| --------------------- | ----------------------------------- |
| `concern.dart`        | Not needed                          |
| `diary_entry.dart`    | Not needed                          |
| `recommendation.dart` | Not needed (replaced by activities) |

### Models to CREATE

| New Model                        | Purpose                           |
| -------------------------------- | --------------------------------- |
| `maths_milestone.dart`           | Core milestone data structure     |
| `maths_activity.dart`            | Activity instructions and details |
| `activity_log.dart`              | Track completed activities        |
| `milestone_completion.dart`      | Track completed milestones        |
| `daily_activity_suggestion.dart` | AI-generated daily activities     |
| `progress_summary.dart`          | Weekly progress data              |

---

## Services to Modify/Create

### Services to KEEP/MODIFY

| Service                 | Changes               |
| ----------------------- | --------------------- |
| `supabase_service.dart` | Update for new tables |
| `auth_service.dart`     | Keep as-is            |

### Services to DELETE

| Service                       | Reason                                    |
| ----------------------------- | ----------------------------------------- |
| `recommendation_service.dart` | Not needed (replaced by activity service) |

### Services to CREATE

| New Service                         | Purpose                               |
| ----------------------------------- | ------------------------------------- |
| `maths_milestone_service.dart`      | Fetch and manage milestones           |
| `activity_service.dart`             | Log activities, generate suggestions  |
| `milestone_completion_service.dart` | Track milestone completions           |
| `progress_service.dart`             | Calculate stats and generate insights |

---

## Providers to Modify/Create

### Providers to MODIFY

| Provider             | Changes                                         |
| -------------------- | ----------------------------------------------- |
| `baby_provider.dart` | Remove sleep/feeding methods, add maths methods |
| `auth_provider.dart` | Keep as-is                                      |

### Providers to CREATE

| New Provider              | Purpose                     |
| ------------------------- | --------------------------- |
| `milestone_provider.dart` | Manage milestone state      |
| `activity_provider.dart`  | Manage activity state       |
| `progress_provider.dart`  | Manage progress/stats state |

---

## Bottom Navigation Structure

### Old Navigation (5 tabs)

1. Home
2. Recommendations
3. Progress
4. Milestones
5. More (Settings)

### New Navigation (2 tabs)

1. **Dashboard/Advice** - Daily activities, weekly advice, streak, quick stats
2. **Milestones** - Browse and track milestones

- **Settings:** Accessible from Home via profile/avatar or overflow menu
- **Progress Dashboard:** Accessible from Home (e.g., "View All Progress"), not a bottom tab

---

## Database Migration Summary

### Tables to DROP (from original schema)

- `concerns`
- `measurements`
- `sleep_schedules`
- `feeding_preferences`
- `diaper_preferences`

### Tables to MODIFY

- `babies` - Remove physical measurements, add maths_level

### Tables to CREATE

- `maths_milestones`
- `activity_logs`
- `milestone_completions`
- `daily_activity_suggestions`
- `weekly_progress_summaries`
- `user_streaks`

---

## Assets & Branding Updates

### Assets to UPDATE

- App icon (add mathematical symbols/themes)
- Splash screen background
- Onboarding illustrations (replace with maths-themed)
- Color palette (keep playful, update for maths theme)
- Font choices (consider more educational feel)

### Assets to CREATE

- Category icons (number sense, counting, patterns, shapes, sorting, measurement, operations)
- Milestone completion celebration graphics
- Streak fire icon
- Empty state illustrations
- Error state illustrations

---

## Priority Order for Migration

### Phase 1: Core Infrastructure

1. Create database schema
2. Update `baby.dart` model
3. Create new models (milestone, activity, logs)
4. Create new services
5. Update providers

### Phase 2: Essential Screens

1. Modify `home_screen.dart` (new design)
2. Modify `milestones_screen.dart`
3. Create `milestone_detail_screen.dart`
4. Create `activity_detail_screen.dart`

### Phase 3: Onboarding

1. Simplify onboarding flow
2. Update existing onboarding screens
3. Create new onboarding screens
4. Delete unused onboarding screens

### Phase 4: Progress & Analytics

1. Create `progress_dashboard_screen.dart`
2. Create chart widgets
3. Implement weekly summaries

### Phase 5: Cleanup

1. Delete all unused screens
2. Delete all unused widgets
3. Delete all unused models
4. Update navigation
5. Update branding

---

## Testing Strategy by Screen

| Screen Type     | Testing Approach                                                                |
| --------------- | ------------------------------------------------------------------------------- |
| Home Screen     | Test with different age babies, test activity loading, test streak logic        |
| Milestones      | Test filtering, test completion tracking, test with all/no completed milestones |
| Activity Detail | Test logging, test all edge cases (no time, no engagement rating, etc.)         |
| Onboarding      | Test complete flow, test skip steps, test error cases                           |
| Progress        | Test with various time ranges, test with no data, test chart rendering          |
| Settings        | Test subscription management, test profile updates                              |

---

## Key Simplifications

### What We're Removing

- ❌ Sleep tracking (entire feature set)
- ❌ Feeding tracking (entire feature set)
- ❌ Diaper tracking (entire feature set)
- ❌ Physical measurements tracking
- ❌ Concerns/focus areas
- ❌ Diary entries
- ❌ Recommendations system (replaced by activities)
- ❌ Most complex onboarding screens

### What We're Keeping

- ✅ Baby profile (simplified)
- ✅ User authentication
- ✅ Subscription/payment system
- ✅ Analytics (Mixpanel)
- ✅ Push notifications
- ✅ Settings management

### What We're Adding

- ➕ Maths milestone system
- ➕ Activity logging system
- ➕ Streak tracking
- ➕ Daily activity suggestions
- ➕ Progress dashboard with charts
- ➕ Category-based organization
- ➕ Drill-down detail views

---

## Final Screen Count

**BabySleepApp:** ~52 screens
**Baby Maths App:** ~15 screens

**Reduction:** ~71% fewer screens for better focus and maintainability
