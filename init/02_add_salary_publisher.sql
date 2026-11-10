-- Phase 2: extra columns for job sources and the salary deal-breaker filter.
-- Safe to run more than once.

ALTER TABLE jobs ADD COLUMN IF NOT EXISTS publisher       TEXT;     -- 'LinkedIn', 'Indeed', 'Glassdoor', ...
ALTER TABLE jobs ADD COLUMN IF NOT EXISTS salary_min      NUMERIC;
ALTER TABLE jobs ADD COLUMN IF NOT EXISTS salary_max      NUMERIC;
ALTER TABLE jobs ADD COLUMN IF NOT EXISTS salary_currency TEXT;     -- 'COP', 'USD', ...
ALTER TABLE jobs ADD COLUMN IF NOT EXISTS salary_period   TEXT;     -- 'MONTH', 'YEAR', 'HOUR'
