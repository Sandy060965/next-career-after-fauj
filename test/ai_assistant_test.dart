import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:next_career_after_fauj/core/models/officer_profile.dart';
import 'package:next_career_after_fauj/core/services/file_picker_service.dart';
import 'package:next_career_after_fauj/core/services/profile_repository.dart';
import 'package:next_career_after_fauj/core/services/voice_input_service.dart';
import 'package:next_career_after_fauj/core/theme/app_theme.dart';
import 'package:next_career_after_fauj/features/ai_assistant/ai_assistant_screen.dart';
import 'package:next_career_after_fauj/features/ai_assistant/assistant_message.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeVoiceInputService implements VoiceInputService {
  bool available = true;
  bool startListeningCalled = false;
  bool stopListeningCalled = false;
  bool _listening = false;
  String dictatedText = 'Dictated question.';

  @override
  Future<bool> initialize() async => available;

  @override
  bool get isListening => _listening;

  @override
  Future<void> startListening({required void Function(String text) onResult}) async {
    startListeningCalled = true;
    _listening = true;
    onResult(dictatedText);
  }

  @override
  Future<void> stopListening() async {
    stopListeningCalled = true;
    _listening = false;
  }
}

final _profile = OfficerProfile(
  rank: 'Lt Col',
  fullName: 'Lt Col A Verma',
  dateOfBirth: DateTime(1978, 5, 10),
  workExperienceYears: 18,
  workExperienceMonths: 2,
  releaseStatus: ReleaseStatus.tentative,
  releaseDate: DateTime(2027, 6, 30),
  service: OfficerService.army,
  mobileNumber: '9876543210',
  email: 'a.verma@example.com',
  segment: OfficerSegment.pmr,
  cvFileName: 'resume.pdf',
  cvExtractedText: 'Sample CV text',
);

Widget _wrap({required ProfileRepository repository, required Widget child}) {
  return ChangeNotifierProvider<ProfileRepository>.value(
    value: repository,
    child: MaterialApp(theme: AppTheme.light, home: child),
  );
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('shows quick actions when the conversation is empty', (tester) async {
    final repo = ProfileRepository()..saveProfile(_profile);
    await tester.pumpWidget(
      _wrap(repository: repo, child: AiAssistantScreen(voiceInputService: _FakeVoiceInputService())),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('quickAction_Analyse my CV')), findsOneWidget);
    expect(find.byKey(const Key('assistantMessageList')), findsNothing);
  });

  testWidgets('a self-contained quick action sends immediately and shows the reply', (tester) async {
    String? capturedMessage;
    String? capturedContext;
    final repo = ProfileRepository()..saveProfile(_profile);

    await tester.pumpWidget(
      _wrap(
        repository: repo,
        child: AiAssistantScreen(
          voiceInputService: _FakeVoiceInputService(),
          sendMessage: ({required message, required history, profileContext, cvText, cvPdfBytes, attachmentName, attachmentText, attachmentPdfBytes}) async {
            capturedMessage = message;
            capturedContext = profileContext;
            return 'Your CV shows strong leadership experience.';
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('quickAction_Analyse my CV')));
    await tester.pumpAndSettle();

    expect(capturedMessage, contains('analysis of my CV'));
    expect(capturedContext, contains('Rank: Lt Col'));
    expect(capturedContext, contains('not yet completed'));
    expect(find.text('Your CV shows strong leadership experience.'), findsOneWidget);
    expect(find.byKey(const Key('assistantMessageList')), findsOneWidget);
  });

  testWidgets('a fill-in quick action populates the input instead of sending', (tester) async {
    var called = false;
    final repo = ProfileRepository();

    await tester.pumpWidget(
      _wrap(
        repository: repo,
        child: AiAssistantScreen(
          voiceInputService: _FakeVoiceInputService(),
          sendMessage: ({required message, required history, profileContext, cvText, cvPdfBytes, attachmentName, attachmentText, attachmentPdfBytes}) async {
            called = true;
            return 'reply';
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('quickAction_Explain this corporate term')));
    await tester.pumpAndSettle();

    expect(called, isFalse);
    final field = tester.widget<TextField>(find.byKey(const Key('assistantInputField')));
    expect(field.controller?.text, 'Explain this corporate term: ');
  });

  testWidgets('typing a message and sending it shows both the user turn and the reply',
      (tester) async {
    final repo = ProfileRepository();

    await tester.pumpWidget(
      _wrap(
        repository: repo,
        child: AiAssistantScreen(
          voiceInputService: _FakeVoiceInputService(),
          sendMessage: ({required message, required history, profileContext, cvText, cvPdfBytes, attachmentName, attachmentText, attachmentPdfBytes}) async {
            return 'Here is my answer.';
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('assistantInputField')), 'What is EBITDA?');
    await tester.tap(find.byKey(const Key('assistantSendButton')));
    await tester.pumpAndSettle();

    expect(find.text('What is EBITDA?'), findsOneWidget);
    expect(find.text('Here is my answer.'), findsOneWidget);
  });

  testWidgets('a second message includes the first turn in history', (tester) async {
    final receivedHistories = <List<AssistantMessage>>[];
    final repo = ProfileRepository();

    await tester.pumpWidget(
      _wrap(
        repository: repo,
        child: AiAssistantScreen(
          voiceInputService: _FakeVoiceInputService(),
          sendMessage: ({required message, required history, profileContext, cvText, cvPdfBytes, attachmentName, attachmentText, attachmentPdfBytes}) async {
            receivedHistories.add(history);
            return 'reply $message';
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('assistantInputField')), 'first question');
    await tester.tap(find.byKey(const Key('assistantSendButton')));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('assistantInputField')), 'second question');
    await tester.tap(find.byKey(const Key('assistantSendButton')));
    await tester.pumpAndSettle();

    expect(receivedHistories.first, isEmpty);
    expect(receivedHistories.last, hasLength(2));
    expect(receivedHistories.last.first.content, 'first question');
    expect(receivedHistories.last.last.content, 'reply first question');
  });

  testWidgets('shows an error message if the assistant call fails', (tester) async {
    final repo = ProfileRepository();

    await tester.pumpWidget(
      _wrap(
        repository: repo,
        child: AiAssistantScreen(
          voiceInputService: _FakeVoiceInputService(),
          sendMessage: ({required message, required history, profileContext, cvText, cvPdfBytes, attachmentName, attachmentText, attachmentPdfBytes}) async {
            throw Exception('network down');
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('assistantInputField')), 'hello');
    await tester.tap(find.byKey(const Key('assistantSendButton')));
    await tester.pumpAndSettle();

    expect(find.textContaining('network down'), findsOneWidget);
  });

  testWidgets('tapping the mic starts listening and fills the field with the dictated text',
      (tester) async {
    final fakeVoice = _FakeVoiceInputService()..dictatedText = 'What does EBITDA mean?';
    final repo = ProfileRepository();

    await tester.pumpWidget(
      _wrap(
        repository: repo,
        child: AiAssistantScreen(
          voiceInputService: fakeVoice,
          sendMessage: ({required message, required history, profileContext, cvText, cvPdfBytes, attachmentName, attachmentText, attachmentPdfBytes}) async =>
              'reply',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.mic_none_outlined), findsOneWidget);

    await tester.tap(find.byKey(const Key('assistantMicButton')));
    await tester.pumpAndSettle();

    expect(fakeVoice.startListeningCalled, isTrue);
    expect(find.byIcon(Icons.mic), findsOneWidget);
    final field = tester.widget<TextField>(find.byKey(const Key('assistantInputField')));
    expect(field.controller?.text, 'What does EBITDA mean?');

    // Tapping again stops listening — the dictated text stays in the field
    // for the officer to review or edit before sending, exactly like typing.
    await tester.tap(find.byKey(const Key('assistantMicButton')));
    await tester.pumpAndSettle();

    expect(fakeVoice.stopListeningCalled, isTrue);
    expect(find.byIcon(Icons.mic_none_outlined), findsOneWidget);
  });

  testWidgets('shows an error if speech recognition is unavailable on the device', (tester) async {
    final fakeVoice = _FakeVoiceInputService()..available = false;
    final repo = ProfileRepository();

    await tester.pumpWidget(
      _wrap(repository: repo, child: AiAssistantScreen(voiceInputService: fakeVoice)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('assistantMicButton')));
    await tester.pumpAndSettle();

    expect(fakeVoice.startListeningCalled, isFalse);
    expect(find.textContaining('Speech recognition isn\'t available'), findsOneWidget);
  });

  testWidgets('sending a message while listening stops the microphone', (tester) async {
    final fakeVoice = _FakeVoiceInputService();
    final repo = ProfileRepository();

    await tester.pumpWidget(
      _wrap(
        repository: repo,
        child: AiAssistantScreen(
          voiceInputService: fakeVoice,
          sendMessage: ({required message, required history, profileContext, cvText, cvPdfBytes, attachmentName, attachmentText, attachmentPdfBytes}) async =>
              'reply',
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('assistantMicButton')));
    await tester.pumpAndSettle();
    expect(fakeVoice.isListening, isTrue);

    await tester.tap(find.byKey(const Key('assistantSendButton')));
    await tester.pumpAndSettle();

    expect(fakeVoice.stopListeningCalled, isTrue);
    expect(fakeVoice.isListening, isFalse);
  });

  testWidgets('attaching a txt file shows a chip and sends its text with the message',
      (tester) async {
    String? capturedAttachmentName;
    String? capturedAttachmentText;
    final repo = ProfileRepository();

    await tester.pumpWidget(
      _wrap(
        repository: repo,
        child: AiAssistantScreen(
          voiceInputService: _FakeVoiceInputService(),
          pickFile: () async => PickedFile(
            name: 'job-description.txt',
            bytes: Uint8List.fromList(utf8.encode('We need a Senior Ops Manager.')),
          ),
          sendMessage: ({
            required message,
            required history,
            profileContext,
            cvText,
            cvPdfBytes,
            attachmentName,
            attachmentText,
            attachmentPdfBytes,
          }) async {
            capturedAttachmentName = attachmentName;
            capturedAttachmentText = attachmentText;
            return 'It looks like a strong match.';
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('assistantAttachButton')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('assistantAttachmentChip')), findsOneWidget);
    expect(find.text('job-description.txt'), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('assistantInputField')),
      'How well does my profile match this?',
    );
    await tester.tap(find.byKey(const Key('assistantSendButton')));
    await tester.pumpAndSettle();

    expect(capturedAttachmentName, 'job-description.txt');
    expect(capturedAttachmentText, 'We need a Senior Ops Manager.');
    // The chip stays for follow-up questions in the same conversation.
    expect(find.byKey(const Key('assistantAttachmentChip')), findsOneWidget);
  });

  testWidgets('removing an attachment clears it from the next message', (tester) async {
    String? capturedAttachmentName = 'not sent yet';
    final repo = ProfileRepository();

    await tester.pumpWidget(
      _wrap(
        repository: repo,
        child: AiAssistantScreen(
          voiceInputService: _FakeVoiceInputService(),
          pickFile: () async => PickedFile(
            name: 'job-description.txt',
            bytes: Uint8List.fromList(utf8.encode('We need a Senior Ops Manager.')),
          ),
          sendMessage: ({
            required message,
            required history,
            profileContext,
            cvText,
            cvPdfBytes,
            attachmentName,
            attachmentText,
            attachmentPdfBytes,
          }) async {
            capturedAttachmentName = attachmentName;
            return 'reply';
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('assistantAttachButton')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('assistantAttachmentChip')), findsOneWidget);

    await tester.tap(find.descendant(
      of: find.byKey(const Key('assistantAttachmentChip')),
      matching: find.byIcon(Icons.cancel),
    ));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('assistantAttachmentChip')), findsNothing);

    await tester.enterText(find.byKey(const Key('assistantInputField')), 'hello');
    await tester.tap(find.byKey(const Key('assistantSendButton')));
    await tester.pumpAndSettle();

    expect(capturedAttachmentName, isNull);
  });

  testWidgets('an oversized PDF attachment is rejected with a clear reason', (tester) async {
    final repo = ProfileRepository();
    final oversized = Uint8List(kMaxUploadPdfBytes + 1);

    await tester.pumpWidget(
      _wrap(
        repository: repo,
        child: AiAssistantScreen(
          voiceInputService: _FakeVoiceInputService(),
          pickFile: () async => PickedFile(name: 'huge-jd.pdf', bytes: oversized),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('assistantAttachButton')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('assistantAttachmentChip')), findsNothing);
    expect(find.textContaining('larger than $kMaxUploadPdfMb MB'), findsOneWidget);
  });
}
