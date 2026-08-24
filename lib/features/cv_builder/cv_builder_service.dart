import 'built_cv.dart';
import 'cv_builder_intake.dart';

typedef CvBuilder = Future<BuiltCv> Function({required CvBuilderIntake intake});

/// Placeholder used until the Worker's /build-cv endpoint is deployed.
/// Returns fixed sample content so the results screen can be built and
/// tested independently of the backend.
Future<BuiltCv> mockBuildCv({required CvBuilderIntake intake}) async {
  await Future.delayed(const Duration(milliseconds: 700));
  final firstRole = intake.workExperience.isNotEmpty ? intake.workExperience.first.roleTitle : 'your role';
  return BuiltCv(
    cvText: 'Sample placeholder CV text built from your intake, starting from "$firstRole".',
  );
}
