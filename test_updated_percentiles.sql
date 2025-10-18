-- Test updated percentile calculation for baby 79e727b8-c5e9-486e-8196-87fedc1bb32b
-- Run this AFTER applying migration 0014_include_unachieved_in_percentiles.sql

-- Note: Only milestones with end date >= (current age - 4 months) are included

-- Social & Emotional milestones with projected percentiles
SELECT
  bma.title AS milestone_title,
  bma.status,
  bma.is_completed,
  ROUND(bma.window_start_weeks::numeric, 1) AS start_weeks,
  ROUND(bma.window_end_weeks::numeric, 1) AS end_weeks,
  ROUND(bma.now_weeks::numeric, 1) AS baby_age_weeks,
  ROUND(bma.achieved_weeks::numeric, 2) AS achieved_weeks,
  ROUND(bma.percentile::numeric, 1) AS percentile,
  CASE 
    WHEN bma.is_completed AND bma.achieved_weeks IS NOT NULL THEN 'Actual achievement'
    WHEN bma.status = 'delayed' THEN 'Delayed (percentile = 0)'
    WHEN bma.status = 'upcoming' THEN 'Projected (age + 10 days)'
    WHEN bma.status = 'not_yet' THEN 'Not yet in window'
    ELSE bma.status
  END AS calculation_method,
  bma.source
FROM public.v_baby_milestone_assessment bma
WHERE bma.baby_id = '79e727b8-c5e9-486e-8196-87fedc1bb32b'
  AND bma.category = 'Social'
  AND NOT bma.discounted
ORDER BY 
  CASE bma.status
    WHEN 'ahead' THEN 1
    WHEN 'on_track' THEN 2
    WHEN 'behind' THEN 3
    WHEN 'upcoming' THEN 4
    WHEN 'delayed' THEN 5
    WHEN 'not_yet' THEN 6
    ELSE 7
  END,
  bma.window_start_weeks,
  bma.title;

-- Summary: count by status
SELECT
  status,
  COUNT(*) AS milestone_count,
  ROUND(AVG(percentile)::numeric, 1) AS avg_percentile
FROM public.v_baby_milestone_assessment
WHERE baby_id = '79e727b8-c5e9-486e-8196-87fedc1bb32b'
  AND category = 'Social'
  AND NOT discounted
GROUP BY status
ORDER BY 
  CASE status
    WHEN 'ahead' THEN 1
    WHEN 'on_track' THEN 2
    WHEN 'behind' THEN 3
    WHEN 'upcoming' THEN 4
    WHEN 'delayed' THEN 5
    WHEN 'not_yet' THEN 6
    ELSE 7
  END;

-- Overall Social & Emotional percentile
SELECT
  d.domain,
  ROUND(d.avg_percentile::numeric, 1) AS avg_percentile,
  d.achieved_count AS milestones_with_percentile,
  d.total_milestones,
  d.confidence
FROM public.v_baby_domain_scores d
WHERE d.baby_id = '79e727b8-c5e9-486e-8196-87fedc1bb32b'
  AND d.domain = 'Social';

-- Show example of projected calculation for one upcoming milestone
SELECT
  bma.title,
  ROUND(bma.now_weeks::numeric, 2) AS current_age_weeks,
  ROUND((bma.now_weeks + (10.0/7.0))::numeric, 2) AS projected_achievement_weeks,
  ROUND(bma.window_start_weeks::numeric, 1) AS window_start,
  ROUND(bma.window_end_weeks::numeric, 1) AS window_end,
  ROUND(bma.percentile::numeric, 1) AS projected_percentile,
  '10 days = ' || ROUND((10.0/7.0)::numeric, 2) || ' weeks' AS note
FROM public.v_baby_milestone_assessment bma
WHERE bma.baby_id = '79e727b8-c5e9-486e-8196-87fedc1bb32b'
  AND bma.category = 'Social'
  AND bma.status = 'upcoming'
  AND NOT bma.discounted
LIMIT 1;

-- Show milestones excluded by the 4-month lookback filter
-- (milestones where end_date < baby_age - 4 months)
WITH baby_age AS (
  SELECT 
    '79e727b8-c5e9-486e-8196-87fedc1bb32b'::uuid AS baby_id,
    EXTRACT(EPOCH FROM (NOW() - birthdate)) / 604800.0 AS age_weeks
  FROM public.babies 
  WHERE id = '79e727b8-c5e9-486e-8196-87fedc1bb32b'
)
SELECT
  m.title AS excluded_milestone,
  m.category,
  ROUND(m.first_noticed_weeks::numeric, 1) AS start_weeks,
  ROUND(
    CASE 
      WHEN m.worry_after_weeks < 0 THEN m.first_noticed_weeks + 24 
      ELSE m.worry_after_weeks 
    END::numeric, 1
  ) AS end_weeks,
  ROUND(ba.age_weeks::numeric, 1) AS baby_age_weeks,
  ROUND(
    (ba.age_weeks - 
      CASE 
        WHEN m.worry_after_weeks < 0 THEN m.first_noticed_weeks + 24 
        ELSE m.worry_after_weeks 
      END
    )::numeric, 1
  ) AS weeks_since_end,
  '4 months = 17.4 weeks' AS lookback_window
FROM public.milestones m
CROSS JOIN baby_age ba
WHERE m.category = 'Social'
  AND CASE 
    WHEN m.worry_after_weeks < 0 THEN m.first_noticed_weeks + 24 
    ELSE m.worry_after_weeks 
  END < ba.age_weeks - 17.4
ORDER BY end_weeks DESC;
