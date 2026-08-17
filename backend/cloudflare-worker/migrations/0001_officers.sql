CREATE TABLE IF NOT EXISTS officers (
  id TEXT PRIMARY KEY,
  mobile_number TEXT UNIQUE NOT NULL,
  created_at TEXT NOT NULL,
  entitlement_tier TEXT NOT NULL DEFAULT 'free',
  entitlement_expires_at TEXT
);
