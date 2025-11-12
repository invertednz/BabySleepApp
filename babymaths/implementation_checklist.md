# Baby Maths Implementation Checklist

## Phase 1: Foundation Setup ✓ = Done, ⚡ = In Progress, ⭕ = Not Started

### Week 1-2: Project Structure

#### Directory Creation
- [ ] Create `/babymaths` root directory
- [ ] Copy `/babysteps_app` to `/babymaths/babymaths_app`
- [ ] Create `/babymaths/supabase` folder
- [ ] Create `/babymaths/supabase/migrations` folder
- [ ] Create `/babymaths/docs` folder

#### Cleanup - Files to DELETE
- [ ] Delete `sleep_schedule_screen.dart`
- [ ] Delete `diary_screen.dart`
- [ ] Delete `concerns_screen.dart`
- [ ] Delete `focus_screen.dart`
- [ ] Delete `onboarding_sleep_screen.dart`
- [ ] Delete `onboarding_feeding_screen.dart`
- [ ] Delete `onboarding_diaper_screen.dart`
- [ ] Delete `onboarding_concerns_screen.dart`
- [ ] Delete `onboarding_activities_loves_hates_screen.dart`
- [ ] Delete `onboarding_growth_chart_screen.dart`
- [ ] Delete `onboarding_progress_preview_screen.dart`
- [ ] Delete `onboarding_baby_progress_screen.dart`
- [ ] Delete `onboarding_nurture_global_screen.dart`
- [ ] Delete `onboarding_nurture_priorities_screen.dart`
- [ ] Delete `onboarding_before_after_screen.dart`
- [ ] Delete `onboarding_gift_received_screen.dart`
- [ ] Delete `ask_ai_screen.dart` (or keep and repurpose)
- [ ] Delete `ask_screen.dart`
- [ ] Delete `progress_screen.dart` (will be replaced)
- [ ] Delete `recommendation_category_screen.dart`
- [ ] Delete `recommendation_detail_screen.dart`
- [ ] Delete `recommendations_screen.dart`

#### Branding Updates
- [ ] Update app name in `pubspec.yaml` to "Baby Maths"
- [ ] Update app bundle ID (com.babymaths.app)
- [ ] Create new app icon (mathematics themed)
- [ ] Update splash screen branding
- [ ] Update color scheme in `app_theme.dart` (consider bright, playful colors)
- [ ] Update primary color, accent color
- [ ] Update font choices if desired

#### Navigation Updates (2 tabs only)
- [ ] Update bottom navigation to 2 tabs: `Dashboard/Advice`, `Milestones`
- [ ] Remove Settings from bottom nav; expose from Home via profile/avatar or overflow
- [ ] Remove Progress tab entirely
- [ ] Ensure `progress_dashboard_screen.dart` is accessible from Home quick stats (e.g., "View All Progress")

#### Firebase Setup
- [ ] Create new Firebase project (separate from BabySleepApp)
- [ ] Add iOS/Android apps; add `GoogleService-Info.plist` and `google-services.json`
- [ ] Run FlutterFire: `flutterfire configure --project=baby-maths`
- [ ] Add Firebase packages to `pubspec.yaml` and `flutter pub get`
- [ ] Initialize Firebase in `lib/main.dart`
- [ ] Add and deploy `firestore.rules` and `firestore.indexes.json`

---

## Phase 2: Core Models & Services

### Week 2-3: Data Layer

#### Models to CREATE (in `/lib/models/`)
- [ ] Create `maths_milestone.dart`
  - [ ] Fields: id, category, title, description, ageMonthsMin, ageMonthsMax, activities, indicators, nextSteps
  - [ ] fromJson/toJson methods
  - [ ] Validation logic

- [ ] Create `maths_activity.dart`
  - [ ] Fields: title, durationMinutes, materials, instructions, variations, tips
  - [ ] fromJson/toJson methods

- [ ] Create `activity_log.dart`
  - [ ] Fields: id, babyId, userId, milestoneId, activityTitle, category, completedAt, durationMinutes, engagementLevel, notes
  - [ ] fromJson/toJson methods

- [ ] Create `milestone_completion.dart`
  - [ ] Fields: id, babyId, milestoneId, completedAt, confidenceLevel, notes
  - [ ] fromJson/toJson methods

- [ ] Create `daily_activity_suggestion.dart`
  - [ ] Fields: id, babyId, activityDate, suggestedActivities
  - [ ] fromJson/toJson methods

- [ ] Create `progress_summary.dart`
  - [ ] Fields: activitiesCompleted, milestonesAchieved, topCategories, etc.
  - [ ] Calculation methods

#### Models to MODIFY
- [ ] Modify `baby.dart`
  - [ ] Remove: weight_kg, height_cm, head_circumference_cm, chest_circumference_cm
  - [ ] Remove: completed_milestones (moved to separate table)
  - [ ] Add: currentMathsLevel (String)
  - [ ] Update fromJson/toJson

#### Services to CREATE (in `/lib/services/`)
- [ ] Create `maths_milestone_service.dart`
  - [ ] `fetchMilestonesByAge(int ageMonths)` → List<MathsMilestone>
  - [ ] `fetchMilestonesByCategory(String category)` → List<MathsMilestone>
  - [ ] `fetchMilestoneById(String id)` → MathsMilestone
  - [ ] `fetchAllMilestones()` → List<MathsMilestone>
  - [ ] `searchMilestones(String query)` → List<MathsMilestone>

- [ ] Create `activity_service.dart`
  - [ ] `logActivity(ActivityLog log)` → bool
  - [ ] `fetchActivityLogs(String babyId, {DateTime? startDate, DateTime? endDate})` → List<ActivityLog>
  - [ ] `generateDailyActivities(String babyId)` → List<MathsActivity>
  - [ ] `getActivityStats(String babyId, String timeRange)` → Map<String, dynamic>

- [ ] Create `milestone_completion_service.dart`
  - [ ] `markMilestoneComplete(String babyId, String milestoneId, {int confidence, String notes})` → bool
  - [ ] `fetchCompletedMilestones(String babyId)` → List<MilestoneCompletion>
  - [ ] `isMilestoneCompleted(String babyId, String milestoneId)` → bool
  - [ ] `getCompletionPercentage(String babyId, String category)` → double

- [ ] Create `progress_service.dart`
  - [ ] `calculateWeeklyProgress(String babyId)` → ProgressSummary
  - [ ] `getStreakInfo(String babyId)` → Map<String, int>
  - [ ] `updateStreak(String babyId)` → void
  - [ ] `generateWeeklyAdvice(String babyId)` → String (calls AI)

#### Unit Tests
- [ ] Write tests for all models (toJson/fromJson)
- [ ] Write tests for all service methods
- [ ] Mock Supabase responses
- [ ] Achieve >80% code coverage on services

---

## Phase 3: Milestone Content Creation

### Week 3-4: Content Writing

#### Research Phase
- [ ] Review NCTM (National Council of Teachers of Mathematics) standards
- [ ] Review Common Core kindergarten mathematics standards
- [ ] Research developmental psychology sources on early math
- [ ] Consult with early childhood education experts (optional but recommended)

#### Milestone Writing (Target: 120 milestones)

**Number Sense (Target: 15 milestones)**
- [ ] Write milestones for 0-12 months (3 milestones)
- [ ] Write milestones for 12-24 months (3 milestones)
- [ ] Write milestones for 24-36 months (3 milestones)
- [ ] Write milestones for 36-48 months (3 milestones)
- [ ] Write milestones for 48-60 months (3 milestones)
- [ ] Write 5-10 activities per milestone

**Counting (Target: 20 milestones)**
- [ ] Write milestones for 12-24 months (4 milestones)
- [ ] Write milestones for 24-36 months (5 milestones)
- [ ] Write milestones for 36-48 months (5 milestones)
- [ ] Write milestones for 48-60 months (6 milestones)
- [ ] Write 5-10 activities per milestone

**Patterns (Target: 15 milestones)**
- [ ] Write milestones for 12-24 months (3 milestones)
- [ ] Write milestones for 24-36 months (4 milestones)
- [ ] Write milestones for 36-48 months (4 milestones)
- [ ] Write milestones for 48-60 months (4 milestones)
- [ ] Write 5-10 activities per milestone

**Shapes & Spatial (Target: 25 milestones)**
- [ ] Write milestones for 6-12 months (3 milestones)
- [ ] Write milestones for 12-24 months (5 milestones)
- [ ] Write milestones for 24-36 months (6 milestones)
- [ ] Write milestones for 36-48 months (6 milestones)
- [ ] Write milestones for 48-60 months (5 milestones)
- [ ] Write 5-10 activities per milestone

**Sorting & Classification (Target: 15 milestones)**
- [ ] Write milestones for 12-24 months (3 milestones)
- [ ] Write milestones for 24-36 months (4 milestones)
- [ ] Write milestones for 36-48 months (4 milestones)
- [ ] Write milestones for 48-60 months (4 milestones)
- [ ] Write 5-10 activities per milestone

**Measurement (Target: 15 milestones)**
- [ ] Write milestones for 12-24 months (3 milestones)
- [ ] Write milestones for 24-36 months (4 milestones)
- [ ] Write milestones for 36-48 months (4 milestones)
- [ ] Write milestones for 48-60 months (4 milestones)
- [ ] Write 5-10 activities per milestone

**Early Operations (Target: 15 milestones)**
- [ ] Write milestones for 36-42 months (3 milestones)
- [ ] Write milestones for 42-48 months (4 milestones)
- [ ] Write milestones for 48-54 months (4 milestones)
- [ ] Write milestones for 54-60 months (4 milestones)
- [ ] Write 5-10 activities per milestone

#### Database Population
- [ ] Convert all milestones to SQL INSERT statements
- [ ] Create `0001_seed_maths_milestones.sql`
- [ ] Run seed migration
- [ ] Verify all milestones in database
- [ ] Test queries by age range
- [ ] Test queries by category

---

## Phase 4: Home Screen Redesign

### Week 4-5: Dashboard Implementation

#### Home Screen Layout
- [ ] Create new `home_screen.dart` (simplified version)
- [ ] Remove all sleep/feeding/diaper widgets
- [ ] Add streak indicator widget at top
- [ ] Add child age display
- [ ] Create "Today's Maths Adventures" section header
- [ ] Build daily activity cards list (3-5 cards)
- [ ] Add "Quick Stats" section (activities this week, new milestones)
- [ ] Add "This Week's Advice" card

#### Widgets to CREATE
- [ ] Create `activity_card.dart`
  - [ ] Display: title, category, duration, materials
  - [ ] Brief description
  - [ ] "Start Activity" button
  - [ ] Beautiful, colorful design

- [ ] Create `streak_indicator.dart`
  - [ ] Flame icon
  - [ ] Current streak number
  - [ ] Encouraging message
  - [ ] Animation when streak increases

- [ ] Modify `home_card.dart` for math context
  - [ ] Update styling
  - [ ] Update content structure

#### Daily Activity Algorithm
- [ ] Implement activity suggestion logic in `activity_service.dart`
  - [ ] Factor in child's age
  - [ ] Factor in completed milestones
  - [ ] Factor in recent activities (variety)
  - [ ] Factor in time of day (optional)
  - [ ] Return 3-5 diverse activities

- [ ] Create Supabase Edge Function: `generate-daily-activities`
  - [ ] Input: baby_id, date
  - [ ] Query child's age and completed milestones
  - [ ] Select 3-5 appropriate activities
  - [ ] Ensure variety across categories
  - [ ] Store in daily_activity_suggestions table
  - [ ] Return activities

#### Streak Tracking
- [ ] Implement streak update logic
  - [ ] When activity logged, check last activity date
  - [ ] If yesterday, increment streak
  - [ ] If today, no change
  - [ ] If older, reset to 1
  - [ ] Update longest streak if applicable

- [ ] Display streak prominently on home screen
- [ ] Add streak celebration animation
- [ ] Add push notification for streak risk

#### Weekly Advice
- [ ] Create Supabase Edge Function: `generate-weekly-advice`
  - [ ] Input: baby_id
  - [ ] Query last week's activity logs
  - [ ] Query completed milestones
  - [ ] Calculate engagement stats
  - [ ] Call OpenAI GPT-4 for personalized advice
  - [ ] Store in weekly_progress_summaries
  - [ ] Return advice text

- [ ] Display advice card on home screen
- [ ] Make it visually distinct and engaging

---

## Phase 5: Milestones Screen & Drill-Down

### Week 5-6: Milestone Browser

#### Milestones List Screen
- [ ] Modify `milestones_screen.dart`
  - [ ] Remove baby-specific milestone logic
  - [ ] Add category filter tabs
  - [ ] Group milestones by age range
  - [ ] Show completion status icons (✅ 🔄 ⭕)
  - [ ] Make each milestone tappable

- [ ] Category filter tabs
  - [ ] All
  - [ ] Number Sense
  - [ ] Counting
  - [ ] Patterns
  - [ ] Shapes & Spatial
  - [ ] Sorting
  - [ ] Measurement
  - [ ] Operations

- [ ] Age-based grouping
  - [ ] Completed (past milestones)
  - [ ] Current Age Range
  - [ ] Coming Soon (future milestones)

- [ ] Milestone card design
  - [ ] Category icon and color
  - [ ] Title
  - [ ] Age range
  - [ ] Completion status
  - [ ] Tap to view details

#### Milestone Detail Screen (NEW)
- [ ] Create `milestone_detail_screen.dart`
  - [ ] Full milestone description
  - [ ] "Why This Matters" section
  - [ ] Age range display
  - [ ] Signs of readiness
  - [ ] List of 5-10 activities (expandable cards)
  - [ ] Each activity tappable for full detail
  - [ ] "Mark as Completed" button
  - [ ] Notes field
  - [ ] Photo upload (optional)
  - [ ] Share button

- [ ] Activity list within milestone
  - [ ] Show activity titles
  - [ ] Show duration and materials
  - [ ] Tap to expand for full instructions
  - [ ] "I Did This" button on each

- [ ] Completion tracking
  - [ ] Button to mark milestone complete
  - [ ] Confidence slider (1-5 stars)
  - [ ] Notes field
  - [ ] Save to milestone_completions table
  - [ ] Show celebration animation

#### Activity Detail Screen (NEW)
- [ ] Create `activity_detail_screen.dart`
  - [ ] Back button to milestone or home
  - [ ] Activity title and category
  - [ ] Age range
  - [ ] Duration estimate
  - [ ] Materials needed (clear list)
  - [ ] Step-by-step instructions (numbered)
  - [ ] Tips for success (callout boxes)
  - [ ] Variations (collapsible)
  - [ ] "I Did This Activity" button
  - [ ] "Save to Favorites" button (future feature)

- [ ] Activity logging popup
  - [ ] "How long did you do this?" (slider 1-30 min)
  - [ ] "How engaged was your child?" (1-5 stars)
  - [ ] "Any observations?" (text field)
  - [ ] Save button → logs to activity_logs table
  - [ ] Updates streak
  - [ ] Shows celebration
  - [ ] Suggests related activities

- [ ] Celebration animation
  - [ ] Confetti or stars
  - [ ] Encouraging message
  - [ ] Streak update display

---

## Phase 6: Onboarding Flow

### Week 6-7: New User Experience

#### Screen 1: Welcome
- [ ] Create `onboarding_welcome_screen.dart`
  - [ ] Beautiful hero image (parent + child with numbers/shapes)
  - [ ] Headline: "Help Your Child Fall in Love with Numbers"
  - [ ] Subheadline: Brief value proposition
  - [ ] "Get Started" button
  - [ ] Smooth animations

#### Screen 2: Child Details
- [ ] Modify `onboarding_baby_screen.dart`
  - [ ] Keep: Name, birthdate, gender
  - [ ] Remove: weight, height, measurements
  - [ ] Add: Profile photo upload (optional)
  - [ ] Calculate age from birthdate
  - [ ] Validate inputs
  - [ ] "Next" button

#### Screen 3: Maths Readiness Assessment
- [ ] Create `onboarding_maths_readiness_screen.dart`
  - [ ] Question 1: "Does your child count objects?"
    - [ ] Yes / Sometimes / Not yet
  - [ ] Question 2: "Can they recognize any numbers?"
    - [ ] Yes / Sometimes / Not yet
  - [ ] Question 3: "Do they sort toys by color or size?"
    - [ ] Yes / Sometimes / Not yet
  - [ ] Question 4: "Can they recognize shapes like circles or squares?"
    - [ ] Yes / Sometimes / Not yet
  - [ ] Store responses (for initial activity suggestions)
  - [ ] "Next" button

#### Screen 4: Goals Selection
- [ ] Modify `onboarding_goals_screen.dart`
  - [ ] Headline: "What's most important to you?"
  - [ ] Multiple choice (select all that apply):
    - [ ] Build a strong foundation for school
    - [ ] Make math fun and anxiety-free
    - [ ] Keep my child ahead
    - [ ] Support my child who struggles with numbers
    - [ ] Build my own confidence in teaching math
  - [ ] Store selections
  - [ ] "Next" button

#### Screen 5: How It Works
- [ ] Create `onboarding_how_it_works_screen.dart`
  - [ ] 3 key features with icons:
    - [ ] Daily activity suggestions
    - [ ] Track milestone progress
    - [ ] See your child's growth over time
  - [ ] Simple, visual explanation
  - [ ] "Next" button

#### Screen 6: Payment/Trial
- [ ] Modify existing payment screen
  - [ ] 7-day free trial (prominent)
  - [ ] Pricing: $9.99/month or $79/year
  - [ ] Feature list (unlimited activities, AI advice, progress tracking)
  - [ ] "Start Free Trial" button
  - [ ] "Restore Purchase" link
  - [ ] Terms & Privacy links

#### Onboarding Flow Logic
- [ ] Update onboarding navigation in `main.dart`
  - [ ] Check if user completed onboarding
  - [ ] If not, show welcome screen
  - [ ] Progress through 6 screens
  - [ ] On completion, create baby profile
  - [ ] Navigate to home screen

---

## Phase 7: Progress & Analytics

### Week 7-8: Insights & Tracking

#### Progress Dashboard Screen (NEW)
- [ ] Create `progress_dashboard_screen.dart`
  - [ ] Time range selector (This Week / This Month / All Time)
  - [ ] Key metrics cards:
    - [ ] Activities completed
    - [ ] New milestones achieved
    - [ ] Total engagement time
    - [ ] Current streak
  - [ ] Category breakdown chart (which categories practiced most)
  - [ ] Milestone progress chart (% complete by age range)
  - [ ] Recent activity timeline
  - [ ] "Export Report" button

#### Widgets for Visualization
- [ ] Create `progress_chart.dart`
  - [ ] Use charts package (fl_chart or charts_flutter)
  - [ ] Bar chart for category breakdown
  - [ ] Line chart for progress over time
  - [ ] Pie chart for time distribution
  - [ ] Beautiful, colorful design

- [ ] Create `metric_card.dart`
  - [ ] Large number display
  - [ ] Label
  - [ ] Trend indicator (up/down)
  - [ ] Icon
  - [ ] Tap for details

#### Weekly Summary Generation
- [ ] Implement in `progress_service.dart`
  - [ ] Calculate weekly stats
  - [ ] Call AI for personalized summary
  - [ ] Store in database
  - [ ] Retrieve for display

- [ ] AI Summary prompt engineering
  - [ ] Include: child's age, activities completed, milestones achieved
  - [ ] Include: engagement levels, category focus
  - [ ] Tone: encouraging, supportive, actionable
  - [ ] Length: 2-3 short paragraphs
  - [ ] Include 2-3 specific suggestions

#### Export & Share
- [ ] Implement progress report export
  - [ ] Generate PDF with charts and summaries
  - [ ] Email report to parent
  - [ ] Share to social media (milestone achievements)

---

## Phase 8: Polish & Testing

### Week 8-9: Quality Assurance

#### UI/UX Polish
- [ ] Review all screens for consistency
- [ ] Ensure color scheme is cohesive
- [ ] Check font sizes and readability
- [ ] Verify button sizes are thumb-friendly
- [ ] Test on multiple device sizes
- [ ] Add loading states for all async operations
- [ ] Add empty states (no activities yet, no milestones completed)
- [ ] Add error states with helpful messages

#### Animations & Transitions
- [ ] Add page transitions (slide, fade)
- [ ] Add milestone completion celebration animation
- [ ] Add activity logging celebration
- [ ] Add streak milestone celebrations (7 days, 30 days, etc.)
- [ ] Add subtle hover/press effects on buttons
- [ ] Add skeleton loaders for data fetching

#### Testing - Functional
- [ ] Test onboarding flow end-to-end
- [ ] Test activity logging
- [ ] Test milestone completion
- [ ] Test streak tracking logic
- [ ] Test daily activity generation
- [ ] Test filtering and search
- [ ] Test offline mode
- [ ] Test with different child ages (0, 12, 24, 36, 48, 60 months)

#### Testing - Performance
- [ ] Profile app startup time
- [ ] Optimize image loading
- [ ] Optimize database queries (add indexes)
- [ ] Test with 100+ activity logs
- [ ] Test with all milestones completed
- [ ] Ensure smooth scrolling

#### Accessibility
- [ ] Add screen reader labels
- [ ] Ensure sufficient color contrast
- [ ] Support dynamic text sizing
- [ ] Test with VoiceOver/TalkBack
- [ ] Add semantic labels for images

#### Bug Fixes
- [ ] Fix any crashes found in testing
- [ ] Fix UI layout issues on small screens
- [ ] Fix UI layout issues on tablets
- [ ] Fix data synchronization issues
- [ ] Fix edge cases in date/age calculations

---

## Phase 9: Launch Preparation

### Week 9-10: Go to Market

#### Analytics Setup
- [ ] Configure Mixpanel (already in app)
- [ ] Add custom events:
  - [ ] onboarding_completed
  - [ ] activity_logged
  - [ ] milestone_completed
  - [ ] daily_activities_viewed
  - [ ] streak_milestone_reached
  - [ ] subscription_started
  - [ ] subscription_cancelled
- [ ] Set up user properties (child_age, plan_type, etc.)
- [ ] Test event tracking

#### Push Notifications
- [ ] Set up Firebase Cloud Messaging
- [ ] Create notification templates:
  - [ ] Daily activity reminder
  - [ ] Streak risk warning (haven't logged in 24 hours)
  - [ ] Weekly summary available
  - [ ] New milestone unlocked
  - [ ] Encouragement after milestone completion
- [ ] Implement notification preferences in settings
- [ ] Test notifications on iOS and Android

#### App Store Preparation
- [ ] Write app description (App Store & Play Store)
- [ ] Create app screenshots (5-8 per platform)
- [ ] Create app preview video (optional but recommended)
- [ ] Prepare app icon in all required sizes
- [ ] Write release notes
- [ ] Set up age rating (4+ likely)
- [ ] Configure pricing (free with in-app purchase)
- [ ] Set up subscription products in App Store Connect & Google Play Console

#### Beta Testing
- [ ] Recruit 10-20 parents for beta
- [ ] Use TestFlight (iOS) and internal testing (Android)
- [ ] Create feedback form
- [ ] Collect feedback on:
  - [ ] Ease of use
  - [ ] Content quality
  - [ ] Activity clarity
  - [ ] Overall value
- [ ] Iterate based on feedback

#### Documentation
- [ ] Create in-app help/FAQ
- [ ] Create tutorial videos (optional)
- [ ] Write privacy policy
- [ ] Write terms of service
- [ ] Create support email address
- [ ] Set up website or landing page

#### Final Checks
- [ ] Review all milestone content for accuracy
- [ ] Review all activity instructions for clarity
- [ ] Legal review of content (if needed)
- [ ] Security audit of API endpoints
- [ ] Test payment flows thoroughly
- [ ] Test subscription management
- [ ] Prepare customer support materials

#### Launch!
- [ ] Submit to App Store
- [ ] Submit to Play Store
- [ ] Announce on social media
- [ ] Reach out to parenting blogs/influencers
- [ ] Monitor reviews and feedback
- [ ] Plan first update based on feedback

---

## Post-Launch: Ongoing Tasks

### Content Expansion
- [ ] Add video demonstrations for top 20 activities
- [ ] Create printable activity cards
- [ ] Add more milestones for 5-8 year olds
- [ ] Translate content to Spanish, Mandarin, etc.

### Feature Enhancements
- [ ] Add community features (share activities, tips)
- [ ] Add favorites/bookmarking for activities
- [ ] Add custom activity creation
- [ ] Add progress sharing to social media
- [ ] Add multiplayer activities (for siblings)
- [ ] Add photo/video diary integration

### Marketing & Growth
- [ ] Run ads (Facebook, Google, TikTok)
- [ ] Partner with early childhood educators
- [ ] Create blog content about early math
- [ ] Build email nurture sequence
- [ ] Referral program
- [ ] App Store Optimization (ASO)

---

## Notes & Best Practices

### Development Guidelines
- Use existing BabySleepApp patterns for consistency
- Maintain Provider state management pattern
- Follow Flutter best practices for widget composition
- Write tests for all business logic
- Keep UI and business logic separate
- Use meaningful variable and function names
- Comment complex logic
- Keep functions small and focused

### Content Guidelines
- Activities should use household items when possible
- Instructions should be simple and clear (elementary reading level)
- Emphasize fun and play over drilling
- Include variations for different skill levels
- Provide encouragement and positive framing
- Cite research when making developmental claims
- Be culturally sensitive and inclusive

### Database Guidelines
- Always use parameterized queries
- Never store sensitive data unencrypted
- Use RLS policies correctly
- Index frequently queried columns
- Monitor query performance
- Plan for scale (1M+ rows)
- Keep migrations reversible when possible

### Design Guidelines
- Use bright, playful colors (but not overwhelming)
- Ensure sufficient contrast for readability
- Use icons to aid comprehension
- Make buttons large enough for thumbs
- Provide visual feedback for all actions
- Use consistent spacing and alignment
- Test on small and large devices
- Support both portrait and landscape

---

## Success Criteria

### MVP Launch Criteria
✅ 100+ milestones across all 7 categories
✅ 500+ activities total
✅ Functional onboarding flow
✅ Activity logging and streak tracking working
✅ Milestone completion tracking working
✅ Home screen with daily activities
✅ Milestones screen with drill-down
✅ Progress dashboard with basic charts
✅ Payment/subscription flow working
✅ No critical bugs
✅ <2s app startup time
✅ Works offline for viewing content

### Post-Launch Goals (3 months)
- 1,000+ downloads
- 15%+ free trial conversion rate
- <5% monthly churn
- 4.5+ star rating
- 10+ positive reviews
- Daily active user rate >40%
- Average 5+ activities logged per user per week

---

## Questions & Decisions Needed

### Open Questions
- [ ] Should we support multiple children per account?
- [ ] Should activities have video demonstrations at launch or post-launch?
- [ ] Should we integrate with Apple Health / Google Fit?
- [ ] Should we offer a one-time purchase option vs subscription only?
- [ ] Should we have a free tier with limited features?
- [ ] Should we show ads in free tier?
- [ ] What age ranges should we support at launch? (0-3 only? 0-5?)
- [ ] Should we integrate with physical products (manipulatives, flashcards)?

### Technical Decisions
- [ ] Use existing Supabase project or new project?
- [ ] Keep existing analytics (Mixpanel) or add others?
- [ ] Self-host or use managed services?
- [ ] CDN for media assets?
- [ ] Video hosting solution (if adding videos)?
