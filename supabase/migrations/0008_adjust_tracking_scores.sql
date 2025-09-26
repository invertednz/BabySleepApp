-- Adjust tracking views to reflect "where they are now" and only discount
-- onboarding ticks when they are truly outside the window with a date
-- that proves the timing is out-of-window. If onboarding has no date:
--   - If now is within [s,e], treat as on_track with neutral percentile (50).
--   - If now < s, it's upcoming (no percentile).
--   - If now > e, mark as overdue (no percentile) so we don't inflate scores
--     based on unknown past timing.

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
  -- Discount only when onboarding has an explicit date outside the window
  (source = 'onboarding' and achieved_weeks is not null and (achieved_weeks < s or achieved_weeks > e)) as discounted,
  -- Status reflecting where the baby is now
  case
    when source = 'onboarding' and achieved_weeks is null then
      case
        when now_weeks < s then 'upcoming'
        when now_weeks >= s and now_weeks < e then 'on_track'
        else 'overdue' -- now beyond the window, no date to verify when it happened
      end
    when source = 'onboarding' and achieved_weeks is not null and (achieved_weeks < s or achieved_weeks > e) then 'discounted'
    when achieved_weeks is not null and achieved_weeks <= s then 'ahead'
    when achieved_weeks is not null and achieved_weeks > s and achieved_weeks < e then 'on_track'
    when achieved_weeks is not null and achieved_weeks >= e then 'behind'
    when achieved_weeks is null and now_weeks < s then 'upcoming'
    when achieved_weeks is null and now_weeks >= s and now_weeks < e then 'in_window'
    when achieved_weeks is null and now_weeks >= e then 'overdue'
    else 'unknown'
  end as status,
  -- Percentile mapping:
  --  * For onboarding without date but now within window -> neutral 50th percentile
  --  * For achieved with date (and not discounted) -> computed percentile
  --  * Otherwise -> null
  case
    when source = 'onboarding' and achieved_weeks is null and now_weeks >= s and now_weeks < e then 50.0
    when not (source = 'onboarding' and achieved_weeks is not null and (achieved_weeks < s or achieved_weeks > e))
         and achieved_weeks is not null then (
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

-- Domain and overall views remain the same, but we recreate them to ensure dependency correctness
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

create or replace view public.v_baby_overall_score as
select
  d.baby_id,
  avg(d.avg_percentile) filter (where d.avg_percentile is not null) as overall_percentile,
  jsonb_object_agg(d.domain, to_jsonb(d) - 'baby_id') as domains
from public.v_baby_domain_scores d
group by d.baby_id;
