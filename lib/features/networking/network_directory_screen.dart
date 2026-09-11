import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/services/profile_repository.dart';
import '../../core/utils/date_format.dart';
import '../../core/widgets/home_button.dart';
import 'network_models.dart';
import 'network_opt_in_screen.dart';
import 'network_service.dart';

/// Pure data capture: officers pledge to give a small, recurring amount of
/// time to help other officers once they've joined their own civilian role.
/// There's deliberately no browsing, request or scheduling flow here —
/// officers typically lose access to this app once they join their new
/// employer, so this only ever captures the pledge itself.
class NetworkDirectoryScreen extends StatefulWidget {
  const NetworkDirectoryScreen({super.key, this.networkService});

  /// Overridable for testing so no real HTTP call is made.
  final NetworkService? networkService;

  @override
  State<NetworkDirectoryScreen> createState() => _NetworkDirectoryScreenState();
}

class _NetworkDirectoryScreenState extends State<NetworkDirectoryScreen> {
  bool _isLoading = true;
  MentorPledge? _pledge;

  NetworkService? _service() {
    if (widget.networkService != null) return widget.networkService;
    final repo = context.read<ProfileRepository>();
    return repo.sessionToken == null ? null : NetworkService(profileRepository: repo);
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final service = _service();
    if (service == null) {
      setState(() => _isLoading = false);
      return;
    }
    try {
      final pledge = await service.myListing();
      if (!mounted) return;
      setState(() {
        _pledge = pledge;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _withdraw() async {
    final service = _service();
    if (service == null) return;
    try {
      await service.optOut();
      if (!mounted) return;
      setState(() => _pledge = null);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('Your pledge has been withdrawn')));
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
      appBar: AppBar(title: const Text('Future Mentor Sign Up'), actions: const [HomeButton()]),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            'Pledge a small, recurring amount of time to mentor other officers once you\'ve '
            'joined your own civilian role — a simple sign-up, not a live booking system.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 20),
          _buildPledgeCard(),
        ],
      ),
    );
  }

  Widget _buildPledgeCard() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    final pledge = _pledge;
    if (pledge == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("You haven't pledged yet", style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 4),
              const Text(
                'Willing to give a little time to the next officer transitioning, once you\'ve '
                'settled into your own role? Fully optional.',
              ),
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
                    if (saved == true) _load();
                  },
                  child: const Text('Pledge to mentor'),
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
            Text("You're pledged as a future mentor", style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text('${pledge.callFrequency.label} · ${pledge.sessionMinutes} min sessions'),
            if (pledge.joiningDate != null) ...[
              const SizedBox(height: 4),
              Text('Joining: ${formatDate(pledge.joiningDate!)}'),
            ],
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
                              NetworkOptInScreen(existing: pledge, networkService: widget.networkService),
                        ),
                      );
                      if (saved == true) _load();
                    },
                    child: const Text('Edit'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    key: const Key('optOutButton'),
                    onPressed: _withdraw,
                    child: const Text('Withdraw'),
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
