-- Update v_baby_milestone_assessment to include unachieved milestones
-- with projected percentiles for upcoming and delayed milestones.

-- Drop the old view
drop view if exists public.v_baby_milestone_assessment cascade;

-- Recreate with expanded logic
create or replace view public.v_baby_milestone_assessment as
with baby_milestone_pairs as (
  -- Cross join all babies with all milestones to get every possible combination
  -- Filter: only include milestones where end date is after current age OR within 4 months before current age
  select
    b.id as baby_id,
    b.birthdate,
    b.completed_milestones,
    m.id as milestone_id,
    m.category,
    m.title,
    m.first_noticed_weeks as s,
    m.worry_after_weeks as e_raw,
    case when m.worry_after_weeks < 0 then m.first_noticed_weeks + 24 else m.worry_after_weeks end as e,
    extract(epoch from (now() - b.birthdate))/604800.0 as now_weeks
  from public.babies b
  cross join public.milestones m
  where 
    -- Effective end date (e) must be >= (baby's current age - 4 months)
    -- 4 months ≈ 17.4 weeks (4 * 30.44 days / 7)
    case when m.worry_after_weeks < 0 then m.first_noticed_weeks + 24 else m.worry_after_weeks end 
      >= extract(epoch from (now() - b.birthdate))/604800.0 - 17.4
),
achievement_status as (
  select
    bmp.*,
    bm.id as baby_milestone_id,
    bm.achieved_at,
    bm.source,
    case when bm.achieved_at is not null then extract(epoch from (bm.achieved_at - bmp.birthdate))/604800.0 end as achieved_weeks,
    -- Check if completed via baby_milestones table or completed_milestones array
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
  -- Status reflecting where the baby is now
  case
    when source = 'onboarding' and achieved_weeks is null then 'discounted'
    when is_completed and achieved_weeks is not null and achieved_weeks <= s then 'ahead'
    when is_completed and achieved_weeks is not null and achieved_weeks > s and achieved_weeks < e then 'on_track'
    when is_completed and achieved_weeks is not null and achieved_weeks >= e then 'behind'
    when not is_completed and now_weeks >= s and now_weeks < e then 'upcoming'
    when not is_completed and now_weeks >= e then 'delayed'
    else 'delayed'
  end as status,
  -- Percentile calculation
  case
    -- Achieved milestones: use actual achieved_weeks
    when is_completed and achieved_weeks is not null then (
      case
        when achieved_weeks <= s then
          least(99.0, 90.0 + 10.0 * greatest(0.0, (s - achieved_weeks) / nullif(0.5 * (e - s), 0)))
        when achieved_weeks > s and achieved_weeks < e then
          greatest(1.0, 90.0 - 80.0 * (achieved_weeks - s) / nullif((e - s), 0))
        else -- achieved_weeks >= e
          greatest(1.0, 10.0 - 9.0 * greatest(0.0, (achieved_weeks - e) / nullif(0.5 * (e - s), 0)))
      end
    )
    -- Delayed milestones: percentile = 0
    when not is_completed and now_weeks >= e then 0.0
    -- Upcoming milestones: project achievement at current_age + 10 days (10/7 weeks ~= 1.43 weeks)
    when not is_completed and now_weeks >= s and now_weeks < e then (
      case
        when (now_weeks + (10.0/7.0)) <= s then
          least(99.0, 90.0 + 10.0 * greatest(0.0, (s - (now_weeks + (10.0/7.0))) / nullif(0.5 * (e - s), 0)))
        when (now_weeks + (10.0/7.0)) > s and (now_weeks + (10.0/7.0)) < e then
          greatest(1.0, 90.0 - 80.0 * ((now_weeks + (10.0/7.0)) - s) / nullif((e - s), 0))
        else -- (now_weeks + (10.0/7.0)) >= e
          greatest(1.0, 10.0 - 9.0 * greatest(0.0, ((now_weeks + (10.0/7.0)) - e) / nullif(0.5 * (e - s), 0)))
      end
    )
    -- Fallback (treated as delayed)
    else 0.0
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
