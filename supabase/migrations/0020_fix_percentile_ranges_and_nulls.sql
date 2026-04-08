-- Fix percentile calculation:
-- 1. New ranges: Ahead 80-100, On-track 20-80, Behind 1-20
-- 2. Unachieved milestones get NULL percentile (not 0) so they don't drag down averages
-- 3. Completed-but-no-date milestones get neutral 50th percentile instead of 'delayed' with 0

drop view if exists public.v_baby_overall_score cascade;
drop view if exists public.v_baby_domain_scores cascade;
drop view if exists public.v_baby_milestone_assessment cascade;

create or replace view public.v_baby_milestone_assessment as
with baby_milestone_pairs as (
  select
    b.id as baby_id,
    b.birthdate,
    b.completed_milestones,
    m.id as milestone_id,
    m.category,
    m.title,
    m.first_noticed_weeks as s,
    m.worry_after_weeks as e_raw,
    case when m.worry_after_weeks <= 0 then m.first_noticed_weeks + 24 else m.worry_after_weeks end as e,
    extract(epoch from (now() - b.birthdate))/604800.0 as now_weeks
  from public.babies b
  cross join public.milestones m
  where
    case when m.worry_after_weeks <= 0 then m.first_noticed_weeks + 24 else m.worry_after_weeks end
      >= extract(epoch from (now() - b.birthdate))/604800.0 - 17.4
),
achievement_status as (
  select
    bmp.*,
    bm.id as baby_milestone_id,
    bm.achieved_at,
    bm.source,
    case when bm.achieved_at is not null then extract(epoch from (bm.achieved_at - bmp.birthdate))/604800.0 end as achieved_weeks,
    (
      bm.achieved_at is not null
      or exists (
        select 1
        from unnest(
          coalesce(
            array(select jsonb_array_elements_text(bmp.completed_milestones)),
            array[]::text[]
          )
        ) as token
        where token = bmp.milestone_id::text or token = bmp.title
      )
    ) as is_completed
  from baby_milestone_pairs bmp
  left join public.baby_milestones bm on bm.baby_id = bmp.baby_id and bm.milestone_id = bmp.milestone_id
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
  -- Discount rule: only onboarding completions without an achieved date
  ((coalesce(source, '') = 'onboarding') and achieved_weeks is null and is_completed) as discounted,
  -- Status
  case
    when source = 'onboarding' and achieved_weeks is null then 'discounted'
    when is_completed and achieved_weeks is not null and achieved_weeks <= s then 'ahead'
    when is_completed and achieved_weeks is not null and achieved_weeks > s and achieved_weeks < e then 'on_track'
    when is_completed and achieved_weeks is not null and achieved_weeks >= e then 'behind'
    -- Completed via JSONB array but no achieved_at date: treat as on-track (neutral)
    when is_completed and achieved_weeks is null then 'on_track'
    when not is_completed and now_weeks >= s and now_weeks < e then 'upcoming'
    when not is_completed and now_weeks >= e then 'delayed'
    else 'future'
  end as status,
  -- Percentile calculation (only for achieved milestones)
  case
    -- Achieved with date: use actual timing
    when is_completed and achieved_weeks is not null then (
      case
        -- Ahead: 80 → 100 (achieved before window start)
        when achieved_weeks <= s then
          least(100.0, 80.0 + 20.0 * greatest(0.0, (s - achieved_weeks) / nullif(0.5 * (e - s), 0)))
        -- On-track: 80 → 20 (achieved within window)
        when achieved_weeks > s and achieved_weeks < e then
          80.0 - 60.0 * (achieved_weeks - s) / nullif((e - s), 0)
        -- Behind: 20 → 1 (achieved after window end)
        else
          greatest(1.0, 20.0 - 19.0 * greatest(0.0, (achieved_weeks - e) / nullif(0.5 * (e - s), 0)))
      end
    )
    -- Completed via JSONB array but no date: neutral 50th percentile
    when is_completed and achieved_weeks is null then 50.0
    -- Unachieved milestones: NULL (do not contribute to average)
    else null
  end as percentile,
  is_completed
from achievement_status
where not (not is_completed and now_weeks < s);

-- Recreate dependent views
create or replace view public.v_baby_domain_scores as
select
  bma.baby_id,
  bma.category as domain,
  avg(bma.percentile) filter (where bma.percentile is not null and not bma.discounted) as avg_percentile,
  count(*) filter (where bma.percentile is not null and not bma.discounted) as achieved_count,
  count(*) as total_milestones,
  (count(*) filter (where bma.percentile is not null and not bma.discounted))::decimal / nullif(count(*),0) as coverage_ratio,
  case
    when (count(*) filter (where bma.percentile is not null and not bma.discounted)) >= 6 then 'high'
    when (count(*) filter (where bma.percentile is not null and not bma.discounted)) >= 3 then 'medium'
    when (count(*) filter (where bma.percentile is not null and not bma.discounted)) >= 1 then 'low'
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
