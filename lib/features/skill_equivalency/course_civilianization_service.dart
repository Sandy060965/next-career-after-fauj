import 'course_civilianization.dart';

typedef CourseCivilianizer = Future<CourseCivilianizationResult> Function({
  required String courseName,
  String? courseDescription,
  String? mobileNumber,
});

/// Placeholder used until the Worker's /civilianize-course endpoint is
/// wired in. Returns a fixed, clearly-unverified sample so the screen can
/// be built and tested independently of the backend.
Future<CourseCivilianizationResult> mockCivilianizeCourse({
  required String courseName,
  String? courseDescription,
  String? mobileNumber,
}) async {
  await Future.delayed(const Duration(milliseconds: 700));
  return CourseCivilianizationResult(
    civilianEquivalent: 'Sample Civilian Equivalent',
    description: 'Sample placeholder translation for "$courseName".',
    verified: false,
    sourceNote: 'Sample data — not a real search result.',
  );
}
