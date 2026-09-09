ALTER TABLE course_submissions ADD COLUMN status TEXT NOT NULL DEFAULT 'pending';
ALTER TABLE course_submissions ADD COLUMN reviewed_at TEXT;

CREATE TABLE IF NOT EXISTS approved_equivalencies (
  id TEXT PRIMARY KEY,
  military_term TEXT NOT NULL,
  civilian_equivalent TEXT NOT NULL,
  description TEXT NOT NULL,
  verified INTEGER NOT NULL DEFAULT 0,
  source_note TEXT,
  approved_at TEXT NOT NULL
);
