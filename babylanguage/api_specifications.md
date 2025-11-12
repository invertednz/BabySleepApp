# Baby Language App - API Specifications

Detailed specifications for Firebase Cloud Functions (HTTPS) and endpoints.

---

## Overview
- Runtime: Node 20 (TypeScript)
- SDKs: firebase-admin (Firestore/Storage), openai
- Config: Firebase Functions config for secrets (e.g., `openai.key`)

### Base URL
```
https://[region]-[project-id].cloudfunctions.net/
```

### Authentication
Send Firebase ID token in header:
```
Authorization: Bearer <firebase_id_token>
```

---

## 1) Generate Daily Activities
- POST `/generate-daily-activities`
- Purpose: Return 3–5 age-appropriate language activities with variety.
- Request:
```json
{ "baby_id": "string", "date": "2025-01-15" }
```
- Response:
```json
{ "baby_id":"string", "activity_date":"2025-01-15", "activities":[ {"milestone_id":"id","title":"Name & Point Game","category":"expressive","duration_minutes":5,"materials":["family photos"],"description":"Point and label familiar people."} ], "generated_at":"ISO" }
```
- Logic: age months → age-appropriate milestones (not completed) → avoid category repetition → pick 3–5 → write to `daily_activity_suggestions`.

## 2) Generate Weekly Advice
- POST `/generate-weekly-advice`
- Purpose: Personalized AI advice (150–200 words) based on last week’s logs.
- Request: `{ "baby_id":"string", "week_start_date":"2025-01-13" }`
- Response: stats summary + `ai_advice` + suggestions array.

## 3) Calculate Progress Metrics
- POST `/calculate-progress-metrics`
- Purpose: Charts-ready metrics and breakdowns.
- Request: `{ "baby_id":"string", "time_range":"week|month|all_time" }`
- Response: totals, category breakdown, daily counts, milestone progress, engagement trend, streaks.

## 4) Update Streak
- POST `/update-streak`
- Purpose: Update streak on activity log.
- Request: `{ "baby_id":"string" }`
- Response: `{ "current_streak": n, "longest_streak": n }`

## 5) Log Activity
- POST `/log-activity`
- Purpose: Create `activity_logs` entry; then call `update-streak`.
- Request fields: baby_id, milestone_id (optional), activity_title, category, completed_at (default now), duration_minutes, engagement_level, notes, media_urls[]
- Response: id, logged_at, streak info.

## 6) Complete Milestone
- POST `/complete-milestone`
- Purpose: Create `milestone_completions` record; return suggested next milestones.

## 7) Get Milestones for Baby
- GET `/milestones?baby_id=...&category=expressive&status=not_completed`
- Purpose: Milestones filtered by age, category, status.

## 8) Search Activities
- GET `/search-activities?baby_id=...&query=rhyme&max_duration=10`
- Purpose: Search activities across all milestones.

## 9) Export Progress Report
- POST `/export-progress-report`
- Purpose: Generate PDF with charts & recent highlights; return temporary URL.

---

## Common Response Envelope
```json
{ "success": true, "data": { }, "timestamp": "ISO" }
```

## Errors
- 400 invalid params
- 401 unauthenticated
- 403 forbidden
- 404 not found
- 500 internal

---

## Environment & Deployment
- Set env:
```bash
firebase functions:config:set openai.key="sk-xxx" mixpanel.token="xxx"
```
- Deploy:
```bash
firebase deploy --only functions
```
