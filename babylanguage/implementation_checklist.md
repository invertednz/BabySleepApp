# Baby Language Implementation Checklist

## Phase 1: Foundation Setup
- [ ] Create `/babylanguage` folder
- [ ] Copy base Flutter app to `/babylanguage/babylanguage_app`
- [ ] Update branding (name, icon, colors)

### Navigation Updates (2 tabs)
- [ ] Bottom nav → `Dashboard/Advice`, `Milestones`
- [ ] Remove Settings from bottom nav; access via Home (profile/overflow)
- [ ] Remove Progress tab; open `progress_dashboard_screen.dart` from Home

### Firebase Setup
- [ ] Create Firebase project (`baby-language`)
- [ ] Add iOS/Android apps; add Google Services files
- [ ] Run FlutterFire configure → `lib/firebase_options.dart`
- [ ] Add Firebase packages; `flutter pub get`
- [ ] Initialize Firebase in `lib/main.dart`
- [ ] Deploy `firestore.rules` and `firestore.indexes.json`

## Phase 2: Models & Services
### Models (create)
- [ ] `language_milestone.dart` (id, category, title, description, ageMonthsMin/Max, activities[], indicators[], nextSteps[])
- [ ] `language_activity.dart` (title, durationMinutes, materials[], instructions[], variations[], tips[])
- [ ] `activity_log.dart` (id, babyId, userId, milestoneId?, title, category, completedAt, durationMinutes?, engagementLevel?, notes?)

### Services (create)
- [ ] `language_milestone_service.dart` (query by age/category/id)
- [ ] `activity_service.dart` (log activities, fetch logs)
- [ ] `progress_service.dart` (calculate metrics, streaks, weekly summaries)

## Phase 3: Content
- [ ] Write 100+ milestones across 7 categories
- [ ] 5–10 activities per milestone
- [ ] Import seed data (`sample_language_milestones_seed.json`)

## Phase 4: Home Screen
- [ ] New layout with streak, age, 3–5 activity cards
- [ ] Activity suggestion logic (Cloud Function `generateDailyActivities`)
- [ ] Weekly advice card (Cloud Function `generateWeeklyAdvice`)

## Phase 5: Milestones & Drill-Down
- [ ] Update `milestones_screen.dart` with filters (categories)
- [ ] `milestone_detail_screen.dart` with full content
- [ ] `activity_detail_screen.dart` with logging popup
- [ ] Completion tracking (confidence, notes)

## Phase 6: Onboarding
- [ ] 6 screens; language-focused copy and assets
- [ ] Payment integration (RevenueCat)

## Phase 7: Progress & Analytics
- [ ] `progress_dashboard_screen.dart` + charts
- [ ] Weekly summaries (functions + Firestore)
- [ ] Export/share report (optional PDF in functions)

## Phase 8: Polish & Testing
- [ ] UI/UX polish, animations
- [ ] Performance pass
- [ ] Accessibility pass
- [ ] Unit tests for services; mock Firestore

## Phase 9: Launch Prep
- [ ] Analytics events (onboarding_completed, activity_logged, milestone_completed, streak_milestone, subscription_started/cancelled)
- [ ] Push notifications (FCM)
- [ ] Store listings & screenshots
- [ ] Beta test & feedback iteration
