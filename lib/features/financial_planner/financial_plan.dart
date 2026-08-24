/// Everything here is arithmetic on numbers the officer types in themselves
/// — no AI call, no invented city cost data. Income tax uses the published
/// New Tax Regime slabs (FY 2025-26 / AY 2026-27, post Budget 2025): a real,
/// citable rule set, not a guess — but still general-purpose, not a
/// substitute for a tax advisor, since it ignores HRA/80C-style exemptions
/// that don't apply under the new regime anyway plus any state-specific
/// professional tax.
class FinancialPlanInput {
  const FinancialPlanInput({
    required this.drawsPension,
    this.monthlyPension = 0,
    required this.annualFixedPay,
    this.annualVariablePay = 0,
    this.monthlyRentDelta = 0,
    this.monthlyHealthcareDelta = 0,
    this.monthlySchoolFeeDelta = 0,
  });

  final bool drawsPension;
  final num monthlyPension;
  final num annualFixedPay;
  final num annualVariablePay;

  /// Extra monthly cost vs. what the officer pays today (in service) —
  /// each can be negative if the officer expects to pay less.
  final num monthlyRentDelta;
  final num monthlyHealthcareDelta;
  final num monthlySchoolFeeDelta;

  Map<String, dynamic> toJson() => {
        'drawsPension': drawsPension,
        'monthlyPension': monthlyPension,
        'annualFixedPay': annualFixedPay,
        'annualVariablePay': annualVariablePay,
        'monthlyRentDelta': monthlyRentDelta,
        'monthlyHealthcareDelta': monthlyHealthcareDelta,
        'monthlySchoolFeeDelta': monthlySchoolFeeDelta,
      };

  factory FinancialPlanInput.fromJson(Map<String, dynamic> json) => FinancialPlanInput(
        drawsPension: json['drawsPension'] as bool,
        monthlyPension: json['monthlyPension'] as num,
        annualFixedPay: json['annualFixedPay'] as num,
        annualVariablePay: json['annualVariablePay'] as num,
        monthlyRentDelta: json['monthlyRentDelta'] as num,
        monthlyHealthcareDelta: json['monthlyHealthcareDelta'] as num,
        monthlySchoolFeeDelta: json['monthlySchoolFeeDelta'] as num,
      );
}

class FinancialPlanResult {
  const FinancialPlanResult({
    required this.annualTaxGuaranteed,
    required this.annualTaxWithVariable,
    required this.netMonthlyGuaranteed,
    required this.netMonthlyWithVariable,
    required this.monthlyCostOfLivingDelta,
    required this.effectiveMonthlyGuaranteed,
    required this.effectiveMonthlyWithVariable,
    required this.negotiationGuidance,
  });

  final num annualTaxGuaranteed;
  final num annualTaxWithVariable;

  /// Post-tax monthly income from pension (if any) + fixed civilian pay only.
  final num netMonthlyGuaranteed;

  /// Post-tax monthly income if the full variable/bonus is realized too.
  final num netMonthlyWithVariable;

  final num monthlyCostOfLivingDelta;

  /// [netMonthlyGuaranteed] minus [monthlyCostOfLivingDelta] — the number
  /// that actually answers "is this offer a raise."
  final num effectiveMonthlyGuaranteed;
  final num effectiveMonthlyWithVariable;

  final String negotiationGuidance;
}

const _slabBoundaries = [400000, 800000, 1200000, 1600000, 2000000, 2400000];
const _slabRates = [0.0, 0.05, 0.10, 0.15, 0.20, 0.25, 0.30];
const _standardDeduction = 75000;
const _rebateThreshold = 1200000;
const _cessRate = 0.04;

num _slabTax(num taxableIncome) {
  if (taxableIncome <= 0) return 0;
  num tax = 0;
  num lower = 0;
  for (var i = 0; i < _slabBoundaries.length; i++) {
    final upper = _slabBoundaries[i];
    if (taxableIncome <= lower) break;
    final amountInSlab = (taxableIncome < upper ? taxableIncome : upper) - lower;
    tax += amountInSlab * _slabRates[i];
    lower = upper;
  }
  if (taxableIncome > lower) {
    tax += (taxableIncome - lower) * _slabRates.last;
  }
  return tax;
}

/// New Tax Regime, FY 2025-26: ₹75,000 standard deduction, then slab tax,
/// then the Section 87A rebate (with marginal relief) that keeps taxable
/// income up to ₹12L effectively tax-free, then 4% health & education cess.
num incomeTaxNewRegime(num grossSalaryIncome) {
  final taxable = grossSalaryIncome - _standardDeduction;
  if (taxable <= 0) return 0;
  var tax = _slabTax(taxable);
  if (taxable <= _rebateThreshold) {
    tax = 0;
  } else {
    final marginalCap = taxable - _rebateThreshold;
    if (tax > marginalCap) tax = marginalCap;
  }
  return tax + tax * _cessRate;
}

FinancialPlanResult calculateFinancialPlan(FinancialPlanInput input) {
  final annualPension = input.drawsPension ? input.monthlyPension * 12 : 0;
  final grossGuaranteed = annualPension + input.annualFixedPay;
  final grossWithVariable = grossGuaranteed + input.annualVariablePay;

  final taxGuaranteed = incomeTaxNewRegime(grossGuaranteed);
  final taxWithVariable = incomeTaxNewRegime(grossWithVariable);

  final netMonthlyGuaranteed = (grossGuaranteed - taxGuaranteed) / 12;
  final netMonthlyWithVariable = (grossWithVariable - taxWithVariable) / 12;

  final monthlyCostOfLivingDelta =
      input.monthlyRentDelta + input.monthlyHealthcareDelta + input.monthlySchoolFeeDelta;

  return FinancialPlanResult(
    annualTaxGuaranteed: taxGuaranteed,
    annualTaxWithVariable: taxWithVariable,
    netMonthlyGuaranteed: netMonthlyGuaranteed,
    netMonthlyWithVariable: netMonthlyWithVariable,
    monthlyCostOfLivingDelta: monthlyCostOfLivingDelta,
    effectiveMonthlyGuaranteed: netMonthlyGuaranteed - monthlyCostOfLivingDelta,
    effectiveMonthlyWithVariable: netMonthlyWithVariable - monthlyCostOfLivingDelta,
    negotiationGuidance: _negotiationGuidance(input, netMonthlyGuaranteed, monthlyCostOfLivingDelta),
  );
}

String _negotiationGuidance(
  FinancialPlanInput input,
  num netMonthlyGuaranteed,
  num monthlyCostOfLivingDelta,
) {
  final buffer = StringBuffer();
  if (input.drawsPension && input.monthlyPension > 0) {
    buffer.write(
      'Your pension gives you a guaranteed income floor of ₹${_fmt(input.monthlyPension)}/month '
      "regardless of this offer. That's real negotiating leverage — you can afford to prioritise "
      'role fit, learning, or a stronger fixed component over chasing the highest headline CTC, '
      'since bonus and variable pay here are upside, not your safety net.',
    );
  } else {
    buffer.write(
      'You have no pension cushion once you leave service — prioritise negotiating the fixed, '
      'guaranteed component of any offer over bonus, ESOPs, or other variable pay, and keep '
      '6–12 months of expenses in reserve before accepting a variable-heavy package.',
    );
  }
  if (netMonthlyGuaranteed > 0 && monthlyCostOfLivingDelta > 0) {
    final pct = (monthlyCostOfLivingDelta / netMonthlyGuaranteed * 100).round();
    if (pct >= 15) {
      buffer.write(
        '\n\nYour estimated cost-of-living changes come to ₹${_fmt(monthlyCostOfLivingDelta)}/month '
        '— about $pct% of your guaranteed net income. A higher headline salary in a costlier city '
        'is not automatically a raise; confirm this offer clears that bar before comparing it to '
        'your service income.',
      );
    }
  }
  return buffer.toString();
}

String _fmt(num amount) => amount.round().toString().replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (match) => ',',
    );
