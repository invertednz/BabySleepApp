# BabySteps AI Chatbot Implementation Plan

## Overview
A context-aware AI chatbot for paid users that leverages Google Gemini to answer parenting questions using the user's baby data, milestones, activities, sleep history, and chat history.

---

## Architecture

### Approach: Structured Context Injection (NOT RAG/Embeddings)
Given the structured nature of baby data and the goal of simplicity, we'll use **structured context injection** rather than embeddings/RAG:

1. **Why not RAG/Embeddings for this use case:**
   - Baby data is already structured in database tables
   - Context is user-specific and relatively small
   - Gemini handles structured JSON context very well
   - RAG adds complexity (vector DB, embeddings, retrieval logic)

2. **Our approach:**
   - Classify the question type to determine what context to fetch
   - Fetch only relevant context from Supabase tables
   - Inject structured context into the Gemini prompt
   - Let Gemini reason over the context

### Components

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

---

## Database Schema

### New Table: `baby_chat_messages`
```sql
CREATE TABLE public.baby_chat_messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  baby_id UUID NOT NULL REFERENCES public.babies(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  role TEXT NOT NULL CHECK (role IN ('user', 'assistant')),
  content TEXT NOT NULL,
  image_url TEXT,  -- Optional: for messages with images
  context_summary TEXT,  -- Summary of context used for this response
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Indexes
CREATE INDEX idx_chat_messages_baby_user ON public.baby_chat_messages(baby_id, user_id);
CREATE INDEX idx_chat_messages_created ON public.baby_chat_messages(created_at DESC);

-- RLS
ALTER TABLE public.baby_chat_messages ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage their own chat messages"
  ON public.baby_chat_messages FOR ALL USING (auth.uid() = user_id);
```

---

## Context Categories & Data Sources

The chatbot will classify questions and fetch relevant context:

| Category | Data Sources | When to Include |
|----------|--------------|-----------------|
| **Baby Profile** | `babies` | Always (basic context) |
| **Milestones** | `baby_milestones`, `v_baby_milestone_assessment` | Questions about development, milestones, "should my baby..." |
| **Activities** | `baby_activities` | Questions about play, activities, what baby likes/dislikes |
| **Sleep** | `sleep_schedules` | Questions about sleep, naps, bedtime |
| **Health** | `concerns`, measurements | Questions about health, growth, concerns |
| **Development** | `baby_weekly_advice`, `baby_nurture_priorities`, `baby_short_term_focus` | Questions about advice, focus, development plan |
| **Chat History** | `baby_chat_messages` | Always (last 10 messages for continuity) |

---

## Supabase Edge Function: `baby_chat`

### Request Body
```typescript
interface ChatRequest {
  baby_id: string;
  message: string;
  image_base64?: string;  // Optional base64 encoded image
  image_mime_type?: string;  // e.g., 'image/jpeg', 'image/png'
}
```

### Response Body
```typescript
interface ChatResponse {
  response: string;
  context_used: string[];  // Categories of context used
  message_id: string;
}
```

### Logic Flow
1. Validate authentication and paid status
2. Classify the question type using simple keyword matching
3. Fetch relevant context from database
4. Build structured prompt with context
5. Call Gemini API (with image if provided)
6. Save both user message and AI response to `baby_chat_messages`
7. Return response

---

## Flutter Implementation

### Files to Modify/Create

1. **`lib/models/chat_message.dart`** - Enhance model
2. **`lib/services/chat_service.dart`** - NEW: API service
3. **`lib/screens/ask_ai_screen.dart`** - Update to use real API
4. **`lib/widgets/chat_message_bubble.dart`** - Enhance for images

### Premium Check
- Check `AuthProvider.isPaidUser` before allowing chat
- Show upgrade prompt for free users

### Image Handling
- Use `image_picker` (already in pubspec)
- Convert to base64 for API call
- Display image thumbnails in chat

---

## Question Classification (Simplified)

```typescript
function classifyQuestion(message: string): string[] {
  const categories: string[] = ['profile'];  // Always include
  const lowerMsg = message.toLowerCase();
  
  if (/milestone|develop|crawl|walk|talk|sit|stand/.test(lowerMsg)) {
    categories.push('milestones');
  }
  if (/sleep|nap|bedtime|wake|night|tired/.test(lowerMsg)) {
    categories.push('sleep');
  }
  if (/play|activity|game|toy|like|hate|love/.test(lowerMsg)) {
    categories.push('activities');
  }
  if (/eat|feed|food|bottle|breast|formula|solid/.test(lowerMsg)) {
    categories.push('feeding');
  }
  if (/sick|health|doctor|concern|worry|fever|rash/.test(lowerMsg)) {
    categories.push('health');
  }
  if (/advice|plan|focus|recommend|should|week/.test(lowerMsg)) {
    categories.push('development');
  }
  
  // If no specific category matched, include more context
  if (categories.length === 1) {
    categories.push('milestones', 'activities', 'development');
  }
  
  return categories;
}
```

---

## System Prompt Template

```
You are a friendly, knowledgeable parenting assistant for BabySteps app. You help parents with questions about their baby's development, sleep, activities, and general parenting.

IMPORTANT GUIDELINES:
- Be warm, supportive, and reassuring
- Give evidence-based advice when possible
- Always recommend consulting a pediatrician for medical concerns
- Personalize responses using the baby's name and context provided
- Keep responses concise but helpful (2-4 paragraphs max)
- If you don't have enough information, ask clarifying questions

BABY CONTEXT:
{context_json}

RECENT CONVERSATION:
{chat_history}

USER MESSAGE:
{user_message}
```

---

## Implementation Phases

### Phase 1: Database & Edge Function (Backend)
1. Create migration for `baby_chat_messages` table
2. Create `baby_chat` edge function with:
   - Auth validation
   - Premium check
   - Context gathering
   - Gemini API call
   - Chat history storage

### Phase 2: Flutter Integration (Frontend)
1. Create `ChatService` class
2. Update `ChatMessage` model for persistence
3. Update `AskAiScreen` with:
   - Real API integration
   - Image picker
   - Loading states
   - Error handling
   - Premium gate

### Phase 3: Polish
1. Add typing indicator
2. Add markdown rendering for responses
3. Add quick suggestion chips
4. Add clear chat option

---

## Security Considerations

1. **Authentication**: All requests require valid JWT
2. **Premium Check**: Verify plan_tier on each request
3. **Rate Limiting**: Limit requests per user (consider adding later)
4. **RLS**: Row Level Security ensures users only see their own data
5. **Image Safety**: Gemini has built-in safety filters for images

---

## Cost Considerations

- Gemini API: Pay per token
- Context size: Limited to keep costs reasonable
- Chat history: Only last 10 messages included
- Image: Base64 adds to token count

---

## Files to Create/Modify

### New Files
- `supabase/migrations/0019_add_chat_messages.sql`
- `supabase/functions/baby_chat/index.ts`
- `babysteps_app/lib/services/chat_service.dart`

### Modified Files
- `babysteps_app/lib/models/chat_message.dart`
- `babysteps_app/lib/screens/ask_ai_screen.dart`
- `babysteps_app/lib/widgets/chat_message_bubble.dart`

---

## Testing Checklist

- [ ] Free user sees upgrade prompt
- [ ] Paid user can send text messages
- [ ] Paid user can send images
- [ ] Chat history persists across sessions
- [ ] Context is correctly injected based on question
- [ ] Responses are personalized with baby name
- [ ] Error states handled gracefully
- [ ] Loading states shown appropriately
