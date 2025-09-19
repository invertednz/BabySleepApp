-- User-level preferences for global onboarding steps
create table if not exists public.user_preferences (
  user_id uuid primary key references auth.users(id) on delete cascade,
  parenting_styles jsonb not null default '[]'::jsonb,
  nurture_priorities jsonb not null default '[]'::jsonb,
  goals jsonb not null default '[]'::jsonb,
  updated_at timestamptz not null default now()
);

-- Per-baby activities (loves/hates)
create table if not exists public.baby_activities (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  baby_id uuid not null references public.babies(id) on delete cascade,
  loves jsonb not null default '[]'::jsonb,
  hates jsonb not null default '[]'::jsonb,
  updated_at timestamptz not null default now()
);

-- Index for quick lookup
create index if not exists idx_baby_activities_user_baby on public.baby_activities(user_id, baby_id);

-- Enable RLS
alter table public.user_preferences enable row level security;
alter table public.baby_activities enable row level security;

-- Policies
create policy if not exists "Allow users to manage their own preferences"
  on public.user_preferences for all using (auth.uid() = user_id);

create policy if not exists "Allow users to manage their own baby activities"
  on public.baby_activities for all using (auth.uid() = user_id);
