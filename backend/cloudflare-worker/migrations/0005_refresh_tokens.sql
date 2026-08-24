CREATE TABLE IF NOT EXISTS refresh_tokens (
  id TEXT PRIMARY KEY,
  officer_id TEXT NOT NULL,
  token_hash TEXT NOT NULL UNIQUE,
  created_at TEXT NOT NULL,
  expires_at TEXT NOT NULL,
  revoked_at TEXT,
  replaced_by_hash TEXT
);

CREATE INDEX IF NOT EXISTS idx_refresh_tokens_officer ON refresh_tokens(officer_id);
