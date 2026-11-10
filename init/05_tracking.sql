-- Phase 6: follow-up tracking and tuning views. Safe to run more than once.

ALTER TABLE jobs ADD COLUMN IF NOT EXISTS followup_sent_at TIMESTAMPTZ;

-- How each source performs through the pipeline
CREATE OR REPLACE VIEW tuning_by_source AS
SELECT source,
       count(*)                                                                AS total,
       count(*) FILTER (WHERE status = 'filtered_out' AND filter_reason NOT LIKE 'AI:%') AS rule_filtered,
       count(*) FILTER (WHERE filter_reason LIKE 'AI:%')                        AS ai_filtered,
       count(*) FILTER (WHERE match_score IS NOT NULL)                          AS scored,
       round(avg(match_score))                                                  AS avg_score,
       count(*) FILTER (WHERE match_score >= 70)                                AS score_70_plus,
       count(*) FILTER (WHERE status IN ('approved','applied','interview','rejected','offer')) AS approved,
       count(*) FILTER (WHERE status = 'skipped')                               AS skipped
FROM jobs
GROUP BY source;

-- Why jobs are being dropped (look for good jobs dropped by mistake)
CREATE OR REPLACE VIEW tuning_filter_reasons AS
SELECT filter_reason, count(*) AS jobs, max(found_at)::date AS last_seen
FROM jobs
WHERE status = 'filtered_out'
GROUP BY filter_reason
ORDER BY jobs DESC;

-- Does the AI score agree with your decisions? Approved should score clearly higher than skipped.
CREATE OR REPLACE VIEW tuning_score_vs_decision AS
SELECT CASE WHEN status = 'skipped' THEN 'skipped' ELSE 'approved' END AS your_decision,
       count(*) AS jobs, round(avg(match_score)) AS avg_score,
       min(match_score) AS min_score, max(match_score) AS max_score
FROM jobs
WHERE status IN ('approved','skipped','applied','interview','rejected','offer')
GROUP BY 1;
