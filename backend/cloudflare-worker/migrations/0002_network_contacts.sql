CREATE TABLE IF NOT EXISTS network_contacts (
  officer_id TEXT PRIMARY KEY,
  channel TEXT NOT NULL,
  display_name TEXT NOT NULL,
  email TEXT NOT NULL,
  vertical TEXT,
  city TEXT,
  current_company TEXT,
  call_frequency TEXT NOT NULL,
  call_slots TEXT NOT NULL,
  offers_referrals INTEGER NOT NULL DEFAULT 0,
  visible INTEGER NOT NULL DEFAULT 1,
  opted_in_at TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS connection_requests (
  id TEXT PRIMARY KEY,
  requester_officer_id TEXT NOT NULL,
  volunteer_officer_id TEXT NOT NULL,
  ask_type TEXT NOT NULL,
  slot_index INTEGER,
  status TEXT NOT NULL DEFAULT 'pending',
  created_at TEXT NOT NULL,
  responded_at TEXT
);
