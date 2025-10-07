-- Create the 'milestone_moments' table
CREATE TABLE public.milestone_moments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  baby_id UUID REFERENCES public.babies(id) ON DELETE CASCADE NOT NULL,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  title TEXT NOT NULL,
  description TEXT,
  captured_at TIMESTAMPTZ DEFAULT now() NOT NULL,
  shareability INTEGER DEFAULT 0,
  priority INTEGER DEFAULT 0,
  location TEXT,
  share_context TEXT,
  photo_url TEXT,
  stickers JSONB DEFAULT '[]'::jsonb,
  highlights JSONB DEFAULT '[]'::jsonb,
  delights JSONB DEFAULT '[]'::jsonb,
  is_anniversary BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT now() NOT NULL,
  updated_at TIMESTAMPTZ DEFAULT now() NOT NULL
);

-- Enable Row Level Security (RLS)
ALTER TABLE public.milestone_moments ENABLE ROW LEVEL SECURITY;

-- Create RLS policies
CREATE POLICY "Allow users to manage their own milestone moments" ON public.milestone_moments
  FOR ALL USING (auth.uid() = user_id);

-- Create index for faster queries
CREATE INDEX idx_milestone_moments_baby_id ON public.milestone_moments(baby_id);
CREATE INDEX idx_milestone_moments_captured_at ON public.milestone_moments(captured_at DESC);

-- Create updated_at trigger
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_milestone_moments_updated_at BEFORE UPDATE
    ON public.milestone_moments FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();
