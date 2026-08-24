import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/services/profile_repository.dart';
import 'network_models.dart';
import 'network_service.dart';

class NetworkQueueScreen extends StatefulWidget {
  const NetworkQueueScreen({super.key, this.networkService});

  /// Overridable for testing so no real HTTP call is made.
  final NetworkService? networkService;

  @override
  State<NetworkQueueScreen> createState() => _NetworkQueueScreenState();
}

class _NetworkQueueScreenState extends State<NetworkQueueScreen> {
  bool _isLoading = true;
  String? _error;
  List<IncomingRequest> _requests = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  NetworkService? _service() {
    if (widget.networkService != null) return widget.networkService;
    final token = context.read<ProfileRepository>().sessionToken;
    return token == null ? null : NetworkService(sessionToken: token);
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
      final requests = await service.myQueue();
      if (!mounted) return;
      setState(() {
        _requests = requests;
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

  Future<void> _respond(IncomingRequest request, bool accept) async {
    final service = _service();
    if (service == null) return;
    try {
      await service.respond(requestId: request.id, accept: accept);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(accept ? 'Accepted' : 'Declined')));
      _load();
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
      appBar: AppBar(title: const Text('Requests Waiting for You')),
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
    if (_requests.isEmpty) {
      return const Center(child: Text('No pending requests right now.'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: _requests.length,
      itemBuilder: (context, i) {
        final request = _requests[i];
        return Card(
          key: ValueKey('incomingRequest_${request.id}'),
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(request.requesterDisplayName, style: Theme.of(context).textTheme.titleMedium),
                    ),
                    Chip(label: Text(request.askType.label), visualDensity: VisualDensity.compact),
                  ],
                ),
                if (request.requesterNote != null) ...[
                  const SizedBox(height: 6),
                  Text(request.requesterNote!, style: Theme.of(context).textTheme.bodyMedium),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        key: ValueKey('declineRequest_${request.id}'),
                        onPressed: () => _respond(request, false),
                        child: const Text('Decline'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        key: ValueKey('acceptRequest_${request.id}'),
                        onPressed: () => _respond(request, true),
                        child: const Text('Accept'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
