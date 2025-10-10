-- Create user activity log table for streak tracking
CREATE TABLE IF NOT EXISTS public.user_activity_log (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  activity_date date NOT NULL DEFAULT CURRENT_DATE,
  activity_types jsonb NOT NULL DEFAULT '[]'::jsonb,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE(user_id, activity_date)
);

-- Create index for faster queries
CREATE INDEX IF NOT EXISTS idx_user_activity_user_date ON public.user_activity_log(user_id, activity_date DESC);

-- Enable RLS
ALTER TABLE public.user_activity_log ENABLE ROW LEVEL SECURITY;

-- Policy (drop if exists first, then create)
DROP POLICY IF EXISTS "Allow users to manage their own activity log" ON public.user_activity_log;
CREATE POLICY "Allow users to manage their own activity log"
  ON public.user_activity_log FOR ALL USING (auth.uid() = user_id);

-- Add comment
COMMENT ON TABLE public.user_activity_log IS 'Tracks daily user activity for streak calculation';
COMMENT ON COLUMN public.user_activity_log.activity_types IS 'Array of activity types performed on this date: focus, sleep, milestones, progress, moments, words, activities, recommendations';
