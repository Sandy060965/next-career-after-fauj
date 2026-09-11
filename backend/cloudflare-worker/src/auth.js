// Officer accounts and entitlements — phone-OTP login (via Twilio Verify) or
// Google Sign-In, a D1-backed officer record, and a signed session token.
// This is deliberately separate from the x-app-key gate in index.js:
// x-app-key just proves a request came from the app itself, this proves
// which officer is calling.

import { createRemoteJWKSet, jwtVerify } from 'jose';

// Duplicated from index.js's CORS_HEADERS (network.js does the same) rather
// than shared via an import, to avoid a circular import with index.js.
const CORS_HEADERS = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
  'Access-Control-Allow-Headers': 'content-type, x-app-key, authorization, x-admin-key',
};

function json(body, status = 200, headers = {}) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { 'content-type': 'application/json', ...CORS_HEADERS, ...headers },
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

// Access tokens are short-lived by design — a leaked one is worth little.
// Refresh tokens are long-lived but single-use-then-rotated: each /auth/
// refresh call issues a new pair and revokes the one just used, so the
// officer's session effectively slides forward as long as they keep using
// the app, without ever needing to re-verify by phone OTP.
const ACCESS_TOKEN_TTL_SECONDS = 60 * 60; // 1 hour
const REFRESH_TOKEN_TTL_SECONDS = 30 * 24 * 60 * 60; // 30 days

async function sha256Hex(text) {
  const digest = await crypto.subtle.digest('SHA-256', new TextEncoder().encode(text));
  return Array.from(new Uint8Array(digest))
    .map((b) => b.toString(16).padStart(2, '0'))
    .join('');
}

function randomToken() {
  const bytes = crypto.getRandomValues(new Uint8Array(32));
  return Array.from(bytes)
    .map((b) => b.toString(16).padStart(2, '0'))
    .join('');
}

// Issues a fresh access+refresh token pair for [officer] and records the
// refresh token's hash (never the raw token) in D1.
//
// revokeOtherSessions is opt-in, not unconditional: it's passed true only at
// an actual new sign-in (handleVerifyOtp, handleGoogleSignIn), which is what
// implements "signing in elsewhere kicks out the old session" as a control
// against two people sharing one identity. handleRefreshToken's routine
// hourly silent refresh — which fires once per access-token TTL from every
// device an officer is legitimately using at once — deliberately leaves
// this false, or an officer using the app on phone and laptop together
// would have each device's own refresh silently kill the other one.
//
// Accepted tradeoff: an already-issued access token on a now-revoked-
// elsewhere device keeps working until it naturally expires (at most one
// hour) or that device's next /auth/refresh call, which will now fail.
// No access-token/jti blocklist is being built to close that bounded
// window — not worth the added complexity for this threat model.
async function issueSession(env, officer, { revokeOtherSessions = false } = {}) {
  const now = Math.floor(Date.now() / 1000);
  const accessToken = await signJwt(
    { sub: officer.id, mobile: officer.mobile_number, iat: now, exp: now + ACCESS_TOKEN_TTL_SECONDS },
    env.JWT_SECRET,
  );

  if (revokeOtherSessions) {
    await env.DB.prepare(
      'UPDATE refresh_tokens SET revoked_at = ? WHERE officer_id = ? AND revoked_at IS NULL',
    )
      .bind(new Date(now * 1000).toISOString(), officer.id)
      .run();
  }

  const refreshToken = randomToken();
  const refreshTokenHash = await sha256Hex(refreshToken);
  await env.DB.prepare(
    'INSERT INTO refresh_tokens (id, officer_id, token_hash, created_at, expires_at) VALUES (?, ?, ?, ?, ?)',
  )
    .bind(
      crypto.randomUUID(),
      officer.id,
      refreshTokenHash,
      new Date(now * 1000).toISOString(),
      new Date((now + REFRESH_TOKEN_TTL_SECONDS) * 1000).toISOString(),
    )
    .run();

  return { accessToken, refreshToken };
}

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

// --- Google Sign-In -------------------------------------------------------
// Verified via a real JWKS signature check against Google's published keys
// (not the simpler tokeninfo endpoint, which Google's own docs say isn't
// meant for production/high-volume use). createRemoteJWKSet caches the key
// set itself and handles Google's own key rotation, at module scope so the
// cache persists across requests within a Worker isolate.
const GOOGLE_JWKS = createRemoteJWKSet(new URL('https://www.googleapis.com/oauth2/v3/certs'));

// Returns the verified ID token payload, or throws — callers map any
// failure to a single 401 without distinguishing why, same posture as
// verifyJwt().
async function verifyGoogleIdToken(idToken, env) {
  const { payload } = await jwtVerify(idToken, GOOGLE_JWKS, {
    issuer: ['https://accounts.google.com', 'accounts.google.com'],
    audience: env.GOOGLE_CLIENT_ID,
  });
  if (!payload.email || payload.email_verified !== true) {
    throw new Error('Google account email is not verified');
  }
  return payload;
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

// Mirrors findOrCreateOfficer, keyed on email instead of mobile number —
// Google Sign-In's equivalent of "find or create this officer's row".
async function findOrCreateOfficerByEmail(env, email, googleSub) {
  const existing = await env.DB.prepare('SELECT * FROM officers WHERE email = ?').bind(email).first();
  if (existing) {
    // Backfill google_sub for an officer row that predates this column —
    // never blocks sign-in on the backfill succeeding.
    if (!existing.google_sub && googleSub) {
      await env.DB.prepare('UPDATE officers SET google_sub = ? WHERE id = ?').bind(googleSub, existing.id).run();
      existing.google_sub = googleSub;
    }
    return existing;
  }

  const officer = {
    id: crypto.randomUUID(),
    mobile_number: null,
    email,
    google_sub: googleSub,
    created_at: new Date().toISOString(),
    entitlement_tier: 'free',
    entitlement_expires_at: null,
  };
  await env.DB.prepare(
    'INSERT INTO officers (id, mobile_number, email, google_sub, created_at, entitlement_tier, entitlement_expires_at) ' +
      'VALUES (?, ?, ?, ?, ?, ?, ?)',
  )
    .bind(
      officer.id,
      officer.mobile_number,
      officer.email,
      officer.google_sub,
      officer.created_at,
      officer.entitlement_tier,
      officer.entitlement_expires_at,
    )
    .run();
  return officer;
}

function officerResponseBody(officer) {
  return {
    id: officer.id,
    mobileNumber: officer.mobile_number,
    email: officer.email ?? null,
    entitlementTier: officer.entitlement_tier,
    entitlementExpiresAt: officer.entitlement_expires_at,
  };
}

// --- Route handlers -------------------------------------------------------

async function handleRequestOtp(body, env) {
  const mobileNumber = normalizeMobileNumber(body.mobileNumber);
  if (!mobileNumber) return json({ error: 'A valid 10-digit mobile number is required' }, 400);

  // Phone-OTP is a recovery path now, not a self-service sign-in option —
  // Google Sign-In is the only way to start a session unassisted. Every
  // request here (whether the number already has an officer row or not)
  // needs an active, non-expired, non-revoked grant issued by an admin for
  // exactly this number, via the "Phone Recovery" admin tab. Checked before
  // the rate limit / Twilio call so an ungranted number never gets an SMS.
  const grant = await env.DB.prepare(
    'SELECT id FROM phone_recovery_grants WHERE mobile_number = ? AND revoked_at IS NULL ' +
      'AND expires_at > ? ORDER BY granted_at DESC LIMIT 1',
  )
    .bind(mobileNumber, new Date().toISOString())
    .first();
  if (!grant) {
    return json(
      {
        error:
          'Phone sign-in isn\'t enabled for this number right now. Sign in with Google instead, or ' +
          'contact the app admin for temporary phone access.',
      },
      403,
    );
  }

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

async function handleVerifyOtp(request, body, env) {
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
  const { accessToken, refreshToken } = await issueSession(env, officer, { revokeOtherSessions: true });
  await recordLogin(request, env, officer);
  return json({ token: accessToken, refreshToken, officer: officerResponseBody(officer) });
}

async function handleGoogleSignIn(request, body, env) {
  const idToken = String(body.idToken ?? '');
  if (!idToken) return json({ error: 'idToken is required' }, 400);

  let payload;
  try {
    payload = await verifyGoogleIdToken(idToken, env);
  } catch (e) {
    console.error('verifyGoogleIdToken failed:', e.message);
    return json({ error: 'Could not verify Google sign-in' }, 401);
  }

  const email = String(payload.email).toLowerCase();
  const googleSub = String(payload.sub);

  // Same beta gate as phone-OTP: an already-registered officer can always
  // sign in again; a genuinely new email must be pre-approved.
  const existingOfficer = await env.DB.prepare('SELECT id FROM officers WHERE email = ?').bind(email).first();
  if (!existingOfficer) {
    const allowlisted = await env.DB.prepare('SELECT email FROM email_allowlist WHERE email = ?')
      .bind(email)
      .first();
    if (!allowlisted) {
      return json(
        { error: "This email isn't on the beta tester list yet. Contact the app admin to be added." },
        403,
      );
    }
  }

  const officer = await findOrCreateOfficerByEmail(env, email, googleSub);
  const { accessToken, refreshToken } = await issueSession(env, officer, { revokeOtherSessions: true });
  await recordLogin(request, env, officer);
  return json({ token: accessToken, refreshToken, officer: officerResponseBody(officer) });
}

// Best-effort, never blocks or fails the login itself — just a signal for
// the admin dashboard to spot an account being used from unexpectedly many
// different devices/locations (a possible sign of shared credentials).
async function recordLogin(request, env, officer) {
  try {
    const cf = request.cf ?? {};
    await env.DB.prepare(
      'INSERT INTO login_history (id, officer_id, mobile_number, user_agent, country, city, logged_in_at) ' +
        'VALUES (?, ?, ?, ?, ?, ?, ?)',
    )
      .bind(
        crypto.randomUUID(),
        officer.id,
        officer.mobile_number,
        request.headers.get('user-agent') ?? null,
        cf.country ?? null,
        cf.city ?? null,
        new Date().toISOString(),
      )
      .run();
  } catch (e) {
    console.error('recordLogin failed:', e.message);
  }
}

async function handleRefreshToken(body, env) {
  const rawToken = String(body.refreshToken ?? '');
  if (!rawToken) return json({ error: 'refreshToken is required' }, 400);

  const tokenHash = await sha256Hex(rawToken);
  const row = await env.DB.prepare('SELECT * FROM refresh_tokens WHERE token_hash = ?')
    .bind(tokenHash)
    .first();
  if (!row) return json({ error: 'Unauthorized' }, 401);

  if (row.revoked_at) {
    // This exact refresh token was already rotated away once before — a
    // legitimate client would be presenting the newer one it got back, so
    // this is a replay of a stolen/leaked token. Revoke every other active
    // token for this officer too, forcing a full re-login everywhere.
    await env.DB.prepare(
      'UPDATE refresh_tokens SET revoked_at = ? WHERE officer_id = ? AND revoked_at IS NULL',
    )
      .bind(new Date().toISOString(), row.officer_id)
      .run();
    return json({ error: 'Unauthorized' }, 401);
  }

  if (new Date(row.expires_at).getTime() < Date.now()) {
    return json({ error: 'Unauthorized' }, 401);
  }

  const officer = await env.DB.prepare('SELECT * FROM officers WHERE id = ?').bind(row.officer_id).first();
  if (!officer) return json({ error: 'Unauthorized' }, 401);

  const { accessToken, refreshToken } = await issueSession(env, officer);
  const newTokenHash = await sha256Hex(refreshToken);
  await env.DB.prepare(
    'UPDATE refresh_tokens SET revoked_at = ?, replaced_by_hash = ? WHERE token_hash = ?',
  )
    .bind(new Date().toISOString(), newTokenHash, tokenHash)
    .run();

  return json({ token: accessToken, refreshToken, officer: officerResponseBody(officer) });
}

// Best-effort server-side revocation on sign-out — never called mid-session,
// only when the officer explicitly logs out.
async function handleLogout(body, env) {
  const rawToken = String(body.refreshToken ?? '');
  if (rawToken) {
    const tokenHash = await sha256Hex(rawToken);
    await env.DB.prepare(
      'UPDATE refresh_tokens SET revoked_at = ? WHERE token_hash = ? AND revoked_at IS NULL',
    )
      .bind(new Date().toISOString(), tokenHash)
      .run();
  }
  return json({ status: 'logged out' });
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
  if (!requireAdmin(request, env)) return json({ error: 'Unauthorized' }, 401);

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

function requireAdmin(request, env) {
  const adminKey = request.headers.get('x-admin-key');
  return Boolean(env.ADMIN_SECRET) && adminKey === env.ADMIN_SECRET;
}

// --- Onboarding progress (for the admin dashboard) -------------------------
// A compact, officer-reported summary of how far they've got — never the
// raw content of their CV/scores, just completion flags and the readiness
// score itself, upserted whenever the app syncs. This is reported by the
// officer's own session (an honest client), not independently verified —
// good enough for "is anyone actually using this and getting stuck",
// not a source of truth for anything security- or billing-relevant.
async function handleSyncProgress(request, body, env) {
  const payload = await verifyJwt(bearerToken(request), env.JWT_SECRET);
  if (!payload) return json({ error: 'Unauthorized' }, 401);

  const b = (value) => (value ? 1 : 0);
  await env.DB.prepare(
    `INSERT INTO officer_progress (
       officer_id, rank, full_name, service, segment, readiness_score,
       readiness_dimensions_completed, readiness_dimensions_total, cv_uploaded,
       civilianized_cv_done, built_cv_done, jd_match_done, financial_plan_done,
       target_role_strategy_done, applications_count, updated_at
     ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
     ON CONFLICT(officer_id) DO UPDATE SET
       rank = excluded.rank, full_name = excluded.full_name, service = excluded.service,
       segment = excluded.segment, readiness_score = excluded.readiness_score,
       readiness_dimensions_completed = excluded.readiness_dimensions_completed,
       readiness_dimensions_total = excluded.readiness_dimensions_total,
       cv_uploaded = excluded.cv_uploaded, civilianized_cv_done = excluded.civilianized_cv_done,
       built_cv_done = excluded.built_cv_done, jd_match_done = excluded.jd_match_done,
       financial_plan_done = excluded.financial_plan_done,
       target_role_strategy_done = excluded.target_role_strategy_done,
       applications_count = excluded.applications_count, updated_at = excluded.updated_at`,
  )
    .bind(
      payload.sub,
      body.rank ?? null,
      body.fullName ?? null,
      body.service ?? null,
      body.segment ?? null,
      body.readinessScore ?? null,
      body.readinessDimensionsCompleted ?? 0,
      body.readinessDimensionsTotal ?? 0,
      b(body.cvUploaded),
      b(body.civilianizedCvDone),
      b(body.builtCvDone),
      b(body.jdMatchDone),
      b(body.financialPlanDone),
      b(body.targetRoleStrategyDone),
      body.applicationsCount ?? 0,
      new Date().toISOString(),
    )
    .run();
  return json({ status: 'synced' });
}

// Lets a fresh sign-in on a device with no local profile (reinstall, new
// device, cleared storage) prefill onboarding from whatever this officer
// already reported via handleSyncProgress above, instead of starting
// blank. Only the four fields officer_progress tracks — the rest of
// onboarding (DOB, release date, corps/arm, CV) still isn't known
// server-side and is re-entered regardless.
async function handleGetProgress(request, env) {
  const payload = await verifyJwt(bearerToken(request), env.JWT_SECRET);
  if (!payload) return json({ error: 'Unauthorized' }, 401);

  const progress = await env.DB.prepare(
    'SELECT rank, full_name, service, segment FROM officer_progress WHERE officer_id = ?',
  )
    .bind(payload.sub)
    .first();
  if (!progress) return json({ progress: null });

  return json({
    progress: {
      rank: progress.rank,
      fullName: progress.full_name,
      service: progress.service,
      segment: progress.segment,
    },
  });
}

// --- Support tickets ---------------------------------------------------
async function handleSubmitSupportTicket(request, body, env) {
  const payload = await verifyJwt(bearerToken(request), env.JWT_SECRET);
  if (!payload) return json({ error: 'Unauthorized' }, 401);

  const message = String(body.message ?? '').trim();
  if (!message) return json({ error: 'message is required' }, 400);

  const officer = await env.DB.prepare('SELECT mobile_number FROM officers WHERE id = ?')
    .bind(payload.sub)
    .first();

  const id = crypto.randomUUID();
  await env.DB.prepare(
    'INSERT INTO support_tickets (id, officer_id, mobile_number, message, status, created_at) ' +
      "VALUES (?, ?, ?, ?, 'open', ?)",
  )
    .bind(id, payload.sub, officer?.mobile_number ?? null, message, new Date().toISOString())
    .run();
  return json({ status: 'submitted', id });
}

async function handleAdminListOfficers(request, env) {
  if (!requireAdmin(request, env)) return json({ error: 'Unauthorized' }, 401);

  const { results } = await env.DB.prepare(
    `SELECT o.id, o.mobile_number, o.email, o.created_at, o.entitlement_tier, o.entitlement_expires_at,
            p.rank, p.full_name, p.service, p.segment, p.readiness_score,
            p.readiness_dimensions_completed, p.readiness_dimensions_total, p.cv_uploaded,
            p.civilianized_cv_done, p.built_cv_done, p.jd_match_done, p.financial_plan_done,
            p.target_role_strategy_done, p.applications_count, p.updated_at AS progress_updated_at
     FROM officers o
     LEFT JOIN officer_progress p ON p.officer_id = o.id
     ORDER BY o.created_at DESC`,
  ).all();

  return json({
    officers: results.map((r) => ({
      id: r.id,
      mobileNumber: r.mobile_number,
      email: r.email,
      createdAt: r.created_at,
      entitlementTier: r.entitlement_tier,
      entitlementExpiresAt: r.entitlement_expires_at,
      rank: r.rank,
      fullName: r.full_name,
      service: r.service,
      segment: r.segment,
      readinessScore: r.readiness_score,
      readinessDimensionsCompleted: r.readiness_dimensions_completed ?? 0,
      readinessDimensionsTotal: r.readiness_dimensions_total ?? 0,
      cvUploaded: Boolean(r.cv_uploaded),
      civilianizedCvDone: Boolean(r.civilianized_cv_done),
      builtCvDone: Boolean(r.built_cv_done),
      jdMatchDone: Boolean(r.jd_match_done),
      financialPlanDone: Boolean(r.financial_plan_done),
      targetRoleStrategyDone: Boolean(r.target_role_strategy_done),
      applicationsCount: r.applications_count ?? 0,
      progressUpdatedAt: r.progress_updated_at,
    })),
  });
}

async function handleAdminListSupportTickets(request, env) {
  if (!requireAdmin(request, env)) return json({ error: 'Unauthorized' }, 401);

  const { results } = await env.DB.prepare(
    `SELECT t.id, t.officer_id, t.mobile_number, t.message, t.status, t.created_at, t.resolved_at,
            o.entitlement_tier
     FROM support_tickets t
     LEFT JOIN officers o ON o.id = t.officer_id
     ORDER BY t.created_at DESC`,
  ).all();

  return json({
    tickets: results.map((r) => ({
      id: r.id,
      officerId: r.officer_id,
      mobileNumber: r.mobile_number,
      message: r.message,
      status: r.status,
      createdAt: r.created_at,
      resolvedAt: r.resolved_at,
    })),
  });
}

async function handleAdminResolveTicket(request, body, env) {
  if (!requireAdmin(request, env)) return json({ error: 'Unauthorized' }, 401);

  const id = String(body.id ?? '');
  if (!id) return json({ error: 'id is required' }, 400);

  const result = await env.DB.prepare(
    "UPDATE support_tickets SET status = 'resolved', resolved_at = ? WHERE id = ?",
  )
    .bind(new Date().toISOString(), id)
    .run();
  if (result.meta.changes === 0) return json({ error: 'No ticket found with that id' }, 404);
  return json({ status: 'resolved' });
}

// --- Phone allowlist (beta gate) --------------------------------------
async function handleAdminListAllowedPhones(request, env) {
  if (!requireAdmin(request, env)) return json({ error: 'Unauthorized' }, 401);

  const { results } = await env.DB.prepare(
    'SELECT mobile_number, note, added_at FROM phone_allowlist ORDER BY added_at DESC',
  ).all();
  return json({
    phones: results.map((r) => ({
      mobileNumber: r.mobile_number,
      note: r.note,
      addedAt: r.added_at,
    })),
  });
}

async function handleAdminAddAllowedPhone(request, body, env) {
  if (!requireAdmin(request, env)) return json({ error: 'Unauthorized' }, 401);

  const mobileNumber = normalizeMobileNumber(body.mobileNumber);
  if (!mobileNumber) return json({ error: 'A valid 10-digit mobile number is required' }, 400);

  await env.DB.prepare(
    'INSERT INTO phone_allowlist (mobile_number, note, added_at) VALUES (?, ?, ?) ' +
      'ON CONFLICT(mobile_number) DO UPDATE SET note = excluded.note',
  )
    .bind(mobileNumber, body.note ?? null, new Date().toISOString())
    .run();
  return json({ status: 'added' });
}

async function handleAdminRemoveAllowedPhone(request, body, env) {
  if (!requireAdmin(request, env)) return json({ error: 'Unauthorized' }, 401);

  const mobileNumber = normalizeMobileNumber(body.mobileNumber);
  if (!mobileNumber) return json({ error: 'A valid 10-digit mobile number is required' }, 400);

  await env.DB.prepare('DELETE FROM phone_allowlist WHERE mobile_number = ?')
    .bind(mobileNumber)
    .run();
  return json({ status: 'removed' });
}

// --- Email allowlist (beta gate for Google Sign-In) -----------------------
function normalizeEmail(raw) {
  const email = String(raw ?? '').trim().toLowerCase();
  if (!email || !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) return null;
  return email;
}

async function handleAdminListAllowedEmails(request, env) {
  if (!requireAdmin(request, env)) return json({ error: 'Unauthorized' }, 401);

  const { results } = await env.DB.prepare(
    'SELECT email, note, added_at FROM email_allowlist ORDER BY added_at DESC',
  ).all();
  return json({
    emails: results.map((r) => ({
      email: r.email,
      note: r.note,
      addedAt: r.added_at,
    })),
  });
}

async function handleAdminAddAllowedEmail(request, body, env) {
  if (!requireAdmin(request, env)) return json({ error: 'Unauthorized' }, 401);

  const email = normalizeEmail(body.email);
  if (!email) return json({ error: 'A valid email address is required' }, 400);

  await env.DB.prepare(
    'INSERT INTO email_allowlist (email, note, added_at) VALUES (?, ?, ?) ' +
      'ON CONFLICT(email) DO UPDATE SET note = excluded.note',
  )
    .bind(email, body.note ?? null, new Date().toISOString())
    .run();
  return json({ status: 'added' });
}

async function handleAdminRemoveAllowedEmail(request, body, env) {
  if (!requireAdmin(request, env)) return json({ error: 'Unauthorized' }, 401);

  const email = normalizeEmail(body.email);
  if (!email) return json({ error: 'A valid email address is required' }, 400);

  await env.DB.prepare('DELETE FROM email_allowlist WHERE email = ?').bind(email).run();
  return json({ status: 'removed' });
}

// --- Phone recovery grants (admin-gated fallback when Google Sign-In ------
// isn't working for a specific officer) ------------------------------------
const PHONE_RECOVERY_GRANT_HOURS = 24;

async function handleAdminListPhoneRecoveryGrants(request, env) {
  if (!requireAdmin(request, env)) return json({ error: 'Unauthorized' }, 401);

  // Every grant ever issued, not just active ones — this list is also the
  // usage signal for "how many officers actually hit a Google sign-in
  // problem," which is the reason this is gated per-grant rather than just
  // hidden in the UI.
  const { results } = await env.DB.prepare(
    'SELECT id, mobile_number, note, granted_at, expires_at, revoked_at ' +
      'FROM phone_recovery_grants ORDER BY granted_at DESC LIMIT 300',
  ).all();
  return json({
    grants: results.map((r) => ({
      id: r.id,
      mobileNumber: r.mobile_number,
      note: r.note,
      grantedAt: r.granted_at,
      expiresAt: r.expires_at,
      revokedAt: r.revoked_at,
    })),
  });
}

async function handleAdminGrantPhoneRecovery(request, body, env) {
  if (!requireAdmin(request, env)) return json({ error: 'Unauthorized' }, 401);

  const mobileNumber = normalizeMobileNumber(body.mobileNumber);
  if (!mobileNumber) return json({ error: 'A valid 10-digit mobile number is required' }, 400);

  const now = new Date();
  const expiresAt = new Date(now.getTime() + PHONE_RECOVERY_GRANT_HOURS * 60 * 60 * 1000);
  await env.DB.prepare(
    'INSERT INTO phone_recovery_grants (id, mobile_number, note, granted_at, expires_at) ' +
      'VALUES (?, ?, ?, ?, ?)',
  )
    .bind(crypto.randomUUID(), mobileNumber, body.note ?? null, now.toISOString(), expiresAt.toISOString())
    .run();
  return json({ status: 'granted', expiresAt: expiresAt.toISOString() });
}

async function handleAdminRevokePhoneRecoveryGrant(request, body, env) {
  if (!requireAdmin(request, env)) return json({ error: 'Unauthorized' }, 401);

  const id = String(body.id ?? '');
  if (!id) return json({ error: 'id is required' }, 400);

  await env.DB.prepare('UPDATE phone_recovery_grants SET revoked_at = ? WHERE id = ? AND revoked_at IS NULL')
    .bind(new Date().toISOString(), id)
    .run();
  return json({ status: 'revoked' });
}

// --- Login history (admin visibility into device/location diversity) -----
async function handleAdminListLoginHistory(request, env) {
  if (!requireAdmin(request, env)) return json({ error: 'Unauthorized' }, 401);

  const { results } = await env.DB.prepare(
    'SELECT officer_id, mobile_number, user_agent, country, city, logged_in_at ' +
      'FROM login_history ORDER BY logged_in_at DESC LIMIT 300',
  ).all();
  return json({
    logins: results.map((r) => ({
      officerId: r.officer_id,
      mobileNumber: r.mobile_number,
      userAgent: r.user_agent,
      country: r.country,
      city: r.city,
      loggedInAt: r.logged_in_at,
    })),
  });
}

// --- Course submissions review (grows the Skill Equivalency Matrix) -------
async function handleAdminListCourseSubmissions(request, env) {
  if (!requireAdmin(request, env)) return json({ error: 'Unauthorized' }, 401);

  const { results } = await env.DB.prepare(
    'SELECT id, mobile_number, course_name, course_description, civilian_equivalent, ' +
      'civilian_description, verified, source_note, status, submitted_at, reviewed_at ' +
      'FROM course_submissions ORDER BY submitted_at DESC LIMIT 300',
  ).all();
  return json({
    submissions: results.map((r) => ({
      id: r.id,
      mobileNumber: r.mobile_number,
      courseName: r.course_name,
      courseDescription: r.course_description,
      civilianEquivalent: r.civilian_equivalent,
      civilianDescription: r.civilian_description,
      verified: Boolean(r.verified),
      sourceNote: r.source_note,
      status: r.status,
      submittedAt: r.submitted_at,
      reviewedAt: r.reviewed_at,
    })),
  });
}

async function handleAdminApproveCourseSubmission(request, body, env) {
  if (!requireAdmin(request, env)) return json({ error: 'Unauthorized' }, 401);

  const id = String(body.id ?? '');
  if (!id) return json({ error: 'id is required' }, 400);

  const submission = await env.DB.prepare('SELECT * FROM course_submissions WHERE id = ?')
    .bind(id)
    .first();
  if (!submission) return json({ error: 'No submission found with that id' }, 404);

  const now = new Date().toISOString();
  await env.DB.prepare("UPDATE course_submissions SET status = 'approved', reviewed_at = ? WHERE id = ?")
    .bind(now, id)
    .run();

  await env.DB.prepare(
    'INSERT INTO approved_equivalencies (id, military_term, civilian_equivalent, description, ' +
      'verified, source_note, approved_at) VALUES (?, ?, ?, ?, ?, ?, ?)',
  )
    .bind(
      crypto.randomUUID(),
      submission.course_name,
      submission.civilian_equivalent ?? submission.course_name,
      submission.civilian_description ?? '',
      submission.verified,
      submission.source_note,
      now,
    )
    .run();

  return json({ status: 'approved' });
}

async function handleAdminRejectCourseSubmission(request, body, env) {
  if (!requireAdmin(request, env)) return json({ error: 'Unauthorized' }, 401);

  const id = String(body.id ?? '');
  if (!id) return json({ error: 'id is required' }, 400);

  const result = await env.DB.prepare(
    "UPDATE course_submissions SET status = 'rejected', reviewed_at = ? WHERE id = ?",
  )
    .bind(new Date().toISOString(), id)
    .run();
  if (result.meta.changes === 0) return json({ error: 'No submission found with that id' }, 404);
  return json({ status: 'rejected' });
}

export {
  handleRequestOtp,
  handleVerifyOtp,
  handleGoogleSignIn,
  handleRefreshToken,
  handleLogout,
  handleMe,
  handleGrantEntitlement,
  handleSyncProgress,
  handleGetProgress,
  handleSubmitSupportTicket,
  handleAdminListOfficers,
  handleAdminListSupportTickets,
  handleAdminResolveTicket,
  handleAdminListAllowedPhones,
  handleAdminAddAllowedPhone,
  handleAdminRemoveAllowedPhone,
  handleAdminListAllowedEmails,
  handleAdminAddAllowedEmail,
  handleAdminRemoveAllowedEmail,
  handleAdminListPhoneRecoveryGrants,
  handleAdminGrantPhoneRecovery,
  handleAdminRevokePhoneRecoveryGrant,
  handleAdminListLoginHistory,
  handleAdminListCourseSubmissions,
  handleAdminApproveCourseSubmission,
  handleAdminRejectCourseSubmission,
  verifyJwt,
  bearerToken,
};
