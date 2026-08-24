CREATE TABLE IF NOT EXISTS otp_rate_limit (
  mobile_number TEXT PRIMARY KEY,
  request_count INTEGER NOT NULL DEFAULT 0,
  window_start TEXT NOT NULL
);
