-- Debug query to check milestone completion status for a baby
-- Replace 'YOUR_BABY_ID_HERE' with the actual baby ID

\prompt baby_id 'Enter Baby UUID: '


WITH baby_info AS (
  SELECT 
    id,
    name,
    birthdate,
    EXTRACT(EPOCH FROM (NOW() - birthdate)) / 604800.0 AS age_weeks,
    completed_milestones
  FROM babies 
  WHERE id = :'baby_id'
),
completed_from_array AS (
  SELECT 
    UNNEST(b.completed_milestones) AS milestone_title,
    'babies.completed_milestones' AS source
  FROM baby_info b
),
completed_from_table AS (
  SELECT 
    bm.milestone_id,
    m.title AS milestone_title,
    'baby_milestones (achieved_at)' AS source,
    bm.achieved_at
  FROM baby_milestones bm
  JOIN milestones m ON m.id = bm.milestone_id
  WHERE bm.baby_id = :'baby_id'
    AND bm.achieved_at IS NOT NULL
),
all_completed AS (
  SELECT DISTINCT milestone_title, source FROM completed_from_array
  UNION
  SELECT DISTINCT milestone_title, source FROM completed_from_table
)
SELECT 
  m.id AS milestone_id,
  m.title AS milestone_title,
  m.first_noticed_weeks,
  m.worry_after_weeks,
  CASE 
    WHEN m.worry_after_weeks >= 0 THEN m.worry_after_weeks
    ELSE m.first_noticed_weeks + 24
  END AS effective_end_weeks,
  b.age_weeks,
  CASE 
    WHEN b.age_weeks < m.first_noticed_weeks THEN '❌ Too early'
    WHEN b.age_weeks <= CASE WHEN m.worry_after_weeks >= 0 THEN m.worry_after_weeks ELSE m.first_noticed_weeks + 24 END THEN '⏰ Current window'
    ELSE '⚠️ Past window'
  END AS age_status,
  CASE 
    WHEN EXISTS (SELECT 1 FROM all_completed ac WHERE ac.milestone_title = m.title) THEN '✅ COMPLETED'
    ELSE '❌ UNTICKED'
  END AS completion_status,
  (SELECT STRING_AGG(source, ', ') FROM all_completed ac WHERE ac.milestone_title = m.title) AS completed_sources,
  -- Age group categorization
  CASE 
    WHEN m.first_noticed_weeks >= 0 AND m.first_noticed_weeks <= 8 THEN '0-2 Months'
    WHEN m.first_noticed_weeks >= 9 AND m.first_noticed_weeks <= 17 THEN '3-4 Months'
    WHEN m.first_noticed_weeks >= 18 AND m.first_noticed_weeks <= 26 THEN '5-6 Months'
    WHEN m.first_noticed_weeks >= 27 AND m.first_noticed_weeks <= 39 THEN '7-9 Months'
    WHEN m.first_noticed_weeks >= 40 AND m.first_noticed_weeks <= 52 THEN '10-12 Months'
    WHEN m.first_noticed_weeks >= 53 AND m.first_noticed_weeks <= 78 THEN '13-18 Months'
    WHEN m.first_noticed_weeks >= 79 AND m.first_noticed_weeks <= 104 THEN '19-24 Months'
    WHEN m.first_noticed_weeks >= 105 AND m.first_noticed_weeks <= 156 THEN '2-3 Years'
    WHEN m.first_noticed_weeks >= 157 AND m.first_noticed_weeks <= 208 THEN '3-4 Years'
    WHEN m.first_noticed_weeks >= 209 AND m.first_noticed_weeks <= 260 THEN '4-5 Years'
    ELSE 'Other'
  END AS age_group
FROM milestones m
CROSS JOIN baby_info b
WHERE m.first_noticed_weeks <= b.age_weeks + 52  -- Show milestones up to 1 year ahead
ORDER BY 
  m.first_noticed_weeks,
  m.title;

-- Summary by age group
SELECT 
  CASE 
    WHEN m.first_noticed_weeks >= 0 AND m.first_noticed_weeks <= 8 THEN '0-2 Months'
    WHEN m.first_noticed_weeks >= 9 AND m.first_noticed_weeks <= 17 THEN '3-4 Months'
    WHEN m.first_noticed_weeks >= 18 AND m.first_noticed_weeks <= 26 THEN '5-6 Months'
    WHEN m.first_noticed_weeks >= 27 AND m.first_noticed_weeks <= 39 THEN '7-9 Months'
    WHEN m.first_noticed_weeks >= 40 AND m.first_noticed_weeks <= 52 THEN '10-12 Months'
    WHEN m.first_noticed_weeks >= 53 AND m.first_noticed_weeks <= 78 THEN '13-18 Months'
    WHEN m.first_noticed_weeks >= 79 AND m.first_noticed_weeks <= 104 THEN '19-24 Months'
    WHEN m.first_noticed_weeks >= 105 AND m.first_noticed_weeks <= 156 THEN '2-3 Years'
    WHEN m.first_noticed_weeks >= 157 AND m.first_noticed_weeks <= 208 THEN '3-4 Years'
    ELSE 'Other'
  END AS age_group,
  COUNT(*) AS total_milestones,
  SUM(CASE WHEN EXISTS (
    SELECT 1 FROM baby_milestones bm 
    WHERE bm.baby_id = :'baby_id'
      AND bm.milestone_id = m.id 
      AND bm.achieved_at IS NOT NULL
  ) OR m.title = ANY((SELECT completed_milestones FROM babies WHERE id = :'baby_id')) 
  THEN 1 ELSE 0 END) AS completed_count,
  COUNT(*) - SUM(CASE WHEN EXISTS (
{{ ... }}
    WHERE bm.baby_id = 'YOUR_BABY_ID_HERE' 
      AND bm.milestone_id = m.id 
      AND bm.achieved_at IS NOT NULL
  ) OR m.title = ANY((SELECT completed_milestones FROM babies WHERE id = 'YOUR_BABY_ID_HERE')) 
  THEN 1 ELSE 0 END) AS unticked_count
FROM milestones m
CROSS JOIN (SELECT EXTRACT(EPOCH FROM (NOW() - birthdate)) / 604800.0 AS age_weeks FROM babies WHERE id = 'YOUR_BABY_ID_HERE') b
WHERE m.first_noticed_weeks <= b.age_weeks + 52
GROUP BY age_group
ORDER BY 
  MIN(m.first_noticed_weeks);

-- Quick check: First unticked milestone
WITH baby_info AS (
  SELECT 
    id,
    EXTRACT(EPOCH FROM (NOW() - birthdate)) / 604800.0 AS age_weeks,
    completed_milestones
  FROM babies 
  WHERE id = 'YOUR_BABY_ID_HERE'
)
SELECT 
  m.title,
  CASE 
    WHEN m.first_noticed_weeks >= 0 AND m.first_noticed_weeks <= 8 THEN '0-2 Months'
    WHEN m.first_noticed_weeks >= 9 AND m.first_noticed_weeks <= 17 THEN '3-4 Months'
    WHEN m.first_noticed_weeks >= 18 AND m.first_noticed_weeks <= 26 THEN '5-6 Months'
    WHEN m.first_noticed_weeks >= 27 AND m.first_noticed_weeks <= 39 THEN '7-9 Months'
    WHEN m.first_noticed_weeks >= 40 AND m.first_noticed_weeks <= 52 THEN '10-12 Months'
    WHEN m.first_noticed_weeks >= 53 AND m.first_noticed_weeks <= 78 THEN '13-18 Months'
    WHEN m.first_noticed_weeks >= 79 AND m.first_noticed_weeks <= 104 THEN '19-24 Months'
    WHEN m.first_noticed_weeks >= 105 AND m.first_noticed_weeks <= 156 THEN '2-3 Years'
    ELSE 'Other'
  END AS age_group,
  m.first_noticed_weeks
FROM milestones m
CROSS JOIN baby_info b
WHERE NOT EXISTS (
  SELECT 1 FROM baby_milestones bm 
  WHERE bm.baby_id = b.id 
    AND bm.milestone_id = m.id 
    AND bm.achieved_at IS NOT NULL
)
AND NOT (m.title = ANY(b.completed_milestones))
ORDER BY m.first_noticed_weeks
LIMIT 1;

-- Domain percentile breakdown ------------------------------------------------
SELECT
  d.domain,
  ROUND(d.avg_percentile::numeric, 2) AS avg_percentile,
  d.achieved_count,
  d.total_milestones,
  ROUND((d.achieved_count::numeric * 100) / NULLIF(d.total_milestones, 0), 1) AS coverage_percent,
  d.confidence
FROM public.v_baby_domain_scores d
WHERE d.baby_id = :'baby_id'
ORDER BY d.domain;

-- Social & Emotional (domain = 'Social') detailed contribution ---------------
WITH social AS (
  SELECT *
  FROM public.v_baby_milestone_assessment bma
  WHERE bma.baby_id = :'baby_id'
    AND bma.category = 'Social'
    AND bma.percentile IS NOT NULL
    AND NOT bma.discounted
)
SELECT
  s.title AS milestone_title,
  s.window_start_weeks,
  s.window_end_weeks,
  ROUND(s.achieved_weeks::numeric, 2) AS achieved_weeks,
  ROUND(s.percentile::numeric, 1) AS percentile,
  CASE
    WHEN s.achieved_weeks <= s.window_start_weeks THEN 'Ahead'
    WHEN s.achieved_weeks BETWEEN s.window_start_weeks AND s.window_end_weeks THEN 'On time'
    ELSE 'Late'
  END AS timing_bucket
FROM social s
ORDER BY s.achieved_weeks NULLS LAST;

-- Social & Emotional percentile math check ----------------------------------
SELECT
  COUNT(*) AS contributing_milestones,
  ROUND(AVG(s.percentile)::numeric, 2) AS avg_percentile,
  ARRAY_AGG(ROUND(s.percentile::numeric, 1)) AS contributing_percentiles,
  ARRAY_AGG(s.title) AS contributing_titles
FROM public.v_baby_milestone_assessment s
WHERE s.baby_id = :'baby_id'
  AND s.category = 'Social'
  AND s.percentile IS NOT NULL
  AND NOT s.discounted;
