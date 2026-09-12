import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/models/officer_profile.dart';
import '../../core/services/profile_repository.dart';
import '../../core/widgets/home_button.dart';
import 'financial_plan.dart';
import 'military_pay_data.dart';

class FinancialPlannerScreen extends StatefulWidget {
  const FinancialPlannerScreen({super.key});

  @override
  State<FinancialPlannerScreen> createState() => _FinancialPlannerScreenState();
}

class _FinancialPlannerScreenState extends State<FinancialPlannerScreen> {
  final _formKey = GlobalKey<FormState>();

  // Pension / deferred
  late final TextEditingController _pensionController;
  late final TextEditingController _gratuityDsopController;

  // Corporate offer
  late final TextEditingController _fixedPayController;
  late final TextEditingController _variablePayController;
  late final TextEditingController _variableAchievementController;
  late final TextEditingController _employerPfGratuityController;
  late final TextEditingController _corporateMedicalController;
  late final TextEditingController _corporateHousingEducationController;
  late final TextEditingController _joiningBonusController;
  late final TextEditingController _equityValueController;

  // Cost-of-living change
  late final TextEditingController _rentDeltaController;
  late final TextEditingController _healthcareDeltaController;
  late final TextEditingController _schoolFeeDeltaController;
  late final TextEditingController _transportDeltaController;
  late final TextEditingController _riskPremiumController;

  // Military pay
  late final TextEditingController _yearsOfServiceController;
  late final TextEditingController _militaryBasicPayController;
  late final TextEditingController _militaryDaPercentController;
  late final TextEditingController _otherCashAllowancesController;
  late final TextEditingController _marketRentController;
  late final TextEditingController _actualAccommodationCostController;
  late final TextEditingController _dependentChildrenController;
  late final TextEditingController _schoolCostComparableController;
  late final TextEditingController _schoolCostActualController;
  late final TextEditingController _medicalBenchmarkController;
  late final TextEditingController _echsSubscriptionController;
  late final TextEditingController _csdSavingsController;

  late bool _drawsPension;
  OfficerService? _service;
  DefenceRank? _rank;
  bool _inGovtAccommodation = false;
  bool _echsSpouseCovered = true;
  bool _echsChildrenCovered = true;
  IllustrativeMilitaryProfile? _selectedExample;
  FinancialPlanResult? _result;

  @override
  void initState() {
    super.initState();
    final repo = context.read<ProfileRepository>();
    final existing = repo.lastFinancialPlanInput;
    final profile = repo.profile;
    final segment = profile?.segment;

    _drawsPension = existing?.drawsPension ?? (segment != null && segment != OfficerSegment.ssc);
    _service = existing?.service ?? profile?.service;
    _rank = existing?.rank;
    _inGovtAccommodation = existing?.inGovtAccommodation ?? false;
    _echsSpouseCovered = existing?.echsSpouseCovered ?? true;
    _echsChildrenCovered = existing?.echsChildrenCovered ?? (segment != OfficerSegment.ssc);

    _pensionController = TextEditingController(text: _numOrEmpty(existing?.monthlyPension ?? 0));
    _gratuityDsopController =
        TextEditingController(text: _numOrEmpty(existing?.oneTimeGratuityAndDsop ?? 0));
    _fixedPayController = TextEditingController(text: _numOrEmpty(existing?.annualFixedPay ?? 0));
    _variablePayController = TextEditingController(text: _numOrEmpty(existing?.annualVariablePay ?? 0));
    _variableAchievementController =
        TextEditingController(text: _numOrEmpty(existing?.variableAchievementPercent ?? 80));
    _employerPfGratuityController =
        TextEditingController(text: _numOrEmpty(existing?.employerPfGratuityAnnual ?? 0));
    _corporateMedicalController =
        TextEditingController(text: _numOrEmpty(existing?.corporateMedicalValue ?? 0));
    _corporateHousingEducationController =
        TextEditingController(text: _numOrEmpty(existing?.corporateHousingEducationSupport ?? 0));
    _joiningBonusController = TextEditingController(text: _numOrEmpty(existing?.joiningBonusOneTime ?? 0));
    _equityValueController = TextEditingController(text: _numOrEmpty(existing?.annualEquityValue ?? 0));
    _rentDeltaController = TextEditingController(text: _numOrEmpty(existing?.monthlyRentDelta ?? 0));
    _healthcareDeltaController =
        TextEditingController(text: _numOrEmpty(existing?.monthlyHealthcareDelta ?? 0));
    _schoolFeeDeltaController =
        TextEditingController(text: _numOrEmpty(existing?.monthlySchoolFeeDelta ?? 0));
    _transportDeltaController =
        TextEditingController(text: _numOrEmpty(existing?.monthlyTransportDelta ?? 0));
    _riskPremiumController =
        TextEditingController(text: _numOrEmpty(existing?.desiredRiskPremiumPercent ?? 10));
    _yearsOfServiceController = TextEditingController(
      text: _numOrEmpty(existing?.yearsOfService ?? profile?.workExperienceYears ?? 0),
    );
    _militaryBasicPayController =
        TextEditingController(text: _numOrEmpty(existing?.militaryBasicPay ?? 0));
    _militaryDaPercentController = TextEditingController(
      text: _numOrEmpty((existing?.militaryDaPercent ?? currentDaPercent) * 100),
    );
    _otherCashAllowancesController =
        TextEditingController(text: _numOrEmpty(existing?.otherAnnualCashAllowances ?? 0));
    _marketRentController =
        TextEditingController(text: _numOrEmpty(existing?.comparableMonthlyMarketRent ?? 0));
    _actualAccommodationCostController =
        TextEditingController(text: _numOrEmpty(existing?.actualMonthlyAccommodationCost ?? 0));
    _dependentChildrenController =
        TextEditingController(text: _numOrEmpty(existing?.dependentChildren ?? 0));
    _schoolCostComparableController =
        TextEditingController(text: _numOrEmpty(existing?.annualSchoolCostPerChildComparable ?? 0));
    _schoolCostActualController =
        TextEditingController(text: _numOrEmpty(existing?.actualAnnualSchoolCostPaid ?? 0));
    _medicalBenchmarkController =
        TextEditingController(text: _numOrEmpty(existing?.privateMedicalBenchmarkAnnual ?? 0));
    _echsSubscriptionController =
        TextEditingController(text: _numOrEmpty(existing?.oneTimeEchsSubscription ?? 0));
    _csdSavingsController = TextEditingController(text: _numOrEmpty(existing?.annualCsdSavings ?? 0));

    if (existing != null) {
      _result = calculateFinancialPlan(existing);
    }
  }

  String _numOrEmpty(num value) => value == 0 ? '' : value.toString();

  @override
  void dispose() {
    _pensionController.dispose();
    _gratuityDsopController.dispose();
    _fixedPayController.dispose();
    _variablePayController.dispose();
    _variableAchievementController.dispose();
    _employerPfGratuityController.dispose();
    _corporateMedicalController.dispose();
    _corporateHousingEducationController.dispose();
    _joiningBonusController.dispose();
    _equityValueController.dispose();
    _rentDeltaController.dispose();
    _healthcareDeltaController.dispose();
    _schoolFeeDeltaController.dispose();
    _transportDeltaController.dispose();
    _riskPremiumController.dispose();
    _yearsOfServiceController.dispose();
    _militaryBasicPayController.dispose();
    _militaryDaPercentController.dispose();
    _otherCashAllowancesController.dispose();
    _marketRentController.dispose();
    _actualAccommodationCostController.dispose();
    _dependentChildrenController.dispose();
    _schoolCostComparableController.dispose();
    _schoolCostActualController.dispose();
    _medicalBenchmarkController.dispose();
    _echsSubscriptionController.dispose();
    _csdSavingsController.dispose();
    super.dispose();
  }

  void _loadExample(IllustrativeMilitaryProfile example) {
    setState(() {
      _selectedExample = example;
      _service = example.service;
      _rank = example.rank;
      _echsChildrenCovered = true;
      _yearsOfServiceController.text = example.yearsOfService.toString();
      _militaryBasicPayController.text = example.basicPay.toString();
      _militaryDaPercentController.text = (currentDaPercent * 100).toString();
    });
  }

  void _calculate() {
    if (!_formKey.currentState!.validate()) return;
    final input = FinancialPlanInput(
      drawsPension: _drawsPension,
      monthlyPension: _drawsPension ? _parse(_pensionController.text) : 0,
      oneTimeGratuityAndDsop: _parse(_gratuityDsopController.text),
      annualFixedPay: _parse(_fixedPayController.text),
      annualVariablePay: _parse(_variablePayController.text),
      variableAchievementPercent: _parse(_variableAchievementController.text, fallback: 80),
      employerPfGratuityAnnual: _parse(_employerPfGratuityController.text),
      corporateMedicalValue: _parse(_corporateMedicalController.text),
      corporateHousingEducationSupport: _parse(_corporateHousingEducationController.text),
      joiningBonusOneTime: _parse(_joiningBonusController.text),
      annualEquityValue: _parse(_equityValueController.text),
      monthlyRentDelta: _parse(_rentDeltaController.text),
      monthlyHealthcareDelta: _parse(_healthcareDeltaController.text),
      monthlySchoolFeeDelta: _parse(_schoolFeeDeltaController.text),
      monthlyTransportDelta: _parse(_transportDeltaController.text),
      desiredRiskPremiumPercent: _parse(_riskPremiumController.text, fallback: 10),
      service: _service,
      rank: _rank,
      yearsOfService: _parse(_yearsOfServiceController.text),
      militaryBasicPay: _parse(_militaryBasicPayController.text),
      militaryDaPercent: _parse(_militaryDaPercentController.text, fallback: currentDaPercent * 100) / 100,
      otherAnnualCashAllowances: _parse(_otherCashAllowancesController.text),
      inGovtAccommodation: _inGovtAccommodation,
      comparableMonthlyMarketRent: _parse(_marketRentController.text),
      actualMonthlyAccommodationCost: _parse(_actualAccommodationCostController.text),
      dependentChildren: _parse(_dependentChildrenController.text).toInt(),
      annualSchoolCostPerChildComparable: _parse(_schoolCostComparableController.text),
      actualAnnualSchoolCostPaid: _parse(_schoolCostActualController.text),
      echsSpouseCovered: _echsSpouseCovered,
      echsChildrenCovered: _echsChildrenCovered,
      privateMedicalBenchmarkAnnual: _parse(_medicalBenchmarkController.text),
      oneTimeEchsSubscription: _parse(_echsSubscriptionController.text),
      annualCsdSavings: _parse(_csdSavingsController.text),
    );
    setState(() => _result = calculateFinancialPlan(input));
    context.read<ProfileRepository>().saveFinancialPlanInput(input);
  }

  num _parse(String text, {num fallback = 0}) =>
      text.trim().isEmpty ? fallback : (num.tryParse(text.trim()) ?? fallback);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Financial & Cost-of-Living Calculator'),
        actions: const [HomeButton()],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Every number here is one you enter or edit — nothing is looked up automatically '
                'except a starting example built on real 7th CPC pay-matrix data, which you should '
                'replace with your own payslip figures. Tax is estimated under the New Tax Regime '
                '(FY 2025-26 slabs) for planning purposes only, not tax advice.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 20),
              _buildExamplePicker(context),
              const SizedBox(height: 24),
              _sectionHeader(context, 'Your military pay'),
              _buildServiceRankRow(context),
              const SizedBox(height: 16),
              TextFormField(
                key: const Key('yearsOfServiceField'),
                controller: _yearsOfServiceController,
                keyboardType: const TextInputType.numberWithOptions(),
                decoration: const InputDecoration(labelText: 'Years of service'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                key: const Key('militaryBasicPayField'),
                controller: _militaryBasicPayController,
                keyboardType: const TextInputType.numberWithOptions(),
                decoration: const InputDecoration(labelText: 'Basic pay (₹/month)'),
              ),
              if (_rank != null) ...[
                const SizedBox(height: 8),
                Text(
                  _rank!.drawsMsp
                      ? 'Military Service Pay of ₹${_fmt(militaryServicePay)}/month is added automatically.'
                      : 'No separate MSP at this rank (apex-scale appointment).',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
              const SizedBox(height: 16),
              TextFormField(
                key: const Key('militaryDaPercentField'),
                controller: _militaryDaPercentController,
                keyboardType: const TextInputType.numberWithOptions(),
                decoration: const InputDecoration(
                  labelText: 'DA rate (%) — check your latest payslip',
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                key: const Key('otherCashAllowancesField'),
                controller: _otherCashAllowancesController,
                keyboardType: const TextInputType.numberWithOptions(),
                decoration: const InputDecoration(
                  labelText: 'Other annual cash allowances — field/hardship/kit/ration-in-lieu (₹)',
                ),
              ),
              const SizedBox(height: 24),
              _sectionHeader(context, 'Accommodation'),
              SwitchListTile(
                key: const Key('inGovtAccommodationSwitch'),
                contentPadding: EdgeInsets.zero,
                value: _inGovtAccommodation,
                onChanged: (v) => setState(() => _inGovtAccommodation = v),
                title: const Text('Currently in government accommodation'),
              ),
              if (_inGovtAccommodation) ...[
                const SizedBox(height: 8),
                TextFormField(
                  key: const Key('marketRentField'),
                  controller: _marketRentController,
                  keyboardType: const TextInputType.numberWithOptions(),
                  decoration: const InputDecoration(labelText: 'Comparable market rent (₹/month)'),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  key: const Key('actualAccommodationCostField'),
                  controller: _actualAccommodationCostController,
                  keyboardType: const TextInputType.numberWithOptions(),
                  decoration: const InputDecoration(labelText: 'What you actually pay (₹/month)'),
                ),
              ] else
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    "If you're drawing HRA instead, include it under other cash allowances above.",
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              const SizedBox(height: 24),
              _sectionHeader(context, 'Family & education'),
              TextFormField(
                key: const Key('dependentChildrenField'),
                controller: _dependentChildrenController,
                keyboardType: const TextInputType.numberWithOptions(),
                decoration: const InputDecoration(labelText: 'Dependent children'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                key: const Key('schoolCostComparableField'),
                controller: _schoolCostComparableController,
                keyboardType: const TextInputType.numberWithOptions(),
                decoration: const InputDecoration(
                  labelText: 'Comparable private school cost, per child (₹/year)',
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                key: const Key('schoolCostActualField'),
                controller: _schoolCostActualController,
                keyboardType: const TextInputType.numberWithOptions(),
                decoration: const InputDecoration(
                  labelText: 'What you actually pay today, total (₹/year)',
                ),
              ),
              const SizedBox(height: 24),
              _sectionHeader(context, 'Medical (ECHS)'),
              Text(
                'ECHS is not lost when you leave service. Pensioners keep full-family ECHS '
                'automatically; SSCOs/ECOs can join after release too — officer + spouse only by '
                'default, via a one-time subscription (amount varies — verify the current figure '
                'with ECHS).',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                key: const Key('echsSpouseSwitch'),
                contentPadding: EdgeInsets.zero,
                value: _echsSpouseCovered,
                onChanged: (v) => setState(() => _echsSpouseCovered = v),
                title: const Text('Spouse covered under ECHS'),
              ),
              SwitchListTile(
                key: const Key('echsChildrenSwitch'),
                contentPadding: EdgeInsets.zero,
                value: _echsChildrenCovered,
                onChanged: (v) => setState(() => _echsChildrenCovered = v),
                title: const Text('Children/other dependants covered under ECHS'),
                subtitle: const Text(
                  'SSCOs: ECHS by default covers officer + spouse only — verify before assuming this.',
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                key: const Key('medicalBenchmarkField'),
                controller: _medicalBenchmarkController,
                keyboardType: const TextInputType.numberWithOptions(),
                decoration: const InputDecoration(
                  labelText: 'Equivalent private family health cover, benchmarked (₹/year)',
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                key: const Key('echsSubscriptionField'),
                controller: _echsSubscriptionController,
                keyboardType: const TextInputType.numberWithOptions(),
                decoration: const InputDecoration(
                  labelText: 'One-time ECHS subscription, if applicable (₹)',
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'Only for SSCOs/ECOs joining after release — pensioners get ECHS automatically, '
                  'no subscription. Shown separately below, not annualised.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              const SizedBox(height: 24),
              _sectionHeader(context, 'CSD & other savings'),
              Text(
                'Also not lost on leaving service — any ex-serviceman with 5+ years of physical '
                'service keeps CSD canteen access.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 8),
              TextFormField(
                key: const Key('csdSavingsField'),
                controller: _csdSavingsController,
                keyboardType: const TextInputType.numberWithOptions(),
                decoration: const InputDecoration(
                  labelText: 'CSD/other subsidy savings actually used (₹/year)',
                ),
              ),
              const SizedBox(height: 24),
              _sectionHeader(context, 'Pension & retirement'),
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
              const SizedBox(height: 16),
              TextFormField(
                key: const Key('gratuityDsopField'),
                controller: _gratuityDsopController,
                keyboardType: const TextInputType.numberWithOptions(),
                decoration: const InputDecoration(
                  labelText: 'Retirement gratuity + DSOP/AFPPF corpus — one-time (₹)',
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'Shown separately below — never added to your current-year economic value.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              const SizedBox(height: 24),
              _sectionHeader(context, 'Corporate offer'),
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
                  labelText: 'Annual variable pay target — bonus/ESOPs, optional (₹)',
                ),
                validator: (v) => _validateNonNegative(v, required: false),
              ),
              const SizedBox(height: 16),
              TextFormField(
                key: const Key('variableAchievementField'),
                controller: _variableAchievementController,
                keyboardType: const TextInputType.numberWithOptions(),
                decoration: const InputDecoration(
                  labelText: 'Expected achievement of that target (%)',
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                key: const Key('employerPfGratuityField'),
                controller: _employerPfGratuityController,
                keyboardType: const TextInputType.numberWithOptions(),
                decoration: const InputDecoration(
                  labelText: 'Employer PF + gratuity contribution, optional (₹/year)',
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                key: const Key('corporateMedicalField'),
                controller: _corporateMedicalController,
                keyboardType: const TextInputType.numberWithOptions(),
                decoration: const InputDecoration(
                  labelText: 'Employer medical/insurance value, optional (₹/year)',
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                key: const Key('corporateHousingEducationField'),
                controller: _corporateHousingEducationController,
                keyboardType: const TextInputType.numberWithOptions(),
                decoration: const InputDecoration(
                  labelText: 'Housing/education support from employer, optional (₹/year)',
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                key: const Key('joiningBonusField'),
                controller: _joiningBonusController,
                keyboardType: const TextInputType.numberWithOptions(),
                decoration: const InputDecoration(
                  labelText: 'Joining/signing bonus, optional — one-time (₹)',
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                key: const Key('equityValueField'),
                controller: _equityValueController,
                keyboardType: const TextInputType.numberWithOptions(),
                decoration: const InputDecoration(
                  labelText: 'ESOP/RSU headline value, optional — annual (₹)',
                  helperText: 'Shown separately, never as guaranteed cash — value conservatively, '
                      'especially if unlisted or unvested.',
                  helperMaxLines: 2,
                ),
              ),
              const SizedBox(height: 24),
              _sectionHeader(context, 'Cost-of-living change'),
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
                  labelText: 'Extra monthly healthcare cost beyond continuing ECHS (₹)',
                  helperText: 'ECHS itself usually continues — only cost the gap: e.g. children not '
                      'covered as an SSCO, or care you want outside the ECHS network.',
                  helperMaxLines: 3,
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
              const SizedBox(height: 16),
              TextFormField(
                key: const Key('transportDeltaField'),
                controller: _transportDeltaController,
                keyboardType: const TextInputType.numberWithOptions(signed: true),
                decoration: const InputDecoration(
                  labelText: 'Extra monthly transport cost — car EMI, fuel, parking, driver (₹)',
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                key: const Key('riskPremiumField'),
                controller: _riskPremiumController,
                keyboardType: const TextInputType.numberWithOptions(),
                decoration: const InputDecoration(
                  labelText: 'Your own risk/transition margin above break-even (%)',
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

  Widget _sectionHeader(BuildContext context, String title) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(title, style: Theme.of(context).textTheme.titleMedium),
      );

  Widget _buildExamplePicker(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('See an illustrative example', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 4),
            Text(
              'Loads real 7th CPC pay-matrix basic pay for a rank and tenure — everything else '
              'stays editable, and this is a starting point, not a forecast of your own pay.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<IllustrativeMilitaryProfile>(
              key: const Key('examplePickerDropdown'),
              initialValue: _selectedExample,
              decoration: const InputDecoration(labelText: 'Rank & years of service'),
              isExpanded: true,
              items: illustrativeMilitaryProfiles
                  .where((p) => _service == null || p.service == _service)
                  .map(
                    (p) => DropdownMenuItem(
                      value: p,
                      child: Text('${p.label} (${p.note})', overflow: TextOverflow.ellipsis),
                    ),
                  )
                  .toList(),
              onChanged: (p) {
                if (p != null) _loadExample(p);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceRankRow(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: DropdownButtonFormField<OfficerService>(
            key: const Key('serviceDropdown'),
            initialValue: _service,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Service'),
            items: OfficerService.values
                .map((s) => DropdownMenuItem(
                    value: s, child: Text(s.label, overflow: TextOverflow.ellipsis)))
                .toList(),
            onChanged: (v) => setState(() => _service = v),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: DropdownButtonFormField<DefenceRank>(
            key: const Key('rankDropdown'),
            initialValue: _rank,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Rank'),
            items: DefenceRank.values
                .map(
                  (r) => DropdownMenuItem(
                    value: r,
                    child: Text(
                      _service != null ? r.labelFor(_service!) : r.armyLabel,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                )
                .toList(),
            onChanged: (v) => setState(() => _rank = v),
          ),
        ),
      ],
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
                Text('Your military compensation', style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 8),
                _AmountRow('Cash compensation (basic + MSP + DA + allowances)',
                    result.militaryCashCompensation),
                _AmountRow('+ current benefits (housing, education, medical, CSD)',
                    result.militaryCurrentEconomicCompensation - result.militaryCashCompensation),
                const Divider(),
                _AmountRow(
                  'Current economic value — a separate comparison, below',
                  result.militaryCurrentEconomicCompensation,
                  emphasize: true,
                ),
                Text(
                  "This is what your current pay plus benefits would cost to replace — it's shown "
                  'for comparison only. Your break-even figure below is based on your cash pay, not '
                  "this number, since the transition cost below already accounts for what it'll "
                  'actually cost you to replace these benefits — adding both would count the same '
                  'thing twice.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 8),
                _AmountRow('Pension (deferred, shown separately)', result.militaryDeferredAnnualEquivalent),
              ],
            ),
          ),
        ),
        if (result.oneTimeGratuityAndDsop != 0 ||
            result.oneTimeJoiningBonus != 0 ||
            result.oneTimeEchsSubscription != 0) ...[
          const SizedBox(height: 16),
          Card(
            key: const Key('oneTimeAmountsCard'),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('One-time amounts (not annualised)',
                      style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 8),
                  if (result.oneTimeGratuityAndDsop != 0)
                    _AmountRow('Retirement gratuity + DSOP/AFPPF', result.oneTimeGratuityAndDsop),
                  if (result.oneTimeJoiningBonus != 0)
                    _AmountRow('Corporate joining bonus', result.oneTimeJoiningBonus),
                  if (result.oneTimeEchsSubscription != 0)
                    _AmountRow('ECHS subscription (cost)', -result.oneTimeEchsSubscription),
                ],
              ),
            ),
          ),
        ],
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('The corporate offer', style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 8),
                _AmountRow('Headline CTC (fixed + target variable + equity)', result.headlineCtc),
                _AmountRow('Guaranteed compensation', result.corporateGuaranteedCompensation),
                _AmountRow('Risk-adjusted (incl. weighted variable)',
                    result.corporateRiskAdjustedCompensation),
                if (result.annualEquityValue != 0)
                  _AmountRow(
                    'Equity — headline value, not guaranteed cash',
                    result.annualEquityValue,
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
                Text('Does this offer clear the bar?', style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 8),
                Text(
                  'What you need = what you already earn in cash, plus what the move will '
                  'genuinely cost you extra — not your full current economic value plus that cost, '
                  'which would double-count your benefits.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 8),
                _AmountRow('Your cash pay today', result.militaryCashCompensation),
                _AmountRow('+ extra it will cost you after transition',
                    result.transitionCostAdjustmentAnnual),
                const Divider(),
                _AmountRow('= Floor — minimum acceptable (break-even)',
                    result.breakEvenCorporateCompensation),
                _AmountRow(
                  '+ your risk margin = Target — recommended',
                  result.recommendedTargetCompensation,
                  emphasize: true,
                ),
                _StretchRow(target: result.recommendedTargetCompensation),
                const Divider(),
                _AmountRow('Economic gap (offer vs. break-even)', result.economicGap, emphasize: true),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: ExpansionTile(
            key: const Key('fullCalculationTile'),
            title: Text('See the full calculation', style: Theme.of(context).textTheme.titleSmall),
            childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            expandedCrossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _AmountRow('O-01 · Military cash compensation', result.militaryCashCompensation),
              _AmountRow(
                'O-02 · Military current economic value',
                result.militaryCurrentEconomicCompensation,
              ),
              _AmountRow('O-03 · Deferred/retirement value (pension)',
                  result.militaryDeferredAnnualEquivalent),
              _AmountRow('O-04 · Corporate guaranteed compensation',
                  result.corporateGuaranteedCompensation),
              _AmountRow('O-05 · Corporate risk-adjusted compensation',
                  result.corporateRiskAdjustedCompensation),
              _AmountRow('O-06 · Transition cost adjustment', result.transitionCostAdjustmentAnnual),
              _AmountRow('O-07 · Corporate break-even (O-01 + O-06, not O-02 + O-06 — see note above)',
                  result.breakEvenCorporateCompensation),
              _AmountRow(
                'O-08 · Recommended target (O-07 × your risk margin)',
                result.recommendedTargetCompensation,
              ),
              _AmountRow('O-09 · Economic gap (O-05 − O-07)', result.economicGap),
            ],
          ),
        ),
        const SizedBox(height: 16),
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

  String _fmt(num value) => value.round().toString().replaceAllMapped(
        RegExp(r'\B(?=(\d{3})+(?!\d))'),
        (match) => ',',
      );
}

/// "Stretch" only ever shows a number when it can be grounded in the real
/// market-data range Compensation Guidance already fetched (JSearch's
/// estimated-salary API, cached in ProfileRepository.lastCompensationEstimate)
/// — never an invented multiplier on top of Target. With no cached market
/// data this explains why, rather than fabricating a plausible-looking figure.
class _StretchRow extends StatelessWidget {
  const _StretchRow({required this.target});

  final num target;

  @override
  Widget build(BuildContext context) {
    final marketMax = context.watch<ProfileRepository>().lastCompensationEstimate?.maxSalary;
    if (marketMax == null || marketMax <= 0) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Text(
          'Stretch — not shown yet. Run JD Match against a real job description, then check '
          'Compensation Guidance, so this can be capped at a real market figure instead of a '
          'guessed one.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic),
        ),
      );
    }
    final uncappedStretch = target * 1.15;
    final stretch = uncappedStretch < marketMax ? uncappedStretch : marketMax;
    return _AmountRow('Stretch — negotiation ceiling (capped at real market data)', stretch);
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
