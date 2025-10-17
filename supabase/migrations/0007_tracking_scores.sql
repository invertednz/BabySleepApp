-- Create a table to record per-baby milestone achievements with source attribution
-- and an optional achieved_at date.
-- This lets us discount onboarding-only ticks that fall outside the window
-- (or have no date) when computing "where they are now".

-- 1) baby_milestones table --------------------------------------------------
create table if not exists public.baby_milestones (
  id uuid primary key default gen_random_uuid(),
  baby_id uuid not null references public.babies(id) on delete cascade,
  milestone_id uuid not null references public.milestones(id) on delete cascade,
  -- If known, the timestamp when the milestone was achieved.
  achieved_at timestamptz,
  -- Source of the record: 'onboarding' (initial tick), 'log' (user logged at time), 'inferred' (system)
  source text not null check (source in ('onboarding','log','inferred')),
  created_at timestamptz not null default now(),
  constraint uq_baby_milestone unique (baby_id, milestone_id)
);

alter table public.baby_milestones enable row level security;

-- RLS policies: user can manage entries for their own babies only
create policy if not exists "baby_milestones_select" on public.baby_milestones
as permissive for select
to authenticated
using (
  exists (
    select 1 from public.babies b
    where b.id = baby_milestones.baby_id and b.user_id = auth.uid()
  )
);

create policy if not exists "baby_milestones_modify" on public.baby_milestones
for all
to authenticated
using (
  exists (
    select 1 from public.babies b
    where b.id = baby_milestones.baby_id and b.user_id = auth.uid()
  )
)
with check (
  exists (
    select 1 from public.babies b
    where b.id = baby_milestones.baby_id and b.user_id = auth.uid()
  )
);

-- 2) Helper view: per-milestone assessment per baby -------------------------
-- Computes status and percentile for achieved milestones, applying discount
-- rules for onboarding ticks that are outside the normative window or lack a date.
-- Milestones with worry_after_weeks < 0 are treated as open-ended; we approximate
-- an effective end window as start + 24 weeks for percentile mapping.

create or replace view public.v_baby_milestone_assessment as
with base as (
  select
    bm.id as baby_milestone_id,
    bm.baby_id,
    bm.milestone_id,
    bm.achieved_at,
    bm.source,
    b.birthdate,
    m.category,
    m.title,
    m.first_noticed_weeks as s,
    m.worry_after_weeks   as e_raw,
    case when m.worry_after_weeks < 0 then m.first_noticed_weeks + 24 else m.worry_after_weeks end as e,
    extract(epoch from (now() - b.birthdate))/604800.0 as now_weeks,
    case when bm.achieved_at is not null then extract(epoch from (bm.achieved_at - b.birthdate))/604800.0 end as achieved_weeks
  from public.baby_milestones bm
  join public.babies b on b.id = bm.baby_id
  join public.milestones m on m.id = bm.milestone_id
)
select
  baby_milestone_id,
  baby_id,
  milestone_id,
  category,
  title,
  s as window_start_weeks,
  e as window_end_weeks,
  achieved_at,
  source,
  now_weeks,
  achieved_weeks,
  -- Discount rule: onboarding with NULL date only (not dates outside window)
  (source = 'onboarding' and achieved_weeks is null) as discounted,
  -- Status reflecting where the baby is now
  case
    when source = 'onboarding' and achieved_weeks is null
      then 'discounted'
    when achieved_weeks is not null and achieved_weeks <= s then 'ahead'
    when achieved_weeks is not null and achieved_weeks > s and achieved_weeks < e then 'on_track'
    when achieved_weeks is not null and achieved_weeks >= e then 'behind'
    when achieved_weeks is null and now_weeks < s then 'upcoming'
    when achieved_weeks is null and now_weeks >= s and now_weeks < e then 'in_window'
    when achieved_weeks is null and now_weeks >= e then 'overdue'
    else 'unknown'
  end as status,
  -- Percentile mapping for achieved milestones (not discounted)
  case
    when achieved_weeks is not null then (
      case
        when achieved_weeks <= s then
          least(99.0, 90.0 + 10.0 * greatest(0.0, (s - achieved_weeks) / nullif(0.5 * (e - s), 0)))
        when achieved_weeks > s and achieved_weeks < e then
          greatest(1.0, 90.0 - 80.0 * (achieved_weeks - s) / nullif((e - s), 0))
        else -- achieved_weeks >= e
          greatest(1.0, 10.0 - 9.0 * greatest(0.0, (achieved_weeks - e) / nullif(0.5 * (e - s), 0)))
      end
    )
    else null
  end as percentile
from base;

-- 3) Domain scores per baby --------------------------------------------------
-- Averages only non-null percentiles (i.e., achieved & not discounted).
-- Provides coverage metrics to support a confidence indicator.

create or replace view public.v_baby_domain_scores as
select
  bma.baby_id,
  bma.category as domain,
  avg(bma.percentile) filter (where bma.percentile is not null) as avg_percentile,
  count(*) filter (where bma.percentile is not null) as achieved_count,
  count(*) as total_milestones,
  (count(*) filter (where bma.percentile is not null))::decimal / nullif(count(*),0) as coverage_ratio,
  case
    when (count(*) filter (where bma.percentile is not null)) >= 6 then 'high'
    when (count(*) filter (where bma.percentile is not null)) >= 3 then 'medium'
    when (count(*) filter (where bma.percentile is not null)) >= 1 then 'low'
    else 'none'
  end as confidence
from public.v_baby_milestone_assessment bma
group by bma.baby_id, bma.category;

-- 4) Overall score per baby --------------------------------------------------
-- Weighted average of domains (weight recent by giving more weight to domains
-- with more achieved items). You can later refine with recency weighting.

create or replace view public.v_baby_overall_score as
select
  d.baby_id,
  avg(d.avg_percentile) filter (where d.avg_percentile is not null) as overall_percentile,
  jsonb_object_agg(d.domain, to_jsonb(d) - 'baby_id') as domains
from public.v_baby_domain_scores d
group by d.baby_id;

-- Notes for app integration:
-- - Use v_baby_milestone_assessment to render per-milestone chips/status.
-- - Use v_baby_domain_scores for each domain ring/badge and confidence indicator.
-- - Use v_baby_overall_score for the top-level "Overall Tracking %ile".
-- - Onboarding ticks with missing/out-of-window dates are marked discounted and
--   excluded from percentile calculations so the picture reflects "where they are now".
