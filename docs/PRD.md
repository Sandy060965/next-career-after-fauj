# Product Requirements Document (PRD)
## AI Career-Translation App — Indian Armed Forces Officers

---

**Problem.** Officers leaving service — via Short Service Commission (SSC) completion (typically age 30–35) or premature retirement (PMR) after 20+ years' pensionable service (typically age 40–52) — struggle to translate military experience into corporate-recognized language, tailor applications to specific job descriptions, pass ATS filters, identify concrete skill gaps ahead of release, and see a clear long-term career trajectory rather than just the next job. No existing tool (government, Army-run, or private) combines AI-driven JD-specific translation with a mobile-first experience for this audience, and none offers structured pre-release skills-gap guidance or a segment-matched career-pathing view.

**Target user.** Two segments, both officers only:
- **Segment A — SSC officers**, typically age 30–35, no pension, higher financial urgency, enter at managerial/deputy level.
- **Segment B — PMR officers**, typically age 40–52, 20+ years pensionable service, lower financial urgency, longer service record to translate, enter at head/director level.

**Value proposition.** "Understand exactly how your service record translates to the corporate roles you're targeting, see where that role leads over the next 10 years, close the specific gaps that stand in the way, and apply with a CV and cover letter matched to each job — without ever having to expose confidential service records."

---

## MVP Screens (6)

1. **Onboarding & Intake** — service-verified sign-up, segment branching (A/B), choice between draft-CV upload or generalized structured-entry form (role + formation category + generalized context; no unit-identifying fields; ACR/service-record upload is a hard exclusion).
2. **Profile / Translated CV** — AI-translated corporate-language profile view, editable, exportable (PDF/DOCX).
3. **JD Match** — paste a job description → match score, keyword-gap highlights, one-tap tailored CV/cover-letter regeneration; tags the JD's vertical/level against the career-taxonomy ladder.
4. **Career Paths (Taxonomy)** — browsable job-profile taxonomy across 13 functional verticals (Security, Administration, Business Development, Supply Chain, Operations, HR, Manufacturing/Technical, Project Management, Corporate Affairs & Governance, L&D, Hospitality/Institutional Management, IT/Cybersecurity, PSU/Government), each showing a segment-matched entry role (SSC vs. PMR level) and its forward career trajectory; segment-aware default view, freely browsable.
5. **Skills-Gap & Prep** — ranked gap list against target JDs and target ladder position, recommended courses/certifications/webinars (incl. a dedicated AI-skills track), progress tracking.
6. **Subscription / Paywall** — free tier limits vs. ₹1,200/year unlock, shown contextually after value is demonstrated (post first translated CV or first match score), not before.

---

## Monetization

- **Free tier (ad-supported):** one-time basic CV translation, one JD match score, view-only curated job feed, view-only community directory, top-3 skills-gap summary (no recommendations), full career-taxonomy browsing (all verticals and forward paths, informational only).
- **Subscription (₹1,200/year, ≈₹100/month):** unlimited JD-specific tailoring and match scoring, full ATS optimization layer, cover letter generation, application pipeline tracker, interview prep bank, full ranked skills-gap recommendations with progress tracking, taxonomy integration into live JD matching and gap scoping, priority support.
- **Ad placement rule:** never mid-task; rewarded ads only, capped frequency; lighter ad load for Segment A (SSC, higher financial stress) as a trust-building design choice.

---

## Non-Negotiable Constraints

- **No ACR or formal service-record upload anywhere in the app** — confidential, security-sensitive, national-security implications. Data intake is limited to (1) officer-authored draft CV, or (2) generalized structured entry with no free-text unit/formation-identity field.
- **No automated multi-portal auto-apply** — job-board ToS violation and Google Play policy risk; the app supports tailored generation and a manual application tracker, not automated submission.
- **DPDP Act 2023-aligned data handling** — explicit consent screens, minimal retention, no third-party/advertiser sharing of any service-related data, on-device processing where feasible.
- **No implied government/Army endorsement** in branding, messaging, or app store listing.

---

## Success Metrics (first 6 months)

- 5,000+ installs from officer-specific channels (LinkedIn veteran communities, regimental/course WhatsApp groups, M2C-adjacent networks).
- >3% free-to-paid conversion.
- One institutional or community partnership (Sainik Board, regimental association, or DGR-empanelled training institute) opened for distribution.

---

*This PRD consolidates the prior competitive due diligence, feature specification, security/skills-gap refinements, and career-taxonomy module into a single build brief. It is ready to hand to Claude Code as the opening brief for Phase 5 (Build Execution) of the original roadmap — starting with the single vertical slice: Onboarding → Profile → one working JD Match score.*
