# Beta Tester Brief (WhatsApp version)

This is the version of the tester brief actually sent to testers over
WhatsApp — plain-text formatting (single asterisks for bold/italic, no
real markdown headers) rather than `docs/TESTER_BRIEF.md`'s rendered
markdown. Update this file whenever the WhatsApp message changes, so the
two don't drift silently out of sync with each other.

---

Thank you for agreeing to try this out. A few things before you start.

## What this is

An app to help officers transitioning out of service — translating your CV into corporate language, matching it against real job descriptions, showing what a fair compensation package looks like, and helping you plan the transition itself. See the [Executive Summary](EXECUTIVE_SUMMARY.md)
for what every module does.

When you open it, you'll land on a Home dashboard showing your Transition Readiness score and the next 3 recommended actions, with a bottom navigation bar — Home / Career / Jobs / Learn / Profile — to get to every module. There's also an AI Assistant (the sparkle button, bottom-right of every screen) you can ask questions like "explain this corporate term" or "help me prepare for an interview" — by typing or
speaking.

This is real, not a demo — your CV, profile, and inputs go through the actual backend and a real AI analysis, the same as it would for a live user. Treat your feedback accordingly: if something looks wrong or confusing, it's a genuine bug or gap, not a placeholder.

## Before you start

Please read the [Privacy Note & Terms] (PRIVACY_AND_TERMS.md) — short version: don't upload your *Record of Service, service-record documents, or any confidential or sensitive service information* (the app never needs it), this is beta software so treat any guidance
(especially financial) as a starting point rather than final advice, and you can ask for your data to be deleted at any time.

## How to access it

We recommend starting on a desktop/laptop browser for the fullest screen and easiest typing — though it works well on every device.

Web (all devices, including iOS): 
https://nextcareerafterfauj.com
— open it in your browser, no install needed.

First thing you'll see is a Cloudflare login screen, separate from the app itself — this restricts access to invited testers only. Enter the exact email address we invited you with, and Cloudflare will email you a one-time code to enter. This is a one-time-per-session check before the app loads; it's not part of the app's own sign-up.

Inside the app, sign in with Google using that same invited email — that's the app's own account, and it should go through in one tap. If you see a message saying your email isn't recognized yet, message us first so we can add you, then try again — please don't use the "Trouble signing in?" phone-number option on your own initiative. That option only works when we've explicitly enabled it for your number, and it creates a separate account from your Google one. So once you're in — whichever way that happened — stick with that same method every time, rather than switching between Google and phone sign-in.

Want it to feel like an installed app? Add it to your home screen — takes 10 seconds, no app store, works on laptop, iPhone, and Android:
•⁠  ⁠Laptop (Chrome): open the link, look for a small install icon at the right end of the address bar (a monitor with a down-arrow) and click it, then click "Install." Don't see that icon? Use the ⋮ menu →
  "Cast, save and share" → "Install page as app" instead. After installing, the app may not stay in your Dock/taskbar on its own — right-click its icon while it's open and choose "Keep in Dock"
  (Mac) or "Pin to taskbar" (Windows) to make that permanent.
•⁠  ⁠iPhone (Safari): open the link, tap the Share icon (square with an arrow, bottom of the screen), scroll down and tap "Add to Home Screen."
•⁠  ⁠Android (Chrome): open the link, tap the ⋮ menu (top right), tap
  "Add to Home screen" (or Chrome may show a banner prompting this automatically).

Either way, you get a real icon that opens full-screen — no browser address bar, closer to a native app.

This beta is web-only for now (no separate Android APK) — every update we ship is live at the link above immediately, so you're always testing the
latest version without needing to reinstall anything.

A note on the AI Assistant's voice input: it works well on Chrome (desktop or Android). On iPhone/Safari, voice recognition support varies
and may not respond — if that happens, just type your question instead, that path always works.

## What to try

You don't need to use every module, but if you can, please try:

1.⁠ ⁠Sign up with your real details and upload a CV (or use the structured CV Builder instead).
2.⁠ ⁠The Home dashboard — does your Transition Readiness score and the "next 3 actions" it suggests actually feel like a sensible starting point?
3.⁠ ⁠JD Match — paste a real job description you're interested in and see the fitment score, refined CV, and gap roadmap. If you upload a
very large PDF (scanned document), you should see a clear message asking for a smaller file rather than the screen hanging — please tell us if it hangs instead.
4.⁠ ⁠The AI Assistant — tap the sparkle button and try a quick action, then try asking it something in your own words, by typing and (if your browser supports it) by voice.
5.⁠ ⁠Financial Planner — load an illustrative example close to your own rank/service, then swap in your own real numbers and see if the output makes sense to you.
6.⁠ ⁠Compensation Guidance — read the "reading a corporate offer" section — does it make sense, is anything missing?
7.⁠ ⁠The Learn tab — under "Prepare," try the new Corporate Culture & Work Environment and Business Etiquette & Professional Conduct guides, and the Learning Resources Library (also linked straight off your Gap Roadmap results). Under "Build Your CV," open the Sample CV Library and look up your own service/rank/career-track — does it read as realistic for your level, or generic?
8.⁠ ⁠Anything else that's relevant to where you are in your own transition.

## What to report

•⁠  ⁠Anything that crashes, errors, or looks visually broken — a screenshot helps a lot.
•⁠  ⁠Anything factually wrong — especially in the Financial Planner or Compensation Guidance, since those use real pay-matrix/tax figures. If a number looks off, tell us what you'd expect instead and why.
•⁠  ⁠Anything confusing — if you weren't sure what a field or button was asking for, that's useful even if nothing broke.
•⁠  ⁠What's missing — a module, a feature, a piece of guidance you expected to find and didn't.

Please use this form to report anything you find — it keeps a record so nothing gets lost in a chat thread: https://forms.gle/oGXMjQRVmaqUo5sq6

## What's not there yet

No payment/subscription system and no native app or App/Play Store listing (this beta is deliberately web-only, see above) — none of that is what we need feedback on right now.

Thank you again — this round of feedback directly shapes what gets built next.
