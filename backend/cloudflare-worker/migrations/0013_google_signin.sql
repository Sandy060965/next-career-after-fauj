-- Google Sign-In: officers can now be identified by email instead of (or in
-- addition to) a phone number. SQLite has no ALTER COLUMN, so relaxing
-- mobile_number's NOT NULL requires the standard rebuild-table recipe
-- rather than a plain ALTER TABLE ADD COLUMN.

-- D1 enforces foreign keys unconditionally — it does not honor
-- `PRAGMA foreign_keys=OFF` or `PRAGMA defer_foreign_keys=TRUE` (verified:
-- both still raise SQLITE_CONSTRAINT_FOREIGNKEY on DROP TABLE officers
-- while a referencing table's schema still exists). officer_progress,
-- login_history and support_tickets all declare REFERENCES officers(id),
-- and SQLite always refuses to drop a table another table's schema still
-- references — that refusal isn't gated by the pragma the way it is in
-- vanilla SQLite. Dropping a *child* table (the one holding the FK) is
-- always allowed regardless, so the safe order is: stash each dependent
-- table's data, drop the dependents, rebuild officers, then recreate the
-- dependents (newly referencing the rebuilt officers table) and restore
-- their data.

CREATE TABLE _stash_officer_progress AS SELECT * FROM officer_progress;
CREATE TABLE _stash_login_history AS SELECT * FROM login_history;
CREATE TABLE _stash_support_tickets AS SELECT * FROM support_tickets;

DROP TABLE officer_progress;
DROP TABLE login_history;
DROP TABLE support_tickets;

CREATE TABLE officers_new (
  id TEXT PRIMARY KEY,
  mobile_number TEXT UNIQUE,
  email TEXT,
  google_sub TEXT,
  created_at TEXT NOT NULL,
  entitlement_tier TEXT NOT NULL DEFAULT 'free',
  entitlement_expires_at TEXT
);

INSERT INTO officers_new (id, mobile_number, email, google_sub, created_at, entitlement_tier, entitlement_expires_at)
  SELECT id, mobile_number, NULL, NULL, created_at, entitlement_tier, entitlement_expires_at FROM officers;

DROP TABLE officers;
ALTER TABLE officers_new RENAME TO officers;

-- Unique only when present, so any number of phone-only (email IS NULL)
-- or email-only (mobile_number IS NULL) officers can coexist.
CREATE UNIQUE INDEX IF NOT EXISTS idx_officers_email_unique ON officers(email) WHERE email IS NOT NULL;
CREATE UNIQUE INDEX IF NOT EXISTS idx_officers_google_sub_unique ON officers(google_sub) WHERE google_sub IS NOT NULL;

-- Recreate officer_progress with its original (unchanged) schema and
-- restore its data.
CREATE TABLE officer_progress (
  officer_id TEXT PRIMARY KEY REFERENCES officers(id),
  rank TEXT,
  full_name TEXT,
  service TEXT,
  segment TEXT,
  readiness_score INTEGER,
  readiness_dimensions_completed INTEGER NOT NULL DEFAULT 0,
  readiness_dimensions_total INTEGER NOT NULL DEFAULT 0,
  cv_uploaded INTEGER NOT NULL DEFAULT 0,
  civilianized_cv_done INTEGER NOT NULL DEFAULT 0,
  built_cv_done INTEGER NOT NULL DEFAULT 0,
  jd_match_done INTEGER NOT NULL DEFAULT 0,
  financial_plan_done INTEGER NOT NULL DEFAULT 0,
  target_role_strategy_done INTEGER NOT NULL DEFAULT 0,
  applications_count INTEGER NOT NULL DEFAULT 0,
  updated_at TEXT NOT NULL
);
INSERT INTO officer_progress SELECT * FROM _stash_officer_progress;
DROP TABLE _stash_officer_progress;

-- Recreate login_history — mobile_number also becomes nullable here since
-- recordLogin() binds officer.mobile_number verbatim, which is null for a
-- Google-only officer.
CREATE TABLE login_history (
  id TEXT PRIMARY KEY,
  officer_id TEXT NOT NULL REFERENCES officers(id),
  mobile_number TEXT,
  user_agent TEXT,
  country TEXT,
  city TEXT,
  logged_in_at TEXT NOT NULL
);
INSERT INTO login_history (id, officer_id, mobile_number, user_agent, country, city, logged_in_at)
  SELECT id, officer_id, mobile_number, user_agent, country, city, logged_in_at FROM _stash_login_history;
DROP TABLE _stash_login_history;

-- Recreate support_tickets with its original (unchanged) schema and
-- restore its data.
CREATE TABLE support_tickets (
  id TEXT PRIMARY KEY,
  officer_id TEXT REFERENCES officers(id),
  mobile_number TEXT,
  message TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'open',
  created_at TEXT NOT NULL,
  resolved_at TEXT
);
INSERT INTO support_tickets SELECT * FROM _stash_support_tickets;
DROP TABLE _stash_support_tickets;

-- Email allowlist — exact mirror of phone_allowlist's shape/semantics: a
-- brand-new email must be pre-approved by an admin before Google Sign-In
-- can create an officer row for it; already-registered officers skip this.
CREATE TABLE IF NOT EXISTS email_allowlist (
  email TEXT PRIMARY KEY,
  note TEXT,
  added_at TEXT NOT NULL
);
