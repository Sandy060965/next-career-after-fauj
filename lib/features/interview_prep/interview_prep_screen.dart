import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/routing/app_routes.dart';
import '../../core/services/profile_repository.dart';
import 'interview_practice_screen.dart';
import 'interview_prep_service.dart';
import 'interview_question.dart';
import 'jd_interview_question.dart';

class InterviewPrepScreen extends StatefulWidget {
  const InterviewPrepScreen({super.key, this.generateJdQuestions = mockGenerateJdInterviewQuestions});

  /// Overridable for testing; defaults to sample data until the Cloudflare
  /// Worker backend is wired in.
  final JdInterviewQuestionsAnalyzer generateJdQuestions;

  @override
  State<InterviewPrepScreen> createState() => _InterviewPrepScreenState();
}

class _InterviewPrepScreenState extends State<InterviewPrepScreen> {
  bool _isLoadingJdQuestions = false;
  List<JdInterviewQuestion>? _jdQuestions;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadJdQuestions());
  }

  Future<void> _loadJdQuestions() async {
    final repository = context.read<ProfileRepository>();
    final jdText = repository.lastJdText;
    if (jdText == null) return;

    setState(() => _isLoadingJdQuestions = true);
    try {
      final questions = await widget.generateJdQuestions(
        jdText: jdText,
        cvText: repository.profile?.cvExtractedText,
      );
      if (!mounted) return;
      setState(() {
        _jdQuestions = questions;
        _isLoadingJdQuestions = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoadingJdQuestions = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasJdText = context.watch<ProfileRepository>().lastJdText != null;

    return Scaffold(
      appBar: AppBar(title: const Text('Interview Prep')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            'Common questions with guidance on how to answer them, plus questions likely '
            'for a specific role once you\'ve run JD Match.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 20),
          if (hasJdText) _buildJdSpecificSection(context) else _buildNoJdCard(context),
          const SizedBox(height: 20),
          Text('Common questions', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          for (final category in InterviewCategory.values) _CategorySection(category: category),
        ],
      ),
    );
  }

  Widget _buildNoJdCard(BuildContext context) {
    return Card(
      key: const Key('noJdQuestionsCard'),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Run JD Match against a job description to get questions tailored to that '
              'specific role.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              key: const Key('goToJdMatchButton'),
              onPressed: () => Navigator.of(context).pushNamed(AppRoutes.jdMatch),
              child: const Text('Run JD Match'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildJdSpecificSection(BuildContext context) {
    return Card(
      key: const Key('jdSpecificQuestionsCard'),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Likely questions for this role', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            if (_isLoadingJdQuestions)
              const Center(child: Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator()))
            else
              for (final q in _jdQuestions ?? const <JdInterviewQuestion>[])
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(q.question, style: Theme.of(context).textTheme.bodyMedium),
                      const SizedBox(height: 2),
                      Text(
                        q.reason,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontStyle: FontStyle.italic,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
          ],
        ),
      ),
    );
  }
}

class _CategorySection extends StatelessWidget {
  const _CategorySection({required this.category});

  final InterviewCategory category;

  @override
  Widget build(BuildContext context) {
    final questions = kInterviewQuestions.where((q) => q.category == category).toList();
    return Card(
      key: ValueKey('category_${category.name}'),
      margin: const EdgeInsets.only(bottom: 8),
      child: ExpansionTile(
        title: Text(category.label),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                category.guidance,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ),
          ),
          for (final question in questions)
            ListTile(
              key: ValueKey('question_${question.id}'),
              title: Text(question.question),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => InterviewPracticeScreen(question: question)),
              ),
            ),
        ],
      ),
    );
  }
}
