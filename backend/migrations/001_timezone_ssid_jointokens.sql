-- ChoreChampion schema delta 001
-- Applies decisions from plan: household timezone, SSID hash, submission lifecycle,
-- join tokens, per-day uniqueness guard.
--
-- Apply AFTER setup.sql (or to an existing Supabase instance that already has
-- the base tables).

BEGIN;

-- Households: timezone + optional SSID hash for SSID-primary device join.
ALTER TABLE households
    ADD COLUMN IF NOT EXISTS timezone VARCHAR(64) NOT NULL DEFAULT 'UTC',
    ADD COLUMN IF NOT EXISTS ssid_hash VARCHAR(128) NULL;

-- Devices: give the row a label so admins can distinguish devices in the panel.
ALTER TABLE devices
    ADD COLUMN IF NOT EXISTS device_name VARCHAR(120) NULL;

-- Chore submissions: tighten timestamps, flip approval default, track rejection
-- reason, denormalize household_id for the functional unique index.
ALTER TABLE chore_submissions
    ALTER COLUMN completed_at TYPE TIMESTAMPTZ USING completed_at AT TIME ZONE 'UTC';

ALTER TABLE chore_submissions
    ALTER COLUMN approved SET DEFAULT TRUE;

ALTER TABLE chore_submissions
    ADD COLUMN IF NOT EXISTS rejection_reason TEXT NULL;

ALTER TABLE chore_submissions
    ADD COLUMN IF NOT EXISTS household_id UUID NULL
        REFERENCES households(household_id) ON DELETE CASCADE;

-- Backfill household_id for any existing submissions (Chore -> we don't know
-- household directly; fall back to NULL and let app fill forward). Skip if empty.
UPDATE chore_submissions cs
SET household_id = fm.household_id
FROM family_members fm
WHERE cs.member_id = fm.member_id
  AND cs.household_id IS NULL;

ALTER TABLE chore_submissions
    ALTER COLUMN household_id SET NOT NULL;

-- Per-day dedupe guard (decision 3c). Uses UTC date in the generated column;
-- authoritative tz-aware check happens in services/submission_rules.py.
ALTER TABLE chore_submissions
    ADD COLUMN IF NOT EXISTS local_date DATE
        GENERATED ALWAYS AS ((completed_at AT TIME ZONE 'UTC')::date) STORED;

CREATE UNIQUE INDEX IF NOT EXISTS uniq_submission_per_member_per_day
    ON chore_submissions (chore_id, member_id, local_date)
    WHERE approved = TRUE;

-- Short-lived device join tokens.
CREATE TABLE IF NOT EXISTS join_tokens (
    token_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    household_id UUID NOT NULL REFERENCES households(household_id) ON DELETE CASCADE,
    token_hash VARCHAR(128) NOT NULL,
    expires_at TIMESTAMPTZ NOT NULL,
    used_at TIMESTAMPTZ NULL,
    created_by_device UUID NOT NULL REFERENCES devices(device_id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_join_tokens_household
    ON join_tokens (household_id);

CREATE INDEX IF NOT EXISTS idx_join_tokens_token_hash
    ON join_tokens (token_hash)
    WHERE used_at IS NULL;

COMMIT;
