# Next Career After Fauj — Executive Summary

**What it is.** A mobile/web app that helps Indian Armed Forces officers
(Short Service Commission, Premature Retirement, or Superannuation) turn
their service record into a civilian career — translating military
experience into corporate language, matching it against real job
descriptions, showing what a fair compensation package actually looks
like, and closing the specific skills gaps that stand between an officer
and their next role. Built for two segments: SSC officers (typically
30–35, higher financial urgency, no pension) and PMR/Superannuation
officers (typically 40–60, pensioned, longer service record to translate).

**How it's organized.** Everything below sits behind a one-time,
phone-verified sign-up (Service, Rank, Name, DOB, work experience, release
date, and — deliberately — no ACR or unit-identifying information, ever).
From there, a Profile screen and a Transition Readiness Index dashboard
link out to every module. The modules fall into seven natural groups:

---

## 1. Career translation — the core loop

- **JD Match** — paste or upload a real job description; the app scores
  how well the officer's CV fits it (out of 10, with a per-requirement
  breakdown), and produces:
  - **Refined CV** — the same CV, reframed in corporate language,
    nothing invented — with a toggle to compare against the original,
    and a one-tap PDF download.
  - **Gap Roadmap** — the specific skills gaps for that role, prioritized.
- **CV Civilianizer** — a general-purpose civilian version of the CV, for
  before a specific JD exists.
- **CV Builder** — builds a CV from structured entry (work experience,
  education, certifications) rather than an uploaded document.
- **CV Writing Guide** — fixed, hand-authored reference content: recommended
  CV structure and section-by-section guidance, plus 6 downloadable
  templates.

## 2. Where to aim — career exploration

- **Career Paths** — 34 civilian functional verticals, each a 5-rung
  ladder highlighting the rung an officer's segment typically enters at.
  Spans well beyond the original generalist categories (Operations,
  Supply Chain, Security & Risk, HR, Business Development, IT &
  Cybersecurity, Corporate Governance, Defence PSUs/GovTech) into
  specialized clusters — a full Healthcare track (9 verticals, from
  Clinical Practice to HealthTech to Government/PSU Healthcare) and a
  full Legal track (5, from Corporate Legal to Arbitration to Labour
  Law), plus Aviation/Maritime, Aerospace & Defence Tech, Intelligence &
  Corporate Investigations, and more.
- **Career Vertical Handbook** — deeper reference detail behind each
  vertical.
- **Corps/Arm Fit Matrix** — a ready-reckoner: pick a Corps/Arm/Branch to
  see which verticals fit best, or the reverse — narrows down what's
  worth reading in the Handbook.
- **Vertical Fit Quiz** — an aptitude-style quiz, corroborated against the
  officer's actual CV evidence (not just self-reported answers), pointing
  toward the vertical(s) most likely to fit.
- **Target Role Strategy** — a focused strategy for one specific target
  role the officer has in mind.
- **Job Matches** — live job listings (via a real market-data API),
  filterable, with a one-tap add to the Application Tracker.

## 3. Money — compensation and financial planning

- **Compensation Guidance** — plain-language education on how service and
  corporate compensation actually compare (the "cash illusion," what's
  hidden, what's deferred, how to negotiate), plus real market-salary
  benchmarking once a JD has been matched.
- **Financial & Cost-of-Living Calculator** — a full military-vs-corporate
  economic comparison: real 7th CPC pay-matrix figures pre-fill a starting
  example (editable to the officer's own numbers), covering basic pay,
  MSP, DA, accommodation, ECHS/CSD (correctly modelled as continuing after
  release, not lost), pension/gratuity, and a corporate offer's guaranteed
  vs. risk-adjusted value — producing a break-even figure and an
  "economic gap" the officer can use as a negotiating floor.

## 4. Skills, interviews, and AI-readiness

- **Skill Equivalency Matrix** — maps military courses/qualifications to
  their civilian equivalents.
- **AI Readiness** — a scenario-based quiz assessing comfort with AI tools
  relevant to civilian roles.
- **Interview Prep** — a question bank plus JD-specific mock interview
  practice with answer analysis.

## 5. The transition itself

- **Transition Plan** — phase-by-phase guidance for the run-up to release.
- **Your First 90 Days** — a roadmap for the first three months in a new
  civilian role.
- **Application Tracker** — tracks every job application's status end to
  end.
- **LinkedIn Writeup** — generates a headline, About section, and
  announcement post for the officer's transition.

## 6. Reference & orientation

- **Corporate Language Guide** — a searchable glossary bridging military
  and corporate vocabulary (every abbreviation shown with its full form),
  organized by "learn before Day 1," "learn within the first month,"
  role-specific quick reference, and more.
- **Corporate Transition – Reading Programme** — a staged, 22-book reading
  list (a 5-book minimum for the time-constrained), each book explaining
  the specific military-to-corporate gap it addresses and when to read it.

## 7. Community

- **Future Mentor Sign Up** — officers pledge a small, recurring amount of
  time (30/60 min, weekly/fortnightly/monthly) to mentor the next officer
  transitioning, once they've settled into their own civilian role — pure
  data capture, no live scheduling system to manage.

---

## The dashboard

**Transition Readiness Index** (Career Readiness screen) — a composite
view across the modules above that produce a score (JD Match, Vertical
Fit, AI Readiness, etc.), showing what's been completed and what's still
worth doing, rather than a single opaque number.

---

## What ties it together

Every module that calls an AI or market-data backend does so through a
real Cloudflare Worker (not a demo/mock) — the analysis, scores, and
guidance officers see are real outputs on their real data, not sample
content. Nothing in the app requires or accepts an ACR or unit-identifying
information, by design.
