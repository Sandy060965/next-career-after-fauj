/// LinkedIn-ready content derived from the officer's CV. All three pieces
/// only reframe what's genuinely in the source CV — never invented facts,
/// employers, or achievements.
class LinkedInWriteup {
  const LinkedInWriteup({
    required this.headline,
    required this.aboutSection,
    required this.announcementPost,
  });

  /// The short line shown under the name on a LinkedIn profile.
  final String headline;

  /// A first-person narrative for LinkedIn's About/Summary section.
  final String aboutSection;

  /// A shareable feed post announcing the officer's transition.
  final String announcementPost;
}
