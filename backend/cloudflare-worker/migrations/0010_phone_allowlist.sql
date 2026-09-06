CREATE TABLE IF NOT EXISTS phone_allowlist (
  mobile_number TEXT PRIMARY KEY,
  note TEXT,
  added_at TEXT NOT NULL
);
