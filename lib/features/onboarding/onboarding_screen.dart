import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/models/officer_profile.dart';
import '../../core/routing/app_routes.dart';
import '../../core/services/document_text_extractor.dart';
import '../../core/services/file_picker_service.dart';
import '../../core/services/profile_repository.dart';
import '../../core/utils/date_format.dart';
import 'rank_options.dart';
import 'widgets/segment_selector.dart';

Future<PickedFile?> _defaultPickCv() =>
    pickFileWithBytes(allowedExtensions: const ['pdf', 'docx']);

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, this.pickFile = _defaultPickCv});

  /// Overridable for testing so the native file-picker channel never needs
  /// to be invoked.
  final Future<PickedFile?> Function() pickFile;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  static const int _stepCount = 3;

  final PageController _pageController = PageController();
  final GlobalKey<FormState> _verificationFormKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _releaseDateController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();

  int _step = 0;
  bool _consentGiven = false;
  bool _verificationAttempted = false;
  bool _segmentAttempted = false;
  OfficerSegment? _segment;
  OfficerService? _service;
  String? _rank;
  DateTime? _dateOfBirth;
  int? _workExperienceYears;
  int? _workExperienceMonths;
  ReleaseStatus? _releaseStatus;
  DateTime? _releaseDate;
  String? _uploadedFileName;
  String? _cvExtractedText;
  Uint8List? _cvPdfBytes;
  String? _cvError;
  bool _isProcessingCv = false;

  @override
  void initState() {
    super.initState();
    final existing = context.read<ProfileRepository>().profile;
    if (existing != null) {
      _service = existing.service;
      _rank = existing.rank;
      _nameController.text = existing.fullName;
      _dateOfBirth = existing.dateOfBirth;
      _dobController.text = formatDate(existing.dateOfBirth);
      _workExperienceYears = existing.workExperienceYears;
      _workExperienceMonths = existing.workExperienceMonths;
      _releaseStatus = existing.releaseStatus;
      _releaseDate = existing.releaseDate;
      _releaseDateController.text = formatDate(existing.releaseDate);
      _emailController.text = existing.email;
      _mobileController.text = existing.mobileNumber;
      _consentGiven = true;
      _segment = existing.segment;
      _uploadedFileName = existing.cvFileName;
      _cvExtractedText = existing.cvExtractedText;
      _cvPdfBytes = existing.cvPdfBytes;
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _dobController.dispose();
    _releaseDateController.dispose();
    _emailController.dispose();
    _mobileController.dispose();
    super.dispose();
  }

  void _goToStep(int step) {
    setState(() => _step = step);
    _pageController.animateToPage(
      step,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
    );
  }

  void _showValidationSnackBar(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _onContinuePressed() {
    switch (_step) {
      case 0:
        setState(() => _verificationAttempted = true);
        final formValid = _verificationFormKey.currentState!.validate();
        if (formValid && _consentGiven) {
          _goToStep(1);
        } else if (!formValid) {
          _showValidationSnackBar('Please fill in all required fields correctly.');
        } else {
          _showValidationSnackBar('Please confirm consent to continue.');
        }
        break;
      case 1:
        setState(() => _segmentAttempted = true);
        if (_segment != null) {
          _goToStep(2);
        } else {
          _showValidationSnackBar('Select a segment to continue.');
        }
        break;
      case 2:
        _submit();
        break;
    }
  }

  Future<void> _pickDateOfBirth() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateOfBirth ?? DateTime(now.year - 30, now.month, now.day),
      firstDate: DateTime(now.year - 65),
      lastDate: DateTime(now.year - 18, now.month, now.day),
      helpText: 'Select date of birth',
    );
    if (picked != null) {
      setState(() {
        _dateOfBirth = picked;
        _dobController.text = formatDate(picked);
      });
    }
  }

  Future<void> _pickReleaseDate() async {
    if (_releaseStatus == null) return;
    final now = DateTime.now();
    final isAlreadyReleased = _releaseStatus == ReleaseStatus.alreadyReleased;
    final picked = await showDatePicker(
      context: context,
      initialDate: _releaseDate ?? now,
      firstDate: isAlreadyReleased ? DateTime(now.year - 40) : now,
      lastDate: isAlreadyReleased ? now : DateTime(now.year + 15),
      helpText: isAlreadyReleased ? 'Select date of release' : 'Select tentative release date',
    );
    if (picked != null) {
      setState(() {
        _releaseDate = picked;
        _releaseDateController.text = formatDate(picked);
      });
    }
  }

  Future<void> _pickCv() async {
    final file = await widget.pickFile();
    if (file == null) return;

    final extension = file.name.split('.').last.toLowerCase();
    setState(() {
      _uploadedFileName = file.name;
      _cvError = null;
      _cvExtractedText = null;
      _cvPdfBytes = null;
    });

    if (extension == 'pdf') {
      // Claude reads PDFs natively — no client-side extraction needed.
      setState(() => _cvPdfBytes = file.bytes);
      return;
    }

    if (extension == 'docx') {
      setState(() => _isProcessingCv = true);
      try {
        final text = await extractDocxText(file.bytes);
        if (!mounted) return;
        setState(() {
          _cvExtractedText = text;
          _isProcessingCv = false;
        });
      } on DocxExtractionException catch (e) {
        if (!mounted) return;
        setState(() {
          _isProcessingCv = false;
          _cvError = "Couldn't read this file's text ($e). The filename is saved, "
              'but try a different file for a full analysis.';
        });
      }
    }
  }

  void _submit() {
    if (_uploadedFileName == null) {
      setState(() => _cvError = 'Upload your CV to continue');
      _showValidationSnackBar('Upload your CV to continue.');
      return;
    }

    final profile = OfficerProfile(
      rank: _rank!,
      fullName: _nameController.text.trim(),
      dateOfBirth: _dateOfBirth!,
      workExperienceYears: _workExperienceYears!,
      workExperienceMonths: _workExperienceMonths!,
      releaseStatus: _releaseStatus!,
      releaseDate: _releaseDate!,
      service: _service!,
      mobileNumber: _mobileController.text.trim(),
      email: _emailController.text.trim(),
      segment: _segment!,
      cvFileName: _uploadedFileName!,
      cvExtractedText: _cvExtractedText,
      cvPdfBytes: _cvPdfBytes,
    );

    // saveProfile updates in-memory state synchronously (before its first
    // await) and persists to disk in the background — navigation doesn't
    // need to wait on that disk write to complete.
    context.read<ProfileRepository>().saveProfile(profile);
    Navigator.of(context).pushReplacementNamed(AppRoutes.profile);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Officer Onboarding'),
        leading: _step > 0
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => _goToStep(_step - 1),
              )
            : null,
      ),
      body: Column(
        children: [
          const SizedBox(height: 8),
          _StepProgress(currentStep: _step, stepCount: _stepCount),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildVerificationStep(),
                _buildSegmentStep(),
                _buildCvUploadStep(),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                key: const Key('continueButton'),
                onPressed: _onContinuePressed,
                child: Text(_step == _stepCount - 1 ? 'Create profile' : 'Continue'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerificationStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _verificationFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Verify your service details', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 4),
            Text(
              'Used only to confirm you are a serving or retired officer. '
              'We never ask for ACR or service-record documents.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            DropdownButtonFormField<OfficerService>(
              key: const Key('serviceDropdown'),
              initialValue: _service,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Service'),
              items: OfficerService.values
                  .map((s) => DropdownMenuItem(value: s, child: Text(s.label)))
                  .toList(),
              onChanged: (v) => setState(() {
                _service = v;
                if (_rank != null && (v == null || !kRanksByService[v]!.contains(_rank))) {
                  _rank = null;
                }
              }),
              validator: (v) => v == null ? 'Select a service' : null,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              key: const Key('rankDropdown'),
              initialValue: _rank,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: 'Rank',
                hintText: _service == null ? 'Select service first' : null,
              ),
              items: (_service == null ? const <String>[] : kRanksByService[_service]!)
                  .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                  .toList(),
              onChanged: _service == null ? null : (v) => setState(() => _rank = v),
              validator: (v) => v == null ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              key: const Key('nameField'),
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Full name'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              key: const Key('dobField'),
              controller: _dobController,
              readOnly: true,
              onTap: _pickDateOfBirth,
              decoration: const InputDecoration(
                labelText: 'Date of birth',
                suffixIcon: Icon(Icons.calendar_today_outlined),
              ),
              validator: (_) => _dateOfBirth == null ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            Text('Total work experience', style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<int>(
                    key: const Key('workExperienceYearsDropdown'),
                    initialValue: _workExperienceYears,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Years'),
                    items: List.generate(41, (i) => i)
                        .map((y) => DropdownMenuItem(value: y, child: Text('$y')))
                        .toList(),
                    onChanged: (v) => setState(() => _workExperienceYears = v),
                    validator: (v) => v == null ? 'Required' : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<int>(
                    key: const Key('workExperienceMonthsDropdown'),
                    initialValue: _workExperienceMonths,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Months'),
                    items: List.generate(12, (i) => i)
                        .map((m) => DropdownMenuItem(value: m, child: Text('$m')))
                        .toList(),
                    onChanged: (v) => setState(() => _workExperienceMonths = v),
                    validator: (v) => v == null ? 'Required' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text('Release from service', style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 4),
            RadioGroup<ReleaseStatus>(
              groupValue: _releaseStatus,
              onChanged: (v) => setState(() {
                _releaseStatus = v;
                _releaseDate = null;
                _releaseDateController.clear();
              }),
              child: Column(
                children: ReleaseStatus.values
                    .map(
                      (status) => RadioListTile<ReleaseStatus>(
                        key: ValueKey('releaseStatus_${status.name}'),
                        value: status,
                        contentPadding: EdgeInsets.zero,
                        title: Text(status.label),
                      ),
                    )
                    .toList(),
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              key: const Key('releaseDateField'),
              controller: _releaseDateController,
              readOnly: true,
              enabled: _releaseStatus != null,
              onTap: _pickReleaseDate,
              decoration: InputDecoration(
                labelText: _releaseStatus == ReleaseStatus.alreadyReleased
                    ? 'Date of release'
                    : 'Tentative release date',
                hintText: _releaseStatus == null ? 'Select an option above' : null,
                suffixIcon: const Icon(Icons.calendar_today_outlined),
              ),
              validator: (_) => _releaseDate == null ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              key: const Key('mobileField'),
              controller: _mobileController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Mobile number'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              key: const Key('emailField'),
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Email'),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Required';
                if (!v.contains('@')) return 'Enter a valid email';
                return null;
              },
            ),
            const SizedBox(height: 24),
            CheckboxListTile(
              key: const Key('consentCheckbox'),
              value: _consentGiven,
              onChanged: (v) => setState(() => _consentGiven = v ?? false),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
              title: const Text(
                'I confirm I am a serving or retired officer of the Indian Armed Forces '
                'and consent to my data being processed to build my profile.',
              ),
            ),
            if (_verificationAttempted && !_consentGiven)
              Padding(
                padding: const EdgeInsets.only(left: 12),
                child: Text(
                  'Consent is required to continue',
                  style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 12),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSegmentStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Which best describes you?', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 4),
          Text(
            'This tailors the entry level and career pathing shown later in the app.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          SegmentSelector(
            selected: _segment,
            onChanged: (segment) => setState(() => _segment = segment),
          ),
          if (_segmentAttempted && _segment == null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                'Select a segment to continue',
                style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCvUploadStep() {
    final colorScheme = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Upload your CV', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 4),
          Text(
            "We only accept a CV you've written / vetted yourself — never your "
            'official record of service.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.errorContainer.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.warning_amber_rounded, size: 20, color: colorScheme.error),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Kindly do not include / upload any confidential details / data.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.error,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _buildUploadPanel(),
          if (_cvError != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                _cvError!,
                style: TextStyle(color: colorScheme.error, fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildUploadPanel() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.description_outlined),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _uploadedFileName ?? 'No file selected (PDF or Word)',
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (_isProcessingCv)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            TextButton(
              key: const Key('browseButton'),
              onPressed: _pickCv,
              child: const Text('Browse'),
            ),
        ],
      ),
    );
  }
}

class _StepProgress extends StatelessWidget {
  const _StepProgress({required this.currentStep, required this.stepCount});

  final int currentStep;
  final int stepCount;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: List.generate(stepCount, (index) {
          final isActive = index <= currentStep;
          return Expanded(
            child: Container(
              margin: EdgeInsets.only(right: index == stepCount - 1 ? 0 : 6),
              height: 4,
              decoration: BoxDecoration(
                color: isActive
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
      ),
    );
  }
}
