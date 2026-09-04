// Mentor pledge registry — pure data capture, no in-app browsing or
// request/response flow. Officers pledge a small, recurring amount of time
// to mentor other officers once they've joined their own civilian role.
// There's deliberately no eligibility gate (e.g. a minimum tenure) because
// officers typically lose access to this app once they join their new
// employer, so the pledge has to be captured in advance rather than after
// they've proven themselves in the role. Every endpoint here requires the
// officer's own JWT session (not just the shared x-app-key) — see auth.js.

import { verifyJwt, bearerToken } from './auth.js';

// Duplicated from index.js rather than imported, to avoid a circular
// import (index.js imports handlers from this file).
const CORS_HEADERS = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
  'Access-Control-Allow-Headers': 'content-type, x-app-key, authorization, x-admin-key',
};

function json(body, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { 'content-type': 'application/json', ...CORS_HEADERS },
  });
}

const VALID_FREQUENCIES = ['weekly', 'fortnightly', 'monthly'];
const VALID_SESSION_MINUTES = [30, 60];

async function requireOfficerId(request, env) {
  const payload = await verifyJwt(bearerToken(request), env.JWT_SECRET);
  return payload?.sub ?? null;
}

// --- /network/opt-in --------------------------------------------------

async function handleOptIn(request, body, env) {
  const officerId = await requireOfficerId(request, env);
  if (!officerId) return json({ error: 'Unauthorized' }, 401);

  const { displayName, email, vertical, city, currentCompany, joiningDate, callFrequency, sessionMinutes } =
    body;
  if (!displayName || !email || !String(email).includes('@')) {
    return json({ error: 'displayName and a valid email are required' }, 400);
  }
  if (!VALID_FREQUENCIES.includes(callFrequency)) {
    return json({ error: 'callFrequency must be weekly, fortnightly, or monthly' }, 400);
  }
  if (!VALID_SESSION_MINUTES.includes(sessionMinutes)) {
    return json({ error: 'sessionMinutes must be 30 or 60' }, 400);
  }
  if (joiningDate != null && Number.isNaN(Date.parse(joiningDate))) {
    return json({ error: 'joiningDate must be a valid date' }, 400);
  }

  await env.DB.prepare(
    `INSERT INTO network_contacts
      (officer_id, display_name, email, vertical, city, current_company,
       joining_date, call_frequency, session_minutes, visible, opted_in_at)
     VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, 1, ?)
     ON CONFLICT(officer_id) DO UPDATE SET
       display_name = excluded.display_name,
       email = excluded.email,
       vertical = excluded.vertical,
       city = excluded.city,
       current_company = excluded.current_company,
       joining_date = excluded.joining_date,
       call_frequency = excluded.call_frequency,
       session_minutes = excluded.session_minutes,
       visible = 1`,
  )
    .bind(
      officerId,
      displayName,
      email,
      vertical ?? null,
      city ?? null,
      currentCompany ?? null,
      joiningDate ?? null,
      callFrequency,
      sessionMinutes,
      new Date().toISOString(),
    )
    .run();

  return json({ status: 'opted_in' });
}

// --- /network/opt-out ---------------------------------------------------

async function handleOptOut(request, env) {
  const officerId = await requireOfficerId(request, env);
  if (!officerId) return json({ error: 'Unauthorized' }, 401);

  await env.DB.prepare('UPDATE network_contacts SET visible = 0 WHERE officer_id = ?')
    .bind(officerId)
    .run();
  return json({ status: 'opted_out' });
}

// --- /network/my-listing -------------------------------------------------

async function handleMyListing(request, env) {
  const officerId = await requireOfficerId(request, env);
  if (!officerId) return json({ error: 'Unauthorized' }, 401);

  const row = await env.DB.prepare(
    'SELECT * FROM network_contacts WHERE officer_id = ? AND visible = 1',
  )
    .bind(officerId)
    .first();
  if (!row) return json({ listing: null });
  return json({
    listing: {
      officerId: row.officer_id,
      displayName: row.display_name,
      email: row.email,
      vertical: row.vertical,
      city: row.city,
      currentCompany: row.current_company,
      joiningDate: row.joining_date,
      callFrequency: row.call_frequency,
      sessionMinutes: row.session_minutes,
    },
  });
}

export { handleOptIn, handleOptOut, handleMyListing };
