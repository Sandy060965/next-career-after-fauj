import { INDIA_CITIES } from './india_cities.js';
import { TOP_COMPANIES } from './top_companies.js';
import { AI_COURSES } from './ai_courses.js';
import { AI_COMPETENCIES } from './ai_competencies.js';
import { handleRequestOtp, handleVerifyOtp, handleMe, handleGrantEntitlement } from './auth.js';

const FITMENT_SYSTEM_PROMPT = `You are a career-transition advisor for Indian Armed Forces officers moving into
civilian roles. You will be given (a) an officer's CV text and (b) a target job
description (JD). Produce a structured analysis with exactly four parts.

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
  message explaining that CV text extraction is not yet available, mark all
  four dimension_gaps "Gap" with the same explanation, and leave gap_roadmap
  empty.

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

PART 3 — DIMENSION GAPS
- Separately assess the CV against the JD on exactly four dimensions:
  "experience" (years/domain of experience), "education" (degree/professional
  qualifications), "skills" (named skills/tools/technical ability), and
  "certifications" (formal credentials).
- For each of the four, classify Met / Partially Met / Gap with one to two
  sentences of grounded justification referencing what the JD asks for vs.
  what the CV actually shows.

PART 4 — GAP ROADMAP
- For every dimension marked "Gap" or "Partially Met" that cannot be fixed by
  rewriting alone (i.e. a genuine experience/education/skill/credential gap,
  not a presentation issue), recommend a specific, real, concrete step to
  close it — a certification (e.g. PMP, Six Sigma Green Belt, CISSP), a
  course, an MBA specialization, or (for experience/education gaps) a
  realistic way to build credibility (e.g. a part-time program, a relevant
  project, an internship route).
- For each item, state which dimension it addresses, why it closes this
  specific gap, and typical time/effort to acquire it — framed so it can
  ideally be completed before release from service.
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
  "dimension_gaps": [
    {"dimension": "experience", "status": "Met|Partially Met|Gap", "notes": "..."},
    {"dimension": "education", "status": "Met|Partially Met|Gap", "notes": "..."},
    {"dimension": "skills", "status": "Met|Partially Met|Gap", "notes": "..."},
    {"dimension": "certifications", "status": "Met|Partially Met|Gap", "notes": "..."}
  ],
  "gap_roadmap": [
    {"title": "...", "dimension": "experience|education|skills|certifications", "closes_gap": "...", "time_to_acquire": "...", "priority": 1}
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

const INTERVIEW_QUESTIONS_SYSTEM_PROMPT = `You are given a job description (JD) and, optionally, an officer's CV. Propose 5-8
interview questions this specific role is likely to probe, grounded ONLY in
what the JD actually states (its listed requirements, responsibilities, and
emphasis) — never generic filler questions, and never invented claims about
the hiring company beyond what the JD text itself says.

STRICT RULES:
- Every question must trace back to something specific the JD mentions
  (a named requirement, responsibility, skill, or context clue).
- The "reason" field must cite that specific JD detail — do not write vague
  reasons like "this is a common interview question."
- Do not repeat generic questions (e.g. "tell me about yourself") — those
  are already covered by a separate fixed question bank; focus only on
  what THIS job description specifically suggests.
- If a CV is provided, you may use it to flag likely follow-up angles (e.g.
  a gap the interviewer may probe), but never invent CV content that isn't
  there.

Respond with ONLY valid JSON (no markdown fences, no commentary) matching this shape:
{
  "questions": [
    {"question": "...", "reason": "..."}
  ]
}`;

const MOCK_INTERVIEW_SYSTEM_PROMPT = `You are an interview coach giving feedback on ONE spoken/typed practice answer from an
Indian Armed Forces officer transitioning to a civilian role. You are given the
interview question, the officer's answer, and optionally the target job
description (JD).

STRICT RULES:
- Evaluate ONLY what the officer actually said. Never invent facts, rewrite
  their answer with fabricated details, or assume experience not stated in
  the answer.
- Do not comment on their CV or career beyond what appears in the answer text.
- Be concrete: reference specific phrases or gaps in what they said, not
  generic interview advice.
- If the answer is very short or off-topic, say so plainly rather than
  inventing strengths that aren't there.

Evaluate against: STAR structure (Situation/Task/Action/Result) for
behavioural questions, relevance to the question (and JD, if provided),
conciseness, and use of civilian vocabulary over unexplained military
jargon.

Respond with ONLY valid JSON (no markdown fences, no commentary) matching this shape:
{
  "strengths": ["...", "..."],
  "improvements": ["...", "..."],
  "overall_impression": "<1-2 sentences>"
}`;

const COMPENSATION_SYSTEM_PROMPT = `Given a job description (JD), extract exactly what is needed to look up REAL market
salary data for it, plus directional negotiation guidance. This app serves
Indian Armed Forces officers transitioning to the INDIAN job market ONLY —
every estimate must be for an Indian location, in Indian Rupees.

STRICT RULES:
- "job_title" must be a concise, standard job title matching the role as
  described — not verbose, not invented beyond what the JD implies.
- "location" must ALWAYS be an Indian city — pick the single best-matching
  city from the provided list of real Indian cities based on what the JD
  states (its stated location, or the nearest major hub for its industry/
  region if no city is stated). If the JD describes a role outside India,
  still pick the closest-fit Indian city for benchmarking purposes rather
  than returning a non-Indian location — never return a city that isn't in
  the provided list.
- "negotiation_guidance" must be grounded ONLY in what the JD itself states
  (seniority signals, scope, required certifications/experience). NEVER
  invent a specific salary figure or currency amount — actual market
  numbers are looked up separately from real data, not from you.

Respond with ONLY valid JSON (no markdown fences, no commentary) matching this shape:
{
  "job_title": "...",
  "location": "<a city name from the provided list>",
  "negotiation_guidance": "<2-4 sentences>"
}`;

const CORS_HEADERS = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
  'Access-Control-Allow-Headers': 'content-type, x-app-key, authorization, x-admin-key',
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

  // /search-v2: OpenWeb Ninja retired /search in favor of this path (confirmed
  // with their support — the old path now 404s even with a valid key).
  // num_pages is unchanged; v2 only replaces offset-based "page" pagination
  // with a "cursor" param, which we don't need since we only fetch page 1.
  const url = `https://jsearch.p.rapidapi.com/search-v2?query=${encodeURIComponent(query)}&num_pages=1&country=in`;
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
  // /search-v2 wraps results as data.jobs (v1 had the array directly on
  // data) — confirmed against OpenWeb Ninja's published schema.
  const listings = data.data?.jobs || [];

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

// ---------------------------------------------------------------------------
// /interview-questions — likely questions for a specific JD, grounded in
// its actual stated requirements. The fixed, generic question bank lives
// entirely client-side and never touches this endpoint.
// ---------------------------------------------------------------------------
async function handleInterviewQuestions(body, env) {
  const { jdText, cvText, cvPdfBase64 } = body;
  if (!jdText) {
    return json({ error: 'jdText is required' }, 400);
  }

  let userContent = `JD:\n${jdText}`;
  if (cvText || cvPdfBase64) {
    const cv = buildCvSection(cvText || '', cvPdfBase64);
    userContent = cv.isDocument
      ? [...cv.content, { type: 'text', text: `The above document is the CV.\n\nJD:\n${jdText}` }]
      : `${cv.content}\n\nJD:\n${jdText}`;
  }

  try {
    const parsed = await callClaude(env, {
      system: INTERVIEW_QUESTIONS_SYSTEM_PROMPT,
      userContent,
      maxTokens: 2048,
    });
    return json(parsed);
  } catch (e) {
    return json({ error: 'Model did not return valid JSON', detail: `${e}` }, 502);
  }
}

// ---------------------------------------------------------------------------
// /mock-interview-feedback — evaluates one practice answer, grounded only
// in what the officer actually said.
// ---------------------------------------------------------------------------
async function handleMockInterviewFeedback(body, env) {
  const { question, answer, jdText } = body;
  if (!question || !answer) {
    return json({ error: 'question and answer are required' }, 400);
  }

  const userContent = `Question:\n${question}\n\nOfficer's answer:\n${answer}` +
    (jdText ? `\n\nTarget job description (for relevance only):\n${jdText}` : '');

  try {
    const parsed = await callClaude(env, {
      system: MOCK_INTERVIEW_SYSTEM_PROMPT,
      userContent,
      maxTokens: 1024,
    });
    return json(parsed);
  } catch (e) {
    return json({ error: 'Model did not return valid JSON', detail: `${e}` }, 502);
  }
}

// ---------------------------------------------------------------------------
// /compensation — real market salary data (JSearch estimated-salary), never
// an LLM-invented figure. Only the directional guidance text is generated.
// ---------------------------------------------------------------------------
async function fetchEstimatedSalary(env, jobTitle, location) {
  const url = `https://jsearch.p.rapidapi.com/estimated-salary?job_title=${encodeURIComponent(jobTitle)}&location=${encodeURIComponent(location)}&location_type=CITY`;
  const response = await fetch(url, {
    headers: {
      'x-rapidapi-key': env.RAPIDAPI_KEY,
      'x-rapidapi-host': 'jsearch.p.rapidapi.com',
    },
  });
  if (!response.ok) {
    throw new Error(`JSearch salary API error: ${response.status} ${await response.text()}`);
  }
  const data = await response.json();
  return (data.data || [])[0] || null;
}

async function handleCompensation(body, env) {
  const { jdText } = body;
  if (!jdText) {
    return json({ error: 'jdText is required' }, 400);
  }
  if (!env.RAPIDAPI_KEY) {
    return json({ error: 'Compensation guidance is not configured (missing RAPIDAPI_KEY)' }, 500);
  }

  const indiaCityNames = INDIA_CITIES.map((c) => c.city);

  let derived;
  try {
    derived = await callClaude(env, {
      system: COMPENSATION_SYSTEM_PROMPT,
      userContent: `JD:\n${jdText}\n\nReal Indian cities to choose "location" from:\n${JSON.stringify(indiaCityNames)}`,
      maxTokens: 512,
    });
  } catch (e) {
    return json({ error: 'Could not derive job title/location from the JD', detail: `${e}` }, 502);
  }

  // Never trust the model's own location blindly — fall back to a major
  // hub if it didn't pick a real city from the list we gave it.
  const location = indiaCityNames.includes(derived.location) ? derived.location : 'Mumbai';

  let salary = null;
  try {
    salary = await fetchEstimatedSalary(env, derived.job_title, location);
  } catch (e) {
    // Real data is best-effort — still return the (fabrication-free)
    // negotiation guidance even if the salary lookup itself fails.
    salary = null;
  }

  // This app only shows India-market figures in Rupees — discard anything
  // that isn't INR rather than surfacing a foreign-currency number.
  if (salary && salary.salary_currency !== 'INR') {
    salary = null;
  }

  return json({
    job_title: derived.job_title,
    location,
    min_salary: salary?.min_salary ?? null,
    max_salary: salary?.max_salary ?? null,
    median_salary: salary?.median_salary ?? null,
    salary_currency: salary?.salary_currency ?? null,
    salary_period: salary?.salary_period ?? null,
    confidence: salary?.confidence ?? null,
    publisher_name: salary?.publisher_name ?? null,
    negotiation_guidance: derived.negotiation_guidance,
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
    if (path === '/interview-questions') return handleInterviewQuestions(body, env);
    if (path === '/mock-interview-feedback') return handleMockInterviewFeedback(body, env);
    if (path === '/compensation') return handleCompensation(body, env);
    if (path === '/auth/request-otp') return handleRequestOtp(body, env);
    if (path === '/auth/verify-otp') return handleVerifyOtp(body, env);
    if (path === '/me') return handleMe(request, env);
    if (path === '/admin/grant-entitlement') return handleGrantEntitlement(request, body, env);
    return handleFitmentAnalysis(body, env);
  },
};
