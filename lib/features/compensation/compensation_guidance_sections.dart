import '../../core/models/guide_section.dart';

/// Reference content for the Compensation Guidance module — how to
/// deconstruct a corporate offer, what its components actually mean, and
/// how to compare it fairly against military compensation. Deliberately
/// has no rupee figures of its own beyond illustrative examples explicitly
/// labelled as such; every real number the officer needs comes from the
/// Financial & Cost-of-Living Calculator below, where they enter their own
/// figures. Reuses the same GuideSection shape as the Corporate Culture
/// and Business Etiquette guides.
const kCompensationGuidanceSections = [
  GuideSection(
    title: 'The Central Principle',
    paragraphs: [
      "A corporate CTC letter and your service pay slip aren't measuring the same thing. Do not "
          'compare your current pay slip with the corporate CTC headline — compare like with like.',
    ],
    referenceTable: GuideReferenceTable(
      columnHeaders: ["Don't compare", 'Compare instead'],
      rows: [
        ['Current salary vs CTC', 'Current effective economic value vs corporate effective economic value'],
        ['Maximum variable pay vs guaranteed pay', 'Guaranteed compensation vs realistic variable outcome'],
        [
          'Employer-provided benefit vs cash',
          "Cash value vs benefit value, and whether you'd actually use it",
        ],
        ['Salary increase % alone', 'Incremental income vs incremental cost of living'],
        ['Equity headline value vs salary', 'Guaranteed cash vs conditional/deferred/illiquid equity'],
      ],
    ),
    closingNote: 'A simple way to think about an offer: Headline CTC → decompose the package → '
        'separate guaranteed / conditional / deferred value → add transition costs → benchmark '
        'the role → negotiate → decide.',
  ),
  GuideSection(
    title: 'The Anatomy of a Corporate CTC',
    paragraphs: [
      "CTC means Cost to Company — the employer's annual cost of employing you. It is not "
          'necessarily the amount that reaches your bank account.',
    ],
    referenceTable: GuideReferenceTable(
      columnHeaders: ['Component', 'What it means', 'How to treat it'],
      rows: [
        ['Basic Pay', 'Core salary component', 'Cash salary; may form the basis for statutory calculations'],
        [
          'Fixed Pay',
          'Guaranteed annual compensation under the offer',
          'Primary figure for comparing recurring income',
        ],
        ['HRA', 'Housing-related salary component', 'Cash component; tax treatment depends on applicable rules'],
        [
          'Special / other allowances',
          'Employer-defined components',
          'Check whether fixed or conditional, and whether taxable',
        ],
        [
          'Conveyance / fuel / driver',
          'Transport-related payment or benefit',
          'Check whether cash or reimbursement, and any limits',
        ],
        [
          'Medical reimbursement',
          'Reimbursement or insurance benefit',
          'Not equivalent to cash unless actually received',
        ],
        [
          'Variable / performance pay',
          'Dependent on individual/company performance',
          'Do not treat the target value as guaranteed',
        ],
        [
          'Joining / retention bonus',
          'One-time or conditional payment',
          'Check clawback terms and the payment/vesting date',
        ],
        ['Employer PF contribution', 'Retirement savings contribution', 'Not immediate spendable cash'],
        [
          'Gratuity provision',
          'Employer liability under the Payment of Gratuity Act',
          "Deferred; needs 5 years' continuous service",
        ],
        [
          'ESOP / RSU / equity',
          'Equity-linked compensation',
          'Separate from guaranteed cash; assess vesting and liquidity',
        ],
        ['Insurance', 'Employer-paid medical/life/accident cover', 'Value as coverage, not as cash'],
      ],
    ),
  ),
  GuideSection(
    title: "Full Forms You're Likely to See",
    referenceTable: GuideReferenceTable(
      columnHeaders: ['Abbreviation', 'Full form'],
      rows: [
        ['CTC', 'Cost to Company'],
        ['HRA', 'House Rent Allowance'],
        ['PF', 'Provident Fund'],
        ['EPF', "Employees' Provident Fund"],
        ['EPS', "Employees' Pension Scheme"],
        ['EDLI', "Employees' Deposit Linked Insurance"],
        ['TDS', 'Tax Deducted at Source'],
        ['ESOP', 'Employee Stock Option Plan'],
        ['RSU', 'Restricted Stock Unit'],
        ['KPI', 'Key Performance Indicator'],
        ['KRA', 'Key Result Area'],
        ['P&L', 'Profit and Loss'],
        ['ROI', 'Return on Investment'],
        ['LTA / LTC', 'Leave Travel Allowance / Leave Travel Concession'],
      ],
    ),
  ),
  GuideSection(
    title: 'Basic Pay, Fixed Pay, Gross and Net Are Not the Same',
    paragraphs: [
      'Basic Pay is one salary component. Fixed Pay generally means compensation that is '
          'contractually fixed rather than performance-linked, but employers may define the term '
          'differently. Gross salary is the aggregate of salary components before employee '
          'deductions. Net (take-home) pay is what reaches the bank after applicable deductions. '
          'CTC can include employer contributions and benefits that never appear as spendable '
          'monthly cash.',
    ],
    closingNote: 'Ask the employer for a written breakup of fixed pay, variable pay, employer '
        'contributions, benefits and equity. Never infer the structure from the headline CTC number.',
  ),
  GuideSection(
    title: 'Guaranteed vs Conditional vs Deferred vs Equity',
    referenceTable: GuideReferenceTable(
      columnHeaders: ['Type', 'Examples', 'How to treat it'],
      rows: [
        ['Guaranteed / fixed', 'Basic + fixed allowances', 'Use as core compensation'],
        [
          'Conditional cash',
          'Performance bonus, sales incentive',
          'Use expected/realistic payout, not the maximum',
        ],
        ['One-time', 'Joining / retention bonus', 'Keep separate from recurring compensation'],
        ['Deferred', 'Employer PF, gratuity provision', 'Recognise as future value, not current cash'],
        ['Equity', 'ESOP, RSU', 'Value conservatively; check vesting and liquidity'],
        ['Reimbursement', 'Fuel, travel, medical claims', 'Value based on actual eligible use'],
        ['Insurance', 'Medical / life / accident cover', 'Value as protection, not salary'],
      ],
    ),
  ),
  GuideSection(
    title: 'Variable and Performance Pay',
    paragraphs: [
      'A corporate offer may show a target variable amount — the target is not necessarily '
          "guaranteed. Ask how it's calculated and what has historically been paid: the "
          'individual-performance component, the company/business-unit component, any '
          'discretionary portion, the minimum/maximum payout, year-one proration, eligibility '
          'date, and clawback or adjustment conditions.',
    ],
    closingNote: 'Example: a ₹30 lakh CTC could comprise ₹23 lakh fixed, ₹5 lakh target variable '
        "and ₹2 lakh employer benefits/deferred components. Don't treat the full ₹30 lakh as salary.",
  ),
  GuideSection(
    title: 'Joining and Retention Bonuses',
    checklistItems: [
      "Joining bonus — ask whether it's paid on joining or after probation.",
      'Retention bonus — confirm the service period required, and what happens if you leave early.',
      'Clawback — understand whether money must be repaid if you resign within a defined period.',
      'Notice period — understand whether the package assumes a particular joining date.',
    ],
  ),
  GuideSection(
    title: 'Equity — ESOPs and RSUs',
    checklistItems: [
      "Don't equate equity with salary.",
      'Ask whether the company is listed or unlisted.',
      'Understand the vesting schedule and any cliff period.',
      'For options: understand the exercise price and the window allowed to exercise.',
      'For RSUs: understand the vesting schedule and the tax/settlement treatment that applies.',
      'For unlisted shares/options: assess liquidity risk and the realistic probability of realisation.',
    ],
    closingNote: 'A ₹3 lakh equity headline value should not automatically be treated as ₹3 lakh '
        'of guaranteed annual income.',
  ),
  GuideSection(
    title: 'Allowances, Reimbursements and Perquisites',
    paragraphs: [
      'The Income Tax Department distinguishes allowances (fixed periodic amounts paid in '
          'addition to salary) from perquisites (benefits received because of employment or '
          'position) — tax treatment can vary by type and applicable rules.',
    ],
    referenceTable: GuideReferenceTable(
      columnHeaders: ['Component', 'Questions to ask'],
      rows: [
        ['HRA', "Is it part of fixed pay? What's the annual amount? What evidence does the tax treatment need?"],
        ['Car / transport', 'Company car, allowance, reimbursement or lease? Who pays maintenance?'],
        ['Fuel / driver', 'Fixed allowance or reimbursement against bills? Is there a cap?'],
        ['Medical', 'Insurance or reimbursement? Employee only or family? Parents? OPD? Deductibles?'],
        ['Telephone / internet', 'Fixed allowance or reimbursement? Is personal use included?'],
        ['LTA / LTC', 'Is it available, and what are the conditions?'],
        ['Meal / club / wellness', 'Optional benefit or part of CTC — and is it actually useful to you?'],
      ],
    ),
  ),
  GuideSection(
    title: 'Employer Provident Fund and Gratuity',
    paragraphs: [
      'Employer PF contributions can form part of CTC but are not monthly spendable cash — '
          "EPFO's contribution framework splits employer contributions between EPF/EPS/other "
          'components. Gratuity is a deferred benefit under the Payment of Gratuity Act, with '
          'eligibility and calculation rules set out there; the actual amount and treatment depend '
          'on your own circumstances.',
    ],
    closingNote: "Practical rule: keep employer PF and gratuity in a separate 'deferred value' "
        'bucket when comparing current spendable income.',
  ),
  GuideSection(
    title: "Medical Coverage — What the Headline Number Doesn't Tell You",
    referenceTable: GuideReferenceTable(
      columnHeaders: ['Ask', 'Why it matters'],
      rows: [
        ['Sum insured', 'The headline coverage amount can be misleading'],
        ['Family coverage', 'Employee-only vs. family floater'],
        ['Parents', 'Often a separate cost/benefit question'],
        ['Room-rent limits', 'Can affect your out-of-pocket cost'],
        ['Co-pay / deductible', 'Can materially change the actual cost'],
        ['Pre-existing conditions', 'Coverage conditions vary'],
        ['OPD', 'Outpatient treatment may be excluded or limited'],
        ['Hospital network', 'Cashless access depends on the network'],
        ['Top-up', 'May be needed for adequate family protection'],
      ],
    ),
  ),
  GuideSection(
    title: 'What Changes After You Leave Service',
    paragraphs: [
      "For many officers, the biggest financial change isn't the loss of a single allowance — "
          "it's the cumulative increase in personal expenditure after moving into civilian life, "
          'especially in a metro or another high-cost city.',
    ],
    referenceTable: GuideReferenceTable(
      columnHeaders: ['Cost area', 'What can increase'],
      rows: [
        ['Housing', 'Rent, deposit, brokerage, maintenance, utilities, parking'],
        ['Schooling', 'Fees, transport, books, admission-related costs'],
        ['Transport', 'Car, EMI/lease, fuel, parking, driver, public transport'],
        ['Medical', "Private insurance, top-up, OPD, parents' cover, deductibles"],
        ['Domestic support', 'House help, maintenance and other services'],
        ['Relocation', 'Moving, temporary accommodation, furnishing'],
        ['Lifestyle / cost of living', 'Groceries, commute, eating out, city-level costs'],
      ],
    ),
    closingNote: 'Enter your own actual current and expected costs in the Financial & '
        "Cost-of-Living Calculator below, rather than applying a generic 'metro penalty.'",
  ),
  GuideSection(
    title: "ECHS and CSD — Check Individually, Don't Assume",
    paragraphs: [
      "Don't automatically subtract ECHS (Ex-Servicemen Contributory Health Scheme) or CSD "
          '(Canteen Stores Department) access from your post-service economic value. For eligible '
          'retirees/ex-servicemen, access may continue subject to prevailing rules — but Short '
          'Service officers and others whose entitlement differs must check their own eligibility. '
          "Only assign a monetary value in the calculator after you've confirmed whether and how "
          'you can use the facility.',
    ],
  ),
  GuideSection(
    title: 'Pension and Gratuity: Current Cash vs Deferred Value',
    referenceTable: GuideReferenceTable(
      columnHeaders: ['Bucket', 'How to treat it'],
      rows: [
        ['Current salary / regular receipts', 'Current purchasing power'],
        ['Service pension', 'Recurring retirement income — model separately from salary'],
        ['Service gratuity / retirement benefits', 'Deferred/one-time value — model separately'],
        ['Corporate PF', 'Deferred retirement savings'],
        ['Corporate gratuity', 'Future employment benefit'],
      ],
    ),
    closingNote: "Never convert a future benefit into an artificial monthly 'salary equivalent' — "
        'show current cash, recurring future income and deferred value separately.',
  ),
  GuideSection(
    title: 'What to Expect From a Salary Increase',
    paragraphs: [
      'As a planning assumption (not a market guarantee), an indicative 10%–25% uplift over a '
          'genuinely comparable current compensation baseline is a reasonable transition-planning '
          'range. A corporate employer may not give the full hike seen in an experienced '
          'corporate-to-corporate move — they may discount for lack of direct industry experience '
          'or P&L responsibility, though you may command strong value from leadership, scale, '
          'resilience, governance and operational experience. The key negotiation objective is the '
          'quality of the overall package and role, not just the percentage hike.',
    ],
    closingNote: 'A 30% increase in headline CTC can be worth less than an 18% increase that is '
        'mostly fixed pay, if the larger offer leans heavily on variable pay, equity and a costlier '
        'city.',
  ),
  GuideSection(
    title: 'The Three Compensation Numbers Every Officer Should Know',
    paragraphs: [
      "A. Headline CTC — the employer's quoted annual Cost to Company.",
      'B. Guaranteed Compensation — the fixed/contractual compensation you can expect '
          "independent of variable performance, subject to the offer's terms.",
      'C. Effective Economic Value — your own estimate after separating guaranteed from '
          'conditional value, valuing benefits realistically, and deducting the incremental cost of '
          'transition.',
    ],
    closingNote: "This is exactly what 'The corporate offer' section below computes for you, once "
        'you enter your own real numbers — a framework for a decision, not a tax computation or '
        'market valuation on its own.',
  ),
  GuideSection(
    title: 'How to Read a Corporate Offer Letter',
    checklistItems: [
      'Identify the exact job title, location and joining date.',
      'Extract the full annual CTC and its detailed breakup.',
      'Mark every item as fixed, variable, one-time, deferred, equity, reimbursement or benefit.',
      'Calculate your guaranteed annual compensation.',
      'Estimate a realistic variable payout, not the maximum.',
      'Review equity separately for vesting, liquidity and risk.',
      'Estimate incremental housing, schooling, transport, medical and other transition costs.',
      'Benchmark the role and location against credible market data.',
      'Determine your minimum acceptable package.',
      'Negotiate the highest-priority items first.',
    ],
  ),
  GuideSection(
    title: 'Questions to Ask HR',
    checklistItems: [
      'Please provide the complete CTC breakup in writing.',
      'What exactly is included in fixed pay?',
      'What was the actual variable payout for this role in the last two or three years?',
      'How is the variable calculated?',
      "What's guaranteed in the first year?",
      'Is the joining bonus subject to a clawback?',
      "What employer benefits are included in CTC but aren't paid as cash?",
      'What medical cover is provided for me and my family? Are parents covered?',
      'Is there a company car, transport, fuel or driver support?',
      "What's the expected location and travel requirement?",
      'Is relocation support available?',
      'Are there equity/ESOP/RSU components, and what are the vesting conditions?',
      "What's the notice period, and what happens to variable pay and equity if I leave?",
    ],
  ),
  GuideSection(
    title: 'What to Negotiate, in Priority Order',
    referenceTable: GuideReferenceTable(
      columnHeaders: ['Priority', 'Item', 'Why'],
      rows: [
        ['1', 'Fixed compensation', 'Most predictable recurring value'],
        ['2', 'Role level / scope', 'Affects future marketability and career trajectory'],
        ['3', 'Variable-pay structure', 'Clarifies realistic earning potential'],
        ['4', 'Joining / relocation support', 'Offsets immediate transition costs'],
        ['5', 'Medical coverage', 'Protects against a major new expense'],
        ['6', 'Equity', 'Potential upside, but not a substitute for weak fixed pay'],
        ['7', 'Other benefits', 'Useful if they have real personal value'],
      ],
    ),
    closingNote: "Don't negotiate from the recruiter's opening CTC — negotiate from your role "
        'value, market evidence, and your own informed floor.',
  ),
  GuideSection(
    title: 'Where the Market Data Comes From',
    paragraphs: [
      'Market salary minimum/median/maximum shown elsewhere in this module comes only from a '
          'defined external market-data source — never an LLM-invented figure. If city-level data '
          "isn't available, the fallback location is clearly labelled rather than silently "
          'substituted. Any AI-generated negotiation guidance is grounded in the actual job '
          'description and your profile, and is never presented as an official salary benchmark or '
          'guarantee.',
    ],
  ),
  GuideSection(
    title: 'What to Never Do',
    checklistItems: [
      "Don't compare your current take-home salary directly with corporate CTC.",
      "Don't treat maximum variable pay as guaranteed income.",
      "Don't treat ESOPs/RSUs as equivalent to cash salary.",
      "Don't subtract ECHS or CSD automatically without checking your individual eligibility.",
      "Don't ignore metro-city housing and schooling costs.",
      "Don't assume a higher designation automatically means a higher-value role.",
      "Don't accept a salary comparison without checking location and role scope.",
      "Don't rely on an AI-generated salary figure without a market-data source behind it.",
      "Don't decide solely on the first-year package — consider role quality and future "
          'trajectory too.',
    ],
  ),
  GuideSection(
    title: 'Before You Decide — Final Checklist',
    checklistItems: [
      'I know my guaranteed corporate compensation.',
      'I know the realistic expected variable payout.',
      'I understand every major CTC component.',
      "I've separately evaluated equity/deferred compensation.",
      "I've estimated the increased cost of housing.",
      "I've estimated the increased cost of schooling.",
      "I've estimated transport and medical costs.",
      "I've checked my ECHS/CSD eligibility where relevant.",
      'I know the market range for the role and location.',
      'I know my personal minimum acceptable package.',
      'I know what I want to negotiate.',
      "I've considered the role's long-term career value, not just year-one cash.",
    ],
    closingNote: 'The first corporate offer is not simply a salary number — it is a package of '
        'guaranteed income, conditional income, future benefits, equity and new personal costs. A '
        'good decision is the one that gives you a fair economic outcome today, a role where your '
        'experience creates value, and a credible platform for what comes next.',
  ),
];
