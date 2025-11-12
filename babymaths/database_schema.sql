-- Baby Maths App - Initial Database Schema
-- Migration: 0000_maths_initial_schema.sql

-- ================================================
-- TABLES
-- ================================================

-- Modified babies table (removed sleep/feeding fields)
CREATE TABLE public.babies (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  name TEXT NOT NULL,
  birthdate TIMESTAMPTZ NOT NULL,
  gender TEXT NOT NULL,
  current_maths_level TEXT DEFAULT 'pre-number',  -- pre-number, early-counting, counting, early-arithmetic
  profile_photo_url TEXT,
  created_at TIMESTAMPTZ DEFAULT now() NOT NULL,
  updated_at TIMESTAMPTZ DEFAULT now() NOT NULL
);

-- Maths milestones (core content)
CREATE TABLE public.maths_milestones (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  category TEXT NOT NULL,  -- number-sense, counting, patterns, shapes, spatial, measurement, sorting, operations
  title TEXT NOT NULL,
  description TEXT NOT NULL,
  age_months_min INTEGER NOT NULL,
  age_months_max INTEGER NOT NULL,
  difficulty_level INTEGER DEFAULT 1 CHECK (difficulty_level BETWEEN 1 AND 5),
  activities JSONB NOT NULL,  -- Array of activity objects
  indicators JSONB,  -- Signs child has mastered this milestone
  next_steps JSONB,  -- What comes after this milestone
  sort_order INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT now() NOT NULL,
  updated_at TIMESTAMPTZ DEFAULT now() NOT NULL
);

-- Activity completion logs
CREATE TABLE public.activity_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  baby_id UUID REFERENCES public.babies(id) ON DELETE CASCADE NOT NULL,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  milestone_id UUID REFERENCES public.maths_milestones(id),
  activity_title TEXT NOT NULL,
  activity_category TEXT NOT NULL,
  completed_at TIMESTAMPTZ DEFAULT now() NOT NULL,
  duration_minutes INTEGER CHECK (duration_minutes > 0),
  engagement_level INTEGER CHECK (engagement_level BETWEEN 1 AND 5),
  notes TEXT,
  media_urls JSONB,  -- Array of photo/video URLs
  created_at TIMESTAMPTZ DEFAULT now() NOT NULL
);

-- Milestone completions
CREATE TABLE public.milestone_completions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  baby_id UUID REFERENCES public.babies(id) ON DELETE CASCADE NOT NULL,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  milestone_id UUID REFERENCES public.maths_milestones(id) ON DELETE CASCADE NOT NULL,
  completed_at TIMESTAMPTZ DEFAULT now() NOT NULL,
  confidence_level INTEGER DEFAULT 3 CHECK (confidence_level BETWEEN 1 AND 5),
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT now() NOT NULL,
  UNIQUE(baby_id, milestone_id)
);

-- Daily activity suggestions (AI-generated)
CREATE TABLE public.daily_activity_suggestions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  baby_id UUID REFERENCES public.babies(id) ON DELETE CASCADE NOT NULL,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  activity_date DATE NOT NULL,
  suggested_activities JSONB NOT NULL,  -- Array of 3-5 activities
  generated_at TIMESTAMPTZ DEFAULT now() NOT NULL,
  UNIQUE(baby_id, activity_date)
);

-- Weekly progress summaries
CREATE TABLE public.weekly_progress_summaries (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  baby_id UUID REFERENCES public.babies(id) ON DELETE CASCADE NOT NULL,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  week_start_date DATE NOT NULL,
  week_end_date DATE NOT NULL,
  activities_completed INTEGER DEFAULT 0,
  new_milestones_achieved INTEGER DEFAULT 0,
  total_engagement_minutes INTEGER DEFAULT 0,
  average_engagement_level DECIMAL(3,2),
  top_categories JSONB,  -- Which categories were most practiced
  ai_summary TEXT,  -- AI-generated weekly summary
  created_at TIMESTAMPTZ DEFAULT now() NOT NULL,
  UNIQUE(baby_id, week_start_date)
);

-- User streaks
CREATE TABLE public.user_streaks (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  baby_id UUID REFERENCES public.babies(id) ON DELETE CASCADE NOT NULL,
  current_streak INTEGER DEFAULT 0,
  longest_streak INTEGER DEFAULT 0,
  last_activity_date DATE,
  created_at TIMESTAMPTZ DEFAULT now() NOT NULL,
  updated_at TIMESTAMPTZ DEFAULT now() NOT NULL,
  UNIQUE(user_id, baby_id)
);

-- ================================================
-- INDEXES FOR PERFORMANCE
-- ================================================

CREATE INDEX idx_babies_user_id ON public.babies(user_id);
CREATE INDEX idx_milestones_category ON public.maths_milestones(category);
CREATE INDEX idx_milestones_age_range ON public.maths_milestones(age_months_min, age_months_max);
CREATE INDEX idx_activity_logs_baby_id ON public.activity_logs(baby_id);
CREATE INDEX idx_activity_logs_completed_at ON public.activity_logs(completed_at);
CREATE INDEX idx_activity_logs_category ON public.activity_logs(activity_category);
CREATE INDEX idx_milestone_completions_baby_id ON public.milestone_completions(baby_id);
CREATE INDEX idx_daily_suggestions_baby_date ON public.daily_activity_suggestions(baby_id, activity_date);
CREATE INDEX idx_weekly_summaries_baby_week ON public.weekly_progress_summaries(baby_id, week_start_date);
CREATE INDEX idx_user_streaks_user_baby ON public.user_streaks(user_id, baby_id);

-- ================================================
-- ROW LEVEL SECURITY (RLS)
-- ================================================

-- Enable RLS on all tables
ALTER TABLE public.babies ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.maths_milestones ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.activity_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.milestone_completions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.daily_activity_suggestions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.weekly_progress_summaries ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_streaks ENABLE ROW LEVEL SECURITY;

-- Babies: Users can only access their own babies
CREATE POLICY "Users can manage their own babies"
  ON public.babies
  FOR ALL
  USING (auth.uid() = user_id);

-- Milestones: Public read access, admin write
CREATE POLICY "Anyone can read milestones"
  ON public.maths_milestones
  FOR SELECT
  USING (true);

CREATE POLICY "Only admins can modify milestones"
  ON public.maths_milestones
  FOR ALL
  USING (auth.jwt() ->> 'role' = 'admin');

-- Activity logs: Users can only access their own
CREATE POLICY "Users can manage their own activity logs"
  ON public.activity_logs
  FOR ALL
  USING (auth.uid() = user_id);

-- Milestone completions: Users can only access their own
CREATE POLICY "Users can manage their own milestone completions"
  ON public.milestone_completions
  FOR ALL
  USING (auth.uid() = user_id);

-- Daily suggestions: Users can only access their own
CREATE POLICY "Users can manage their own daily suggestions"
  ON public.daily_activity_suggestions
  FOR ALL
  USING (auth.uid() = user_id);

-- Weekly summaries: Users can only access their own
CREATE POLICY "Users can manage their own weekly summaries"
  ON public.weekly_progress_summaries
  FOR ALL
  USING (auth.uid() = user_id);

-- User streaks: Users can only access their own
CREATE POLICY "Users can manage their own streaks"
  ON public.user_streaks
  FOR ALL
  USING (auth.uid() = user_id);

-- ================================================
-- FUNCTIONS
-- ================================================

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ language 'plpgsql';

-- Triggers for updated_at
CREATE TRIGGER update_babies_updated_at
  BEFORE UPDATE ON public.babies
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_milestones_updated_at
  BEFORE UPDATE ON public.maths_milestones
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_streaks_updated_at
  BEFORE UPDATE ON public.user_streaks
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Function to get age-appropriate milestones
CREATE OR REPLACE FUNCTION get_milestones_for_age(child_age_months INTEGER)
RETURNS SETOF public.maths_milestones AS $$
BEGIN
  RETURN QUERY
  SELECT *
  FROM public.maths_milestones
  WHERE age_months_min <= child_age_months
    AND age_months_max >= child_age_months
  ORDER BY category, sort_order, age_months_min;
END;
$$ LANGUAGE plpgsql;

-- Function to update streak
CREATE OR REPLACE FUNCTION update_user_streak(p_user_id UUID, p_baby_id UUID)
RETURNS void AS $$
DECLARE
  v_last_activity_date DATE;
  v_current_streak INTEGER;
  v_longest_streak INTEGER;
  v_today DATE := CURRENT_DATE;
BEGIN
  -- Get current streak data
  SELECT last_activity_date, current_streak, longest_streak
  INTO v_last_activity_date, v_current_streak, v_longest_streak
  FROM public.user_streaks
  WHERE user_id = p_user_id AND baby_id = p_baby_id;

  -- If no streak record exists, create one
  IF NOT FOUND THEN
    INSERT INTO public.user_streaks (user_id, baby_id, current_streak, longest_streak, last_activity_date)
    VALUES (p_user_id, p_baby_id, 1, 1, v_today);
    RETURN;
  END IF;

  -- If activity is today, no change
  IF v_last_activity_date = v_today THEN
    RETURN;
  END IF;

  -- If activity was yesterday, increment streak
  IF v_last_activity_date = v_today - INTERVAL '1 day' THEN
    v_current_streak := v_current_streak + 1;
    IF v_current_streak > v_longest_streak THEN
      v_longest_streak := v_current_streak;
    END IF;
  ELSE
    -- Streak broken, reset to 1
    v_current_streak := 1;
  END IF;

  -- Update streak record
  UPDATE public.user_streaks
  SET current_streak = v_current_streak,
      longest_streak = v_longest_streak,
      last_activity_date = v_today,
      updated_at = now()
  WHERE user_id = p_user_id AND baby_id = p_baby_id;
END;
$$ LANGUAGE plpgsql;
