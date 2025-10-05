-- Add plan tier tracking to user preferences
alter table public.user_preferences
  add column if not exists plan_tier text not null default 'free';

alter table public.user_preferences
  add column if not exists is_on_trial boolean not null default false;

alter table public.user_preferences
  add column if not exists plan_started_at timestamptz;

-- Optional: future billing metadata
-- alter table public.user_preferences
--   add column if not exists plan_renews_at timestamptz;
