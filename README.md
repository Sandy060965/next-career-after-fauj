# Next Career After Fauj — Vertical Slice 1

Onboarding (service-verified sign-up: Service, Rank, Name, Date of birth,
Total work experience, tentative/actual release-from-service date, Mobile,
Email — with SSC/PMR/Superannuation segment branching and CV upload with a
confidentiality disclaimer) → Profile (read-only view of what was entered) →
Career Paths (browsable civilian-role ladders, segment-aware entry level) →
JD Match (paste or upload a job description, analyzed against the CV) →
Fitment Score / Refined CV / Certification Guidance (score out of 10 with a
per-requirement breakdown, a reframed CV, and a prioritized certification
roadmap timed against the release date). See [docs/PRD.md](docs/PRD.md) for
the full product brief.

Note: this build deliberately deviates from the PRD's "draft-CV upload or
structured-entry form" onboarding spec — CV upload is currently the only
intake path, per a later product decision. Email/mobile are format-validated
only; OTP verification is deferred until a backend/SMS/email-delivery service
exists to actually perform it. The fitment analysis is powered by a Cloudflare
Worker backend (`backend/cloudflare-worker/`) that proxies to the Anthropic
API — see the "Backend" section below for how it's authenticated.

## Prerequisites

Flutter is installed at `~/development/flutter` (added to `PATH` via
`~/.zshrc`). Android builds additionally need the JDK at
`~/development/jdk-17` and the Android SDK at `~/Library/Android/sdk` (both
also on `PATH` via `~/.zshrc`).

## Run

JD Match calls the deployed Cloudflare Worker, which requires the shared
secret set as `APP_SHARED_KEY` on the Worker (see Backend section below) to
be passed at build/run time — it's never hardcoded in source:

```
flutter run --dart-define=APP_SHARED_KEY=<value>
```

Running without the flag still launches the app, but JD Match's analysis
step will show an "Unauthorized" error since the Worker rejects requests
missing a valid key.

## Test

```
flutter test
```

## Build

```
flutter build apk --debug   --dart-define=APP_SHARED_KEY=<value>
flutter build apk --release --dart-define=APP_SHARED_KEY=<value>
# release APK is R8-minified; still signed with the debug keystore
# placeholder, not ready for Play Store submission until a real
# signing config is added
```

## Layout

- `lib/core` — theme, the `OfficerProfile` model (service, rank, name, DOB,
  work experience, release status/date, mobile, email, segment, CV filename),
  the in-memory `ProfileRepository` (Provider/`ChangeNotifier`), route name
  constants, the shared `pickFileName()` file-picker wrapper, and the
  `formatDate()` utility.
- `lib/features/onboarding` — the 3-step onboarding flow (verification →
  segment → CV upload). Rank is a dropdown constrained by the selected
  Service (`rank_options.dart`). `OnboardingScreen` takes an injectable
  `pickFile` callback so tests never touch the native file-picker channel.
- `lib/features/profile` — read-only profile screen, with links to Career
  Paths and JD Match.
- `lib/features/career_paths` — browsable list of 13 civilian functional
  verticals (`career_vertical.dart`), each a 5-rung ladder highlighting the
  rung the user's segment (SSC/PMR/Superannuation) typically enters at.
- `lib/features/jd_match` — paste-or-upload job description intake; on
  submit, calls `analyzeFitment` (real HTTP call in the running app, an
  injectable stub in tests) and navigates into the fitment result screens.
- `lib/features/fitment` — `FitmentResult` model, `fitment_http_service.dart`
  (the real Cloudflare Worker client) and `fitment_service.dart` (a mock used
  as the widget's default/test value), and three screens: Score & Gap
  Breakdown, Refined CV (original/refined toggle), and Certification
  Guidance (timeline anchored to the profile's release date).
- `test/` — widget tests for onboarding → profile, Career Paths, JD Match,
  and the three fitment screens.

## Backend

`backend/cloudflare-worker/` is a small proxy that keeps the Anthropic API
key off the client: the app POSTs `{cvText, jdText}` with an `x-app-key`
header, the Worker calls Anthropic with the analysis system prompt, and
returns the structured JSON the fitment screens render. See that folder's
`wrangler.toml` for the two secrets it needs (`ANTHROPIC_API_KEY`,
`APP_SHARED_KEY`) and use `npx wrangler secret put <NAME>` / `npx wrangler
deploy` from inside it to (re)deploy.

## Not built yet (by design)

Real OTP-based service verification, CV text extraction (CV content is
currently referenced by filename only, not parsed), and subscription/paywall
— per the phased build plan in the PRD.
