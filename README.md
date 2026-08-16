# Officer Career App — Vertical Slice 1

Onboarding (service-verified sign-up: rank/name/email/mobile, SSC/PMR segment
branching, CV upload with a confidentiality disclaimer) → Profile (read-only
view of what was entered, in rank/name/email/mobile order). See
[docs/PRD.md](docs/PRD.md) for the full product brief.

Note: this build deliberately deviates from the PRD's "draft-CV upload or
structured-entry form" onboarding spec — CV upload is currently the only
intake path, per a later product decision. Email/mobile are format-validated
only; OTP verification is deferred until a backend/SMS/email-delivery service
exists to actually perform it.

## Prerequisites

Flutter is installed at `~/development/flutter` (added to `PATH` via
`~/.zshrc`).

## Run

```
flutter run
```

## Test

```
flutter test
```

## Layout

- `lib/core` — theme, the `OfficerProfile` model, the in-memory
  `ProfileRepository` (Provider/`ChangeNotifier`), route name constants.
- `lib/features/onboarding` — the 3-step onboarding flow (verification →
  segment → CV upload). `OnboardingScreen` takes an injectable `pickFile`
  callback so tests never touch the native file-picker channel.
- `lib/features/profile` — read-only profile screen.
- `test/` — a widget test covering the CV-upload flow end to end.

## Not built yet (by design)

AI translation, JD matching, career taxonomy, skills-gap, and
subscription/paywall — this slice stops at Onboarding → Profile per the
phased build plan in the PRD.
