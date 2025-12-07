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

-- Indexes for efficient queries
CREATE INDEX IF NOT EXISTS idx_chat_messages_baby_user ON public.baby_chat_messages(baby_id, user_id);
CREATE INDEX IF NOT EXISTS idx_chat_messages_created ON public.baby_chat_messages(created_at DESC);

-- Enable RLS
ALTER TABLE public.baby_chat_messages ENABLE ROW LEVEL SECURITY;

-- RLS policy
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename = 'baby_chat_messages'
      AND policyname = 'Users can manage their own chat messages'
  ) THEN
    CREATE POLICY "Users can manage their own chat messages"
      ON public.baby_chat_messages FOR ALL USING (auth.uid() = user_id);
  END IF;
END $$;

COMMENT ON TABLE public.baby_chat_messages IS 'Stores chat messages between users and the AI assistant for each baby';
