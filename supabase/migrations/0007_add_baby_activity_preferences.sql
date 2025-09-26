-- Convert baby_activities to track four JSONB maps (label -> ISO8601 timestamp)
-- Add neutral and skipped; convert loves/hates if currently arrays; set defaults to '{}'

begin;

-- Ensure table exists
create table if not exists public.baby_activities (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  baby_id uuid not null references public.babies(id) on delete cascade,
  loves jsonb not null default '{}'::jsonb,
  hates jsonb not null default '{}'::jsonb,
  neutral jsonb not null default '{}'::jsonb,
  skipped jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default now()
);

-- Add missing columns for existing deployments
alter table public.baby_activities
  alter column loves set default '{}'::jsonb,
  alter column hates set default '{}'::jsonb;

alter table public.baby_activities
  add column if not exists neutral jsonb not null default '{}'::jsonb;

alter table public.baby_activities
  add column if not exists skipped jsonb not null default '{}'::jsonb;

-- If some rows still use arrays in loves/hates, convert them to maps with current timestamp
-- We use now() for lack of per-item history; app will maintain timestamps going forward
update public.baby_activities
set loves = (
  select coalesce(jsonb_object_agg(val, to_char(now(), 'YYYY-MM-DD"T"HH24:MI:SS.MS"Z"')), '{}'::jsonb)
  from (
    select value::text as val from jsonb_array_elements(loves)
  ) s
)
where jsonb_typeof(loves) = 'array';

update public.baby_activities
set hates = (
  select coalesce(jsonb_object_agg(val, to_char(now(), 'YYYY-MM-DD"T"HH24:MI:SS.MS"Z"')), '{}'::jsonb)
  from (
    select value::text as val from jsonb_array_elements(hates)
  ) s
)
where jsonb_typeof(hates) = 'array';

-- Ensure unique constraint for idempotent upserts
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conname = 'baby_activities_user_baby_key'
      AND conrelid = 'public.baby_activities'::regclass
  ) THEN
    ALTER TABLE public.baby_activities
      ADD CONSTRAINT baby_activities_user_baby_key UNIQUE (user_id, baby_id);
  END IF;
END $$;

-- RLS and policies (idempotent)
alter table public.baby_activities enable row level security;
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename = 'baby_activities'
      AND policyname = 'Allow users to manage their own baby activities'
  ) THEN
    CREATE POLICY "Allow users to manage their own baby activities"
      ON public.baby_activities FOR ALL USING (auth.uid() = user_id);
  END IF;
END $$;

commit;
