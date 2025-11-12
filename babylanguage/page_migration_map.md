# Baby Language App - Page Migration Map

## Main Application Screens
| Original Screen | Status | New Name/Purpose | Changes Needed |
|-----------------|--------|------------------|----------------|
| `splash_screen.dart` | ✅ KEEP | Same | Update branding/logo |
| `login_screen.dart` | ✅ KEEP | Same | Update copy to mention language |
| `app_container.dart` | 🔄 MODIFY | Same | Remove sleep/feeding navigation |
| `main_screen.dart` | 🔄 MODIFY | Same | Bottom nav → 2 tabs (Dashboard/Advice, Milestones); Settings via profile |
| `home_screen.dart` | 🆕 REPLACE | `home_screen.dart` | Redesign for language activities + weekly advice |
| `milestones_screen.dart` | 🔄 MODIFY | `milestones_screen.dart` | Adapt for language milestones |
| `progress_screen.dart` | 🆕 REPLACE | `progress_dashboard_screen.dart` | Open from Home (not a bottom tab) |
| `settings_screen.dart` | 🔄 MODIFY | Same | Remove from bottom nav; open via Home profile/avatar |
| `diary_screen.dart` | ❌ DELETE | N/A | Not needed |
| `concerns_screen.dart` | ❌ DELETE | N/A | Not needed |
| `focus_screen.dart` | ❌ DELETE | N/A | Not needed |
| `ask_ai_screen.dart` | ❌ DELETE | N/A | Not MVP |

## New Screens to Create
- `milestone_detail_screen.dart` – Drill-down milestone view with activities
- `activity_detail_screen.dart` – Full activity instructions and logging
- `progress_dashboard_screen.dart` – Charts and insights (from Home)

## Onboarding Screens (6)
- Welcome (modified)
- Child Details (modified)
- Language Readiness (new)
- Goals (modified for language)
- How It Works (new)
- Payment/Trial (modified)

## Widgets
- `bottom_nav_bar.dart` → 2 tabs (Dashboard/Advice, Milestones)
- `activity_card.dart`, `milestone_card.dart`, `streak_indicator.dart`, `progress_chart.dart`

## Database Migration Summary (Firestore)
- Collections to CREATE: `language_milestones`, `activity_logs`, `milestone_completions`, `daily_activity_suggestions`, `weekly_progress_summaries`, `user_streaks`
- Update `babies` doc fields: add `current_language_level`

## Final Screen Count
- From ~52 → ~15 screens (≈71% reduction)
