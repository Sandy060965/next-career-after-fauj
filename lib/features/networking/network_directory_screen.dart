import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/services/profile_repository.dart';
import 'network_browse_screen.dart';
import 'network_models.dart';
import 'network_my_requests_screen.dart';
import 'network_opt_in_screen.dart';
import 'network_queue_screen.dart';
import 'network_service.dart';

class NetworkDirectoryScreen extends StatefulWidget {
  const NetworkDirectoryScreen({super.key, this.networkService});

  /// Overridable for testing so no real HTTP call is made.
  final NetworkService? networkService;

  @override
  State<NetworkDirectoryScreen> createState() => _NetworkDirectoryScreenState();
}

class _NetworkDirectoryScreenState extends State<NetworkDirectoryScreen> {
  bool _isLoading = true;
  NetworkContact? _listing;

  NetworkService? _service() {
    if (widget.networkService != null) return widget.networkService;
    final repo = context.read<ProfileRepository>();
    return repo.sessionToken == null ? null : NetworkService(profileRepository: repo);
  }

  @override
  void initState() {
    super.initState();
    _loadListing();
  }

  Future<void> _loadListing() async {
    final service = _service();
    if (service == null) {
      setState(() => _isLoading = false);
      return;
    }
    try {
      final listing = await service.myListing();
      if (!mounted) return;
      setState(() {
        _listing = listing;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _optOut() async {
    final service = _service();
    if (service == null) return;
    try {
      await service.optOut();
      if (!mounted) return;
      setState(() => _listing = null);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('Removed from the directory')));
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
      appBar: AppBar(title: const Text('Networking Directory')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            'Connect with other officers voluntarily, on your own terms — a call or a '
            'referral ask, capped so nobody gets flooded.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 20),
          _buildListingCard(),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              key: const Key('browseVolunteersButton'),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => NetworkBrowseScreen(networkService: widget.networkService)),
              ),
              child: const Text('Browse Volunteers'),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              key: const Key('myRequestsButton'),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => NetworkMyRequestsScreen(networkService: widget.networkService)),
              ),
              child: const Text('My Sent Requests'),
            ),
          ),
          if (_listing != null) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                key: const Key('myQueueButton'),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => NetworkQueueScreen(networkService: widget.networkService)),
                ),
                child: const Text('Requests Waiting for You'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildListingCard() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    final listing = _listing;
    if (listing == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("You're not listed yet", style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 4),
              const Text('Volunteer a small amount of time to help other officers — fully optional.'),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  key: const Key('becomeVolunteerButton'),
                  onPressed: () async {
                    final saved = await Navigator.of(context).push<bool>(
                      MaterialPageRoute(
                        builder: (_) => NetworkOptInScreen(networkService: widget.networkService),
                      ),
                    );
                    if (saved == true) _loadListing();
                  },
                  child: const Text('Volunteer to help others'),
                ),
              ),
            ],
          ),
        ),
      );
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text("You're listed as ${listing.channel.label}",
                      style: Theme.of(context).textTheme.titleMedium),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text('${listing.callFrequency.label} · ${listing.callSlots.length} slot(s)'),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    key: const Key('editListingButton'),
                    onPressed: () async {
                      final saved = await Navigator.of(context).push<bool>(
                        MaterialPageRoute(
                          builder: (_) =>
                              NetworkOptInScreen(existing: listing, networkService: widget.networkService),
                        ),
                      );
                      if (saved == true) _loadListing();
                    },
                    child: const Text('Edit'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    key: const Key('optOutButton'),
                    onPressed: _optOut,
                    child: const Text('Remove me'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
