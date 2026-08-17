import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:next_career_after_fauj/core/services/profile_repository.dart';
import 'package:next_career_after_fauj/core/theme/app_theme.dart';
import 'package:next_career_after_fauj/features/fitment/fitment_result.dart';
import 'package:next_career_after_fauj/features/interview_prep/interview_practice_screen.dart';
import 'package:next_career_after_fauj/features/interview_prep/interview_prep_screen.dart';
import 'package:next_career_after_fauj/features/interview_prep/interview_question.dart';
import 'package:next_career_after_fauj/features/interview_prep/jd_interview_question.dart';
import 'package:next_career_after_fauj/features/interview_prep/voice_input_service.dart';
import 'package:provider/provider.dart';

const _stubFitmentResult = FitmentResult(
  fitmentScore: 7,
  scoreRationale: 'Test',
  requirementBreakdown: [],
  originalCvExcerpt: 'Excerpt',
  refinedCv: 'Refined',
  dimensionGaps: [],
  gapRoadmap: [],
);

Future<List<JdInterviewQuestion>> _stubGenerateJdQuestions({
  required String jdText,
  String? cvText,
}) async =>
    const [
      JdInterviewQuestion(
        question: 'Tailored question about the role.',
        reason: 'The JD asks for this specific skill.',
      ),
    ];

class _FakeVoiceInputService implements VoiceInputService {
  bool initializeCalled = false;
  bool startListeningCalled = false;
  bool stopListeningCalled = false;
  bool _listening = false;
  bool available = true;

  @override
  Future<bool> initialize() async {
    initializeCalled = true;
    return available;
  }

  @override
  bool get isListening => _listening;

  @override
  Future<void> startListening({required void Function(String text) onResult}) async {
    startListeningCalled = true;
    _listening = true;
    onResult('Dictated practice answer.');
  }

  @override
  Future<void> stopListening() async {
    stopListeningCalled = true;
    _listening = false;
  }
}

Widget _wrap(Widget child, {ProfileRepository? repository}) {
  return ChangeNotifierProvider<ProfileRepository>.value(
    value: repository ?? ProfileRepository(),
    child: MaterialApp(theme: AppTheme.light, home: child),
  );
}

void main() {
  group('InterviewPrepScreen', () {
    testWidgets('shows a prompt to run JD Match when no JD is cached yet', (tester) async {
      await tester.pumpWidget(
        _wrap(const InterviewPrepScreen(generateJdQuestions: _stubGenerateJdQuestions)),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('noJdQuestionsCard')), findsOneWidget);
      expect(find.byKey(const Key('jdSpecificQuestionsCard')), findsNothing);
    });

    testWidgets('shows JD-specific questions once a JD is cached', (tester) async {
      final repository = ProfileRepository()
        ..saveFitmentResult(_stubFitmentResult, jdText: 'Looking for a COO with P&L ownership.');

      await tester.pumpWidget(
        _wrap(
          const InterviewPrepScreen(generateJdQuestions: _stubGenerateJdQuestions),
          repository: repository,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('jdSpecificQuestionsCard')), findsOneWidget);
      expect(find.text('Tailored question about the role.'), findsOneWidget);
      expect(find.text('The JD asks for this specific skill.'), findsOneWidget);
    });

    testWidgets('lists all five categories and navigates to practice on tap', (tester) async {
      tester.view.physicalSize = const Size(430, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        _wrap(const InterviewPrepScreen(generateJdQuestions: _stubGenerateJdQuestions)),
      );
      await tester.pumpAndSettle();

      for (final category in InterviewCategory.values) {
        expect(find.text(category.label), findsOneWidget);
      }

      await tester.tap(find.byKey(const Key('category_aboutYou')));
      await tester.pumpAndSettle();

      expect(find.text('Tell me about yourself.'), findsOneWidget);
      await tester.tap(find.text('Tell me about yourself.'));
      await tester.pumpAndSettle();

      expect(find.text('Practice'), findsOneWidget);
      expect(find.text('Tell me about yourself.'), findsOneWidget);
    });
  });

  group('InterviewPracticeScreen', () {
    const question = InterviewQuestion(
      id: 'about-1',
      category: InterviewCategory.aboutYou,
      question: 'Tell me about yourself.',
    );

    testWidgets('shows the category guidance', (tester) async {
      await tester.pumpWidget(
        _wrap(
          InterviewPracticeScreen(question: question, voiceInputService: _FakeVoiceInputService()),
        ),
      );

      expect(find.byKey(const Key('categoryGuidanceCard')), findsOneWidget);
      expect(find.textContaining('Translate rank and unit scale'), findsOneWidget);
    });

    testWidgets('tapping the mic starts dictation and fills the answer field', (tester) async {
      final fakeVoice = _FakeVoiceInputService();
      await tester.pumpWidget(
        _wrap(InterviewPracticeScreen(question: question, voiceInputService: fakeVoice)),
      );

      await tester.tap(find.byKey(const Key('micButton')));
      await tester.pumpAndSettle();

      expect(fakeVoice.initializeCalled, isTrue);
      expect(fakeVoice.startListeningCalled, isTrue);
      expect(find.text('Dictated practice answer.'), findsOneWidget);

      await tester.tap(find.byKey(const Key('micButton')));
      await tester.pumpAndSettle();

      expect(fakeVoice.stopListeningCalled, isTrue);
    });

    testWidgets('shows an error if speech recognition is unavailable', (tester) async {
      final fakeVoice = _FakeVoiceInputService()..available = false;
      await tester.pumpWidget(
        _wrap(InterviewPracticeScreen(question: question, voiceInputService: fakeVoice)),
      );

      await tester.tap(find.byKey(const Key('micButton')));
      await tester.pumpAndSettle();

      expect(find.textContaining('isn\'t available'), findsOneWidget);
    });
  });
}
