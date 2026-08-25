CREATE TABLE IF NOT EXISTS course_submissions (
  id TEXT PRIMARY KEY,
  mobile_number TEXT,
  course_name TEXT NOT NULL,
  course_description TEXT,
  civilian_equivalent TEXT,
  civilian_description TEXT,
  verified INTEGER NOT NULL DEFAULT 0,
  source_note TEXT,
  submitted_at TEXT NOT NULL
);
