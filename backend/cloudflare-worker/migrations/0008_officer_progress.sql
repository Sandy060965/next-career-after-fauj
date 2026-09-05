CREATE TABLE IF NOT EXISTS officer_progress (
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
