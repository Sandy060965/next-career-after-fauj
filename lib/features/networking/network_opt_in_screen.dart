import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/services/profile_repository.dart';
import 'network_models.dart';
import 'network_service.dart';

class NetworkOptInScreen extends StatefulWidget {
  const NetworkOptInScreen({super.key, this.existing, this.networkService});

  final NetworkContact? existing;

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

  late NetworkChannel _channel;
  late CallFrequency _frequency;
  late List<CallSlot> _slots;
  late bool _offersReferrals;
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
    _channel = existing?.channel ?? NetworkChannel.inTransition;
    _frequency = existing?.callFrequency ?? CallFrequency.weekly;
    _slots = existing?.callSlots.isNotEmpty == true
        ? List.of(existing!.callSlots)
        : [const CallSlot(dayOfWeek: 'Wed', startTime: '19:00')];
    _offersReferrals = existing?.offersReferrals ?? false;
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

  Future<void> _pickTime(int slotIndex) async {
    final current = _slots[slotIndex];
    final parts = current.startTime.split(':');
    final initial = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked == null) return;
    setState(() {
      _slots[slotIndex] = CallSlot(
        dayOfWeek: current.dayOfWeek,
        startTime:
            '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}',
      );
    });
  }

  void _setSlotCount(int count) {
    setState(() {
      if (count == 1) {
        _slots = [_slots.first];
      } else if (_slots.length == 1) {
        _slots = [_slots.first, const CallSlot(dayOfWeek: 'Sat', startTime: '10:00')];
      }
    });
  }

  NetworkService? _service() {
    if (widget.networkService != null) return widget.networkService;
    final token = context.read<ProfileRepository>().sessionToken;
    return token == null ? null : NetworkService(sessionToken: token);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final service = _service();
    if (service == null) return;

    setState(() => _isSaving = true);
    try {
      await service.optIn(
        channel: _channel,
        displayName: _nameController.text.trim(),
        email: _emailController.text.trim(),
        callFrequency: _frequency,
        callSlots: _slots,
        offersReferrals: _channel == NetworkChannel.transitioned && _offersReferrals,
        vertical: _verticalController.text.trim().isEmpty ? null : _verticalController.text.trim(),
        city: _cityController.text.trim().isEmpty ? null : _cityController.text.trim(),
        currentCompany: _channel == NetworkChannel.transitioned && _companyController.text.trim().isNotEmpty
            ? _companyController.text.trim()
            : null,
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
      appBar: AppBar(title: const Text('Volunteer to Help Others')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "You're always in control — set how much time you can give, and remove "
                'yourself from this list any time.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 20),
              RadioGroup<NetworkChannel>(
                groupValue: _channel,
                onChanged: (v) => setState(() => _channel = v!),
                child: Column(
                  children: NetworkChannel.values
                      .map(
                        (c) => RadioListTile<NetworkChannel>(
                          key: ValueKey('channel_${c.wireValue}'),
                          value: c,
                          contentPadding: EdgeInsets.zero,
                          title: Text(c.label),
                        ),
                      )
                      .toList(),
                ),
              ),
              const SizedBox(height: 12),
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
                  helperText: 'Only shared once you accept a specific request — never your mobile number.',
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
              if (_channel == NetworkChannel.transitioned) ...[
                const SizedBox(height: 16),
                TextFormField(
                  key: const Key('companyField'),
                  controller: _companyController,
                  decoration: const InputDecoration(labelText: 'Current company (optional)'),
                ),
              ],
              const SizedBox(height: 24),
              Text('How often can you offer time?', style: Theme.of(context).textTheme.titleSmall),
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
              Text('How many 30-min slots each time?', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              SegmentedButton<int>(
                key: const Key('slotCountSelector'),
                segments: const [
                  ButtonSegment(value: 1, label: Text('1 slot')),
                  ButtonSegment(value: 2, label: Text('2 slots')),
                ],
                selected: {_slots.length},
                onSelectionChanged: (s) => _setSlotCount(s.first),
              ),
              const SizedBox(height: 12),
              for (var i = 0; i < _slots.length; i++) _buildSlotRow(i),
              if (_channel == NetworkChannel.transitioned) ...[
                const SizedBox(height: 12),
                SwitchListTile(
                  key: const Key('offersReferralsSwitch'),
                  contentPadding: EdgeInsets.zero,
                  value: _offersReferrals,
                  onChanged: (v) => setState(() => _offersReferrals = v),
                  title: const Text('Open to giving referrals'),
                  subtitle: const Text('Requesting officers are capped to 1 referral ask per week.'),
                ),
              ],
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
                      : const Text('Save my listing'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSlotRow(int index) {
    final slot = _slots[index];
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: DropdownButtonFormField<String>(
              key: ValueKey('slotDayDropdown_$index'),
              initialValue: slot.dayOfWeek,
              decoration: const InputDecoration(labelText: 'Day'),
              items: kWeekdays.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
              onChanged: (v) =>
                  setState(() => _slots[index] = CallSlot(dayOfWeek: v!, startTime: slot.startTime)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: InkWell(
              key: ValueKey('slotTimeField_$index'),
              onTap: () => _pickTime(index),
              child: InputDecorator(
                decoration: const InputDecoration(labelText: 'Time'),
                child: Text(slot.startTime),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
