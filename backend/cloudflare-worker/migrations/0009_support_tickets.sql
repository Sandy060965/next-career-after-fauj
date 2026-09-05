CREATE TABLE IF NOT EXISTS support_tickets (
  id TEXT PRIMARY KEY,
  officer_id TEXT REFERENCES officers(id),
  mobile_number TEXT,
  message TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'open',
  created_at TEXT NOT NULL,
  resolved_at TEXT
);
