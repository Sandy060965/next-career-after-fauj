class AppRoutes {
  AppRoutes._();

  static const String phoneVerification = '/verify-phone';
  static const String onboarding = '/';
  static const String startHere = '/start-here';
  static const String profile = '/profile';
  static const String careerReadiness = '/career-readiness';
  static const String jdMatch = '/jd-match';
  static const String verticalFit = '/vertical-fit';
  static const String careerPaths = '/career-paths';
  static const String refinedCv = '/refined-cv';
  static const String gapRoadmap = '/gap-roadmap';
  static const String jobMatches = '/job-matches';
  static const String linkedinWriteup = '/linkedin-writeup';
  static const String aiReadiness = '/ai-readiness';
  static const String interviewPrep = '/interview-prep';
  static const String ninetyDayRoadmap = '/ninety-day-roadmap';
  static const String compensation = '/compensation';
  static const String transitionPlan = '/transition-plan';
  static const String applicationTracker = '/application-tracker';
  static const String cvCivilianizer = '/civilianize-cv';
  static const String networkDirectory = '/network-directory';
  static const String financialPlanner = '/financial-planner';
  static const String targetRoleStrategy = '/target-role-strategy';
  static const String cvBuilder = '/cv-builder';
  static const String cvWritingGuide = '/cv-writing-guide';
  static const String careerHandbook = '/career-handbook';
  static const String corpsMatrix = '/corps-vertical-matrix';
  static const String corporateLanguageGuide = '/corporate-language-guide';
  static const String readingProgramme = '/reading-programme';
  static const String aiAssistant = '/ai-assistant';
  static const String supportTicket = '/support';
  static const String admin = '/admin';

  /// Dev-only navigation shortcut — see debug_menu_screen.dart. Registered
  /// only when the app is launched with --dart-define=SKIP_AUTH_FOR_TESTING.
  static const String debugMenu = '/debug';
}
