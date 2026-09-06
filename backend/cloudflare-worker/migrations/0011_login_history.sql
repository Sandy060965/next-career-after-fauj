CREATE TABLE IF NOT EXISTS login_history (
  id TEXT PRIMARY KEY,
  officer_id TEXT NOT NULL REFERENCES officers(id),
  mobile_number TEXT NOT NULL,
  user_agent TEXT,
  country TEXT,
  city TEXT,
  logged_in_at TEXT NOT NULL
);
