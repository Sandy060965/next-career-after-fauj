# Next Career After Fauj

An AI career-transition app for Indian Armed Forces officers (SSC/PMR/
Superannuation) moving into civilian careers — CV translation and tailoring,
JD-specific fitment scoring, a 13-vertical career taxonomy, skills-gap
roadmaps, and a growing set of reference/planning tools (compensation
guidance, a real-pay-matrix financial calculator, corporate language guide,
reading programme, and more). See [docs/PRD.md](docs/PRD.md) for the
original product brief and [docs/EXECUTIVE_SUMMARY.md](docs/EXECUTIVE_SUMMARY.md)
for a plain-language walkthrough of every module.

**Status: pre-launch beta.** Real backend, Google Sign-In as the primary
login with phone-OTP kept as a fallback, no payment gateway yet, not listed
on any app store. See "What's not built yet" below.

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
flutter run --dart-define=APP_SHARED_KEY=<value> --dart-define=GOOGLE_SERVER_CLIENT_ID=<value>
```

`GOOGLE_SERVER_CLIENT_ID` is the Google Cloud OAuth 2.0 Web-application
Client ID (Google Cloud Console > APIs & Services > Credentials) — the same
value set as the Worker's `GOOGLE_CLIENT_ID` secret. Running without it still
launches the app, but tapping "Sign in with Google" will fail; phone-OTP
sign-in works regardless.

Running without `APP_SHARED_KEY` still launches the app, but every
backend-calling screen (JD Match, Compensation, CV tools, etc.) will show an
"Unauthorized" error since the Worker rejects requests missing a valid key.

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

348+ widget/unit tests across every module.

## Build

**Web** (fastest path to a shareable link — see "Beta distribution" below):
```
flutter build web --dart-define=APP_SHARED_KEY=<value> --dart-define=GOOGLE_SERVER_CLIENT_ID=<value>
```

**Android:**
```
flutter build apk --debug   --dart-define=APP_SHARED_KEY=<value> --dart-define=GOOGLE_SERVER_CLIENT_ID=<value>
flutter build apk --release --dart-define=APP_SHARED_KEY=<value> --dart-define=GOOGLE_SERVER_CLIENT_ID=<value>
```
Google Sign-In on Android additionally needs a real `applicationId` (see
below) and an Android-type OAuth client in the same Google Cloud project,
registered with that application ID and the build's SHA-1 signing
fingerprint — otherwise the "Sign in with Google" button will fail even
with a correct `GOOGLE_SERVER_CLIENT_ID`.
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
- handles Google Sign-In (primary) and phone-OTP login via Twilio Verify
  (fallback) and issues JWT session tokens,
- reads/writes a D1 database (`next-career-after-fauj-officers`) for officer
  accounts, entitlements, and mentor-pledge records,
- proxies job-market data via the JSearch (RapidAPI) API.

See `wrangler.toml` for the full secrets list and use `npx wrangler secret
put <NAME>` to set/rotate them. To (re)deploy, either run `npx wrangler
deploy` from inside `backend/cloudflare-worker/` yourself, or trigger the
**Deploy Backend Worker** GitHub Actions workflow (see "Deploying" below)
— both do the same thing, the workflow just doesn't need Node installed
locally.

## Web hosting

The web build is deployed as a separate Cloudflare Worker (static assets,
what used to be called "Cloudflare Pages" — Cloudflare folded Pages into
Workers) — a different project from the API backend above:

```
flutter build web --release --dart-define=APP_SHARED_KEY=<value> \
  --dart-define=GOOGLE_SERVER_CLIENT_ID=<value>
npx wrangler deploy   # from the repo root — uses wrangler.jsonc
```

Or trigger the **Deploy Web App** GitHub Actions workflow instead of
running those two commands locally — see "Deploying" below.

Live at: **https://nextcareerafterfauj.com** (custom domain, registered
via Cloudflare Registrar and connected as this Worker's custom domain —
the underlying `next-career-after-fauj.sandy060965.workers.dev` still
resolves too, but isn't the one to share).

`wrangler.jsonc`'s `assets.directory` must point at `build/web` (the
compiled output), not `web` (the source scaffold) — `wrangler deploy`
auto-detects the wrong one by default if `wrangler.jsonc` doesn't already
exist, since `web/` also contains an `index.html`.

### Deploying

Both `.github/workflows/deploy-web.yml` and `.github/workflows/deploy-
backend.yml` are **manual-only** (`workflow_dispatch`) — nothing deploys
on push or merge. Ship a change from the GitHub UI: Actions tab -> pick
the workflow -> **Run workflow**. That deliberate click matters here more
than usual: this is a live beta with real officer accounts, so a
merge-triggered auto-deploy would ship a bad `main` (which has happened
mid-session before) straight to them with no checkpoint.

One-time setup, in the repo's Settings -> Secrets and variables ->
Actions:

| Name | Kind | Used by | Value |
|---|---|---|---|
| `CLOUDFLARE_API_TOKEN` | Secret | both workflows | A Cloudflare API token scoped to *Account -> Workers Scripts -> Edit* (the dashboard's "Edit Cloudflare Workers" template token covers this) |
| `APP_SHARED_KEY` | Secret | deploy-web | Same value already set as a secret on the backend Worker — the app sends it as the `x-app-key` header, so both sides must agree |
| `GOOGLE_SERVER_CLIENT_ID` | Variable | deploy-web | The Google OAuth Web-application Client ID — not sensitive (it's public in the compiled JS either way), so a repo *variable* rather than a secret |

The backend Worker's own runtime secrets (`ANTHROPIC_API_KEY`, `TWILIO_*`,
`JWT_SECRET`, `ADMIN_SECRET`, `GOOGLE_CLIENT_ID`, `RAPIDAPI_KEY`) live on
the Worker itself via `wrangler secret put` and are untouched by either
workflow — they don't need to be GitHub secrets too.

### Access control

The live site sits behind **Cloudflare Access** (Zero Trust → Access
controls → Applications → "nextcareerafterfauj.com"), gated to an
email allow-list (policy: "Beta Testers") — only those exact addresses
can get past the login wall, regardless of who has the link. To add or
remove a tester, edit that policy's email list directly in the Cloudflare
dashboard.

### Admin dashboard

Reached at `/admin` on the live web app (e.g.
`https://nextcareerafterfauj.com/#/admin`) — not linked from anywhere in
the app's own navigation. Gated on the `ADMIN_SECRET` Worker secret (`npx
wrangler secret put ADMIN_SECRET` to set/rotate it); the key is entered
once per visit and held in memory only, never persisted to disk. Shows
every signed-up officer with a self-reported onboarding-progress snapshot
(Transition Readiness score, which modules they've completed, applications
tracked), and a Support Tickets tab for messages officers submit in-app via
Profile → Help & Support.

## What's not built yet

- **Subscription/paywall** — no payment gateway; the only entitlement
  mechanism is a manual `ADMIN_SECRET`-gated grant endpoint.
- **Play Store / App Store distribution** — Android needs a real
  applicationId + signing config; iOS needs Apple Developer setup (the
  web build above works fine on iOS in the meantime, just not as an
  installed app).
- **CI/CD** — deploy is a manual button-press (see "Deploying" above),
  not automatic on push/merge; there's also no automated `flutter
  test`/`flutter analyze` run on PRs yet.

## Beta distribution

See [docs/TESTER_BRIEF.md](docs/TESTER_BRIEF.md) for what to send testers,
and [docs/PRIVACY_AND_TERMS.md](docs/PRIVACY_AND_TERMS.md) for the privacy
note / terms to share alongside it.
