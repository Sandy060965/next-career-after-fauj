import { INDIA_CITIES } from './india_cities.js';
import { TOP_COMPANIES } from './top_companies.js';
import { AI_COURSES } from './ai_courses.js';
import { AI_COMPETENCIES } from './ai_competencies.js';

const FITMENT_SYSTEM_PROMPT = `You are a career-transition advisor for Indian Armed Forces officers moving into
civilian roles. You will be given (a) an officer's CV text and (b) a target job
description (JD). Produce a structured analysis with exactly three parts.

STRICT RULES:
- Never invent skills, employers, dates, metrics, institutions, unit sizes, or
  achievements not present in the source CV. Only reframe, reword, or reorder
  what is already there.
- Never reference military rank progression, ACRs, or classified/unit-identifying
  details — treat the CV as the sole source of truth, already sanitized.
- If the CV lacks enough information to judge a requirement, say so explicitly
  rather than guessing.
- If the CV text is marked below as unavailable (e.g. only a filename with no
  extracted content), you have ZERO information about this officer. Do not
  infer, guess, or generate a plausible-sounding profile from the filename or
  the JD alone. In that case: mark every requirement "Gap" with notes stating
  CV content was unavailable, set fitment_score to 1 with a rationale
  explaining no CV content was available to assess, set refined_cv to a
  message explaining that CV text extraction is not yet available, and leave
  certification_guidance empty.

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

const QUERY_SYSTEM_PROMPT = `Given an officer's CV, propose ONE concise job-search query string
(role title + 1-2 key skills, e.g. "Head of Security manufacturing plant")
suitable for a job-search API. Respond with ONLY JSON: {"query": "..."}`;

const JOB_RANKING_SYSTEM_PROMPT = `You are given an officer's CV and a list of REAL job postings retrieved
from a job-search API. Never invent, alter, or add postings — only select
from and annotate the list you are given.

For each posting, you already have its exact url, ctc range (or null), and
top-company flag — do not change these values.

Select and rank the postings that best fit the CV (up to 8). For each,
write one concise sentence explaining why it fits the officer's real
experience — grounded only in what the CV actually says.

Respond with ONLY valid JSON (no markdown fences) matching this shape:
{
  "matches": [
    {"index": <index into the provided list>, "fit_reason": "..."}
  ]
}`;

const LINKEDIN_SYSTEM_PROMPT = `You are helping an Indian Armed Forces officer transitioning to civilian
roles prepare LinkedIn content, based solely on their CV.

STRICT RULES:
- Never invent skills, employers, dates, metrics, or achievements not
  present in the source CV. Only reframe, reword, or reorder what is
  already there.
- Never reference military rank progression, ACRs, or classified/unit-
  identifying details.
- If the CV text is unavailable (only a filename, no real content), say so
  in all three fields rather than inventing a profile.

Produce three pieces, respond with ONLY valid JSON (no markdown fences):
{
  "headline": "<LinkedIn headline, under 220 characters>",
  "about_section": "<first-person About section, 3-5 short paragraphs>",
  "announcement_post": "<shareable feed post announcing the transition and what they're looking for>"
}`;

const AI_READINESS_SYSTEM_PROMPT = `You are advising an Indian Armed Forces officer transitioning to a civilian
career on their AI readiness, based on their CV and a self-assessment of how
confident they feel (0-100, already computed) across five dimensions:
AI Awareness, AI Productivity, AI Decision Support, AI Leadership, and AI
Governance.

You are given a FIXED list of competencies and a FIXED list of courses/
workshops. You may only reference items from these lists — never invent a
skill name, course, provider, URL, or duration.

STRICT RULES:
- Skill gaps must each reference one competency "id" from the provided
  competency list, verbatim.
- Roadmap items that recommend a course must use one course "id" from the
  provided course list, verbatim, in "course_id". Not every roadmap item
  needs a course — some can be practice/application milestones with
  "course_id": null.
- The CV-to-AI bridge must be grounded only in what the CV actually says.
  Never invent employers, achievements, or experience not present in the CV.
- Never reference military rank progression, ACRs, or classified/unit-
  identifying details.
- If the CV text is unavailable (only a filename, no real content), say so
  in the score rationale and CV-to-AI bridge, and keep skill gaps limited to
  what the self-assessment scores alone can support.
- Do NOT invent or alter the readiness score — it is provided to you
  precomputed; only explain it.
- Roadmap should have phases "day30", "day60", "day90". If a target release
  date is provided, frame the 90-day roadmap as leading up to it; otherwise
  treat day30/60/90 as starting today.

Respond with ONLY valid JSON (no markdown fences, no commentary) matching this shape:
{
  "score_rationale": "<1-2 sentences interpreting the provided score and dimension breakdown>",
  "skill_gaps": [
    {"competency_id": "<id from the competency list>", "severity": "high|medium|low", "reason": "..."}
  ],
  "cv_ai_bridge": "<2-4 sentences connecting real CV experience to AI-relevant capability>",
  "roadmap": [
    {"phase": "day30|day60|day90", "title": "...", "description": "...", "course_id": "<id from the course list or null>"}
  ]
}`;

const CORS_HEADERS = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
  'Access-Control-Allow-Headers': 'content-type, x-app-key',
};

function stripCodeFence(text) {
  const trimmed = text.trim();
  const fenced = trimmed.match(/^```(?:json)?\s*([\s\S]*?)\s*```$/);
  return fenced ? fenced[1] : trimmed;
}

function json(body, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { 'content-type': 'application/json', ...CORS_HEADERS },
  });
}

async function callClaude(env, { system, userContent, maxTokens = 8192 }) {
  const response = await fetch('https://api.anthropic.com/v1/messages', {
    method: 'POST',
    headers: {
      'content-type': 'application/json',
      'x-api-key': env.ANTHROPIC_API_KEY,
      'anthropic-version': '2023-06-01',
    },
    body: JSON.stringify({
      model: 'claude-sonnet-4-5',
      max_tokens: maxTokens,
      system,
      messages: [{ role: 'user', content: userContent }],
    }),
  });
  if (!response.ok) {
    const detail = await response.text();
    throw new Error(`Upstream error: ${detail}`);
  }
  const data = await response.json();
  const text = data.content?.[0]?.text ?? '';
  return JSON.parse(stripCodeFence(text));
}

function buildCvSection(cvText, cvPdfBase64) {
  if (cvPdfBase64) {
    return {
      isDocument: true,
      content: [
        { type: 'document', source: { type: 'base64', media_type: 'application/pdf', data: cvPdfBase64 } },
      ],
    };
  }
  const isFilenameOnly =
    /\.(pdf|docx?|txt)$/i.test(cvText.trim()) && cvText.trim().split(/\s+/).length <= 3;
  const text = isFilenameOnly
    ? `CV: [No CV text was extracted — only the filename "${cvText.trim()}" is available. ` +
      'There is no real CV content to analyze.]'
    : `CV:\n${cvText}`;
  return { isDocument: false, content: text };
}

// ---------------------------------------------------------------------------
// /  (default) — CV/JD fitment analysis
// ---------------------------------------------------------------------------
async function handleFitmentAnalysis(body, env) {
  const { cvText, cvPdfBase64, jdText } = body;
  if (!jdText || (!cvText && !cvPdfBase64)) {
    return json({ error: 'jdText and one of cvText/cvPdfBase64 are required' }, 400);
  }

  const cv = buildCvSection(cvText, cvPdfBase64);
  const userContent = cv.isDocument
    ? [...cv.content, { type: 'text', text: `The above document is the CV.\n\nJD:\n${jdText}` }]
    : `${cv.content}\n\nJD:\n${jdText}`;

  try {
    const parsed = await callClaude(env, { system: FITMENT_SYSTEM_PROMPT, userContent });
    return json(parsed);
  } catch (e) {
    return json({ error: 'Model did not return valid JSON', detail: `${e}` }, 502);
  }
}

// ---------------------------------------------------------------------------
// /job-matches — real job listings (JSearch) ranked against the CV
// ---------------------------------------------------------------------------
function matchesCityTier(location, cityTier) {
  if (!cityTier) return true;
  if (!location) return false;
  const lower = location.toLowerCase();
  return INDIA_CITIES.some((c) => c.tier === cityTier && lower.includes(c.city.toLowerCase()));
}

function findTopCompany(employerName) {
  if (!employerName) return false;
  const lower = employerName.toLowerCase();
  return TOP_COMPANIES.some(
    (c) => lower.includes(c.name.toLowerCase()) || c.name.toLowerCase().includes(lower),
  );
}

function formatCtc(listing) {
  const { job_min_salary: min, job_max_salary: max, job_salary_currency: currency, job_salary_period: period } = listing;
  if (min == null && max == null) return null;
  const cur = currency || '';
  const per = period ? `/${period.toLowerCase()}` : '';
  if (min != null && max != null) return `${cur}${min}-${max}${per}`;
  return `${cur}${min ?? max}${per}`;
}

async function searchJSearch(env, query) {
  const cacheKey = `jsearch:${query.toLowerCase()}`;
  if (env.JOB_CACHE) {
    const cached = await env.JOB_CACHE.get(cacheKey, 'json');
    if (cached) return cached;
  }

  const url = `https://jsearch.p.rapidapi.com/search?query=${encodeURIComponent(query)}&num_pages=1&country=in`;
  const response = await fetch(url, {
    headers: {
      'x-rapidapi-key': env.RAPIDAPI_KEY,
      'x-rapidapi-host': 'jsearch.p.rapidapi.com',
    },
  });
  if (!response.ok) {
    throw new Error(`JSearch API error: ${response.status} ${await response.text()}`);
  }
  const data = await response.json();
  const listings = data.data || [];

  if (env.JOB_CACHE) {
    // Cache for 12 hours to conserve the JSearch request quota.
    await env.JOB_CACHE.put(cacheKey, JSON.stringify(listings), { expirationTtl: 12 * 60 * 60 });
  }
  return listings;
}

async function handleJobMatches(body, env) {
  const { cvText, cvPdfBase64, cityTier } = body;
  if (!cvText && !cvPdfBase64) {
    return json({ error: 'cvText or cvPdfBase64 is required' }, 400);
  }
  if (!env.RAPIDAPI_KEY) {
    return json({ error: 'Job search is not configured (missing RAPIDAPI_KEY)' }, 500);
  }

  const cv = buildCvSection(cvText, cvPdfBase64);

  // Step 1: derive a search query from the CV.
  let query;
  try {
    const queryUserContent = cv.isDocument
      ? [...cv.content, { type: 'text', text: 'Propose a search query for this CV.' }]
      : `${cv.content}\n\nPropose a search query for this CV.`;
    const queryResult = await callClaude(env, {
      system: QUERY_SYSTEM_PROMPT,
      userContent: queryUserContent,
      maxTokens: 256,
    });
    query = queryResult.query;
  } catch (e) {
    return json({ error: 'Could not derive a search query from the CV', detail: `${e}` }, 502);
  }
  if (!query) {
    return json({ error: 'Could not derive a search query from the CV' }, 502);
  }

  // Step 2: search real listings.
  let listings;
  try {
    listings = await searchJSearch(env, query);
  } catch (e) {
    return json({ error: 'Job search failed', detail: `${e}` }, 502);
  }

  // Step 3+4: filter by city tier, annotate CTC + top-company, keep only
  // fields the client needs — the URL, CTC, and company flag all come
  // straight from this real data, never touched by the LLM afterwards.
  const candidates = listings
    .map((listing) => ({
      title: listing.job_title,
      company: listing.employer_name,
      applyUrl: listing.job_apply_link || listing.job_google_link,
      location: [listing.job_city, listing.job_state].filter(Boolean).join(', ') || listing.job_country,
      postedDate: listing.job_posted_at_datetime_utc || null,
      ctcRange: formatCtc(listing),
      isTopCompany: findTopCompany(listing.employer_name),
    }))
    .filter((c) => c.applyUrl && matchesCityTier(c.location, cityTier));

  if (candidates.length === 0) {
    return json({ matches: [] });
  }

  // Step 5: have Claude select and rank the best-fitting real listings.
  let ranking;
  try {
    const listForRanking = candidates.map((c, i) => ({
      index: i,
      title: c.title,
      company: c.company,
      location: c.location,
    }));
    const rankingUserContent = cv.isDocument
      ? [
          ...cv.content,
          { type: 'text', text: `Job postings:\n${JSON.stringify(listForRanking)}` },
        ]
      : `${cv.content}\n\nJob postings:\n${JSON.stringify(listForRanking)}`;
    ranking = await callClaude(env, {
      system: JOB_RANKING_SYSTEM_PROMPT,
      userContent: rankingUserContent,
    });
  } catch (e) {
    return json({ error: 'Could not rank job matches', detail: `${e}` }, 502);
  }

  const matches = (ranking.matches || [])
    .map((m) => {
      const candidate = candidates[m.index];
      if (!candidate) return null;
      return { ...candidate, fitReason: m.fit_reason };
    })
    .filter(Boolean);

  return json({ matches });
}

// ---------------------------------------------------------------------------
// /linkedin-writeup — headline / About / announcement post from the CV
// ---------------------------------------------------------------------------
async function handleLinkedInWriteup(body, env) {
  const { cvText, cvPdfBase64 } = body;
  if (!cvText && !cvPdfBase64) {
    return json({ error: 'cvText or cvPdfBase64 is required' }, 400);
  }

  const cv = buildCvSection(cvText, cvPdfBase64);
  const userContent = cv.isDocument
    ? [...cv.content, { type: 'text', text: 'The above document is the CV.' }]
    : cv.content;

  try {
    const parsed = await callClaude(env, { system: LINKEDIN_SYSTEM_PROMPT, userContent, maxTokens: 2048 });
    return json(parsed);
  } catch (e) {
    return json({ error: 'Model did not return valid JSON', detail: `${e}` }, 502);
  }
}

// ---------------------------------------------------------------------------
// /ai-readiness — AI readiness roadmap grounded in the fixed course/
// competency reference lists and a client-computed readiness score.
// ---------------------------------------------------------------------------
async function handleAiReadiness(body, env) {
  const { cvText, cvPdfBase64, readinessScore, dimensionScores, releaseDate } = body;
  if (!cvText && !cvPdfBase64) {
    return json({ error: 'cvText or cvPdfBase64 is required' }, 400);
  }
  if (typeof readinessScore !== 'number' || !dimensionScores) {
    return json({ error: 'readinessScore and dimensionScores are required' }, 400);
  }

  const cv = buildCvSection(cvText, cvPdfBase64);
  const context = {
    readiness_score: readinessScore,
    dimension_scores: dimensionScores,
    release_date: releaseDate || null,
    competencies: AI_COMPETENCIES,
    courses: AI_COURSES.map(({ id, name, provider, duration, cost }) => ({
      id,
      name,
      provider,
      duration,
      cost,
    })),
  };
  const userContent = cv.isDocument
    ? [...cv.content, { type: 'text', text: `Context:\n${JSON.stringify(context)}` }]
    : `${cv.content}\n\nContext:\n${JSON.stringify(context)}`;

  let parsed;
  try {
    parsed = await callClaude(env, { system: AI_READINESS_SYSTEM_PROMPT, userContent, maxTokens: 4096 });
  } catch (e) {
    return json({ error: 'Model did not return valid JSON', detail: `${e}` }, 502);
  }

  // Never trust the model's own ids blindly — drop anything that doesn't
  // match a real, fixed competency/course.
  const competencyIds = new Set(AI_COMPETENCIES.map((c) => c.id));
  const courseIds = new Set(AI_COURSES.map((c) => c.id));
  const skillGaps = (parsed.skill_gaps || []).filter((g) => competencyIds.has(g.competency_id));
  const roadmap = (parsed.roadmap || []).map((item) => ({
    ...item,
    course_id: item.course_id && courseIds.has(item.course_id) ? item.course_id : null,
  }));

  return json({
    readiness_score: readinessScore,
    score_rationale: parsed.score_rationale,
    skill_gaps: skillGaps,
    cv_ai_bridge: parsed.cv_ai_bridge,
    roadmap,
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

    const path = new URL(request.url).pathname;
    if (path === '/job-matches') return handleJobMatches(body, env);
    if (path === '/linkedin-writeup') return handleLinkedInWriteup(body, env);
    if (path === '/ai-readiness') return handleAiReadiness(body, env);
    return handleFitmentAnalysis(body, env);
  },
};
