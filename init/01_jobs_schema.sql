-- Job Hunting Copilot: tracker schema
-- Runs automatically the FIRST time the Postgres volume is created.

CREATE TABLE IF NOT EXISTS jobs (
    id               BIGSERIAL PRIMARY KEY,
    job_hash         TEXT NOT NULL UNIQUE,          -- md5(company + title + url), used for dedupe
    source           TEXT NOT NULL,                 -- 'linkedin_alert', 'jsearch', 'greenhouse', ...
    external_id      TEXT,
    title            TEXT NOT NULL,
    company          TEXT NOT NULL,
    location         TEXT,
    work_mode        TEXT CHECK (work_mode IN ('remote', 'hybrid', 'onsite', 'unknown')) DEFAULT 'unknown',
    url              TEXT NOT NULL,
    description      TEXT,
    language         TEXT,                          -- 'en', 'es'
    posted_at        TIMESTAMPTZ,

    status           TEXT NOT NULL DEFAULT 'found' CHECK (status IN (
                        'found', 'filtered_out', 'scored', 'tailored', 'pending_review',
                        'approved', 'skipped', 'applied', 'interview', 'rejected', 'offer'
                     )),
    filter_reason    TEXT,                          -- why a rule filter dropped it

    match_score      SMALLINT CHECK (match_score BETWEEN 0 AND 100),
    matched_skills   TEXT[],
    missing_skills   TEXT[],
    red_flags        TEXT[],
    match_reasoning  TEXT,

    cv_file_name     TEXT,
    cover_letter     TEXT,

    found_at         TIMESTAMPTZ NOT NULL DEFAULT now(),
    reviewed_at      TIMESTAMPTZ,
    applied_at       TIMESTAMPTZ,
    updated_at       TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_jobs_status   ON jobs (status);
CREATE INDEX IF NOT EXISTS idx_jobs_found_at ON jobs (found_at DESC);
CREATE INDEX IF NOT EXISTS idx_jobs_score    ON jobs (match_score DESC);

-- Status history: every status change is logged automatically
CREATE TABLE IF NOT EXISTS job_events (
    id          BIGSERIAL PRIMARY KEY,
    job_id      BIGINT NOT NULL REFERENCES jobs(id) ON DELETE CASCADE,
    old_status  TEXT,
    new_status  TEXT NOT NULL,
    changed_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Before update: refresh updated_at
CREATE OR REPLACE FUNCTION jobs_set_updated_at() RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at := now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- After insert/update: log new rows and status changes
CREATE OR REPLACE FUNCTION jobs_log_status() RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        INSERT INTO job_events (job_id, old_status, new_status) VALUES (NEW.id, NULL, NEW.status);
    ELSIF NEW.status IS DISTINCT FROM OLD.status THEN
        INSERT INTO job_events (job_id, old_status, new_status) VALUES (NEW.id, OLD.status, NEW.status);
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_jobs_updated_at ON jobs;
CREATE TRIGGER trg_jobs_updated_at
    BEFORE UPDATE ON jobs
    FOR EACH ROW EXECUTE FUNCTION jobs_set_updated_at();

DROP TRIGGER IF EXISTS trg_jobs_log_status ON jobs;
CREATE TRIGGER trg_jobs_log_status
    AFTER INSERT OR UPDATE OF status ON jobs
    FOR EACH ROW EXECUTE FUNCTION jobs_log_status();

-- Quick pipeline overview
CREATE OR REPLACE VIEW pipeline_summary AS
SELECT status, COUNT(*) AS jobs, ROUND(AVG(match_score)) AS avg_score
FROM jobs
GROUP BY status
ORDER BY jobs DESC;
