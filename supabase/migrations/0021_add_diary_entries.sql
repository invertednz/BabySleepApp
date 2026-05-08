-- Diary entries table for baby diary/journal feature
CREATE TABLE diary_entries (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  baby_id UUID NOT NULL,
  type TEXT NOT NULL DEFAULT 'note',
  title TEXT,
  content TEXT,
  timestamp TIMESTAMPTZ NOT NULL DEFAULT now(),
  measurements JSONB,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE diary_entries ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage their own diary entries"
  ON diary_entries FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE INDEX idx_diary_entries_user_baby ON diary_entries(user_id, baby_id);
CREATE INDEX idx_diary_entries_timestamp ON diary_entries(timestamp DESC);

-- Add unique constraint on sleep_schedules for upsert support (baby_id + date)
-- The date column stores a TIMESTAMPTZ; we cast to DATE for daily uniqueness.
CREATE UNIQUE INDEX idx_sleep_schedules_baby_date
  ON sleep_schedules (baby_id, (date::date));
