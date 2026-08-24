import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/models/job_application.dart';
import '../../core/services/profile_repository.dart';
import '../../core/utils/date_format.dart';

/// Add a new application, or edit an existing one when [existing] is
/// provided. All fields are the officer's own entry — nothing here is
/// generated.
class AddEditApplicationScreen extends StatefulWidget {
  const AddEditApplicationScreen({
    super.key,
    this.existing,
    this.initialCompanyName,
    this.initialRoleTitle,
    this.initialSource,
  });

  final JobApplication? existing;

  /// Pre-fills for the "Track this application" hook from Job Matches.
  final String? initialCompanyName;
  final String? initialRoleTitle;
  final String? initialSource;

  @override
  State<AddEditApplicationScreen> createState() => _AddEditApplicationScreenState();
}

class _AddEditApplicationScreenState extends State<AddEditApplicationScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _companyController;
  late final TextEditingController _roleController;
  late final TextEditingController _sourceController;
  late final TextEditingController _notesController;
  late final TextEditingController _nextActionNoteController;

  late ApplicationStatus _status;
  DateTime? _appliedDate;
  DateTime? _nextActionDate;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _companyController = TextEditingController(text: existing?.companyName ?? widget.initialCompanyName ?? '');
    _roleController = TextEditingController(text: existing?.roleTitle ?? widget.initialRoleTitle ?? '');
    _sourceController = TextEditingController(text: existing?.source ?? widget.initialSource ?? '');
    _notesController = TextEditingController(text: existing?.notes ?? '');
    _nextActionNoteController = TextEditingController(text: existing?.nextActionNote ?? '');
    _status = existing?.status ?? ApplicationStatus.saved;
    _appliedDate = existing?.appliedDate;
    _nextActionDate = existing?.nextActionDate;
  }

  @override
  void dispose() {
    _companyController.dispose();
    _roleController.dispose();
    _sourceController.dispose();
    _notesController.dispose();
    _nextActionNoteController.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required DateTime? initial, required ValueChanged<DateTime> onPicked}) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial ?? now,
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year + 2),
    );
    if (picked != null) onPicked(picked);
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final repo = context.read<ProfileRepository>();
    final existing = widget.existing;
    final application = JobApplication(
      id: existing?.id ?? DateTime.now().microsecondsSinceEpoch.toString(),
      companyName: _companyController.text.trim(),
      roleTitle: _roleController.text.trim(),
      status: _status,
      createdAt: existing?.createdAt ?? DateTime.now(),
      source: _sourceController.text.trim().isEmpty ? null : _sourceController.text.trim(),
      appliedDate: _appliedDate,
      nextActionDate: _nextActionDate,
      nextActionNote: _nextActionNoteController.text.trim().isEmpty
          ? null
          : _nextActionNoteController.text.trim(),
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
    );

    if (existing == null) {
      repo.addApplication(application);
    } else {
      repo.updateApplication(application);
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existing != null;
    return Scaffold(
      appBar: AppBar(title: Text(isEditing ? 'Edit application' : 'Add application')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                key: const Key('companyField'),
                controller: _companyController,
                decoration: const InputDecoration(labelText: 'Company'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                key: const Key('roleField'),
                controller: _roleController,
                decoration: const InputDecoration(labelText: 'Role title'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<ApplicationStatus>(
                key: const Key('statusDropdown'),
                initialValue: _status,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Status'),
                items: ApplicationStatus.values
                    .map((s) => DropdownMenuItem(value: s, child: Text(s.label)))
                    .toList(),
                onChanged: (v) => setState(() => _status = v!),
              ),
              const SizedBox(height: 16),
              TextFormField(
                key: const Key('sourceField'),
                controller: _sourceController,
                decoration: const InputDecoration(
                  labelText: 'Source (optional)',
                  hintText: 'e.g. Job Matches, LinkedIn, referral name',
                ),
              ),
              const SizedBox(height: 16),
              _DateField(
                key: const Key('appliedDateField'),
                label: 'Applied date (optional)',
                value: _appliedDate,
                onTap: () => _pickDate(
                  initial: _appliedDate,
                  onPicked: (d) => setState(() => _appliedDate = d),
                ),
                onClear: () => setState(() => _appliedDate = null),
              ),
              const SizedBox(height: 16),
              _DateField(
                key: const Key('nextActionDateField'),
                label: 'Next action date (optional)',
                value: _nextActionDate,
                onTap: () => _pickDate(
                  initial: _nextActionDate,
                  onPicked: (d) => setState(() => _nextActionDate = d),
                ),
                onClear: () => setState(() => _nextActionDate = null),
              ),
              const SizedBox(height: 16),
              TextFormField(
                key: const Key('nextActionNoteField'),
                controller: _nextActionNoteController,
                decoration: const InputDecoration(
                  labelText: 'Next action (optional)',
                  hintText: 'e.g. Follow up with recruiter',
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                key: const Key('notesField'),
                controller: _notesController,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Notes (optional)'),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  key: const Key('saveApplicationButton'),
                  onPressed: _save,
                  child: Text(isEditing ? 'Save changes' : 'Add application'),
                ),
              ),
              if (isEditing) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    key: const Key('deleteApplicationButton'),
                    onPressed: () {
                      context.read<ProfileRepository>().deleteApplication(widget.existing!.id);
                      Navigator.of(context).pop();
                    },
                    child: const Text('Delete'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({
    super.key,
    required this.label,
    required this.value,
    required this.onTap,
    required this.onClear,
  });

  final String label;
  final DateTime? value;
  final VoidCallback onTap;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          suffixIcon: value != null
              ? IconButton(icon: const Icon(Icons.clear), onPressed: onClear)
              : const Icon(Icons.calendar_today_outlined),
        ),
        child: Text(value == null ? 'Not set' : formatDate(value!)),
      ),
    );
  }
}
