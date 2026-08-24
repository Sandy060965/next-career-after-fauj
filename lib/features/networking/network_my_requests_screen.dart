import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/services/profile_repository.dart';
import 'network_models.dart';
import 'network_service.dart';

class NetworkMyRequestsScreen extends StatefulWidget {
  const NetworkMyRequestsScreen({super.key, this.networkService});

  /// Overridable for testing so no real HTTP call is made.
  final NetworkService? networkService;

  @override
  State<NetworkMyRequestsScreen> createState() => _NetworkMyRequestsScreenState();
}

class _NetworkMyRequestsScreenState extends State<NetworkMyRequestsScreen> {
  bool _isLoading = true;
  String? _error;
  List<OutgoingRequest> _requests = const [];

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
      final requests = await service.myRequests();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Requests')),
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
      return const Center(child: Text("You haven't sent any requests yet."));
    }
    final colorScheme = Theme.of(context).colorScheme;
    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: _requests.length,
      itemBuilder: (context, i) {
        final request = _requests[i];
        final (chipColor, chipTextColor) = switch (request.status) {
          ConnectionRequestStatus.accepted => (colorScheme.primaryContainer, colorScheme.onPrimaryContainer),
          ConnectionRequestStatus.declined => (colorScheme.errorContainer, colorScheme.onErrorContainer),
          ConnectionRequestStatus.expired => (colorScheme.surfaceContainerHighest, colorScheme.onSurfaceVariant),
          ConnectionRequestStatus.pending => (colorScheme.tertiaryContainer, colorScheme.onTertiaryContainer),
        };
        return Card(
          key: ValueKey('outgoingRequest_${request.id}'),
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(request.volunteerDisplayName, style: Theme.of(context).textTheme.titleMedium),
                    ),
                    Chip(
                      label: Text(request.status.label),
                      backgroundColor: chipColor,
                      labelStyle: TextStyle(color: chipTextColor, fontSize: 12),
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(request.askType.label, style: Theme.of(context).textTheme.bodySmall),
                if (request.volunteerEmail != null) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: Text(request.volunteerEmail!)),
                      IconButton(
                        key: ValueKey('copyEmail_${request.id}'),
                        icon: const Icon(Icons.copy_outlined),
                        onPressed: () async {
                          final messenger = ScaffoldMessenger.of(context);
                          await Clipboard.setData(ClipboardData(text: request.volunteerEmail!));
                          messenger
                            ..hideCurrentSnackBar()
                            ..showSnackBar(const SnackBar(content: Text('Email copied to clipboard')));
                        },
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
