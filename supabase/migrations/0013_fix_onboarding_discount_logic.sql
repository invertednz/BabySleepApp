-- Fix onboarding milestone discount logic
-- Only discount onboarding milestones with NULL achieved_at
-- Milestones with valid timestamps should be treated normally (ahead/on_track/behind)

create or replace view public.v_baby_milestone_assessment
with (security_invoker = true)
as
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
