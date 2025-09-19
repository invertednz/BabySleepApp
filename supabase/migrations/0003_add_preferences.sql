-- Add tables for per-baby preferences
create table if not exists public.baby_nurture_priorities (
  baby_id uuid references public.babies(id) on delete cascade not null,
  user_id uuid references auth.users(id) on delete cascade not null,
  priorities jsonb not null default '[]'::jsonb,
  updated_at timestamptz default now() not null,
  primary key (baby_id, user_id)
);

create table if not exists public.baby_short_term_focus (
  baby_id uuid references public.babies(id) on delete cascade not null,
  user_id uuid references auth.users(id) on delete cascade not null,
  focus jsonb not null default '[]'::jsonb,
  timeframe_start timestamptz,
  timeframe_end timestamptz,
  updated_at timestamptz default now() not null,
  primary key (baby_id, user_id)
);

-- Enable RLS
alter table public.baby_nurture_priorities enable row level security;
alter table public.baby_short_term_focus enable row level security;

-- Policies
create policy if not exists "Allow users to manage their own nurture priorities"
  on public.baby_nurture_priorities for all using (auth.uid() = user_id);

create policy if not exists "Allow users to manage their own short term focus"
  on public.baby_short_term_focus for all using (auth.uid() = user_id);
