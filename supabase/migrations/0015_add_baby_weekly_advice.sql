-- Weekly advice plan per baby (overwrites on update)
create table if not exists public.baby_weekly_advice (
  baby_id uuid primary key references public.babies(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  plan jsonb not null,
  model_version text not null default 'gemini-2.5-pro',
  generated_at timestamptz not null default now(),
  valid_from date,
  valid_to date,
  prompt text,
  response_raw jsonb
);

-- Helpful indexes
create index if not exists idx_baby_weekly_advice_user on public.baby_weekly_advice(user_id);
create index if not exists idx_baby_weekly_advice_generated_at on public.baby_weekly_advice(generated_at desc);

-- RLS
alter table public.baby_weekly_advice enable row level security;

-- Policies (idempotent pattern)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename = 'baby_weekly_advice'
      AND policyname = 'Allow users to manage their own weekly advice'
  ) THEN
    CREATE POLICY "Allow users to manage their own weekly advice"
      ON public.baby_weekly_advice FOR ALL USING (auth.uid() = user_id);
  END IF;
END $$;

COMMENT ON TABLE public.baby_weekly_advice IS 'Stores a single weekly Gemini-generated advice plan per baby (overwrites on update).';
