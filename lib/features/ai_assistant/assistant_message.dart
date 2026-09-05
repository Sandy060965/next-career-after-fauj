enum AssistantRole { user, assistant }

/// One turn in the assistant conversation. Kept in memory for the current
/// session only — not persisted, so a fresh app launch starts a fresh
/// conversation rather than carrying old context indefinitely.
class AssistantMessage {
  const AssistantMessage({required this.role, required this.content});

  final AssistantRole role;
  final String content;
}
