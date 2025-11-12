# Baby Maths App - Complete Implementation Plan

## Executive Summary

Transform BabySleepApp into a dedicated early mathematics learning platform at `/babymaths`. Guide parents through age-appropriate maths activities for children 0-5 years, tracking progress through developmental milestones. This initiative will run on a **new Supabase project/database** isolated from the existing BabySleepApp backend.

---

## 1. Application Structure

### 1.1 Simplified Screen Architecture (2 Core Screens)

**Keep (top-level tabs):**
- **Dashboard/Advice** - Daily activities, weekly advice, streak tracking, quick stats
- **Milestones** - Age-based math milestone tracking with drill-down

**Access (not a top-level tab):**
- **Settings** - Profile, preferences, subscription (open via profile/avatar menu from Home)

**Remove:**
- Sleep, Feeding, Diaper tracking screens
- Diary, Concerns, Focus screens
- Ask AI screen (or repurpose for maths Q&A)

### 1.2 New Screens to Create

1. `milestone_detail_screen.dart` - Drill-down for specific milestone with 5-10 activities
2. `activity_detail_screen.dart` - Detailed activity instructions, materials, tips
3. `progress_dashboard_screen.dart` - Visual progress charts and insights (accessed from Home; not a top-level tab)

### 1.3 Directory Structure
```
/babymaths/
  /lib/
    /screens/
      home_screen.dart (MODIFIED)
      milestones_screen.dart (MODIFIED)
      milestone_detail_screen.dart (NEW)
      activity_detail_screen.dart (NEW)
      progress_dashboard_screen.dart (NEW)
      settings_screen.dart (MODIFIED)
      /onboarding/ (SIMPLIFIED - 6 screens instead of 30+)
    /models/
      baby.dart (MODIFIED - remove sleep/feeding)
      maths_milestone.dart (NEW)
      maths_activity.dart (NEW)
      activity_log.dart (NEW)
    /services/
      maths_milestone_service.dart (NEW)
      activity_service.dart (NEW)
      progress_service.dart (NEW)
    /widgets/
      activity_card.dart (NEW)
      milestone_card.dart (MODIFIED)
      progress_chart.dart (NEW)
```

### 1.4 Navigation

- **Bottom Nav Tabs (2):** `Dashboard/Advice`, `Milestones`
- **Settings Access:** From `home_screen.dart` via avatar/profile or overflow menu (not a bottom tab)
- **Progress Dashboard:** Opened from Home quick stats (e.g., "View All Progress" button); not a bottom tab

---

## 2. Data Model (Firestore)

### 2.1 Firestore Collections

Create a new Firebase project (Firestore) for Baby Maths. Use top-level collections with per-user security rules.

**babies** (modified - remove sleep/feeding fields, add maths level)
**maths_milestones** (categories, activities, age ranges, indicators)
**activity_logs** (track completed activities with engagement)
**milestone_completions** (track achieved milestones)
**daily_activity_suggestions** (AI-generated daily activities)
**weekly_progress_summaries** (AI summaries of progress)
**user_streaks**

### 2.2 Initial Setup

1. `firestore.rules` - Security rules (per-user access, public read for milestones)
2. `firestore.indexes.json` - Composite indexes for common queries
3. Seed data for `maths_milestones` (JSON import or script)

---

## 3. Mathematics Milestone Framework

### 3.1 Seven Core Categories (Ages 0-60 months)

1. **Number Sense** - Understanding quantity, more/less, subitizing
2. **Counting** - Rote counting, 1-to-1 correspondence, cardinality
3. **Patterns** - Recognizing, copying, creating AB/ABC patterns
4. **Shapes & Spatial** - 2D/3D shapes, positional words, composition
5. **Sorting & Classification** - By color, size, multiple attributes
6. **Measurement** - Comparison, ordering, non-standard units
7. **Early Operations** - Adding/subtracting with objects (36+ months)

### 3.2 Milestone Structure

Each milestone contains:
- Category & title
- Age range (min/max months)
- Full description
- 5-10 concrete activities with:
  - Materials needed (household items preferred)
  - Step-by-step instructions
  - Duration estimate
  - Variations
  - Success tips
- Indicators of mastery
- Next steps (progression)

### 3.3 Target Content

- **120 milestones** across 7 categories
- **600-1200 activities** total (5-10 per milestone)
- Age ranges: 0-12, 12-24, 24-36, 36-48, 48-60 months

---

## 4. User Experience Design

### 4.1 Simplified Onboarding (6 Screens)

1. **Welcome** - "Help Your Child Fall in Love with Numbers"
2. **Child Details** - Name, birthdate, gender, photo
3. **Maths Readiness** - Quick assessment (Can they count? Sort? Recognize numbers?)
4. **Goals** - Parent's learning objectives
5. **How It Works** - Daily activities, milestone tracking, progress insights
6. **Payment** - 7-day free trial, then $9.99/mo or $79/year

### 4.2 Home Screen Design

**Components:**
- Streak indicator (flame + days)
- Child's age display
- 3-5 daily activity cards with:
  - Title, category, duration
  - Materials needed
  - Brief description
  - "Start Activity" button
- Quick stats: activities this week, new milestones
- AI-generated weekly advice

**Activity Card Example:**
```
┌────────────────────────────────┐
│ 🔢 Counting Fingers & Toes    │
│ 5 mins | Counting | No items  │
│ Count together during diaper  │
│ changes or getting dressed    │
│ [Start Activity →]            │
└────────────────────────────────┘
```

### 4.3 Milestones Screen

**Features:**
- Filter tabs by category
- Age-based sections (current, upcoming, future)
- Visual indicators: ✅ Completed, 🔄 In Progress, ⭕ Not Started
- Tap milestone → Opens drill-down detail screen

**Milestone Detail Screen:**
- Full description & why it matters
- Age range & readiness signs
- 5-10 activities with full instructions
- Track completion button
- Notes field
- Progress photos (optional)

### 4.4 Activity Detail Screen (Drill-Down)

When tapping "Start Activity":
- Activity title & category
- Duration & materials list
- Step-by-step instructions
- Tips for success
- Variations for different levels
- "I Did This Activity" button → Quick log:
  - Duration slider
  - Engagement rating (1-5 stars)
  - Notes field
- Adds to streak & shows celebration

---

## 5. Implementation Phases

### Phase 1: Foundation (Week 1-2)
- Create `/babymaths` directory structure
- Copy and strip down existing app
- Remove sleep/feeding/diaper code
- Update branding for "Baby Maths"
- Create Supabase schema
- Set up migrations

### Phase 2: Models & Services (Week 2-3)
- Create all new models (MathsMilestone, MathsActivity, ActivityLog)
- Build services (MilestoneService, ActivityService, ProgressService)
- Unit tests

### Phase 3: Milestone Content (Week 3-4)
- Research and document 100+ milestones
- Write 5-10 activities per milestone
- Create seed SQL file
- Test milestone retrieval

### Phase 4: Home Screen (Week 4-5)
- Rebuild home screen
- Daily activity suggestion algorithm
- Streak tracking
- Weekly advice generation

### Phase 5: Milestones & Drill-Down (Week 5-6)
- Milestones list with filtering
- Milestone detail screen
- Activity detail screen
- Completion tracking
- Notes/observations

### Phase 6: Onboarding (Week 6-7)
- Design 6 onboarding screens
- Maths readiness assessment
- Profile creation
- Payment integration

### Phase 7: Progress & Analytics (Week 7-8)
- Activity logging
- Weekly summaries
- Progress visualizations
- AI-generated advice
- Export/share features

### Phase 8: Polish & Test (Week 8-9)
- UI/UX refinement
- Animations
- Testing
- Performance optimization
- Accessibility

### Phase 9: Launch Prep (Week 9-10)
- Content review
- Analytics setup (Mixpanel)
- Push notifications
- App store listings
- Beta testing

---

## 6. Key Features

### 6.1 Smart Daily Activities
Algorithm considers:
- Child's current age
- Completed vs pending milestones
- Recent activity history
- Time available (5/10/20 min options)
- Category variety

### 6.2 Drill-Down Learning
Each milestone provides:
- Clear explanation of concept
- Developmental significance
- 5-10 concrete activities
- Signs of mastery
- Progression pathway

### 6.3 Engagement Tracking
- Duration of activity
- Child's engagement (1-5 stars)
- Parent observations/notes
- Optional photos/videos
- Trends over time

### 6.4 AI-Powered Insights
Weekly summaries include:
- Progress highlights
- Milestone achievements
- Suggested focus areas
- Specific activity recommendations
- Encouragement

---

## 7. Technical Architecture

### 7.1 State Management
Provider pattern (consistent with existing app):
- BabyProvider (modified)
- MilestoneProvider (new)
- ActivityProvider (new)
- ProgressProvider (new)

### 7.2 Firebase Cloud Functions

1. **generateDailyActivities** (HTTPS)
   - Input: babyId, date
   - Output: 3-5 age-appropriate activities

2. **generateWeeklyAdvice** (HTTPS)
   - Input: babyId, weekStart
   - Output: AI progress summary using GPT-4

3. **calculateProgressMetrics** (HTTPS)
   - Input: babyId, timeRange
   - Output: Statistics and insights

### 7.3 Offline Support
- View cached milestones
- View today's activities
- Log completions (sync later)
- Offline indicator on UI

---

## 8. Migration Checklist

### Files to Create
- [ ] New database schema
- [ ] All new model files
- [ ] All new service files
- [ ] New screen files (activity_detail, milestone_detail, progress_dashboard)
- [ ] Database migrations
- [ ] Milestone seed data

### Files to Modify
- [ ] main.dart - App name, theme
- [ ] baby.dart - Remove sleep/feeding
- [ ] home_screen.dart - Complete redesign
- [ ] milestones_screen.dart - Adapt for maths
- [ ] settings_screen.dart - Remove from bottom nav; expose via Home profile/overflow
- [ ] Onboarding screens - Simplify

### Files to Delete
- [ ] sleep_schedule_screen.dart
- [ ] diary_screen.dart
- [ ] concerns_screen.dart
- [ ] progress_screen.dart (replaced by in-flow progress dashboard opened from Home)
- [ ] All feeding/diaper screens
- [ ] Related models and services

---

## 9. Monetization

**Free Trial:** 7 days full access
**Pricing:** $9.99/month or $79/year (34% savings)

**Free Tier:**
- Browse milestones
- 1 activity per day
- Basic progress tracking

**Premium:**
- Unlimited activities
- Full activity library
- Detailed analytics
- Weekly AI advice
- Export reports

---

## 10. Sample Milestone Examples

### Example 1: Early Counting (24-30 months)
**Title:** "Counts objects 1-5 with one-to-one correspondence"

**Activities:**
1. Counting Snack Time (5 min, crackers)
2. Counting Walk (10 min, outdoor)
3. Toy Lineup Count (5 min, toys)
4. Stair Climbing Count (5 min, stairs)
5. Bath Toy Count (10 min, bath toys)

### Example 2: Patterns (24-30 months)
**Title:** "Copies simple AB patterns"

**Activities:**
1. Clap-Stomp Pattern (5 min, none)
2. Color Block Pattern (10 min, blocks)
3. Snack Pattern Line (5 min, 2 snacks)
4. Sticker Pattern (10 min, stickers)
5. Movement Pattern Dance (10 min, none)

### Example 3: Shapes (18-24 months)
**Title:** "Recognizes circles and squares"

**Activities:**
1. Shape Hunt Around House (10 min)
2. Shape Sorter Play (10 min, toy)
3. Drawing Shapes (10 min, paper/crayon)
4. Shape Snacks (5 min, cut foods)
5. Shape Books (10 min, books)

---

## 11. Success Metrics

**Engagement:**
- Daily active users
- Activities per week per user
- 7-day and 30-day streak retention

**Learning:**
- Milestones achieved per month
- Parent-reported confidence

**Business:**
- Free trial → paid conversion (target 15%)
- Monthly churn (target <5%)
- NPS score

---

## 12. Risk Mitigation

**Content Quality Risk:**
- Consult early childhood education experts
- Reference NCTM standards
- Beta test with parents

**Adoption Risk:**
- Push notifications for daily activities
- Streak system for habits
- Show clear progress
- Make activities very simple

**Technical Risk:**
- Launch with MVP: 60 milestones minimum
- Focus on 0-36 months first
- Add age ranges in updates

---

## Appendix: Category Progression Examples

### Number Sense (0-60 months)
- 12-18mo: Recognizes "more" vs "less"
- 18-24mo: Understands "one" and "many"
- 24-30mo: Subitizing 1-3 objects
- 30-36mo: Compares quantities without counting
- 36-42mo: Understands zero
- 42-48mo: Recognizes bigger numbers
- 48-60mo: Mental quantity manipulation

### Counting (12-60 months)
- 18-24mo: Rote counts 1-5
- 24-30mo: One-to-one correspondence 1-5
- 30-36mo: Counts objects 1-10
- 36-42mo: Understands cardinality
- 42-48mo: Counts to 20+
- 48-54mo: Skip counts by 2s, 5s
- 54-60mo: Counts to 100

### Shapes (6-60 months)
- 6-12mo: Explores 3D shapes
- 18-24mo: Recognizes circles/squares
- 24-30mo: Names basic shapes
- 30-36mo: Positional words (in/on/under)
- 36-42mo: Triangles, rectangles, ovals
- 42-48mo: 2D vs 3D understanding
- 48-60mo: Shape composition
