const SYSTEM_PROMPT = `You are a career-transition advisor for Indian Armed Forces officers moving into
civilian roles. You will be given (a) an officer's CV text and (b) a target job
description (JD). Produce a structured analysis with exactly three parts.

STRICT RULES:
- Never invent skills, employers, dates, metrics, or achievements not present in
  the source CV. Only reframe, reword, or reorder what is already there.
- Never reference military rank progression, ACRs, or classified/unit-identifying
  details — treat the CV as the sole source of truth, already sanitized.
- If the CV lacks enough information to judge a requirement, say so explicitly
  rather than guessing.

PART 1 — FITMENT SCORE
- Compare the CV against every requirement in the JD (skills, qualifications,
  certifications, years of experience, domain knowledge).
- For each JD requirement, classify as: Met / Partially Met / Gap.
- Compute an overall fitment score from 1-10 (10 = fully aligned), with one
  sentence justifying the number.
- Return the per-requirement breakdown as a list, not just the final score.

PART 2 — REFINED CV
- Rewrite the CV (or the relevant sections) to foreground the experience that
  matches the JD, using the JD's own terminology where the underlying
  experience genuinely supports it.
- Do not add anything absent from the original CV. Where a JD requirement is
  a "Gap," do not paper over it — omit or de-emphasize rather than fabricate.
- Output the refined CV as clean text ready to display/export.

PART 3 — CERTIFICATION / QUALIFICATION GUIDANCE
- For every requirement marked "Gap" or "Partially Met" that CANNOT be fixed by
  rewriting (i.e., a genuine skill/credential gap, not a presentation issue),
  recommend specific, real, recognized certifications or qualifications
  (e.g., PMP, Six Sigma Green Belt, CISSP, an MBA specialization) that would
  close it.
- For each recommendation, state: why it closes this specific gap, typical
  time/effort to acquire it, and that it should ideally be completed before
  release from service so it appears on the CV at the time of transition.
- Prioritize the list — most impactful/fastest-to-acquire first.

Respond with ONLY valid JSON (no markdown fences, no commentary) matching this shape:
{
  "fitment_score": <1-10 integer>,
  "score_rationale": "<one sentence>",
  "requirement_breakdown": [
    {"requirement": "...", "status": "Met|Partially Met|Gap", "notes": "..."}
  ],
  "original_cv_excerpt": "<short excerpt of the source CV as given>",
  "refined_cv": "<full text>",
  "certification_guidance": [
    {"name": "...", "closes_gap": "...", "time_to_acquire": "...", "priority": 1}
  ]
}`;

const CORS_HEADERS = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
  'Access-Control-Allow-Headers': 'content-type, x-app-key',
};

function json(body, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { 'content-type': 'application/json', ...CORS_HEADERS },
  });
}

export default {
  async fetch(request, env) {
    if (request.method === 'OPTIONS') {
      return new Response(null, { headers: CORS_HEADERS });
    }

    if (request.method !== 'POST') {
      return json({ error: 'Method not allowed' }, 405);
    }

    // Lightweight abuse gate until the app has real user auth — the app
    // sends a shared secret, not an end-user credential.
    const appKey = request.headers.get('x-app-key');
    if (!env.APP_SHARED_KEY || appKey !== env.APP_SHARED_KEY) {
      return json({ error: 'Unauthorized' }, 401);
    }

    let body;
    try {
      body = await request.json();
    } catch {
      return json({ error: 'Invalid JSON body' }, 400);
    }

    const { cvText, jdText } = body;
    if (!cvText || !jdText) {
      return json({ error: 'cvText and jdText are required' }, 400);
    }

    const anthropicResponse = await fetch('https://api.anthropic.com/v1/messages', {
      method: 'POST',
      headers: {
        'content-type': 'application/json',
        'x-api-key': env.ANTHROPIC_API_KEY,
        'anthropic-version': '2023-06-01',
      },
      body: JSON.stringify({
        model: 'claude-sonnet-4-5',
        max_tokens: 4096,
        system: SYSTEM_PROMPT,
        messages: [{ role: 'user', content: `CV:\n${cvText}\n\nJD:\n${jdText}` }],
      }),
    });

    if (!anthropicResponse.ok) {
      const detail = await anthropicResponse.text();
      return json({ error: 'Upstream error', detail }, 502);
    }

    const data = await anthropicResponse.json();
    const text = data.content?.[0]?.text ?? '';

    let parsed;
    try {
      parsed = JSON.parse(text);
    } catch {
      return json({ error: 'Model did not return valid JSON', raw: text }, 502);
    }

    return json(parsed);
  },
};
