-- Phone-OTP is now a recovery path, not a self-service sign-in option —
-- Google Sign-In is the only way to start a session on your own. A number
-- can request an OTP only while it holds an active (non-expired) grant
-- here, issued by an admin for one officer at a time via the "Phone
-- Recovery" admin tab. Keeping every grant ever issued (not deleting on
-- expiry) doubles as the actual usage signal for "how many officers hit a
-- Google sign-in problem" — that's the whole point of gating it this way
-- rather than just hiding the phone field in the UI.
CREATE TABLE IF NOT EXISTS phone_recovery_grants (
  id TEXT PRIMARY KEY,
  mobile_number TEXT NOT NULL,
  note TEXT,
  granted_at TEXT NOT NULL,
  expires_at TEXT NOT NULL,
  revoked_at TEXT
);
CREATE INDEX IF NOT EXISTS idx_phone_recovery_grants_mobile ON phone_recovery_grants(mobile_number);
