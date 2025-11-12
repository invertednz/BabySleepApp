# Baby Language App - Project Documentation

Comprehensive plan to transform BabySleepApp into Baby Language – an early language development platform for ages 0–5.

## 📁 Documentation Structure

### Core Planning Documents
1. **[languageplan.md](../languageplan.md)** – Master implementation plan
2. **[implementation_checklist.md](./implementation_checklist.md)** – Phase-by-phase tasks
3. **[page_migration_map.md](./page_migration_map.md)** – Screen migration and nav

### Technical Specifications
4. **[api_specifications.md](./api_specifications.md)** – Firebase Cloud Functions APIs
5. **[FIREBASE_SETUP.md](./FIREBASE_SETUP.md)** – Setup guide (FlutterFire, configs, rules, indexes)
6. **firestore.rules** and **firestore.indexes.json** – Security and indexes
7. **[sample_language_milestones_seed.json](./sample_language_milestones_seed.json)** – Example milestone content (10 samples)

---

## 📊 Project Overview

### The Transformation
- **From:** BabySleepApp (sleep/feeding/diaper tracking)
- **To:** Baby Language (language milestones, daily activities, insights)

### Core Concept
- Daily activity suggestions (3–5)
- Milestone tracking (120 milestones, 7 categories)
- Progress insights + AI weekly advice
- Gamification via streaks

### Key Targets
- 120 milestones • 600–1200 activities • Ages 0–60 months
- Simplified navigation: 5 tabs → 2 tabs

---

## 🏗️ Technical Architecture

### Technology Stack
- **Frontend:** Flutter
- **Backend:** Firebase (Firestore + Cloud Functions)
- **Auth:** Firebase Authentication
- **Storage:** Firebase Storage
- **Analytics:** Firebase Analytics (and/or Mixpanel)
- **Notifications:** Firebase Cloud Messaging
- **Payments:** RevenueCat
- **AI:** OpenAI via Cloud Functions

### Database Architecture (Firestore)
- Collections: `babies`, `language_milestones`, `activity_logs`, `milestone_completions`, `daily_activity_suggestions`, `weekly_progress_summaries`, `user_streaks`

---

## 🎨 UX Highlights

### Onboarding (6 screens)
1. Welcome
2. Child Details
3. Language Readiness
4. Parent Goals
5. How It Works
6. Payment/Trial

### Main Navigation (2 tabs)
1. **Dashboard/Advice** – Daily activities, weekly advice, streak, quick stats
2. **Milestones** – Browse by category/age with drill-down
- **Settings:** From Home (profile/overflow)
- **Progress Dashboard:** From Home (not a bottom tab)

---

## 🚀 Implementation Timeline (10 weeks)
- Phase 1: Foundation & Firebase setup
- Phase 2: Models & Services
- Phase 3: Content (milestones + activities)
- Phase 4: Home screen
- Phase 5: Milestones & Drill-down
- Phase 6: Onboarding
- Phase 7: Progress & Analytics
- Phase 8: Polish & Test
- Phase 9: Launch Prep

---

## 🎯 MVP Features
- Auth, baby profile, milestones browser
- Activity logging + streaks
- Daily suggestions + weekly advice
- Basic progress dashboard
- Offline content viewing

---

## 🔒 Privacy & Security
- Per-user Firestore rules; public read for `language_milestones`
- Encrypted at rest/in transit
- GDPR/CCPA compliant; account deletion

---

## 📞 Support
- Technical: support@babylanguage.app
- Content: content@babylanguage.app
- Partnerships: partnerships@babylanguage.app
