import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/services/profile_repository.dart';
import 'built_cv.dart';
import 'cv_builder_intake.dart';
import 'cv_builder_service.dart';

class _WorkExperienceControllers {
  _WorkExperienceControllers({WorkExperienceEntry? initial})
      : roleTitle = TextEditingController(text: initial?.roleTitle ?? ''),
        organizationType = TextEditingController(text: initial?.organizationType ?? ''),
        duration = TextEditingController(text: initial?.duration ?? ''),
        responsibilities = TextEditingController(text: initial?.responsibilities ?? '');

  final TextEditingController roleTitle;
  final TextEditingController organizationType;
  final TextEditingController duration;
  final TextEditingController responsibilities;

  WorkExperienceEntry toEntry() => WorkExperienceEntry(
        roleTitle: roleTitle.text.trim(),
        organizationType: organizationType.text.trim(),
        duration: duration.text.trim(),
        responsibilities: responsibilities.text.trim(),
      );

  void dispose() {
    roleTitle.dispose();
    organizationType.dispose();
    duration.dispose();
    responsibilities.dispose();
  }
}

class _EducationControllers {
  _EducationControllers({EducationEntry? initial})
      : degree = TextEditingController(text: initial?.degree ?? ''),
        institution = TextEditingController(text: initial?.institution ?? ''),
        year = TextEditingController(text: initial?.year ?? '');

  final TextEditingController degree;
  final TextEditingController institution;
  final TextEditingController year;

  EducationEntry toEntry() => EducationEntry(
        degree: degree.text.trim(),
        institution: institution.text.trim(),
        year: year.text.trim(),
      );

  void dispose() {
    degree.dispose();
    institution.dispose();
    year.dispose();
  }
}

class _CertificationControllers {
  _CertificationControllers({CertificationEntry? initial})
      : name = TextEditingController(text: initial?.name ?? ''),
        year = TextEditingController(text: initial?.year ?? '');

  final TextEditingController name;
  final TextEditingController year;

  CertificationEntry toEntry() =>
      CertificationEntry(name: name.text.trim(), year: year.text.trim());

  void dispose() {
    name.dispose();
    year.dispose();
  }
}

class CvBuilderScreen extends StatefulWidget {
  const CvBuilderScreen({super.key, this.buildCv = mockBuildCv});

  /// Overridable for testing; defaults to sample data until the Worker's
  /// /build-cv endpoint is wired in.
  final CvBuilder buildCv;

  @override
  State<CvBuilderScreen> createState() => _CvBuilderScreenState();
}

class _CvBuilderScreenState extends State<CvBuilderScreen> {
  late final TextEditingController _summaryController;
  late final TextEditingController _skillsController;
  final List<_WorkExperienceControllers> _workExperience = [];
  final List<_EducationControllers> _education = [];
  final List<_CertificationControllers> _certifications = [];

  bool _isBuilding = false;
  String? _error;
  BuiltCv? _result;

  @override
  void initState() {
    super.initState();
    final cachedIntake = context.read<ProfileRepository>().lastCvBuilderIntake;
    _summaryController = TextEditingController(text: cachedIntake?.summary ?? '');
    _skillsController = TextEditingController(text: cachedIntake?.skills ?? '');
    if (cachedIntake != null) {
      _workExperience.addAll(cachedIntake.workExperience.map((e) => _WorkExperienceControllers(initial: e)));
      _education.addAll(cachedIntake.education.map((e) => _EducationControllers(initial: e)));
      _certifications.addAll(cachedIntake.certifications.map((e) => _CertificationControllers(initial: e)));
    }
    if (_workExperience.isEmpty) _workExperience.add(_WorkExperienceControllers());
    _result = context.read<ProfileRepository>().lastBuiltCv;
  }

  @override
  void dispose() {
    _summaryController.dispose();
    _skillsController.dispose();
    for (final c in _workExperience) {
      c.dispose();
    }
    for (final c in _education) {
      c.dispose();
    }
    for (final c in _certifications) {
      c.dispose();
    }
    super.dispose();
  }

  CvBuilderIntake _currentIntake() => CvBuilderIntake(
        summary: _summaryController.text.trim(),
        workExperience: _workExperience
            .map((c) => c.toEntry())
            .where((e) => e.roleTitle.isNotEmpty)
            .toList(),
        education: _education.map((c) => c.toEntry()).where((e) => e.degree.isNotEmpty).toList(),
        certifications:
            _certifications.map((c) => c.toEntry()).where((e) => e.name.isNotEmpty).toList(),
        skills: _skillsController.text.trim(),
      );

  Future<void> _build() async {
    final intake = _currentIntake();
    if (intake.workExperience.isEmpty) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('Add at least one role title before building your CV')));
      return;
    }

    setState(() {
      _isBuilding = true;
      _error = null;
    });
    final repo = context.read<ProfileRepository>();
    repo.saveCvBuilderIntake(intake);
    try {
      final result = await widget.buildCv(intake: intake);
      if (!mounted) return;
      repo.saveBuiltCv(result);
      setState(() {
        _result = result;
        _isBuilding = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '$e';
        _isBuilding = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Build My Civilian CV')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "For officers without a usable existing CV — type in what you've actually done and "
              "we'll organise it into a clean civilian CV. Nothing is invented beyond what you type.",
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 20),
            TextFormField(
              key: const Key('summaryField'),
              controller: _summaryController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Professional summary (optional)',
                helperText: 'A couple of sentences on who you are professionally — leave blank to '
                    'let us compose one from your work experience.',
              ),
            ),
            const SizedBox(height: 24),
            Text('Work experience', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            for (var i = 0; i < _workExperience.length; i++) _buildWorkExperienceCard(i),
            OutlinedButton.icon(
              key: const Key('addWorkExperienceButton'),
              onPressed: () => setState(() => _workExperience.add(_WorkExperienceControllers())),
              icon: const Icon(Icons.add),
              label: const Text('Add another role'),
            ),
            const SizedBox(height: 24),
            Text('Education', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            for (var i = 0; i < _education.length; i++) _buildEducationCard(i),
            OutlinedButton.icon(
              key: const Key('addEducationButton'),
              onPressed: () => setState(() => _education.add(_EducationControllers())),
              icon: const Icon(Icons.add),
              label: const Text('Add education'),
            ),
            const SizedBox(height: 24),
            Text('Certifications', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            for (var i = 0; i < _certifications.length; i++) _buildCertificationCard(i),
            OutlinedButton.icon(
              key: const Key('addCertificationButton'),
              onPressed: () => setState(() => _certifications.add(_CertificationControllers())),
              icon: const Icon(Icons.add),
              label: const Text('Add certification'),
            ),
            const SizedBox(height: 24),
            Text('Skills', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            TextFormField(
              key: const Key('skillsField'),
              controller: _skillsController,
              maxLines: 2,
              decoration: const InputDecoration(labelText: 'Comma-separated (optional)'),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                key: const Key('buildCvButton'),
                onPressed: _isBuilding ? null : _build,
                child: _isBuilding
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Build my CV'),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 16),
              Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ],
            if (_result != null) ...[
              const SizedBox(height: 24),
              _buildResultCard(_result!),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildWorkExperienceCard(int index) {
    final c = _workExperience[index];
    return Card(
      key: ValueKey('workExperienceCard_$index'),
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text('Role ${index + 1}', style: Theme.of(context).textTheme.titleSmall)),
                if (_workExperience.length > 1)
                  IconButton(
                    key: ValueKey('removeWorkExperienceButton_$index'),
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => setState(() {
                      _workExperience.removeAt(index).dispose();
                    }),
                  ),
              ],
            ),
            TextFormField(
              key: ValueKey('roleTitleField_$index'),
              controller: c.roleTitle,
              decoration: const InputDecoration(labelText: 'Role / title'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              key: ValueKey('organizationTypeField_$index'),
              controller: c.organizationType,
              decoration: const InputDecoration(
                labelText: 'Organisation (describe generally, e.g. "Infantry battalion, ~800 personnel")',
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              key: ValueKey('durationField_$index'),
              controller: c.duration,
              decoration: const InputDecoration(labelText: 'Duration (e.g. "2018-2021")'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              key: ValueKey('responsibilitiesField_$index'),
              controller: c.responsibilities,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Key responsibilities / achievements'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEducationCard(int index) {
    final c = _education[index];
    return Card(
      key: ValueKey('educationCard_$index'),
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Spacer(),
                IconButton(
                  key: ValueKey('removeEducationButton_$index'),
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => setState(() {
                    _education.removeAt(index).dispose();
                  }),
                ),
              ],
            ),
            TextFormField(
              key: ValueKey('degreeField_$index'),
              controller: c.degree,
              decoration: const InputDecoration(labelText: 'Degree / qualification'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              key: ValueKey('institutionField_$index'),
              controller: c.institution,
              decoration: const InputDecoration(labelText: 'Institution'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              key: ValueKey('educationYearField_$index'),
              controller: c.year,
              decoration: const InputDecoration(labelText: 'Year'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCertificationCard(int index) {
    final c = _certifications[index];
    return Card(
      key: ValueKey('certificationCard_$index'),
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: TextFormField(
                key: ValueKey('certificationNameField_$index'),
                controller: c.name,
                decoration: const InputDecoration(labelText: 'Certification'),
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 90,
              child: TextFormField(
                key: ValueKey('certificationYearField_$index'),
                controller: c.year,
                decoration: const InputDecoration(labelText: 'Year'),
              ),
            ),
            IconButton(
              key: ValueKey('removeCertificationButton_$index'),
              icon: const Icon(Icons.delete_outline),
              onPressed: () => setState(() {
                _certifications.removeAt(index).dispose();
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultCard(BuiltCv result) {
    return Card(
      key: const Key('builtCvResult'),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Your CV', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(result.cvText, key: const Key('builtCvText')),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                key: const Key('copyBuiltCvButton'),
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: result.cvText));
                  if (mounted) {
                    ScaffoldMessenger.of(context)
                      ..hideCurrentSnackBar()
                      ..showSnackBar(const SnackBar(content: Text('CV copied to clipboard')));
                  }
                },
                icon: const Icon(Icons.copy_outlined),
                label: const Text('Copy'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
