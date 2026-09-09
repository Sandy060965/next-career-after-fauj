import 'package:flutter/material.dart';

import 'admin_http_service.dart';
import 'admin_officer_summary.dart';
import 'allowed_phone_summary.dart';
import 'course_submission_summary.dart';
import 'login_event.dart';
import 'support_ticket_summary.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({
    super.key,
    required this.adminKey,
    this.fetchOfficers = httpFetchAdminOfficers,
    this.fetchSupportTickets = httpFetchAdminSupportTickets,
    this.resolveTicket = httpResolveSupportTicket,
    this.fetchAllowedPhones = httpFetchAllowedPhones,
    this.addAllowedPhone = httpAddAllowedPhone,
    this.removeAllowedPhone = httpRemoveAllowedPhone,
    this.fetchLoginHistory = httpFetchLoginHistory,
    this.fetchCourseSubmissions = httpFetchCourseSubmissions,
    this.approveCourseSubmission = httpApproveCourseSubmission,
    this.rejectCourseSubmission = httpRejectCourseSubmission,
  });

  final String adminKey;
  final FetchAdminOfficers fetchOfficers;
  final FetchAdminSupportTickets fetchSupportTickets;
  final ResolveSupportTicket resolveTicket;
  final FetchAllowedPhones fetchAllowedPhones;
  final AddAllowedPhone addAllowedPhone;
  final RemoveAllowedPhone removeAllowedPhone;
  final FetchLoginHistory fetchLoginHistory;
  final FetchCourseSubmissions fetchCourseSubmissions;
  final ApproveCourseSubmission approveCourseSubmission;
  final RejectCourseSubmission rejectCourseSubmission;

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  bool _isLoading = true;
  String? _error;
  List<AdminOfficerSummary> _officers = const [];
  List<SupportTicketSummary> _tickets = const [];
  List<AllowedPhoneSummary> _allowedPhones = const [];
  List<LoginEvent> _logins = const [];
  List<CourseSubmissionSummary> _courseSubmissions = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        widget.fetchOfficers(widget.adminKey),
        widget.fetchSupportTickets(widget.adminKey),
        widget.fetchAllowedPhones(widget.adminKey),
        widget.fetchLoginHistory(widget.adminKey),
        widget.fetchCourseSubmissions(widget.adminKey),
      ]);
      if (!mounted) return;
      setState(() {
        _officers = results[0] as List<AdminOfficerSummary>;
        _tickets = results[1] as List<SupportTicketSummary>;
        _allowedPhones = results[2] as List<AllowedPhoneSummary>;
        _logins = results[3] as List<LoginEvent>;
        _courseSubmissions = results[4] as List<CourseSubmissionSummary>;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = '$e';
      });
    }
  }

  Future<void> _resolve(String ticketId) async {
    try {
      await widget.resolveTicket(widget.adminKey, ticketId);
      if (!mounted) return;
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  Future<void> _addPhone(String mobileNumber, String? note) async {
    try {
      await widget.addAllowedPhone(widget.adminKey, mobileNumber, note);
      if (!mounted) return;
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  Future<void> _removePhone(String mobileNumber) async {
    try {
      await widget.removeAllowedPhone(widget.adminKey, mobileNumber);
      if (!mounted) return;
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  Future<void> _approveCourse(String id) async {
    try {
      await widget.approveCourseSubmission(widget.adminKey, id);
      if (!mounted) return;
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  Future<void> _rejectCourse(String id) async {
    try {
      await widget.rejectCourseSubmission(widget.adminKey, id);
      if (!mounted) return;
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final openTickets = _tickets.where((t) => !t.isResolved).length;
    final pendingCourses = _courseSubmissions.where((s) => s.isPending).length;
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Admin Dashboard'),
          actions: [
            IconButton(
              key: const Key('adminRefreshButton'),
              icon: const Icon(Icons.refresh),
              tooltip: 'Refresh',
              onPressed: _isLoading ? null : _load,
            ),
          ],
          bottom: TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: 'Officers (${_officers.length})'),
              Tab(text: 'Support Tickets ($openTickets open)'),
              Tab(text: 'Allowed Numbers (${_allowedPhones.length})'),
              Tab(text: 'Course Submissions ($pendingCourses pending)'),
            ],
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(_error!, textAlign: TextAlign.center),
                    ),
                  )
                : TabBarView(
                    children: [
                      _OfficersTab(officers: _officers, logins: _logins),
                      _SupportTicketsTab(tickets: _tickets, onResolve: _resolve),
                      _AllowedPhonesTab(
                        phones: _allowedPhones,
                        onAdd: _addPhone,
                        onRemove: _removePhone,
                      ),
                      _CourseSubmissionsTab(
                        submissions: _courseSubmissions,
                        onApprove: _approveCourse,
                        onReject: _rejectCourse,
                      ),
                    ],
                  ),
      ),
    );
  }
}

class _OfficersTab extends StatelessWidget {
  const _OfficersTab({required this.officers, required this.logins});

  final List<AdminOfficerSummary> officers;
  final List<LoginEvent> logins;

  @override
  Widget build(BuildContext context) {
    if (officers.isEmpty) {
      return const Center(child: Text('No officers have signed up yet.'));
    }
    return ListView.builder(
      key: const Key('adminOfficersList'),
      padding: const EdgeInsets.all(16),
      itemCount: officers.length,
      itemBuilder: (context, index) {
        final officer = officers[index];
        final officerLogins = logins.where((l) => l.officerId == officer.id).toList();
        return _OfficerCard(officer: officer, logins: officerLogins);
      },
    );
  }
}

class _OfficerCard extends StatelessWidget {
  const _OfficerCard({required this.officer, required this.logins});

  final AdminOfficerSummary officer;
  final List<LoginEvent> logins;

  @override
  Widget build(BuildContext context) {
    final o = officer;
    final displayName = [if (o.rank != null) o.rank, if (o.fullName != null) o.fullName]
        .whereType<String>()
        .join(' ');
    return Card(
      key: ValueKey('adminOfficerCard_${o.id}'),
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    displayName.isEmpty ? o.mobileNumber : displayName,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Chip(label: Text(o.entitlementTier), visualDensity: VisualDensity.compact),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${o.mobileNumber} • signed up ${_formatDate(o.createdAt)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            if (!o.hasOpenedApp)
              Text(
                "Hasn't opened the app since signing up.",
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontStyle: FontStyle.italic,
                ),
              )
            else ...[
              Text(
                o.readinessScore == null
                    ? 'Transition Readiness: not yet started '
                        '(${o.readinessDimensionsCompleted}/${o.readinessDimensionsTotal})'
                    : 'Transition Readiness: ${o.readinessScore}/100 '
                        '(${o.readinessDimensionsCompleted}/${o.readinessDimensionsTotal} assessments)',
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  _MilestoneChip(label: 'CV uploaded', done: o.cvUploaded),
                  _MilestoneChip(label: 'CV civilianized', done: o.civilianizedCvDone),
                  _MilestoneChip(label: 'CV built', done: o.builtCvDone),
                  _MilestoneChip(label: 'JD Match', done: o.jdMatchDone),
                  _MilestoneChip(label: 'Financial plan', done: o.financialPlanDone),
                  _MilestoneChip(label: 'Target role strategy', done: o.targetRoleStrategyDone),
                  if (o.applicationsCount > 0)
                    Chip(
                      label: Text('${o.applicationsCount} application(s) tracked'),
                      visualDensity: VisualDensity.compact,
                    ),
                ],
              ),
            ],
            if (logins.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),
              _LoginHistorySection(logins: logins),
            ],
          ],
        ),
      ),
    );
  }
}

class _LoginHistorySection extends StatelessWidget {
  const _LoginHistorySection({required this.logins});

  final List<LoginEvent> logins;

  @override
  Widget build(BuildContext context) {
    final distinctDevices = logins.map((l) => l.deviceLabel).toSet().length;
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              distinctDevices > 2 ? Icons.warning_amber : Icons.devices_outlined,
              size: 16,
              color: distinctDevices > 2 ? colorScheme.error : colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 6),
            Text(
              '${logins.length} login(s) from $distinctDevices distinct device(s)',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: distinctDevices > 2 ? colorScheme.error : colorScheme.onSurfaceVariant,
                    fontWeight: distinctDevices > 2 ? FontWeight.bold : null,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        for (final login in logins.take(5))
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              '${_formatDate(login.loggedInAt)} — ${login.deviceLabel} • ${login.locationLabel}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        if (logins.length > 5)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              '+ ${logins.length - 5} more',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
      ],
    );
  }
}

class _MilestoneChip extends StatelessWidget {
  const _MilestoneChip({required this.label, required this.done});

  final String label;
  final bool done;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Chip(
      avatar: Icon(
        done ? Icons.check_circle : Icons.radio_button_unchecked,
        size: 16,
        color: done ? colorScheme.primary : colorScheme.onSurfaceVariant,
      ),
      label: Text(label),
      visualDensity: VisualDensity.compact,
      backgroundColor: done ? colorScheme.primaryContainer : null,
    );
  }
}

class _SupportTicketsTab extends StatelessWidget {
  const _SupportTicketsTab({required this.tickets, required this.onResolve});

  final List<SupportTicketSummary> tickets;
  final ValueChanged<String> onResolve;

  @override
  Widget build(BuildContext context) {
    if (tickets.isEmpty) {
      return const Center(child: Text('No support tickets yet.'));
    }
    return ListView.builder(
      key: const Key('adminSupportTicketsList'),
      padding: const EdgeInsets.all(16),
      itemCount: tickets.length,
      itemBuilder: (context, index) {
        final ticket = tickets[index];
        return Card(
          key: ValueKey('adminTicketCard_${ticket.id}'),
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        ticket.mobileNumber ?? 'Unknown officer',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                    ),
                    Chip(
                      label: Text(ticket.isResolved ? 'Resolved' : 'Open'),
                      visualDensity: VisualDensity.compact,
                      backgroundColor: ticket.isResolved
                          ? Theme.of(context).colorScheme.surfaceContainerHighest
                          : Theme.of(context).colorScheme.errorContainer,
                    ),
                  ],
                ),
                Text(
                  _formatDate(ticket.createdAt),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 8),
                Text(ticket.message),
                if (!ticket.isResolved) ...[
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: OutlinedButton(
                      key: ValueKey('resolveTicketButton_${ticket.id}'),
                      onPressed: () => onResolve(ticket.id),
                      child: const Text('Mark resolved'),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _AllowedPhonesTab extends StatefulWidget {
  const _AllowedPhonesTab({required this.phones, required this.onAdd, required this.onRemove});

  final List<AllowedPhoneSummary> phones;
  final Future<void> Function(String mobileNumber, String? note) onAdd;
  final ValueChanged<String> onRemove;

  @override
  State<_AllowedPhonesTab> createState() => _AllowedPhonesTabState();
}

class _AllowedPhonesTabState extends State<_AllowedPhonesTab> {
  final _numberController = TextEditingController();
  final _noteController = TextEditingController();
  bool _isAdding = false;

  @override
  void dispose() {
    _numberController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final number = _numberController.text.trim();
    if (number.length != 10) return;
    setState(() => _isAdding = true);
    await widget.onAdd(number, _noteController.text.trim());
    if (!mounted) return;
    setState(() {
      _isAdding = false;
      _numberController.clear();
      _noteController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'A brand-new mobile number must be on this list before it can complete '
                    'sign-up — closes the gap where a shared Cloudflare email alone would '
                    "otherwise let an uninvited person in. Officers who've already signed up "
                    "aren't affected.",
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: TextField(
                          key: const Key('newAllowedPhoneField'),
                          controller: _numberController,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(labelText: '10-digit mobile number'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          key: const Key('newAllowedPhoneNoteField'),
                          controller: _noteController,
                          decoration: const InputDecoration(labelText: 'Note (optional)'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: FilledButton(
                      key: const Key('addAllowedPhoneButton'),
                      onPressed: _isAdding ? null : _submit,
                      child: _isAdding
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Add'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Expanded(
          child: widget.phones.isEmpty
              ? const Center(child: Text('No numbers added yet — every new signup is blocked.'))
              : ListView.builder(
                  key: const Key('adminAllowedPhonesList'),
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  itemCount: widget.phones.length,
                  itemBuilder: (context, index) {
                    final phone = widget.phones[index];
                    return Card(
                      key: ValueKey('allowedPhoneCard_${phone.mobileNumber}'),
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        title: Text(phone.mobileNumber),
                        subtitle: Text(
                          [
                            if (phone.note != null && phone.note!.isNotEmpty) phone.note,
                            'added ${_formatDate(phone.addedAt)}',
                          ].join(' • '),
                        ),
                        trailing: IconButton(
                          key: ValueKey('removeAllowedPhoneButton_${phone.mobileNumber}'),
                          icon: const Icon(Icons.delete_outline),
                          tooltip: 'Remove',
                          onPressed: () => widget.onRemove(phone.mobileNumber),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _CourseSubmissionsTab extends StatelessWidget {
  const _CourseSubmissionsTab({
    required this.submissions,
    required this.onApprove,
    required this.onReject,
  });

  final List<CourseSubmissionSummary> submissions;
  final ValueChanged<String> onApprove;
  final ValueChanged<String> onReject;

  @override
  Widget build(BuildContext context) {
    if (submissions.isEmpty) {
      return const Center(child: Text('No course lookups submitted by officers yet.'));
    }
    // Pending first — that's the actual work queue; already-reviewed
    // entries stay visible below for reference, not left to accumulate
    // invisibly.
    final sorted = [...submissions]..sort((a, b) {
        if (a.isPending == b.isPending) return b.submittedAt.compareTo(a.submittedAt);
        return a.isPending ? -1 : 1;
      });
    return ListView.builder(
      key: const Key('adminCourseSubmissionsList'),
      padding: const EdgeInsets.all(16),
      itemCount: sorted.length,
      itemBuilder: (context, index) {
        final submission = sorted[index];
        final colorScheme = Theme.of(context).colorScheme;
        return Card(
          key: ValueKey('courseSubmissionCard_${submission.id}'),
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        submission.courseName,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                    ),
                    Chip(
                      label: Text(submission.status),
                      visualDensity: VisualDensity.compact,
                      backgroundColor: switch (submission.status) {
                        'approved' => colorScheme.primaryContainer,
                        'rejected' => colorScheme.surfaceContainerHighest,
                        _ => colorScheme.tertiaryContainer,
                      },
                    ),
                  ],
                ),
                Text(
                  '${submission.mobileNumber ?? 'Unknown officer'} • '
                  '${_formatDate(submission.submittedAt)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 8),
                if (submission.civilianEquivalent != null) ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.arrow_downward, size: 16, color: colorScheme.primary),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          submission.civilianEquivalent!,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                ],
                if (submission.civilianDescription != null)
                  Text(submission.civilianDescription!, style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 6),
                Chip(
                  label: Text(
                    submission.verified ? 'Verified via web search' : 'Not independently verified',
                  ),
                  visualDensity: VisualDensity.compact,
                  backgroundColor:
                      submission.verified ? colorScheme.primaryContainer : colorScheme.surfaceContainerHighest,
                ),
                if (submission.sourceNote != null && submission.sourceNote!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    submission.sourceNote!,
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(fontStyle: FontStyle.italic, color: colorScheme.onSurfaceVariant),
                  ),
                ],
                if (submission.courseDescription != null && submission.courseDescription!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    "Officer's own description: ${submission.courseDescription}",
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
                if (submission.isPending) ...[
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        key: ValueKey('rejectCourseButton_${submission.id}'),
                        onPressed: () => onReject(submission.id),
                        child: const Text('Reject'),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        key: ValueKey('approveCourseButton_${submission.id}'),
                        onPressed: () => onApprove(submission.id),
                        child: const Text('Approve & add to list'),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

String _formatDate(DateTime date) {
  final local = date.toLocal();
  return '${local.day.toString().padLeft(2, '0')}/${local.month.toString().padLeft(2, '0')}/'
      '${local.year}';
}
