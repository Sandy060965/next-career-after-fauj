import 'dart:html' as html;

/// True when the page is running in the browser's "installed app" display
/// mode (added to home screen / launched from its own icon), as opposed to
/// a normal browser tab. Confirmed this session: Safari's Web Speech
/// Recognition API — used for the mic/voice-input buttons — silently
/// produces zero results in this mode even though it works in a plain
/// Safari tab on the same device, so this lets the mic buttons detect the
/// situation up front and point the officer at the fix (open the site in
/// the browser instead) rather than let a doomed attempt run and report a
/// generic "didn't catch that".
bool isRunningAsInstalledApp() {
  try {
    return html.window.matchMedia('(display-mode: standalone)').matches;
  } catch (_) {
    return false;
  }
}
