import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/services/profile_repository.dart';
import '../../core/utils/date_format.dart';
import 'network_models.dart';
import 'network_service.dart';

class NetworkOptInScreen extends StatefulWidget {
  const NetworkOptInScreen({super.key, this.existing, this.networkService});

  final MentorPledge? existing;

  /// Overridable for testing so no real HTTP call is made.
  final NetworkService? networkService;

  @override
  State<NetworkOptInScreen> createState() => _NetworkOptInScreenState();
}

class _NetworkOptInScreenState extends State<NetworkOptInScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _verticalController;
  late final TextEditingController _cityController;
  late final TextEditingController _companyController;

  late CallFrequency _frequency;
  late int _sessionMinutes;
  DateTime? _joiningDate;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final profile = context.read<ProfileRepository>().profile;
    final existing = widget.existing;
    _nameController = TextEditingController(text: existing?.displayName ?? profile?.fullName ?? '');
    _emailController = TextEditingController(text: existing?.email ?? profile?.email ?? '');
    _verticalController = TextEditingController(text: existing?.vertical ?? '');
    _cityController = TextEditingController(text: existing?.city ?? '');
    _companyController = TextEditingController(text: existing?.currentCompany ?? '');
    _frequency = existing?.callFrequency ?? CallFrequency.weekly;
    _sessionMinutes = existing?.sessionMinutes ?? kSessionMinuteOptions.first;
    _joiningDate = existing?.joiningDate;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _verticalController.dispose();
    _cityController.dispose();
    _companyController.dispose();
    super.dispose();
  }

  Future<void> _pickJoiningDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _joiningDate ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 3),
    );
    if (picked == null) return;
    setState(() => _joiningDate = picked);
  }

  NetworkService? _service() {
    if (widget.networkService != null) return widget.networkService;
    final repo = context.read<ProfileRepository>();
    return repo.sessionToken == null ? null : NetworkService(profileRepository: repo);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final service = _service();
    if (service == null) return;

    setState(() => _isSaving = true);
    try {
      await service.optIn(
        displayName: _nameController.text.trim(),
        email: _emailController.text.trim(),
        callFrequency: _frequency,
        sessionMinutes: _sessionMinutes,
        vertical: _verticalController.text.trim().isEmpty ? null : _verticalController.text.trim(),
        city: _cityController.text.trim().isEmpty ? null : _cityController.text.trim(),
        currentCompany:
            _companyController.text.trim().isEmpty ? null : _companyController.text.trim(),
        joiningDate: _joiningDate,
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pledge to Mentor')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'A pledge to give some time to other officers once you\'ve joined your civilian '
                'role — not a live booking. You can update or withdraw this any time before then.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 20),
              TextFormField(
                key: const Key('displayNameField'),
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Display name'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                key: const Key('emailField'),
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  helperText: 'How officers you agree to help will reach you.',
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Required';
                  if (!v.contains('@')) return 'Enter a valid email';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                key: const Key('verticalField'),
                controller: _verticalController,
                decoration: const InputDecoration(labelText: 'Vertical (optional)'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                key: const Key('cityField'),
                controller: _cityController,
                decoration: const InputDecoration(labelText: 'City (optional)'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                key: const Key('companyField'),
                controller: _companyController,
                decoration: const InputDecoration(
                  labelText: 'Company joined or accepted (optional)',
                ),
              ),
              const SizedBox(height: 16),
              InkWell(
                key: const Key('joiningDateField'),
                onTap: _pickJoiningDate,
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Tentative or confirmed joining date (optional)',
                    suffixIcon: _joiningDate == null
                        ? null
                        : IconButton(
                            key: const Key('clearJoiningDateButton'),
                            icon: const Icon(Icons.clear),
                            tooltip: 'Clear date',
                            onPressed: () => setState(() => _joiningDate = null),
                          ),
                  ),
                  child: Text(_joiningDate == null ? 'Not set' : formatDate(_joiningDate!)),
                ),
              ),
              const SizedBox(height: 24),
              Text('How often can you offer time, once you\'ve joined?',
                  style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              DropdownButtonFormField<CallFrequency>(
                key: const Key('frequencyDropdown'),
                initialValue: _frequency,
                isExpanded: true,
                items: CallFrequency.values
                    .map((f) => DropdownMenuItem(value: f, child: Text(f.label)))
                    .toList(),
                onChanged: (v) => setState(() => _frequency = v!),
              ),
              const SizedBox(height: 16),
              Text('How long per session?', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              SegmentedButton<int>(
                key: const Key('sessionMinutesSelector'),
                segments: [
                  for (final m in kSessionMinuteOptions) ButtonSegment(value: m, label: Text('$m min')),
                ],
                selected: {_sessionMinutes},
                onSelectionChanged: (s) => setState(() => _sessionMinutes = s.first),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  key: const Key('saveListingButton'),
                  onPressed: _isSaving ? null : _save,
                  child: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Save my pledge'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
