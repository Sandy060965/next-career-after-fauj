import 'package:flutter/material.dart';

import 'admin_http_service.dart';
import 'admin_officer_summary.dart';
import 'support_ticket_summary.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({
    super.key,
    required this.adminKey,
    this.fetchOfficers = httpFetchAdminOfficers,
    this.fetchSupportTickets = httpFetchAdminSupportTickets,
    this.resolveTicket = httpResolveSupportTicket,
  });

  final String adminKey;
  final FetchAdminOfficers fetchOfficers;
  final FetchAdminSupportTickets fetchSupportTickets;
  final ResolveSupportTicket resolveTicket;

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  bool _isLoading = true;
  String? _error;
  List<AdminOfficerSummary> _officers = const [];
  List<SupportTicketSummary> _tickets = const [];

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
      ]);
      if (!mounted) return;
      setState(() {
        _officers = results[0] as List<AdminOfficerSummary>;
        _tickets = results[1] as List<SupportTicketSummary>;
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

  @override
  Widget build(BuildContext context) {
    final openTickets = _tickets.where((t) => !t.isResolved).length;
    return DefaultTabController(
      length: 2,
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
            tabs: [
              Tab(text: 'Officers (${_officers.length})'),
              Tab(text: 'Support Tickets ($openTickets open)'),
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
                      _OfficersTab(officers: _officers),
                      _SupportTicketsTab(tickets: _tickets, onResolve: _resolve),
                    ],
                  ),
      ),
    );
  }
}

class _OfficersTab extends StatelessWidget {
  const _OfficersTab({required this.officers});

  final List<AdminOfficerSummary> officers;

  @override
  Widget build(BuildContext context) {
    if (officers.isEmpty) {
      return const Center(child: Text('No officers have signed up yet.'));
    }
    return ListView.builder(
      key: const Key('adminOfficersList'),
      padding: const EdgeInsets.all(16),
      itemCount: officers.length,
      itemBuilder: (context, index) => _OfficerCard(officer: officers[index]),
    );
  }
}

class _OfficerCard extends StatelessWidget {
  const _OfficerCard({required this.officer});

  final AdminOfficerSummary officer;

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
          ],
        ),
      ),
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

String _formatDate(DateTime date) {
  final local = date.toLocal();
  return '${local.day.toString().padLeft(2, '0')}/${local.month.toString().padLeft(2, '0')}/'
      '${local.year}';
}
