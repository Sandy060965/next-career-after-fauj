# Beta Tester Brief

Thank you for agreeing to try this out. A few things before you start.

## What this is

An app to help officers transitioning out of service — translating your
CV into corporate language, matching it against real job descriptions,
showing what a fair compensation package looks like, and helping you plan
the transition itself. See the [Executive Summary](EXECUTIVE_SUMMARY.md)
for what every module does.

**New since the last round:** a Home dashboard (your Transition Readiness
score and next 3 recommended actions, right when you open the app), a
bottom navigation bar — **Home / Career / Jobs / Learn / Profile** — that
replaces the old single scrolling list of buttons, and an **AI Assistant**
(the sparkle button, bottom-right of every screen) you can ask questions
like "explain this corporate term" or "help me prepare for an interview" —
by typing or speaking.

This is **real**, not a demo — your CV, profile, and inputs go through
the actual backend and a real AI analysis, the same as it would for a
live user. Treat your feedback accordingly: if something looks wrong or
confusing, it's a genuine bug or gap, not a placeholder.

## Before you start

Please read the [Privacy Note & Terms](PRIVACY_AND_TERMS.md) — short
version: don't upload your ACR or any unit-identifying information (the
app never needs it), this is beta software so treat any guidance
(especially financial) as a starting point rather than final advice, and
you can ask for your data to be deleted at any time.

## How to access it

**Web (all devices, including iOS):** https://nextcareerafterfauj.com
— open it in your phone or laptop browser, no install needed.

**First thing you'll see is a Cloudflare login screen**, separate from the
app itself — this restricts access to invited testers only. Enter the
exact email address we invited you with, and Cloudflare will email you a
one-time code to enter. This is a one-time-per-session check before the
app loads; it's not part of the app's own sign-up (that comes right after,
using your phone number).

**Want it to feel like an installed app?** Add it to your home screen —
takes 10 seconds, no app store, works on both iPhone and Android:
- **iPhone (Safari):** open the link, tap the **Share** icon (square with
  an arrow, bottom of the screen), scroll down and tap **"Add to Home
  Screen."**
- **Android (Chrome):** open the link, tap the **⋮** menu (top right), tap
  **"Add to Home screen"** (or Chrome may show a banner prompting this
  automatically).

Either way, you get a real icon on your home screen that opens full-screen
— no browser address bar, closer to a native app.

This beta is web-only for now (no separate Android APK) — every update we
ship is live at the link above immediately, so you're always testing the
latest version without needing to reinstall anything.

**A note on the AI Assistant's voice input:** it works well on Chrome
(desktop or Android). On iPhone/Safari, voice recognition support varies
and may not respond — if that happens, just type your question instead,
that path always works.

## What to try

You don't need to use every module, but if you can, please try:

1. **Sign up** with your real details and upload a CV (or use the
   structured CV Builder instead).
2. **The Home dashboard** — does your Transition Readiness score and the
   "next 3 actions" it suggests actually feel like a sensible starting
   point?
3. **JD Match** — paste a real job description you're interested in and
   see the fitment score, refined CV, and gap roadmap. If you upload a
   very large PDF (scanned document), you should see a clear message
   asking for a smaller file rather than the screen hanging — please tell
   us if it hangs instead.
4. **The AI Assistant** — tap the sparkle button and try a quick action,
   then try asking it something in your own words, by typing and (if your
   browser supports it) by voice.
5. **Financial Planner** — load an illustrative example close to your
   own rank/service, then swap in your own real numbers and see if the
   output makes sense to you.
6. **Compensation Guidance** — read the "reading a corporate offer"
   section — does it make sense, is anything missing?
7. Anything else that's relevant to where you are in your own transition.

## What to report

- **Anything that crashes, errors, or looks visually broken** — a
  screenshot helps a lot.
- **Anything factually wrong** — especially in the Financial Planner or
  Compensation Guidance, since those use real pay-matrix/tax figures.
  If a number looks off, tell us what you'd expect instead and why.
- **Anything confusing** — if you weren't sure what a field or button
  was asking for, that's useful even if nothing broke.
- **What's missing** — a module, a feature, a piece of guidance you
  expected to find and didn't.

Please use this form to report anything you find — it keeps a record so
nothing gets lost in a chat thread: https://forms.gle/oGXMjQRVmaqUo5sq6

## What's not there yet

No payment/subscription system, no native app or App/Play Store listing
(this beta is deliberately web-only, see above), and the browser tab icon
is still the default placeholder — none of that is what we need feedback
on right now.

Thank you again — this round of feedback directly shapes what gets built
next.
