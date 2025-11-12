# Baby Maths App - API Specifications

Detailed specifications for Firebase Cloud Functions (HTTPS) and API endpoints.

---

## Overview

All APIs are implemented as Firebase Cloud Functions (Node 20, TypeScript) and called from the Flutter app via HTTPS. They use:
- Firebase Admin SDK (Firestore/Storage)
- OpenAI API (for AI-generated content)
- Environment variables via Functions config

### Base URL
```
https://[region]-[project-id].cloudfunctions.net/
```

### Authentication
Send Firebase ID token in Authorization header:
```
Authorization: Bearer <firebase_id_token>
```

---

## 1. Generate Daily Activities

### Endpoint
`POST /generate-daily-activities`

### Purpose
Generate 3-5 age-appropriate math activities for a specific baby on a specific date. Uses AI to select activities based on child's age, completed milestones, and recent activity history to ensure variety.

### Request Body
```json
{
  "baby_id": "uuid",
  "date": "2024-01-15"  // ISO date string, defaults to today
}
```

### Response (200 OK)
```json
{
  "baby_id": "uuid",
  "activity_date": "2024-01-15",
  "activities": [
    {
      "milestone_id": "uuid",
      "title": "Counting Snack Time",
      "category": "counting",
      "duration_minutes": 5,
      "materials": ["5 crackers or berries"],
      "description": "Count together during snack time",
      "age_appropriate": true,
      "difficulty": 2
    },
    {
      "milestone_id": "uuid",
      "title": "Shape Hunt",
      "category": "shapes",
      "duration_minutes": 10,
      "materials": ["None"],
      "description": "Find circles and squares around the house",
      "age_appropriate": true,
      "difficulty": 2
    }
    // ... 3-5 activities total
  ],
  "generated_at": "2024-01-15T08:00:00Z"
}
```

### Error Responses
- `400 Bad Request` - Invalid baby_id or date format
- `401 Unauthorized` - Missing or invalid JWT
- `403 Forbidden` - User doesn't have access to this baby
- `404 Not Found` - Baby not found
- `500 Internal Server Error` - Database or AI service error

### Algorithm Logic
1. Query baby's current age in months
2. Fetch age-appropriate milestones (age_months_min <= age <= age_months_max)
3. Exclude milestones already completed
4. Fetch activities logged in past 7 days
5. Calculate category distribution (avoid repeating same category too much)
6. Select 3-5 activities:
   - 60% from milestones NOT completed but age-appropriate
   - 30% from milestones slightly ahead (challenge)
   - 10% from favorite categories (if available)
7. Ensure variety across categories
8. Store in `daily_activity_suggestions` table
9. Return activities

### Sample Implementation (Pseudocode)
```javascript
const babyAge = calculateAgeInMonths(baby.birthdate);
const appropriateMilestones = await getMilestonesForAge(babyAge);
const completedMilestoneIds = await getCompletedMilestones(babyId);
const recentActivities = await getRecentActivities(babyId, 7); // last 7 days

// Filter out completed milestones
const availableMilestones = appropriateMilestones.filter(
  m => !completedMilestoneIds.includes(m.id)
);

// Get category distribution from recent activities
const recentCategories = recentActivities.map(a => a.category);
const categoryCount = countBy(recentCategories);

// Select activities ensuring variety
const selectedActivities = selectActivitiesWithVariety(
  availableMilestones,
  categoryCount,
  3 // minimum
);

// Store and return
await storeDailySuggestions(babyId, date, selectedActivities);
return { activities: selectedActivities };
```

---

## 2. Generate Weekly Advice

### Endpoint
`POST /generate-weekly-advice`

### Purpose
Generate personalized AI advice for parents based on the past week's activity and progress. Uses GPT-4 to analyze patterns and provide encouraging, actionable suggestions.

### Request Body
```json
{
  "baby_id": "uuid",
  "week_start_date": "2024-01-08"  // ISO date (Monday), defaults to this week
}
```

### Response (200 OK)
```json
{
  "baby_id": "uuid",
  "week_start_date": "2024-01-08",
  "week_end_date": "2024-01-14",
  "summary": {
    "activities_completed": 12,
    "new_milestones_achieved": 2,
    "total_engagement_minutes": 85,
    "average_engagement_level": 4.2,
    "top_categories": [
      { "category": "counting", "count": 5 },
      { "category": "patterns", "count": 4 },
      { "category": "shapes", "count": 3 }
    ]
  },
  "ai_advice": "Great week, Sarah! You completed 12 activities with Emma, focusing heavily on counting skills. Emma seems highly engaged (4.2/5 stars average), which is wonderful! This week, you achieved 2 new milestones in counting and patterns.\n\nNext week, consider:\n1. Continue the counting momentum with real-world applications like counting stairs or toys during cleanup\n2. Introduce more shape activities since Emma is ready for triangles and rectangles\n3. Try some sorting activities to develop classification skills\n\nYour consistency is paying off - keep up the great work!",
  "suggestions": [
    "Try shape activities this week",
    "Introduce sorting by color",
    "Practice counting during daily routines"
  ],
  "generated_at": "2024-01-15T10:00:00Z"
}
```

### Error Responses
- `400 Bad Request` - Invalid baby_id or date
- `401 Unauthorized` - Missing or invalid JWT
- `403 Forbidden` - User doesn't have access to this baby
- `404 Not Found` - Baby not found or no activities this week
- `500 Internal Server Error` - Database or OpenAI API error

### GPT-4 Prompt Template
```
You are an encouraging early childhood mathematics educator. Analyze this week's activity data and provide personalized advice for the parent.

Child: {baby_name}, {age_months} months old
Week: {week_start} to {week_end}

Statistics:
- Activities completed: {activities_completed}
- New milestones achieved: {new_milestones}
- Total time engaged: {total_minutes} minutes
- Average engagement level: {avg_engagement}/5 stars
- Top categories practiced: {top_categories}

Recent milestones achieved:
{milestone_list}

Write a warm, encouraging message (2-3 paragraphs) that:
1. Celebrates their efforts and consistency
2. Notes patterns in their activity choices
3. Acknowledges the child's engagement level
4. Provides 2-3 specific, actionable suggestions for next week
5. Encourages continued practice

Tone: Warm, supportive, knowledgeable but not overly academic
Length: 150-200 words
Include parent's name: {parent_name}
Include child's name: {baby_name}
```

### Algorithm Logic
1. Query all activity_logs for date range (Firestore)
2. Calculate statistics (count, engagement, minutes, categories)
3. Query milestone_completions for this week
4. Build context for GPT-4
5. Call OpenAI API with prompt
6. Parse response
7. Store in `weekly_progress_summaries` table
8. Return summary + advice

---

## 3. Calculate Progress Metrics

### Endpoint
`POST /calculate-progress-metrics`

### Purpose
Calculate real-time progress metrics for charts and dashboard displays. Returns data optimized for visualization.

### Request Body
```json
{
  "baby_id": "uuid",
  "time_range": "week"  // "week", "month", "all_time"
}
```

### Response (200 OK)
```json
{
  "baby_id": "uuid",
  "time_range": "week",
  "period_start": "2024-01-08",
  "period_end": "2024-01-14",
  "metrics": {
    "total_activities": 12,
    "total_milestones": 2,
    "total_minutes": 85,
    "current_streak": 5,
    "longest_streak": 12,
    "average_engagement": 4.2
  },
  "category_breakdown": [
    {
      "category": "counting",
      "count": 5,
      "percentage": 41.7,
      "avg_engagement": 4.6
    },
    {
      "category": "patterns",
      "count": 4,
      "percentage": 33.3,
      "avg_engagement": 4.0
    },
    {
      "category": "shapes",
      "count": 3,
      "percentage": 25.0,
      "avg_engagement": 4.0
    }
  ],
  "daily_activity_count": [
    { "date": "2024-01-08", "count": 2 },
    { "date": "2024-01-09", "count": 0 },
    { "date": "2024-01-10", "count": 3 },
    { "date": "2024-01-11", "count": 2 },
    { "date": "2024-01-12", "count": 1 },
    { "date": "2024-01-13", "count": 2 },
    { "date": "2024-01-14", "count": 2 }
  ],
  "milestone_progress": {
    "total_milestones": 120,
    "completed": 28,
    "completion_percentage": 23.3,
    "by_category": [
      { "category": "counting", "total": 20, "completed": 8, "percentage": 40 },
      { "category": "number-sense", "total": 15, "completed": 6, "percentage": 40 },
      { "category": "shapes", "total": 25, "completed": 7, "percentage": 28 },
      { "category": "patterns", "total": 15, "completed": 4, "percentage": 26.7 },
      { "category": "sorting", "total": 15, "completed": 2, "percentage": 13.3 },
      { "category": "measurement", "total": 15, "completed": 1, "percentage": 6.7 },
      { "category": "operations", "total": 15, "completed": 0, "percentage": 0 }
    ]
  },
  "engagement_trend": [
    { "week": "2024-W01", "avg_engagement": 4.0 },
    { "week": "2024-W02", "avg_engagement": 4.2 }
  ]
}
```

### Error Responses
- `400 Bad Request` - Invalid time_range
- `401 Unauthorized` - Missing or invalid JWT
- `403 Forbidden` - User doesn't have access to this baby
- `404 Not Found` - Baby not found
- `500 Internal Server Error` - Database error

### Algorithm Logic
1. Determine date range based on time_range parameter
2. Query `activity_logs` for period (Firestore composite index)
3. Query `milestone_completions` for all time and period
4. Calculate totals and averages
5. Group by category
6. Group by date for timeline chart
7. Calculate milestone completion percentages
8. Return structured data for charts

---

## 4. Update Streak

### Endpoint
`POST /update-streak`

### Purpose
Update user's activity streak when they log an activity. Called automatically after activity logging.

### Request Body
```json
{
  "baby_id": "uuid"
}
```

### Response (200 OK)
```json
{
  "baby_id": "uuid",
  "current_streak": 6,
  "longest_streak": 12,
  "last_activity_date": "2024-01-15",
  "milestone_reached": false,  // true if streak hit 7, 30, 100 etc.
  "message": "Great! 6 days in a row!"
}
```

### Error Responses
- `401 Unauthorized` - Missing or invalid JWT
- `403 Forbidden` - User doesn't have access to this baby
- `404 Not Found` - Baby not found
- `500 Internal Server Error` - Database error

### Algorithm Logic
1. Get current streak data from `user_streaks` doc
2. Get today's date
3. Compare last_activity_date:
   - If today: no change
   - If yesterday: increment streak
   - If older: reset to 1
4. Update longest_streak if current exceeds it
5. Check for milestone streaks (7, 30, 100 days)
6. Update user_streaks table
7. Return new streak info

---

## 5. Log Activity

### Endpoint
`POST /log-activity`

### Purpose
Log a completed activity with engagement metrics. This is the primary way activity data enters the system.

### Request Body
```json
{
  "baby_id": "uuid",
  "milestone_id": "uuid",  // optional if custom activity
  "activity_title": "Counting Snack Time",
  "activity_category": "counting",
  "completed_at": "2024-01-15T14:30:00Z",  // defaults to now
  "duration_minutes": 5,
  "engagement_level": 4,  // 1-5 stars
  "notes": "She loved counting the crackers! Said 'one, two, three' clearly.",
  "media_urls": []  // optional array of uploaded photo/video URLs
}
```

### Response (200 OK)
```json
{
  "activity_log_id": "uuid",
  "baby_id": "uuid",
  "logged_at": "2024-01-15T14:30:00Z",
  "streak_updated": true,
  "new_streak": 6,
  "streak_milestone": false
}
```

### Error Responses
- `400 Bad Request` - Missing required fields or invalid values
- `401 Unauthorized` - Missing or invalid JWT
- `403 Forbidden` - User doesn't have access to this baby
- `404 Not Found` - Baby or milestone not found
- `500 Internal Server Error` - Database error

### Side Effects
1. Create doc in `activity_logs`
2. Call `updateStreak` function
3. May trigger push notification for streak milestone
4. May invalidate cached daily suggestions

---

## 6. Complete Milestone

### Endpoint
`POST /complete-milestone`

### Purpose
Mark a milestone as completed by the child. Allows parent to record confidence level and notes.

### Request Body
```json
{
  "baby_id": "uuid",
  "milestone_id": "uuid",
  "confidence_level": 4,  // 1-5 scale
  "notes": "Confidently counts to 10 with one-to-one correspondence. Sometimes forgets 7."
}
```

### Response (200 OK)
```json
{
  "milestone_completion_id": "uuid",
  "baby_id": "uuid",
  "milestone_id": "uuid",
  "completed_at": "2024-01-15T14:45:00Z",
  "next_milestones": [
    {
      "id": "uuid",
      "title": "Counts to 20",
      "category": "counting"
    },
    {
      "id": "uuid",
      "title": "Counts backwards from 10",
      "category": "counting"
    }
  ]
}
```

### Error Responses
- `400 Bad Request` - Missing required fields
- `401 Unauthorized` - Missing or invalid JWT
- `403 Forbidden` - User doesn't have access to this baby
- `404 Not Found` - Baby or milestone not found
- `409 Conflict` - Milestone already marked complete
- `500 Internal Server Error` - Database error

### Side Effects
1. Create doc in `milestone_completions`
2. Updates baby.current_maths_level if appropriate
3. May trigger celebration animation in app
4. May trigger push notification with encouragement
5. Returns suggested next milestones

---

## 7. Get Milestones for Baby

### Endpoint
`GET /milestones?baby_id=uuid&category=counting&status=not_completed`

### Purpose
Fetch milestones filtered by age appropriateness, category, and completion status.

### Query Parameters
- `baby_id` (required): UUID of baby
- `category` (optional): Filter by category (counting, shapes, patterns, etc.)
- `status` (optional): all | completed | not_completed | in_progress
- `age_range` (optional): current | upcoming | past

### Response (200 OK)
```json
{
  "baby_id": "uuid",
  "baby_age_months": 28,
  "milestones": [
    {
      "id": "uuid",
      "category": "counting",
      "title": "Counts objects 1-5 with one-to-one correspondence",
      "description": "Child can touch each object once while saying one number...",
      "age_months_min": 24,
      "age_months_max": 36,
      "difficulty_level": 2,
      "is_completed": false,
      "is_age_appropriate": true,
      "activity_count": 7,
      "indicators": ["Points to each object", "Doesn't skip objects"],
      "next_steps": ["Counts to 10", "Counts out requested amount"]
    }
    // ... more milestones
  ],
  "total_count": 15,
  "completed_count": 3
}
```

### Error Responses
- `400 Bad Request` - Invalid query parameters
- `401 Unauthorized` - Missing or invalid JWT
- `403 Forbidden` - User doesn't have access to this baby
- `404 Not Found` - Baby not found
- `500 Internal Server Error` - Database error

---

## 8. Search Activities

### Endpoint
`GET /search-activities?baby_id=uuid&query=counting&materials=none`

### Purpose
Search for activities across all milestones based on keywords, materials available, duration, etc.

### Query Parameters
- `baby_id` (required): UUID of baby
- `query` (optional): Text search across titles and descriptions
- `materials` (optional): none | household | specific item
- `max_duration` (optional): Maximum duration in minutes
- `category` (optional): Filter by category

### Response (200 OK)
```json
{
  "baby_id": "uuid",
  "query": "counting",
  "results": [
    {
      "milestone_id": "uuid",
      "milestone_title": "Counts objects 1-5",
      "activity": {
        "title": "Counting Snack Time",
        "duration_minutes": 5,
        "materials": ["5 crackers"],
        "category": "counting",
        "description": "Count together during snack time",
        "instructions": ["Step 1...", "Step 2..."],
        "tips": ["Go slowly", "Celebrate success"],
        "variations": ["Count toys", "Count stairs"]
      }
    }
    // ... more results
  ],
  "total_results": 12
}
```

---

## 9. Export Progress Report

### Endpoint
`POST /export-progress-report`

### Purpose
Generate a PDF report of child's progress suitable for sharing with educators or keeping as a record.

### Request Body
```json
{
  "baby_id": "uuid",
  "time_range": "all_time",  // or specific dates
  "include_charts": true,
  "include_activity_list": true,
  "include_notes": false
}
```

### Response (200 OK)
```json
{
  "baby_id": "uuid",
  "report_url": "https://storage.supabase.co/reports/abc123.pdf",
  "generated_at": "2024-01-15T15:00:00Z",
  "expires_at": "2024-01-22T15:00:00Z"  // 7 days
}
```

### Error Responses
- `401 Unauthorized` - Missing or invalid JWT
- `403 Forbidden` - User doesn't have access to this baby or not premium subscriber
- `404 Not Found` - Baby not found
- `500 Internal Server Error` - PDF generation error

---

## Common Response Fields

All API responses include:
```json
{
  "success": true,
  "data": { /* response data */ },
  "timestamp": "2024-01-15T10:00:00Z"
}
```

Error responses include:
```json
{
  "success": false,
  "error": {
    "code": "INVALID_BABY_ID",
    "message": "The provided baby_id is invalid or not found",
    "details": {}
  },
  "timestamp": "2024-01-15T10:00:00Z"
}
```

---

## Rate Limiting

Apply per-user quotas in Functions or via Firebase App Check when needed.

---

## Webhooks (Future)

Planned webhooks for external integrations:
- `activity.logged` - Fires when activity is logged
- `milestone.completed` - Fires when milestone is marked complete
- `streak.milestone` - Fires when streak hits 7, 30, 100 days
- `subscription.changed` - Fires on subscription events

---

## Testing Endpoints

All Edge Functions have a `/test` variant that uses mock data:
- `/generate-daily-activities-test`
- `/generate-weekly-advice-test`
- etc.

These don't require authentication and return sample data for UI testing.

---

## Environment Variables Required

Set via Functions config:
```bash
firebase functions:config:set openai.key="sk-xxx" mixpanel.token="xxx"
```

---

## Deployment

Deploy to Firebase using CLI:
```bash
firebase deploy --only functions
```
