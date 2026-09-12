# Privacy Note & Terms of Use — Beta

**Status: draft, for the closed beta only.** This has not been reviewed by
a lawyer. It's written to be honest and specific about what the app
actually does today, so beta testers can give informed consent — treat it
as a starting point to formalize (with proper legal review) before any
public or Play Store/App Store release.

Last updated: 4 September 2026.

---

## Privacy Note

### What we collect

When you sign up: your rank, full name, date of birth, service branch
(Army/Navy/Air Force), total work experience, release status and date,
mobile number, email, and your SSC/PMR/Superannuation segment. Optionally,
your Corps/Arm/Branch.

**Your CV**, if you upload one — either as extracted text or, for PDFs, the
file itself.

**Job descriptions** you paste or upload for JD Match, and whatever you
type into the compensation calculator, financial planner, CV builder, and
mentor sign-up screens.

We deliberately **do not ask for or require** your **Record of Service,
service-record documents, or any confidential or sensitive service
information**. The app is designed to work without such information.
Please do not upload it.

### How it's used and where it goes

- Your CV and job description text are sent to Anthropic's Claude API to
  generate the fitment score, refined CV, and related guidance. They are
  not used to train any model.
- Your mobile number is sent to Twilio to deliver the one-time login
  code. We don't see or store the code itself beyond verifying it.
- Everything else — your profile, saved calculator inputs, application
  tracker entries — is stored in our Cloudflare Worker/D1 database (for
  your account) and locally on your device. Your session login token is
  kept in your device's OS-level secure storage (Keychain on iOS,
  Keystore on Android), not in general app storage.
- We do not sell or share your data with advertisers or any third party
  outside the processors named above (Anthropic, Twilio, Cloudflare) who
  are only used to run the features you actively use.

### Retention and deletion

This is a beta. We're keeping data for the duration of the beta so the
app can function (your saved profile, CV, and history persist between
sessions). If you want your account and data deleted at any point —
during or after the beta — contact the developer directly and it will be
removed from the backend; ask and we'll confirm once it's done.

### Your device

Some data (your profile, saved calculator/planner inputs) lives locally
on your device via standard app storage, so uninstalling the app removes
it from that device even before a backend deletion request is processed.

---

## Terms of Use

**This is not an official product of, or endorsed by, the Indian Army,
Navy, Air Force, or Ministry of Defence.** It's an independent tool built
to help officers translate their service experience for civilian careers.

**Beta software, provided as-is.** Features may change or break during
the beta. Report issues via the feedback form — that's exactly what this
round is for.

**Not financial, legal, or tax advice.** The Compensation Guidance and
Financial Planner give estimates based on figures you enter and
publicly-sourced pay-matrix/tax data — verify anything before acting on
it, especially for financial decisions.

**Don't upload your Record of Service or confidential/sensitive service
information.** The app is built to never need it; please don't submit any
such information anywhere in it.

**Your content stays yours.** Your CV and anything else you enter is
processed only to generate the outputs you asked for (a refined CV, a
compensation estimate, etc.) — we don't claim ownership of it.

**No liability for beta use.** Since this is free, pre-launch beta
software, it's provided without warranty — use it as a helpful tool
alongside your own judgement, not as your sole source of truth for a
career or financial decision.

**You can stop anytime.** Uninstall the app or ask for your data to be
deleted whenever you like — no lock-in, nothing to cancel.
