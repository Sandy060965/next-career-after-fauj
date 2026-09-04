-- Restructures the networking directory into pure mentor-pledge data
-- capture: no more channel distinction, live call-slot scheduling, referral
-- offers, or the connection-request negotiation flow that went with them.

ALTER TABLE network_contacts ADD COLUMN joining_date TEXT;
ALTER TABLE network_contacts ADD COLUMN session_minutes INTEGER NOT NULL DEFAULT 30;

ALTER TABLE network_contacts DROP COLUMN channel;
ALTER TABLE network_contacts DROP COLUMN call_slots;
ALTER TABLE network_contacts DROP COLUMN offers_referrals;

DROP TABLE IF EXISTS connection_requests;
