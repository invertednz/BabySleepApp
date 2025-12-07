# BabySteps AI Chatbot Setup Guide

This document explains how to set up and deploy the AI chatbot feature for BabySteps.

---

## Overview

The chatbot is a premium feature that allows users to ask questions about their baby's development, sleep, activities, and more. It uses Google Gemini for AI responses and pulls context from the user's data to provide personalized answers.

### Features
- Context-aware responses using baby profile, milestones, activities, sleep data
- Image analysis (users can share photos for AI feedback)
- Chat history persistence
- Premium user gating
- Markdown-formatted responses

---

## Prerequisites

1. **Supabase Project** - Already set up for BabySteps
2. **Google Cloud Account** - For Gemini API access
3. **Supabase CLI** - For deploying edge functions

---

## Setup Steps

### 1. Database Migration

Run the migration to create the chat messages table:

```bash
# Navigate to project root
cd BabySleepApp

# Apply migration (if using Supabase CLI)
supabase db push

# Or manually run the SQL from:
# supabase/migrations/0019_add_chat_messages.sql
```

**Manual SQL (run in Supabase SQL Editor):**
```sql
-- Chat messages table for AI chatbot conversations
CREATE TABLE IF NOT EXISTS public.baby_chat_messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  baby_id UUID NOT NULL REFERENCES public.babies(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  role TEXT NOT NULL CHECK (role IN ('user', 'assistant')),
  content TEXT NOT NULL,
  image_url TEXT,
  context_summary TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_chat_messages_baby_user ON public.baby_chat_messages(baby_id, user_id);
CREATE INDEX IF NOT EXISTS idx_chat_messages_created ON public.baby_chat_messages(created_at DESC);

ALTER TABLE public.baby_chat_messages ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage their own chat messages"
  ON public.baby_chat_messages FOR ALL USING (auth.uid() = user_id);
```

---

### 2. Get Gemini API Key

1. Go to [Google AI Studio](https://aistudio.google.com/app/apikey)
2. Create a new API key
3. Copy the key for the next step

---

### 3. Set Supabase Edge Function Secrets

```bash
# Set the Gemini API key
supabase secrets set GEMINI_API_KEY=your_gemini_api_key_here

# Optionally set a specific model (defaults to gemini-2.0-flash)
supabase secrets set GEMINI_MODEL_ID=gemini-2.0-flash
```

**Available Gemini Models:**
- `gemini-2.0-flash` - Fast, good for chat (recommended)
- `gemini-2.5-pro` - Most capable, but slower/more expensive
- `gemini-1.5-flash` - Previous generation, still good

---

### 4. Deploy the Edge Function

```bash
# From project root
cd BabySleepApp

# Deploy the baby_chat function
supabase functions deploy baby_chat --no-verify-jwt
```

**Note:** The `--no-verify-jwt` flag is used because we handle JWT verification inside the function itself using the Authorization header.

---

### 5. Test the Edge Function

You can test the function using curl:

```bash
# Get your access token from the Supabase dashboard or app
ACCESS_TOKEN="your_supabase_access_token"

curl -X POST \
  'https://YOUR_PROJECT_REF.supabase.co/functions/v1/baby_chat' \
  -H 'Authorization: Bearer $ACCESS_TOKEN' \
  -H 'Content-Type: application/json' \
  -d '{
    "baby_id": "your-baby-uuid",
    "message": "Is my baby on track for milestones?"
  }'
```

---

## Flutter Integration

The chatbot is integrated into the app at:

- **Screen:** `lib/screens/ask_ai_screen.dart`
- **Service:** `lib/services/chat_service.dart`
- **Model:** `lib/models/chat_message.dart`
- **Widget:** `lib/widgets/chat_message_bubble.dart`

### Accessing the Chat Screen

The chat screen can be accessed from:
1. **Home Screen** - Tap the "Ask about baby sleep, development, or care..." input field
2. Direct navigation in code: `Navigator.push(context, MaterialPageRoute(builder: (_) => const AskAiScreen()))`

The home screen's Ask AI input field is wrapped in a `GestureDetector` that navigates to `AskAiScreen` when tapped.

---

## How It Works

### Context Gathering

The chatbot automatically determines what context to fetch based on the user's question:

| Keywords | Context Fetched |
|----------|-----------------|
| milestone, develop, walk, crawl, etc. | Baby milestones data |
| sleep, nap, bedtime, wake, etc. | Sleep schedule data |
| play, activity, toy, like, hate, etc. | Activity preferences |
| feed, eat, bottle, formula, etc. | Feeding info |
| sick, health, concern, worry, etc. | Health concerns |
| advice, plan, focus, recommend, etc. | Development plans |

### Premium Check

The chatbot checks the user's `plan_tier` in `user_preferences`:
- Free users see an upgrade prompt
- Paid users (or trial users) can use the chat

---

## Architecture

```
┌─────────────────┐     ┌──────────────────────┐     ┌─────────────┐
│  Flutter App    │────▶│  Supabase Edge Fn    │────▶│   Gemini    │
│  (Chat Screen)  │◀────│  (baby_chat)         │◀────│   API       │
└─────────────────┘     └──────────────────────┘     └─────────────┘
                               │
                               ▼
                        ┌──────────────┐
                        │   Supabase   │
                        │   Database   │
                        └──────────────┘
```

1. User sends message (with optional image)
2. Flutter calls `baby_chat` edge function
3. Edge function:
   - Validates authentication
   - Checks premium status
   - Classifies question type
   - Fetches relevant context from database
   - Calls Gemini API with context + message
   - Saves messages to chat history
   - Returns response
4. Flutter displays response with markdown rendering

---

## Cost Considerations

### Gemini API Pricing (as of 2024)

- **Gemini 2.0 Flash:** Very affordable for chat use
- **Gemini 2.5 Pro:** Higher cost, use sparingly

### Optimization Tips

1. Context is limited to relevant data only (based on question classification)
2. Chat history limited to last 10 messages
3. Images are compressed before sending (1024px max, 85% quality)

---

## Troubleshooting

### "Premium subscription required" error
- User is on free tier
- Check `user_preferences.plan_tier` in database

### "Unauthorized" error
- JWT token expired or invalid
- User needs to re-authenticate

### "AI service temporarily unavailable"
- Gemini API error (rate limit, key issue, etc.)
- Check edge function logs: `supabase functions logs baby_chat`

### Empty or weird responses
- Check Gemini model availability
- Verify API key is correct
- Check edge function logs for prompt/response

---

## Security Notes

1. **API Key Security:** Gemini API key is stored as Supabase secret, never exposed to client
2. **Row Level Security:** Users can only access their own chat messages
3. **Premium Gating:** Enforced server-side, not just client-side
4. **Image Safety:** Gemini has built-in content safety filters

---

## Files Reference

| File | Purpose |
|------|---------|
| `supabase/migrations/0019_add_chat_messages.sql` | Database table |
| `supabase/functions/baby_chat/index.ts` | Edge function |
| `lib/services/chat_service.dart` | Flutter API service |
| `lib/screens/ask_ai_screen.dart` | Chat UI screen |
| `lib/models/chat_message.dart` | Message model |
| `lib/widgets/chat_message_bubble.dart` | Message bubble UI |

---

## Future Improvements

- [ ] Voice input/output
- [ ] Rate limiting per user
- [ ] Chat export functionality
- [ ] Suggested follow-up questions
- [ ] Multi-baby context switching
