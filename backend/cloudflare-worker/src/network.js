// Networking & Referral directory — voluntary, opt-in only. Two channels:
// officers still in transition (Channel A) offering peer calls, and already-
// transitioned officers (Channel B) offering calls and/or referrals. Every
// endpoint here requires the officer's own JWT session (not just the shared
// x-app-key), because — unlike every other endpoint in this Worker — these
// return or act on data belonging to OTHER officers, not just the caller's
// own. See auth.js for why that distinction matters.

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

const FREQUENCY_DAYS = { weekly: 7, fortnightly: 14, monthly: 30 };
const REFERRAL_COOLDOWN_DAYS = 7;

async function requireOfficerId(request, env) {
  const payload = await verifyJwt(bearerToken(request), env.JWT_SECRET);
  return payload?.sub ?? null;
}

function isValidCallSlots(callSlots) {
  if (!Array.isArray(callSlots) || callSlots.length < 1 || callSlots.length > 2) return false;
  return callSlots.every(
    (s) => s && typeof s.dayOfWeek === 'string' && typeof s.startTime === 'string',
  );
}

// --- /network/opt-in --------------------------------------------------

async function handleOptIn(request, body, env) {
  const officerId = await requireOfficerId(request, env);
  if (!officerId) return json({ error: 'Unauthorized' }, 401);

  const { channel, displayName, email, vertical, city, currentCompany, callFrequency, callSlots } = body;
  if (!['inTransition', 'transitioned'].includes(channel)) {
    return json({ error: 'channel must be inTransition or transitioned' }, 400);
  }
  if (!displayName || !email || !String(email).includes('@')) {
    return json({ error: 'displayName and a valid email are required' }, 400);
  }
  if (!FREQUENCY_DAYS[callFrequency]) {
    return json({ error: 'callFrequency must be weekly, fortnightly, or monthly' }, 400);
  }
  if (!isValidCallSlots(callSlots)) {
    return json({ error: 'callSlots must be 1-2 entries of {dayOfWeek, startTime}' }, 400);
  }
  // Referrals only make sense from an officer who has actually landed
  // somewhere — never allow Channel A (still in transition) to offer them,
  // regardless of what the client sends.
  const offersReferrals = channel === 'transitioned' && Boolean(body.offersReferrals);

  await env.DB.prepare(
    `INSERT INTO network_contacts
      (officer_id, channel, display_name, email, vertical, city, current_company,
       call_frequency, call_slots, offers_referrals, visible, opted_in_at)
     VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 1, ?)
     ON CONFLICT(officer_id) DO UPDATE SET
       channel = excluded.channel,
       display_name = excluded.display_name,
       email = excluded.email,
       vertical = excluded.vertical,
       city = excluded.city,
       current_company = excluded.current_company,
       call_frequency = excluded.call_frequency,
       call_slots = excluded.call_slots,
       offers_referrals = excluded.offers_referrals,
       visible = 1`,
  )
    .bind(
      officerId,
      channel,
      displayName,
      email,
      vertical ?? null,
      city ?? null,
      currentCompany ?? null,
      callFrequency,
      JSON.stringify(callSlots),
      offersReferrals ? 1 : 0,
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

  const row = await env.DB.prepare('SELECT * FROM network_contacts WHERE officer_id = ?')
    .bind(officerId)
    .first();
  if (!row) return json({ listing: null });
  // Only this endpoint (an officer fetching their OWN listing) includes
  // email — /network/browse must never return it for other officers.
  return json({ listing: contactResponseBody(row, { includeEmail: true }) });
}

// --- shared helpers -------------------------------------------------------

function contactResponseBody(row, { includeEmail = false } = {}) {
  return {
    officerId: row.officer_id,
    ...(includeEmail ? { email: row.email } : {}),
    channel: row.channel,
    displayName: row.display_name,
    vertical: row.vertical,
    city: row.city,
    currentCompany: row.current_company,
    callFrequency: row.call_frequency,
    callSlots: JSON.parse(row.call_slots),
    offersReferrals: !!row.offers_referrals,
    visible: !!row.visible,
  };
}

async function slotAvailability(env, volunteerOfficerId, callFrequency, slotCount) {
  const days = FREQUENCY_DAYS[callFrequency] ?? 7;
  const cutoff = new Date(Date.now() - days * 24 * 60 * 60 * 1000).toISOString();
  const accepted = await env.DB.prepare(
    `SELECT slot_index FROM connection_requests
     WHERE volunteer_officer_id = ? AND ask_type = 'call' AND status = 'accepted' AND responded_at > ?`,
  )
    .bind(volunteerOfficerId, cutoff)
    .all();
  const bookedSlots = new Set((accepted.results ?? []).map((r) => r.slot_index));
  return Array.from({ length: slotCount }, (_, i) => !bookedSlots.has(i));
}

// --- /network/browse -------------------------------------------------------

async function handleBrowse(request, body, env) {
  const officerId = await requireOfficerId(request, env);
  if (!officerId) return json({ error: 'Unauthorized' }, 401);

  const { channel, vertical, city } = body;
  let query = 'SELECT * FROM network_contacts WHERE visible = 1 AND officer_id != ?';
  const params = [officerId];
  if (channel) {
    query += ' AND channel = ?';
    params.push(channel);
  }
  if (vertical) {
    query += ' AND vertical = ?';
    params.push(vertical);
  }
  if (city) {
    query += ' AND city = ?';
    params.push(city);
  }

  const { results } = await env.DB.prepare(query).bind(...params).all();
  const contacts = [];
  for (const row of results ?? []) {
    const slots = JSON.parse(row.call_slots);
    const availability = await slotAvailability(env, row.officer_id, row.call_frequency, slots.length);
    contacts.push({ ...contactResponseBody(row), slotAvailability: availability });
  }
  return json({ contacts });
}

// --- /network/request -------------------------------------------------------

async function handleRequestConnection(request, body, env) {
  const officerId = await requireOfficerId(request, env);
  if (!officerId) return json({ error: 'Unauthorized' }, 401);

  const { volunteerOfficerId, askType, slotIndex, requesterDisplayName, requesterNote } = body;
  if (!volunteerOfficerId || !['call', 'referral'].includes(askType) || !requesterDisplayName) {
    return json({ error: 'volunteerOfficerId, askType, and requesterDisplayName are required' }, 400);
  }
  if (volunteerOfficerId === officerId) {
    return json({ error: 'You cannot request a connection with yourself' }, 400);
  }

  const volunteer = await env.DB.prepare(
    'SELECT * FROM network_contacts WHERE officer_id = ? AND visible = 1',
  )
    .bind(volunteerOfficerId)
    .first();
  if (!volunteer) return json({ error: 'That volunteer is not available' }, 404);

  if (askType === 'call') {
    const slots = JSON.parse(volunteer.call_slots);
    if (!Number.isInteger(slotIndex) || slotIndex < 0 || slotIndex >= slots.length) {
      return json({ error: 'Invalid slotIndex for this volunteer' }, 400);
    }
    const availability = await slotAvailability(env, volunteerOfficerId, volunteer.call_frequency, slots.length);
    if (!availability[slotIndex]) {
      return json({ error: 'That slot is already booked for this period' }, 409);
    }
  } else {
    if (!volunteer.offers_referrals) {
      return json({ error: 'This volunteer is not offering referrals' }, 400);
    }
    const cutoff = new Date(Date.now() - REFERRAL_COOLDOWN_DAYS * 24 * 60 * 60 * 1000).toISOString();
    const recent = await env.DB.prepare(
      `SELECT 1 FROM connection_requests
       WHERE requester_officer_id = ? AND ask_type = 'referral' AND created_at > ? LIMIT 1`,
    )
      .bind(officerId, cutoff)
      .first();
    if (recent) {
      return json({ error: 'You can send at most one referral request per week' }, 429);
    }
  }

  const id = crypto.randomUUID();
  await env.DB.prepare(
    `INSERT INTO connection_requests
      (id, requester_officer_id, requester_display_name, requester_note, volunteer_officer_id,
       ask_type, slot_index, status, created_at)
     VALUES (?, ?, ?, ?, ?, ?, ?, 'pending', ?)`,
  )
    .bind(
      id,
      officerId,
      requesterDisplayName,
      requesterNote ?? null,
      volunteerOfficerId,
      askType,
      askType === 'call' ? slotIndex : null,
      new Date().toISOString(),
    )
    .run();

  return json({ status: 'requested', requestId: id });
}

// --- /network/respond -------------------------------------------------------

async function handleRespondConnection(request, body, env) {
  const officerId = await requireOfficerId(request, env);
  if (!officerId) return json({ error: 'Unauthorized' }, 401);

  const { requestId, accept } = body;
  if (!requestId || typeof accept !== 'boolean') {
    return json({ error: 'requestId and accept (boolean) are required' }, 400);
  }

  const existing = await env.DB.prepare('SELECT * FROM connection_requests WHERE id = ?')
    .bind(requestId)
    .first();
  if (!existing) return json({ error: 'Request not found' }, 404);
  if (existing.volunteer_officer_id !== officerId) return json({ error: 'Unauthorized' }, 401);
  if (existing.status !== 'pending') return json({ error: 'This request was already responded to' }, 409);

  if (accept && existing.ask_type === 'call') {
    const volunteer = await env.DB.prepare('SELECT * FROM network_contacts WHERE officer_id = ?')
      .bind(officerId)
      .first();
    const slots = JSON.parse(volunteer.call_slots);
    const availability = await slotAvailability(env, officerId, volunteer.call_frequency, slots.length);
    if (!availability[existing.slot_index]) {
      return json({ error: 'That slot was just booked by another accepted request' }, 409);
    }
  }

  await env.DB.prepare(
    "UPDATE connection_requests SET status = ?, responded_at = ? WHERE id = ?",
  )
    .bind(accept ? 'accepted' : 'declined', new Date().toISOString(), requestId)
    .run();

  return json({ status: accept ? 'accepted' : 'declined' });
}

// --- /network/my-queue (incoming requests a volunteer needs to answer) ----

async function handleMyQueue(request, env) {
  const officerId = await requireOfficerId(request, env);
  if (!officerId) return json({ error: 'Unauthorized' }, 401);

  const { results } = await env.DB.prepare(
    `SELECT * FROM connection_requests WHERE volunteer_officer_id = ? AND status = 'pending'
     ORDER BY created_at ASC`,
  )
    .bind(officerId)
    .all();

  return json({
    requests: (results ?? []).map((r) => ({
      id: r.id,
      requesterDisplayName: r.requester_display_name,
      requesterNote: r.requester_note,
      askType: r.ask_type,
      slotIndex: r.slot_index,
      createdAt: r.created_at,
    })),
  });
}

// --- /network/my-requests (outgoing requests a requester has sent) --------

async function handleMyRequests(request, env) {
  const officerId = await requireOfficerId(request, env);
  if (!officerId) return json({ error: 'Unauthorized' }, 401);

  const { results } = await env.DB.prepare(
    `SELECT cr.*, nc.display_name AS volunteer_display_name, nc.email AS volunteer_email
     FROM connection_requests cr
     JOIN network_contacts nc ON cr.volunteer_officer_id = nc.officer_id
     WHERE cr.requester_officer_id = ?
     ORDER BY cr.created_at DESC`,
  )
    .bind(officerId)
    .all();

  return json({
    requests: (results ?? []).map((r) => ({
      id: r.id,
      volunteerDisplayName: r.volunteer_display_name,
      // Only ever reveal contact info once the volunteer has accepted —
      // this is the whole point of routing through requests instead of a
      // raw directory.
      volunteerEmail: r.status === 'accepted' ? r.volunteer_email : null,
      askType: r.ask_type,
      slotIndex: r.slot_index,
      status: r.status,
      createdAt: r.created_at,
      respondedAt: r.responded_at,
    })),
  });
}

export {
  handleOptIn,
  handleOptOut,
  handleMyListing,
  handleBrowse,
  handleRequestConnection,
  handleRespondConnection,
  handleMyQueue,
  handleMyRequests,
};
