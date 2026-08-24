import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/models/officer_profile.dart';
import '../../core/services/profile_repository.dart';
import 'financial_plan.dart';

class FinancialPlannerScreen extends StatefulWidget {
  const FinancialPlannerScreen({super.key});

  @override
  State<FinancialPlannerScreen> createState() => _FinancialPlannerScreenState();
}

class _FinancialPlannerScreenState extends State<FinancialPlannerScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _pensionController;
  late final TextEditingController _fixedPayController;
  late final TextEditingController _variablePayController;
  late final TextEditingController _rentDeltaController;
  late final TextEditingController _healthcareDeltaController;
  late final TextEditingController _schoolFeeDeltaController;

  late bool _drawsPension;
  FinancialPlanResult? _result;

  @override
  void initState() {
    super.initState();
    final repo = context.read<ProfileRepository>();
    final existing = repo.lastFinancialPlanInput;
    final segment = repo.profile?.segment;

    _drawsPension = existing?.drawsPension ?? (segment != null && segment != OfficerSegment.ssc);
    _pensionController =
        TextEditingController(text: existing != null ? _numOrEmpty(existing.monthlyPension) : '');
    _fixedPayController =
        TextEditingController(text: existing != null ? _numOrEmpty(existing.annualFixedPay) : '');
    _variablePayController =
        TextEditingController(text: existing != null ? _numOrEmpty(existing.annualVariablePay) : '');
    _rentDeltaController =
        TextEditingController(text: existing != null ? _numOrEmpty(existing.monthlyRentDelta) : '');
    _healthcareDeltaController = TextEditingController(
        text: existing != null ? _numOrEmpty(existing.monthlyHealthcareDelta) : '');
    _schoolFeeDeltaController = TextEditingController(
        text: existing != null ? _numOrEmpty(existing.monthlySchoolFeeDelta) : '');

    if (existing != null) {
      _result = calculateFinancialPlan(existing);
    }
  }

  String _numOrEmpty(num value) => value == 0 ? '' : value.toString();

  @override
  void dispose() {
    _pensionController.dispose();
    _fixedPayController.dispose();
    _variablePayController.dispose();
    _rentDeltaController.dispose();
    _healthcareDeltaController.dispose();
    _schoolFeeDeltaController.dispose();
    super.dispose();
  }

  void _calculate() {
    if (!_formKey.currentState!.validate()) return;
    final input = FinancialPlanInput(
      drawsPension: _drawsPension,
      monthlyPension: _drawsPension ? _parse(_pensionController.text) : 0,
      annualFixedPay: _parse(_fixedPayController.text),
      annualVariablePay: _parse(_variablePayController.text),
      monthlyRentDelta: _parse(_rentDeltaController.text),
      monthlyHealthcareDelta: _parse(_healthcareDeltaController.text),
      monthlySchoolFeeDelta: _parse(_schoolFeeDeltaController.text),
    );
    setState(() => _result = calculateFinancialPlan(input));
    context.read<ProfileRepository>().saveFinancialPlanInput(input);
  }

  num _parse(String text) => text.trim().isEmpty ? 0 : (num.tryParse(text.trim()) ?? 0);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Financial & Cost-of-Living Calculator')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Every number here is one you enter — nothing is looked up automatically. Tax is '
                'estimated under the New Tax Regime (FY 2025-26 slabs) for planning purposes only, '
                'not tax advice.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 20),
              Text('Pension', style: Theme.of(context).textTheme.titleMedium),
              SwitchListTile(
                key: const Key('drawsPensionSwitch'),
                contentPadding: EdgeInsets.zero,
                value: _drawsPension,
                onChanged: (v) => setState(() => _drawsPension = v),
                title: const Text('I will draw a pension'),
              ),
              if (_drawsPension) ...[
                const SizedBox(height: 8),
                TextFormField(
                  key: const Key('monthlyPensionField'),
                  controller: _pensionController,
                  keyboardType: const TextInputType.numberWithOptions(),
                  decoration: const InputDecoration(labelText: 'Monthly pension (₹)'),
                  validator: (v) => _validateNonNegative(v, required: true),
                ),
              ],
              const SizedBox(height: 24),
              Text('Civilian offer', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              TextFormField(
                key: const Key('fixedPayField'),
                controller: _fixedPayController,
                keyboardType: const TextInputType.numberWithOptions(),
                decoration: const InputDecoration(
                  labelText: 'Annual fixed pay — guaranteed (₹)',
                ),
                validator: (v) => _validateNonNegative(v, required: true),
              ),
              const SizedBox(height: 16),
              TextFormField(
                key: const Key('variablePayField'),
                controller: _variablePayController,
                keyboardType: const TextInputType.numberWithOptions(),
                decoration: const InputDecoration(
                  labelText: 'Annual variable pay — bonus/ESOPs, optional (₹)',
                ),
                validator: (v) => _validateNonNegative(v, required: false),
              ),
              const SizedBox(height: 24),
              Text('Cost-of-living change', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 4),
              Text(
                "Estimate the change vs. what you pay today — negative if it'll cost you less.",
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 8),
              TextFormField(
                key: const Key('rentDeltaField'),
                controller: _rentDeltaController,
                keyboardType: const TextInputType.numberWithOptions(signed: true),
                decoration: const InputDecoration(labelText: 'Extra monthly rent (₹)'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                key: const Key('healthcareDeltaField'),
                controller: _healthcareDeltaController,
                keyboardType: const TextInputType.numberWithOptions(signed: true),
                decoration: const InputDecoration(
                  labelText: 'Extra monthly healthcare cost vs. ECHS/AFMS (₹)',
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                key: const Key('schoolFeeDeltaField'),
                controller: _schoolFeeDeltaController,
                keyboardType: const TextInputType.numberWithOptions(signed: true),
                decoration: const InputDecoration(
                  labelText: "Extra monthly children's education cost (₹)",
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  key: const Key('calculateButton'),
                  onPressed: _calculate,
                  child: const Text('Calculate'),
                ),
              ),
              if (_result != null) ...[
                const SizedBox(height: 24),
                _buildResult(_result!),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String? _validateNonNegative(String? value, {required bool required}) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return required ? 'Required' : null;
    final parsed = num.tryParse(text);
    if (parsed == null) return 'Enter a number';
    if (parsed < 0) return 'Enter a non-negative amount';
    return null;
  }

  Widget _buildResult(FinancialPlanResult result) {
    return Column(
      key: const Key('financialPlanResult'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Net monthly income (post-tax)', style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 8),
                _AmountRow('Guaranteed (fixed pay only)', result.netMonthlyGuaranteed),
                _AmountRow('With variable pay realized', result.netMonthlyWithVariable),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('After your cost-of-living change', style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 8),
                _AmountRow('Monthly cost-of-living delta', result.monthlyCostOfLivingDelta),
                const Divider(),
                _AmountRow('Effective net (guaranteed)', result.effectiveMonthlyGuaranteed, emphasize: true),
                _AmountRow(
                  'Effective net (with variable)',
                  result.effectiveMonthlyWithVariable,
                  emphasize: true,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Negotiation framing', style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 8),
                Text(result.negotiationGuidance, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _AmountRow extends StatelessWidget {
  const _AmountRow(this.label, this.amount, {this.emphasize = false});

  final String label;
  final num amount;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    final style = emphasize
        ? Theme.of(context).textTheme.titleMedium
        : Theme.of(context).textTheme.bodyMedium;
    final sign = amount < 0 ? '-' : '';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(label, style: style)),
          Text('$sign₹${_fmt(amount.abs())}', style: style),
        ],
      ),
    );
  }

  String _fmt(num value) => value.round().toString().replaceAllMapped(
        RegExp(r'\B(?=(\d{3})+(?!\d))'),
        (match) => ',',
      );
}
