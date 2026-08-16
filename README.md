# Next Career After Fauj — Vertical Slice 1

Onboarding (service-verified sign-up: Service, Rank, Name, Date of birth,
Total work experience, Mobile, Email — with SSC/PMR/Superannuation segment
branching and CV upload with a confidentiality disclaimer) → Profile
(read-only view of what was entered, in the same field order) → JD Match
(paste or upload a job description). See [docs/PRD.md](docs/PRD.md) for the
full product brief.

Note: this build deliberately deviates from the PRD's "draft-CV upload or
structured-entry form" onboarding spec — CV upload is currently the only
intake path, per a later product decision. Email/mobile are format-validated
only; OTP verification is deferred until a backend/SMS/email-delivery service
exists to actually perform it. JD Match captures paste/upload input but does
not yet score anything — no backend exists for that either, and it says so
plainly in the UI rather than faking a result.

## Prerequisites

Flutter is installed at `~/development/flutter` (added to `PATH` via
`~/.zshrc`). Android builds additionally need the JDK at
`~/development/jdk-17` and the Android SDK at `~/Library/Android/sdk` (both
also on `PATH` via `~/.zshrc`).

## Run

```
flutter run
```

## Test

```
flutter test
```

## Build

```
flutter build apk --debug     # unoptimized, fast, for local testing
flutter build apk --release   # R8-minified; still signed with the debug
                               # keystore placeholder, not ready for
                               # Play Store submission until a real
                               # signing config is added
```

## Layout

- `lib/core` — theme, the `OfficerProfile` model (rank, name, DOB, work
  experience, service, mobile, email, segment, CV filename), the in-memory
  `ProfileRepository` (Provider/`ChangeNotifier`), route name constants, the
  shared `pickFileName()` file-picker wrapper, and the `formatDate()` utility.
- `lib/features/onboarding` — the 3-step onboarding flow (verification →
  segment → CV upload). Rank is a dropdown constrained by the selected
  Service (`rank_options.dart`). `OnboardingScreen` takes an injectable
  `pickFile` callback so tests never touch the native file-picker channel.
- `lib/features/profile` — read-only profile screen, with a link to JD Match.
- `lib/features/jd_match` — paste-or-upload job description intake.
- `test/` — widget tests covering the onboarding → profile flow end to end,
  and the JD Match paste/upload paths.

## Not built yet (by design)

AI translation, career taxonomy, skills-gap, and subscription/paywall — per
the phased build plan in the PRD.
