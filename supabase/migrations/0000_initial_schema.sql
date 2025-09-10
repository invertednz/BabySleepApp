-- Create the 'babies' table
CREATE TABLE public.babies (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  name TEXT NOT NULL,
  birthdate TIMESTAMPTZ NOT NULL,
  gender TEXT NOT NULL,
  weight_kg DOUBLE PRECISION,
  height_cm DOUBLE PRECISION,
  head_circumference_cm DOUBLE PRECISION,
  chest_circumference_cm DOUBLE PRECISION,
  completed_milestones JSONB,
  created_at TIMESTAMPTZ DEFAULT now() NOT NULL,
  updated_at TIMESTAMPTZ
);

-- Create the 'concerns' table
CREATE TABLE public.concerns (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  baby_id UUID REFERENCES public.babies(id) ON DELETE CASCADE NOT NULL,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  text TEXT NOT NULL,
  is_resolved BOOLEAN DEFAULT false NOT NULL,
  created_at TIMESTAMPTZ DEFAULT now() NOT NULL,
  resolved_at TIMESTAMPTZ
);

-- Create the 'measurements' table
CREATE TABLE public.measurements (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    baby_id UUID REFERENCES public.babies(id) ON DELETE CASCADE NOT NULL,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    weight_kg DOUBLE PRECISION,
    height_cm DOUBLE PRECISION,
    head_circumference_cm DOUBLE PRECISION,
    chest_circumference_cm DOUBLE PRECISION,
    date TIMESTAMPTZ DEFAULT now() NOT NULL
);

-- Create the 'sleep_schedules' table
CREATE TABLE public.sleep_schedules (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    baby_id UUID REFERENCES public.babies(id) ON DELETE CASCADE NOT NULL,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    bedtime TEXT,
    wake_time TEXT,
    naps JSONB,
    date TIMESTAMPTZ DEFAULT now() NOT NULL
);

-- Create the 'feeding_preferences' table
CREATE TABLE public.feeding_preferences (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    baby_id UUID REFERENCES public.babies(id) ON DELETE CASCADE NOT NULL,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    feeding_method TEXT,
    feedings_per_day INTEGER,
    amount_per_feeding DOUBLE PRECISION,
    feeding_duration INTEGER,
    date TIMESTAMPTZ DEFAULT now() NOT NULL
);

-- Create the 'diaper_preferences' table
CREATE TABLE public.diaper_preferences (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    baby_id UUID REFERENCES public.babies(id) ON DELETE CASCADE NOT NULL,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    wet_diapers_per_day INTEGER,
    dirty_diapers_per_day INTEGER,
    stool_color TEXT,
    notes TEXT,
    date TIMESTAMPTZ DEFAULT now() NOT NULL
);

-- Enable Row Level Security (RLS) for all tables
ALTER TABLE public.babies ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.concerns ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.measurements ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.sleep_schedules ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.feeding_preferences ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.diaper_preferences ENABLE ROW LEVEL SECURITY;

-- Create RLS policies to ensure users can only access their own data
CREATE POLICY "Allow users to manage their own babies" ON public.babies
  FOR ALL USING (auth.uid() = user_id);

CREATE POLICY "Allow users to manage their own concerns" ON public.concerns
  FOR ALL USING (auth.uid() = user_id);

CREATE POLICY "Allow users to manage their own measurements" ON public.measurements
  FOR ALL USING (auth.uid() = user_id);

CREATE POLICY "Allow users to manage their own sleep schedules" ON public.sleep_schedules
  FOR ALL USING (auth.uid() = user_id);

CREATE POLICY "Allow users to manage their own feeding preferences" ON public.feeding_preferences
  FOR ALL USING (auth.uid() = user_id);

CREATE POLICY "Allow users to manage their own diaper preferences" ON public.diaper_preferences
  FOR ALL USING (auth.uid() = user_id);
