ALTER TABLE connection_requests ADD COLUMN requester_display_name TEXT NOT NULL DEFAULT '';
ALTER TABLE connection_requests ADD COLUMN requester_note TEXT;
