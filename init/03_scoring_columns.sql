-- Phase 3: scoring confidence and description enrichment tracking.
-- Safe to run more than once.

ALTER TABLE jobs ADD COLUMN IF NOT EXISTS score_confidence TEXT
    CHECK (score_confidence IN ('full', 'title_only'));          -- title_only = scored without a description
ALTER TABLE jobs ADD COLUMN IF NOT EXISTS enrich_attempted BOOLEAN NOT NULL DEFAULT false;
