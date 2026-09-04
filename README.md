# Next Career After Fauj

An AI career-transition app for Indian Armed Forces officers (SSC/PMR/
Superannuation) moving into civilian careers — CV translation and tailoring,
JD-specific fitment scoring, a 13-vertical career taxonomy, skills-gap
roadmaps, and a growing set of reference/planning tools (compensation
guidance, a real-pay-matrix financial calculator, corporate language guide,
reading programme, and more). See [docs/PRD.md](docs/PRD.md) for the
original product brief and [docs/EXECUTIVE_SUMMARY.md](docs/EXECUTIVE_SUMMARY.md)
for a plain-language walkthrough of every module.

**Status: pre-launch beta.** Real backend, real phone-OTP login, no payment
gateway yet, not listed on any app store. See "What's not built yet" below.

## Prerequisites

Flutter is installed at `~/development/flutter` (added to `PATH` via
`~/.zshrc`). Android builds additionally need the JDK at
`~/development/jdk-17` and the Android SDK at `~/Library/Android/sdk` (both
also on `PATH` via `~/.zshrc`).

## Run

The app calls the deployed Cloudflare Worker for every AI/backend feature,
which requires the shared secret set as `APP_SHARED_KEY` on the Worker (see
Backend section below) to be passed at build/run time — it's never
hardcoded in source:

```
flutter run --dart-define=APP_SHARED_KEY=<value>
```

Running without the flag still launches the app, but every backend-calling
screen (JD Match, Compensation, CV tools, etc.) will show an "Unauthorized"
error since the Worker rejects requests missing a valid key.

For a UI-only preview that skips phone verification (no real OTP needed),
add `--dart-define=SKIP_AUTH_FOR_TESTING=true` — debug-only, never set in a
real build; see `main.dart`. Screens that call the real backend will still
require a valid `APP_SHARED_KEY` and will still fail auth-gated calls
without a real session, since this flag only bypasses the phone-verification
*screen*, not the Worker's own auth.

## Test

```
flutter test
```

246+ widget/unit tests across every module.

## Build

**Web** (fastest path to a shareable link — see "Beta distribution" below):
```
flutter build web --dart-define=APP_SHARED_KEY=<value>
```

**Android:**
```
flutter build apk --debug   --dart-define=APP_SHARED_KEY=<value>
flutter build apk --release --dart-define=APP_SHARED_KEY=<value>
```
Release APK is R8-minified but still signed with the debug keystore
placeholder and uses the default `com.example.next_career_after_fauj`
application ID — fine for sideloading beta testers, **not** Play Store
submission-ready (needs a real applicationId + release signing config).

**iOS:** no distribution setup yet (no Apple Developer account/provisioning
configured in this repo).

## Layout

- `lib/core` — `OfficerProfile` model, `ProfileRepository` (Provider/
  `ChangeNotifier`, persists via `SharedPreferences` + `flutter_secure_storage`
  for session tokens), route name constants, shared utilities (file picker,
  PDF export, date formatting).
- `lib/features/*` — one directory per module (27 total); see
  [docs/EXECUTIVE_SUMMARY.md](docs/EXECUTIVE_SUMMARY.md) for what each one does.
  Every screen that calls the backend takes an injectable function parameter
  (defaulting to a `mock*` implementation for tests); `lib/main.dart` wires
  every route to its real `http*` implementation.
- `test/` — widget/unit tests, one file per module, mirroring `lib/features/`.

## Backend

`backend/cloudflare-worker/` is a Cloudflare Worker (`next-career-after-fauj-fitment`)
that:
- proxies AI analysis calls to the Anthropic API (keeping the API key off
  the client),
- handles phone-OTP login via Twilio Verify and issues JWT session tokens,
- reads/writes a D1 database (`next-career-after-fauj-officers`) for officer
  accounts, entitlements, and mentor-pledge records,
- proxies job-market data via the JSearch (RapidAPI) API.

See `wrangler.toml` for the full secrets list and use `npx wrangler secret
put <NAME>` / `npx wrangler deploy` from inside `backend/cloudflare-worker/`
to (re)deploy. There's currently no CI — every deploy is manual.

## What's not built yet

- **Subscription/paywall** — no payment gateway; the only entitlement
  mechanism is a manual `ADMIN_SECRET`-gated grant endpoint.
- **Public hosting** — the web build has no deployed URL yet; run it
  locally or see "Beta distribution" for how to get a shareable link.
- **Play Store / App Store distribution** — Android needs a real
  applicationId + signing config; iOS needs Apple Developer setup.
- **CI/CD** — no automated test/build/deploy pipeline.
- Real app icon (currently the default Flutter template icon).

## Beta distribution

See [docs/TESTER_BRIEF.md](docs/TESTER_BRIEF.md) for what to send testers,
and [docs/PRIVACY_AND_TERMS.md](docs/PRIVACY_AND_TERMS.md) for the privacy
note / terms to share alongside it.
