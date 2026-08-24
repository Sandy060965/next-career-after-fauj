import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/services/profile_repository.dart';
import 'network_models.dart';
import 'network_service.dart';

class NetworkBrowseScreen extends StatefulWidget {
  const NetworkBrowseScreen({super.key, this.networkService});

  /// Overridable for testing so no real HTTP call is made.
  final NetworkService? networkService;

  @override
  State<NetworkBrowseScreen> createState() => _NetworkBrowseScreenState();
}

class _NetworkBrowseScreenState extends State<NetworkBrowseScreen> {
  bool _isLoading = true;
  String? _error;
  List<NetworkContact> _contacts = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  NetworkService? _service() {
    if (widget.networkService != null) return widget.networkService;
    final repo = context.read<ProfileRepository>();
    return repo.sessionToken == null ? null : NetworkService(profileRepository: repo);
  }

  Future<void> _load() async {
    final service = _service();
    if (service == null) {
      setState(() => _isLoading = false);
      return;
    }
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final contacts = await service.browse();
      if (!mounted) return;
      setState(() {
        _contacts = contacts;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '$e';
        _isLoading = false;
      });
    }
  }

  Future<void> _requestCall(NetworkContact contact, int slotIndex) async {
    final service = _service();
    if (service == null) return;
    final profile = context.read<ProfileRepository>().profile;
    try {
      await service.requestConnection(
        volunteerOfficerId: contact.officerId,
        askType: AskType.call,
        slotIndex: slotIndex,
        requesterDisplayName: profile?.fullName ?? 'An officer',
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('Call request sent')));
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  Future<void> _requestReferral(NetworkContact contact) async {
    final service = _service();
    if (service == null) return;
    final profile = context.read<ProfileRepository>().profile;
    try {
      await service.requestConnection(
        volunteerOfficerId: contact.officerId,
        askType: AskType.referral,
        requesterDisplayName: profile?.fullName ?? 'An officer',
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('Referral request sent')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Browse Volunteers')),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Padding(padding: const EdgeInsets.all(24), child: Text(_error!, textAlign: TextAlign.center)),
      );
    }
    if (_contacts.isEmpty) {
      return const Center(child: Text('No volunteers listed yet — check back soon.'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: _contacts.length,
      itemBuilder: (context, i) => _ContactCard(
        contact: _contacts[i],
        onRequestCall: (slotIndex) => _requestCall(_contacts[i], slotIndex),
        onRequestReferral: () => _requestReferral(_contacts[i]),
      ),
    );
  }
}

class _ContactCard extends StatelessWidget {
  const _ContactCard({required this.contact, required this.onRequestCall, required this.onRequestReferral});

  final NetworkContact contact;
  final ValueChanged<int> onRequestCall;
  final VoidCallback onRequestReferral;

  @override
  Widget build(BuildContext context) {
    return Card(
      key: ValueKey('contact_${contact.officerId}'),
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text(contact.displayName, style: Theme.of(context).textTheme.titleMedium)),
                Chip(
                  label: Text(contact.channel.label),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            if (contact.vertical != null || contact.city != null || contact.currentCompany != null) ...[
              const SizedBox(height: 4),
              Text(
                [contact.currentCompany, contact.vertical, contact.city].whereType<String>().join(' · '),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            const SizedBox(height: 12),
            Text(contact.callFrequency.label, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (var i = 0; i < contact.callSlots.length; i++)
                  _SlotChip(
                    slot: contact.callSlots[i],
                    isAvailable: contact.slotAvailability?[i] ?? true,
                    onTap: (contact.slotAvailability?[i] ?? true) ? () => onRequestCall(i) : null,
                  ),
              ],
            ),
            if (contact.offersReferrals) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  key: ValueKey('requestReferral_${contact.officerId}'),
                  onPressed: onRequestReferral,
                  child: const Text('Request a referral'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SlotChip extends StatelessWidget {
  const _SlotChip({required this.slot, required this.isAvailable, required this.onTap});

  final CallSlot slot;
  final bool isAvailable;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return ActionChip(
      key: ValueKey('slotChip_${slot.dayOfWeek}_${slot.startTime}'),
      label: Text('${slot.dayOfWeek} ${slot.startTime}${isAvailable ? '' : ' · Booked'}'),
      onPressed: onTap,
      backgroundColor: isAvailable ? colorScheme.primaryContainer : colorScheme.surfaceContainerHighest,
      labelStyle: TextStyle(
        color: isAvailable ? colorScheme.onPrimaryContainer : colorScheme.onSurfaceVariant,
      ),
    );
  }
}
