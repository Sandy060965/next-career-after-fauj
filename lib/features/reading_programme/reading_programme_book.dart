/// One book in the Corporate Transition - Reading Programme. Every field
/// through [howToRead] is taken directly from the reviewed source
/// programme document; [whatYoudLearn] through [selfAssessmentQuestions]
/// are narrative enrichment reviewed for fabrication before use — see
/// `reading_programme_books.dart`.
class ReadingProgrammeBook {
  const ReadingProgrammeBook({
    required this.title,
    required this.author,
    required this.theme,
    required this.priority,
    required this.bestTiming,
    required this.reviewSignal,
    required this.whyItBelongs,
    required this.militaryTranslation,
    required this.practicalApplication,
    required this.howToRead,
    required this.whatYoudLearn,
    required this.keyTakeaways,
    required this.summary,
    required this.selfAssessmentQuestions,
  });

  final String title;
  final String author;
  final String theme;

  /// 'ESSENTIAL', 'HIGHLY RECOMMENDED' or 'RECOMMENDED'.
  final String priority;

  final String bestTiming;

  /// A rough, approximate reader-reception signal (e.g. Goodreads rating
  /// and count) — illustrative context, not an academic-quality score.
  final String reviewSignal;

  final String whyItBelongs;
  final String militaryTranslation;
  final String practicalApplication;
  final String howToRead;

  final String whatYoudLearn;
  final List<String> keyTakeaways;
  final String summary;
  final List<String> selfAssessmentQuestions;
}
