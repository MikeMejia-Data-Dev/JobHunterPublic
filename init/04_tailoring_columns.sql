-- Phase 4: store the tailored CV content so it can be re-rendered or reviewed later.
-- Safe to run more than once.

ALTER TABLE jobs ADD COLUMN IF NOT EXISTS tailored_cv JSONB;   -- tailored content + automatic check notes
