import '../../core/models/officer_profile.dart';
import 'military_pay_data.dart';

/// Everything here is arithmetic on numbers the officer types in themselves
/// (or loads from an illustrative example built on real, sourced 7th CPC
/// pay-matrix data and then edits) — no AI call, no invented benefit
/// valuations. Income tax uses the published New Tax Regime slabs (FY
/// 2025-26 / AY 2026-27, post Budget 2025): a real, citable rule set, not
/// a guess — but still general-purpose, not a substitute for a tax
/// advisor, since it ignores HRA/80C-style exemptions that don't apply
/// under the new regime anyway plus any state-specific professional tax.
///
/// Deliberately no rank-to-pay lookup table is baked into the calculation
/// logic below — that lives only in [military_pay_data.dart], used to
/// pre-fill a starting figure the officer then edits. When the 8th Pay
/// Commission's matrix, MSP and allowance rules are notified, only that
/// one file (plus the tax-slab constants here, if they've also changed)
/// needs a refresh — this calculation engine doesn't change.
class FinancialPlanInput {
  const FinancialPlanInput({
    required this.drawsPension,
    this.monthlyPension = 0,
    this.oneTimeGratuityAndDsop = 0,
    required this.annualFixedPay,
    this.annualVariablePay = 0,
    this.variableAchievementPercent = 80,
    this.employerPfGratuityAnnual = 0,
    this.corporateMedicalValue = 0,
    this.corporateHousingEducationSupport = 0,
    this.joiningBonusOneTime = 0,
    this.monthlyRentDelta = 0,
    this.monthlyHealthcareDelta = 0,
    this.monthlySchoolFeeDelta = 0,
    this.desiredRiskPremiumPercent = 10,
    this.service,
    this.rank,
    this.yearsOfService = 0,
    this.militaryBasicPay = 0,
    this.militaryDaPercent = currentDaPercent,
    this.otherAnnualCashAllowances = 0,
    this.inGovtAccommodation = false,
    this.comparableMonthlyMarketRent = 0,
    this.actualMonthlyAccommodationCost = 0,
    this.dependentChildren = 0,
    this.annualSchoolCostPerChildComparable = 0,
    this.actualAnnualSchoolCostPaid = 0,
    this.echsSpouseCovered = true,
    this.echsChildrenCovered = true,
    this.privateMedicalBenchmarkAnnual = 0,
    this.annualCsdSavings = 0,
  });

  final bool drawsPension;
  final num monthlyPension;

  /// Retirement gratuity + DSOP/AFPPF corpus, a one-time sum — shown
  /// separately from current economic compensation, never added into it
  /// (per the guardrail against inflating current CTC with retirement
  /// value).
  final num oneTimeGratuityAndDsop;

  final num annualFixedPay;
  final num annualVariablePay;

  /// % of the variable target the officer realistically expects to
  /// achieve — variable pay is not guaranteed, so it's risk-weighted
  /// rather than counted at face value.
  final num variableAchievementPercent;

  final num employerPfGratuityAnnual;
  final num corporateMedicalValue;
  final num corporateHousingEducationSupport;

  /// One-time signing bonus — shown separately, not annualised into
  /// guaranteed/risk-adjusted compensation.
  final num joiningBonusOneTime;

  /// Extra monthly cost vs. what the officer pays today (in service) —
  /// each can be negative if the officer expects to pay less.
  final num monthlyRentDelta;
  final num monthlyHealthcareDelta;
  final num monthlySchoolFeeDelta;

  /// The officer's own margin, above pure break-even, for the uncertainty
  /// of a new role vs. guaranteed service tenure — a personal judgement
  /// call, not a computed fact, so it's an explicit input rather than a
  /// baked-in multiplier.
  final num desiredRiskPremiumPercent;

  // --- Military side ---
  final OfficerService? service;
  final DefenceRank? rank;
  final num yearsOfService;

  /// Basic pay (₹/month) — pre-filled from the real pay matrix by an
  /// illustrative example, but always officer-editable to their actual
  /// payslip figure.
  final num militaryBasicPay;

  /// DA rate applied to (basic pay + MSP). Defaults to the current
  /// published rate but must stay editable — DA revises roughly every six
  /// months.
  final num militaryDaPercent;

  /// Field/hardship/kit/ration-in-lieu and any other cash allowances
  /// actually drawn — varies too much by posting/arm to estimate
  /// generically, so purely officer-entered.
  final num otherAnnualCashAllowances;

  final bool inGovtAccommodation;
  final num comparableMonthlyMarketRent;
  final num actualMonthlyAccommodationCost;

  final int dependentChildren;
  final num annualSchoolCostPerChildComparable;
  final num actualAnnualSchoolCostPaid;

  final bool echsSpouseCovered;

  /// SSCOs' ECHS coverage is narrower than the general rule — it does not
  /// extend to children/other dependants by default.
  final bool echsChildrenCovered;

  final num privateMedicalBenchmarkAnnual;
  final num annualCsdSavings;

  num get militaryMsp => rank?.drawsMsp == true ? militaryServicePay : 0;

  Map<String, dynamic> toJson() => {
        'drawsPension': drawsPension,
        'monthlyPension': monthlyPension,
        'oneTimeGratuityAndDsop': oneTimeGratuityAndDsop,
        'annualFixedPay': annualFixedPay,
        'annualVariablePay': annualVariablePay,
        'variableAchievementPercent': variableAchievementPercent,
        'employerPfGratuityAnnual': employerPfGratuityAnnual,
        'corporateMedicalValue': corporateMedicalValue,
        'corporateHousingEducationSupport': corporateHousingEducationSupport,
        'joiningBonusOneTime': joiningBonusOneTime,
        'monthlyRentDelta': monthlyRentDelta,
        'monthlyHealthcareDelta': monthlyHealthcareDelta,
        'monthlySchoolFeeDelta': monthlySchoolFeeDelta,
        'desiredRiskPremiumPercent': desiredRiskPremiumPercent,
        'service': service?.name,
        'rank': rank?.name,
        'yearsOfService': yearsOfService,
        'militaryBasicPay': militaryBasicPay,
        'militaryDaPercent': militaryDaPercent,
        'otherAnnualCashAllowances': otherAnnualCashAllowances,
        'inGovtAccommodation': inGovtAccommodation,
        'comparableMonthlyMarketRent': comparableMonthlyMarketRent,
        'actualMonthlyAccommodationCost': actualMonthlyAccommodationCost,
        'dependentChildren': dependentChildren,
        'annualSchoolCostPerChildComparable': annualSchoolCostPerChildComparable,
        'actualAnnualSchoolCostPaid': actualAnnualSchoolCostPaid,
        'echsSpouseCovered': echsSpouseCovered,
        'echsChildrenCovered': echsChildrenCovered,
        'privateMedicalBenchmarkAnnual': privateMedicalBenchmarkAnnual,
        'annualCsdSavings': annualCsdSavings,
      };

  factory FinancialPlanInput.fromJson(Map<String, dynamic> json) => FinancialPlanInput(
        drawsPension: json['drawsPension'] as bool,
        monthlyPension: json['monthlyPension'] as num,
        oneTimeGratuityAndDsop: json['oneTimeGratuityAndDsop'] as num? ?? 0,
        annualFixedPay: json['annualFixedPay'] as num,
        annualVariablePay: json['annualVariablePay'] as num,
        variableAchievementPercent: json['variableAchievementPercent'] as num? ?? 80,
        employerPfGratuityAnnual: json['employerPfGratuityAnnual'] as num? ?? 0,
        corporateMedicalValue: json['corporateMedicalValue'] as num? ?? 0,
        corporateHousingEducationSupport: json['corporateHousingEducationSupport'] as num? ?? 0,
        joiningBonusOneTime: json['joiningBonusOneTime'] as num? ?? 0,
        monthlyRentDelta: json['monthlyRentDelta'] as num,
        monthlyHealthcareDelta: json['monthlyHealthcareDelta'] as num,
        monthlySchoolFeeDelta: json['monthlySchoolFeeDelta'] as num,
        desiredRiskPremiumPercent: json['desiredRiskPremiumPercent'] as num? ?? 10,
        service: (json['service'] as String?) != null
            ? OfficerService.values.byName(json['service'] as String)
            : null,
        rank: (json['rank'] as String?) != null ? DefenceRank.values.byName(json['rank'] as String) : null,
        yearsOfService: json['yearsOfService'] as num? ?? 0,
        militaryBasicPay: json['militaryBasicPay'] as num? ?? 0,
        militaryDaPercent: json['militaryDaPercent'] as num? ?? currentDaPercent,
        otherAnnualCashAllowances: json['otherAnnualCashAllowances'] as num? ?? 0,
        inGovtAccommodation: json['inGovtAccommodation'] as bool? ?? false,
        comparableMonthlyMarketRent: json['comparableMonthlyMarketRent'] as num? ?? 0,
        actualMonthlyAccommodationCost: json['actualMonthlyAccommodationCost'] as num? ?? 0,
        dependentChildren: json['dependentChildren'] as int? ?? 0,
        annualSchoolCostPerChildComparable: json['annualSchoolCostPerChildComparable'] as num? ?? 0,
        actualAnnualSchoolCostPaid: json['actualAnnualSchoolCostPaid'] as num? ?? 0,
        echsSpouseCovered: json['echsSpouseCovered'] as bool? ?? true,
        echsChildrenCovered: json['echsChildrenCovered'] as bool? ?? true,
        privateMedicalBenchmarkAnnual: json['privateMedicalBenchmarkAnnual'] as num? ?? 0,
        annualCsdSavings: json['annualCsdSavings'] as num? ?? 0,
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
    required this.militaryCashCompensation,
    required this.militaryCurrentEconomicCompensation,
    required this.militaryDeferredAnnualEquivalent,
    required this.corporateGuaranteedCompensation,
    required this.corporateRiskAdjustedCompensation,
    required this.transitionCostAdjustmentAnnual,
    required this.breakEvenCorporateCompensation,
    required this.recommendedTargetCompensation,
    required this.economicGap,
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

  /// O-01: Basic + MSP + DA + eligible cash allowances, ₹/year.
  final num militaryCashCompensation;

  /// O-02: Cash + monetised current benefits (housing, education, medical,
  /// CSD), ₹/year. Does not include pension or gratuity.
  final num militaryCurrentEconomicCompensation;

  /// O-03: Pension annualised, shown separately — never folded into
  /// current economic compensation. The one-time gratuity/DSOP corpus is
  /// available on the input but intentionally not annualised here.
  final num militaryDeferredAnnualEquivalent;

  /// O-04: Guaranteed corporate cash + benefits, excluding variable pay.
  final num corporateGuaranteedCompensation;

  /// O-05: Guaranteed + achievement-weighted variable pay.
  final num corporateRiskAdjustedCompensation;

  /// O-06: Incremental annual post-service cost-of-living change.
  final num transitionCostAdjustmentAnnual;

  /// O-07: Corporate value required to match current military economic
  /// value after absorbing transition costs.
  final num breakEvenCorporateCompensation;

  /// O-08: Break-even + the officer's own stated risk/transition premium.
  final num recommendedTargetCompensation;

  /// O-09: Risk-adjusted corporate value minus military economic value
  /// minus transition costs. Positive = offer clears break-even.
  final num economicGap;
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

  // --- Military side (Output Specification O-01 to O-03) ---
  final monthlyCashBasicMsp = input.militaryBasicPay + input.militaryMsp;
  final annualDa = monthlyCashBasicMsp * 12 * input.militaryDaPercent;
  final militaryCashCompensation = monthlyCashBasicMsp * 12 + annualDa + input.otherAnnualCashAllowances;

  final housingBenefit = input.inGovtAccommodation
      ? _nonNegative(input.comparableMonthlyMarketRent - input.actualMonthlyAccommodationCost) * 12
      : 0;
  final educationBenefit = _nonNegative(
    input.annualSchoolCostPerChildComparable * input.dependentChildren -
        input.actualAnnualSchoolCostPaid,
  );
  final militaryCurrentEconomicCompensation = militaryCashCompensation +
      housingBenefit +
      educationBenefit +
      input.privateMedicalBenchmarkAnnual +
      input.annualCsdSavings;

  final militaryDeferredAnnualEquivalent = annualPension;

  // --- Corporate side (O-04, O-05) ---
  final corporateGuaranteedCompensation = input.annualFixedPay +
      input.employerPfGratuityAnnual +
      input.corporateMedicalValue +
      input.corporateHousingEducationSupport;
  final corporateRiskAdjustedCompensation = corporateGuaranteedCompensation +
      input.annualVariablePay * (input.variableAchievementPercent / 100);

  // --- Comparison (O-06 to O-09) ---
  final transitionCostAdjustmentAnnual = monthlyCostOfLivingDelta * 12;
  final breakEvenCorporateCompensation =
      militaryCurrentEconomicCompensation + transitionCostAdjustmentAnnual;
  final recommendedTargetCompensation =
      breakEvenCorporateCompensation * (1 + input.desiredRiskPremiumPercent / 100);
  final economicGap = corporateRiskAdjustedCompensation -
      militaryCurrentEconomicCompensation -
      transitionCostAdjustmentAnnual;

  return FinancialPlanResult(
    annualTaxGuaranteed: taxGuaranteed,
    annualTaxWithVariable: taxWithVariable,
    netMonthlyGuaranteed: netMonthlyGuaranteed,
    netMonthlyWithVariable: netMonthlyWithVariable,
    monthlyCostOfLivingDelta: monthlyCostOfLivingDelta,
    effectiveMonthlyGuaranteed: netMonthlyGuaranteed - monthlyCostOfLivingDelta,
    effectiveMonthlyWithVariable: netMonthlyWithVariable - monthlyCostOfLivingDelta,
    negotiationGuidance: _negotiationGuidance(input, netMonthlyGuaranteed, monthlyCostOfLivingDelta),
    militaryCashCompensation: militaryCashCompensation,
    militaryCurrentEconomicCompensation: militaryCurrentEconomicCompensation,
    militaryDeferredAnnualEquivalent: militaryDeferredAnnualEquivalent,
    corporateGuaranteedCompensation: corporateGuaranteedCompensation,
    corporateRiskAdjustedCompensation: corporateRiskAdjustedCompensation,
    transitionCostAdjustmentAnnual: transitionCostAdjustmentAnnual,
    breakEvenCorporateCompensation: breakEvenCorporateCompensation,
    recommendedTargetCompensation: recommendedTargetCompensation,
    economicGap: economicGap,
  );
}

num _nonNegative(num value) => value < 0 ? 0 : value;

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
