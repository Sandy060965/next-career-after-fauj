// Officer accounts and entitlements — phone-OTP login (via Twilio Verify),
// a D1-backed officer record, and a signed session token. This is deliberately
// separate from the x-app-key gate in index.js: x-app-key just proves a
// request came from the app itself, this proves which officer is calling.

function json(body, status = 200, headers = {}) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { 'content-type': 'application/json', ...headers },
  });
}

function normalizeMobileNumber(raw) {
  const digits = String(raw ?? '').replace(/\D/g, '');
  // The app only ever collects a 10-digit Indian mobile number (no country
  // code) — see OfficerProfile.mobileNumber — so a valid one is exactly 10
  // digits here, and we add +91 ourselves for Twilio's E.164 requirement.
  if (digits.length !== 10) return null;
  return digits;
}

function toE164(mobileNumber) {
  return `+91${mobileNumber}`;
}

// --- Minimal dependency-free JWT (HS256) -----------------------------------
// A single, fixed token shape for this app doesn't need a full JWT library —
// Workers' native WebCrypto (crypto.subtle) covers HMAC signing/verification.

function base64UrlEncode(bytes) {
  let binary = '';
  for (const byte of bytes) binary += String.fromCharCode(byte);
  return btoa(binary).replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/, '');
}

function base64UrlDecode(str) {
  const padded = str.replace(/-/g, '+').replace(/_/g, '/').padEnd(str.length + ((4 - (str.length % 4)) % 4), '=');
  const binary = atob(padded);
  return Uint8Array.from(binary, (c) => c.charCodeAt(0));
}

async function hmacKey(secret) {
  return crypto.subtle.importKey(
    'raw',
    new TextEncoder().encode(secret),
    { name: 'HMAC', hash: 'SHA-256' },
    false,
    ['sign', 'verify'],
  );
}

async function signJwt(payload, secret) {
  const header = { alg: 'HS256', typ: 'JWT' };
  const encodedHeader = base64UrlEncode(new TextEncoder().encode(JSON.stringify(header)));
  const encodedPayload = base64UrlEncode(new TextEncoder().encode(JSON.stringify(payload)));
  const signingInput = `${encodedHeader}.${encodedPayload}`;
  const key = await hmacKey(secret);
  const signature = await crypto.subtle.sign('HMAC', key, new TextEncoder().encode(signingInput));
  return `${signingInput}.${base64UrlEncode(new Uint8Array(signature))}`;
}

// Returns the decoded payload if the signature is valid and it hasn't
// expired, otherwise null — callers treat null as "not authenticated" and
// never distinguish why, so we don't leak which check failed.
async function verifyJwt(token, secret) {
  if (!token) return null;
  const parts = token.split('.');
  if (parts.length !== 3) return null;
  const [encodedHeader, encodedPayload, encodedSignature] = parts;
  try {
    const key = await hmacKey(secret);
    const valid = await crypto.subtle.verify(
      'HMAC',
      key,
      base64UrlDecode(encodedSignature),
      new TextEncoder().encode(`${encodedHeader}.${encodedPayload}`),
    );
    if (!valid) return null;
    const payload = JSON.parse(new TextDecoder().decode(base64UrlDecode(encodedPayload)));
    if (typeof payload.exp !== 'number' || Date.now() / 1000 > payload.exp) return null;
    return payload;
  } catch {
    return null;
  }
}

function bearerToken(request) {
  const header = request.headers.get('authorization') ?? '';
  const match = header.match(/^Bearer\s+(.+)$/i);
  return match ? match[1] : null;
}

const SESSION_TTL_SECONDS = 30 * 24 * 60 * 60; // 30 days

// --- Twilio Verify -----------------------------------------------------

async function twilioVerifyStart(env, e164Number) {
  const url = `https://verify.twilio.com/v2/Services/${env.TWILIO_VERIFY_SERVICE_SID}/Verifications`;
  const response = await fetch(url, {
    method: 'POST',
    headers: {
      // An API Key SID/Secret pair authenticates the same way an Account
      // SID/Auth Token pair does — Basic Auth — but can be scoped and
      // revoked independently of the account's master credential.
      authorization: `Basic ${btoa(`${env.TWILIO_API_KEY_SID}:${env.TWILIO_API_KEY_SECRET}`)}`,
      'content-type': 'application/x-www-form-urlencoded',
    },
    body: new URLSearchParams({ To: e164Number, Channel: 'sms' }),
  });
  if (!response.ok) {
    const detail = await response.text();
    throw new Error(`Twilio Verify start failed (${response.status}): ${detail}`);
  }
  return response.json();
}

async function twilioVerifyCheck(env, e164Number, code) {
  const url = `https://verify.twilio.com/v2/Services/${env.TWILIO_VERIFY_SERVICE_SID}/VerificationCheck`;
  const response = await fetch(url, {
    method: 'POST',
    headers: {
      // An API Key SID/Secret pair authenticates the same way an Account
      // SID/Auth Token pair does — Basic Auth — but can be scoped and
      // revoked independently of the account's master credential.
      authorization: `Basic ${btoa(`${env.TWILIO_API_KEY_SID}:${env.TWILIO_API_KEY_SECRET}`)}`,
      'content-type': 'application/x-www-form-urlencoded',
    },
    body: new URLSearchParams({ To: e164Number, Code: code }),
  });
  if (!response.ok) {
    // Twilio returns 404 for "no pending verification" and 400 for a
    // malformed code — both just mean "not approved" to the caller.
    return { status: 'failed' };
  }
  return response.json();
}

// --- OTP rate limiting ---------------------------------------------------
// Each request here costs real money (one SMS via Twilio) and can be aimed
// at a real person's phone as harassment — so this limits by the number
// being texted, not by caller IP, since that's the actual abuse surface.

const OTP_RATE_LIMIT_WINDOW_MS = 60 * 60 * 1000; // 1 hour
const OTP_RATE_LIMIT_MAX = 3; // per number, per window

async function checkAndRecordOtpRequest(env, mobileNumber) {
  const now = Date.now();
  const row = await env.DB.prepare(
    'SELECT request_count, window_start FROM otp_rate_limit WHERE mobile_number = ?',
  )
    .bind(mobileNumber)
    .first();

  if (!row || now - new Date(row.window_start).getTime() > OTP_RATE_LIMIT_WINDOW_MS) {
    await env.DB.prepare(
      'INSERT INTO otp_rate_limit (mobile_number, request_count, window_start) VALUES (?, 1, ?) ' +
        'ON CONFLICT(mobile_number) DO UPDATE SET request_count = 1, window_start = excluded.window_start',
    )
      .bind(mobileNumber, new Date(now).toISOString())
      .run();
    return true;
  }

  if (row.request_count >= OTP_RATE_LIMIT_MAX) return false;

  await env.DB.prepare('UPDATE otp_rate_limit SET request_count = request_count + 1 WHERE mobile_number = ?')
    .bind(mobileNumber)
    .run();
  return true;
}

// --- D1 officer records -------------------------------------------------

async function findOrCreateOfficer(env, mobileNumber) {
  const existing = await env.DB.prepare('SELECT * FROM officers WHERE mobile_number = ?')
    .bind(mobileNumber)
    .first();
  if (existing) return existing;

  const officer = {
    id: crypto.randomUUID(),
    mobile_number: mobileNumber,
    created_at: new Date().toISOString(),
    entitlement_tier: 'free',
    entitlement_expires_at: null,
  };
  await env.DB.prepare(
    'INSERT INTO officers (id, mobile_number, created_at, entitlement_tier, entitlement_expires_at) VALUES (?, ?, ?, ?, ?)',
  )
    .bind(officer.id, officer.mobile_number, officer.created_at, officer.entitlement_tier, officer.entitlement_expires_at)
    .run();
  return officer;
}

function officerResponseBody(officer) {
  return {
    id: officer.id,
    mobileNumber: officer.mobile_number,
    entitlementTier: officer.entitlement_tier,
    entitlementExpiresAt: officer.entitlement_expires_at,
  };
}

// --- Route handlers -------------------------------------------------------

async function handleRequestOtp(body, env) {
  const mobileNumber = normalizeMobileNumber(body.mobileNumber);
  if (!mobileNumber) return json({ error: 'A valid 10-digit mobile number is required' }, 400);

  const allowed = await checkAndRecordOtpRequest(env, mobileNumber);
  if (!allowed) {
    return json(
      { error: 'Too many verification codes requested for this number. Please try again later.' },
      429,
    );
  }

  try {
    await twilioVerifyStart(env, toE164(mobileNumber));
  } catch (e) {
    console.error('twilioVerifyStart failed:', e.message);
    return json({ error: 'Could not send verification code. Please try again.' }, 502);
  }
  return json({ status: 'sent' });
}

async function handleVerifyOtp(body, env) {
  const mobileNumber = normalizeMobileNumber(body.mobileNumber);
  const code = String(body.code ?? '').trim();
  if (!mobileNumber || !code) {
    return json({ error: 'mobileNumber and code are required' }, 400);
  }

  const result = await twilioVerifyCheck(env, toE164(mobileNumber), code);
  if (result.status !== 'approved') {
    return json({ error: 'Invalid or expired code' }, 401);
  }

  const officer = await findOrCreateOfficer(env, mobileNumber);
  const now = Math.floor(Date.now() / 1000);
  const token = await signJwt(
    { sub: officer.id, mobile: officer.mobile_number, iat: now, exp: now + SESSION_TTL_SECONDS },
    env.JWT_SECRET,
  );
  return json({ token, officer: officerResponseBody(officer) });
}

async function handleMe(request, env) {
  const payload = await verifyJwt(bearerToken(request), env.JWT_SECRET);
  if (!payload) return json({ error: 'Unauthorized' }, 401);

  const officer = await env.DB.prepare('SELECT * FROM officers WHERE id = ?').bind(payload.sub).first();
  if (!officer) return json({ error: 'Officer not found' }, 404);
  return json(officerResponseBody(officer));
}

// Manual entitlement grant for testing before a real payment gateway is
// wired in. Never called by the app itself — gated on a separate operator
// secret, not the per-officer session token.
async function handleGrantEntitlement(request, body, env) {
  const adminKey = request.headers.get('x-admin-key');
  if (!env.ADMIN_SECRET || adminKey !== env.ADMIN_SECRET) {
    return json({ error: 'Unauthorized' }, 401);
  }

  const mobileNumber = normalizeMobileNumber(body.mobileNumber);
  const tier = body.tier;
  if (!mobileNumber || !['free', 'pass', 'annual'].includes(tier)) {
    return json({ error: 'mobileNumber and a valid tier (free/pass/annual) are required' }, 400);
  }
  const expiresAt = body.expiresAt ?? null;

  const result = await env.DB.prepare(
    'UPDATE officers SET entitlement_tier = ?, entitlement_expires_at = ? WHERE mobile_number = ?',
  )
    .bind(tier, expiresAt, mobileNumber)
    .run();
  if (result.meta.changes === 0) return json({ error: 'No officer found with that mobile number' }, 404);
  return json({ status: 'updated' });
}

export {
  handleRequestOtp,
  handleVerifyOtp,
  handleMe,
  handleGrantEntitlement,
  verifyJwt,
  bearerToken,
};
