// Static supporting content for the Corporate Language Guide — extracted
// directly from the source glossary document, not AI-generated, so none
// of it needs the fabrication review the per-term deep-dive content does.

class MindsetBridge {
  const MindsetBridge(this.military, this.corporate);
  final String military;
  final String corporate;
}

class ConfusedTermPair {
  const ConfusedTermPair(this.pair, this.distinction);
  final String pair;
  final String distinction;
}

class MeetingPhrase {
  const MeetingPhrase(this.heard, this.means);
  final String heard;
  final String means;
}

class RoleQuickReference {
  const RoleQuickReference(this.role, this.terms);
  final String role;
  final List<String> terms;
}

/// The 'Mission -> business objective' style vocabulary bridge from the
/// top of the source guide.
const List<MindsetBridge> kMindsetBridge = [
  MindsetBridge('Mission', 'business objective / strategic objective'),
  MindsetBridge('Task', 'deliverable / assignment'),
  MindsetBridge('Commander’s intent', 'strategic intent / desired business outcome'),
  MindsetBridge('Situation report', 'MIS / status report / dashboard'),
  MindsetBridge('After Action Review', 'retrospective / post-project review / post-mortem'),
  MindsetBridge('Chain of command', 'reporting hierarchy'),
  MindsetBridge('Formation / unit', 'business unit / function / operating organisation'),
  MindsetBridge('Quartermaster / logistics function', 'supply chain / procurement / logistics'),
  MindsetBridge('Inspection', 'audit / assessment / review'),
  MindsetBridge('Operational readiness', 'business readiness / service readiness'),
  MindsetBridge('Operational plan', 'business plan / operating plan / project plan'),
  MindsetBridge('Contingency plan', 'contingency plan / business continuity plan'),
  MindsetBridge('Training requirement', 'capability / competency / learning requirement'),
  MindsetBridge('Resource state', 'capacity / resource availability'),
  MindsetBridge('Escalation', 'management escalation / issue escalation'),
];

const List<ConfusedTermPair> kConfusedTermPairs = [
  ConfusedTermPair('KRA vs KPI vs OKR', 'KRA = area of responsibility; KPI = measurable performance indicator; OKR = goal-setting framework linking an objective to measurable key results.'),
  ConfusedTermPair('Revenue vs Profit vs Cash Flow', 'Revenue is what is earned from sales; profit is what remains after relevant costs/expenses; cash flow is actual movement of cash. A company can report profit while having cash-flow pressure.'),
  ConfusedTermPair('CAPEX vs OPEX', 'CAPEX generally creates/acquires long-term assets; OPEX generally covers recurring operating costs. Accounting treatment can be more nuanced.'),
  ConfusedTermPair('RFP vs RFQ vs RFI', 'RFI gathers information; RFP asks for a solution/proposal; RFQ primarily seeks pricing for a defined requirement.'),
  ConfusedTermPair('QA vs QC', 'QA focuses on processes and assurance; QC focuses on checking outputs against requirements.'),
  ConfusedTermPair('Risk vs Issue', 'A risk may happen; an issue has happened or is currently happening.'),
  ConfusedTermPair('Mitigation vs Contingency', 'Mitigation reduces likelihood/impact in advance; contingency is the prepared response if the event occurs.'),
  ConfusedTermPair('Project vs Program vs Portfolio', 'Project = defined temporary outcome; program = coordinated group of related projects; portfolio = collection managed for strategic investment/prioritisation.'),
  ConfusedTermPair('Agile vs Scrum', 'Agile is a broad philosophy/approach; Scrum is one specific Agile framework.'),
  ConfusedTermPair('POC vs MVP', 'POC tests feasibility; MVP tests a usable product concept with real users while minimising initial scope.'),
  ConfusedTermPair('EBITDA vs Cash Flow', 'EBITDA is a performance/profitability measure before specified charges; cash flow measures actual cash movement. They are not interchangeable.'),
  ConfusedTermPair('Customer vs Client', 'Often interchangeable, but \'client\' is common in professional services/B2B while \'customer\' is broader. Company usage varies.'),
  ConfusedTermPair('Vendor vs Supplier', 'Often interchangeable; supplier commonly implies provision of goods/materials, vendor can be broader. Company usage varies.'),
  ConfusedTermPair('Efficiency vs Effectiveness', 'Efficiency = using resources well; effectiveness = achieving the intended outcome. A process can be efficient but ineffective.'),
  ConfusedTermPair('Authority vs Accountability vs Responsibility', 'Authority = right to decide/direct; responsibility = obligation to perform; accountability = being answerable for the outcome.'),
  ConfusedTermPair('Forecast vs Budget', 'Budget is the approved plan/target; forecast is the current estimate of what is likely to happen.'),
  ConfusedTermPair('GMV vs Revenue', 'GMV is total transaction value through a marketplace; revenue is what the company actually recognises as its own revenue under applicable accounting rules.'),
  ConfusedTermPair('ARR vs Revenue', 'ARR is an annualised recurring-revenue measure used mainly in subscription businesses; revenue is accounting-recognised income for a reporting period.'),
];

const List<MeetingPhrase> kMeetingPhrases = [
  MeetingPhrase('“What’s the ETA?”', 'What is the expected completion/arrival time?'),
  MeetingPhrase('“Who owns this?”', 'Who is accountable for driving the action/outcome?'),
  MeetingPhrase('“Let’s take this offline.”', 'Let’s discuss this separately rather than spend meeting time on it.'),
  MeetingPhrase('“Can you share the deck?”', 'Please send the presentation/slides.'),
  MeetingPhrase('“What’s the business impact?”', 'How does this affect revenue, cost, customer, risk, timeline or another business outcome?'),
  MeetingPhrase('“What are the dependencies?”', 'What other activities/decisions/resources must happen first?'),
  MeetingPhrase('“Please close this by EOD.”', 'Complete the action by the end of the working day.'),
  MeetingPhrase('“We need stakeholder buy-in.”', 'Relevant decision-makers/affected parties need to support or accept the proposal.'),
  MeetingPhrase('“Let’s deep dive.”', 'Let’s examine the issue in greater detail.'),
  MeetingPhrase('“What’s the root cause?”', 'What underlying factor actually caused the problem?'),
  MeetingPhrase('“What’s the ROI?”', 'What benefit/return is expected relative to the investment?'),
  MeetingPhrase('“This is BAU.”', 'This is routine ongoing work, not a special change/project.'),
  MeetingPhrase('“This is a quick win.”', 'This can deliver visible benefit relatively quickly.'),
  MeetingPhrase('“We need alignment.”', 'We need a shared understanding/decision before proceeding.'),
  MeetingPhrase('“Let’s escalate.”', 'The matter needs a higher-level decision, intervention or visibility.'),
];

const List<RoleQuickReference> kRoleQuickReferences = [
  RoleQuickReference('Consulting / Strategy', ['Strategy', 'Business Plan', 'TAM', 'SAM', 'SOM', 'GTM', 'MECE', 'Hypothesis', 'Workstream', 'SteerCo', 'Benchmarking', 'ROI', 'EBITDA', 'RACI', 'RAID']),
  RoleQuickReference('Operations / Supply Chain', ['SCM', 'ERP', 'SKU', 'BOM', 'MRP', 'MOQ', 'EOQ', 'OTIF', 'OEE', 'RCA', 'CAPA', 'SOP', '3PL', '4PL', 'TAT', 'MTBF', 'MTTR']),
  RoleQuickReference('Project / Program Management', ['Project', 'Program', 'Portfolio', 'PMO', 'Scope', 'Deliverable', 'Milestone', 'Dependency', 'Critical Path', 'RAID', 'RACI', 'UAT', 'POC', 'MVP', 'Agile', 'Waterfall']),
  RoleQuickReference('Finance', ['P&L', 'Revenue', 'COGS', 'Gross Profit', 'EBITDA', 'EBIT', 'PAT', 'CAPEX', 'OPEX', 'Working Capital', 'Accounts Receivable (AR)', 'Accounts Payable (AP)', 'Cash Flow', 'NPV', 'IRR', 'WACC', 'DCF', 'ROE', 'ROCE']),
  RoleQuickReference('Sales / Business Development', ['CRM', 'Lead', 'Prospect', 'Opportunity', 'Pipeline', 'Funnel', 'Conversion Rate', 'KAM', 'Upsell', 'Cross-sell', 'Churn', 'CAC', 'LTV / CLV', 'NPS', 'GTM', 'B2B', 'B2C', 'D2C']),
  RoleQuickReference('HR / People', ['HRBP', 'HRMS', 'ATS', 'L&D', 'C&B', 'CTC', 'ESOP', 'KRA', 'KPI', 'OKR', 'Attrition', 'Retention', 'EVP', 'PIP', 'Succession Planning', 'Span of Control']),
  RoleQuickReference('Technology / Digital', ['IT', 'SaaS', 'PaaS', 'IaaS', 'API', 'ERP', 'BI', 'SQL', 'ETL', 'RPA', 'AI', 'ML', 'GenAI', 'DevOps', 'CI/CD', 'IAM', 'MFA', 'SOC', 'SIEM']),
  RoleQuickReference('Risk / Governance / Compliance', ['GRC', 'ERM', 'Risk', 'Issue', 'Mitigation', 'Contingency', 'BCP', 'BCM', 'DR', 'Compliance', 'Internal Audit', 'NDA', 'Due Diligence', 'ESG', 'CSR']),
  RoleQuickReference('Manufacturing / Engineering', ['EPC', 'O&M', 'BOM', 'OEE', 'QA', 'QC', 'RCA', 'CAPA', 'JIT', 'Lean', 'Six Sigma', 'Kaizen', 'FAT', 'SAT', 'HSE / EHS', 'MTBF', 'MTTR']),
  RoleQuickReference('Defence / Aerospace', ['OEM', 'MRO', 'COTS', 'ILS', 'TCO', 'FAT', 'SAT', 'EPC', 'O&M', 'BOM', 'FTE', 'SLA', 'RFP', 'RFQ', 'SOW']),
  RoleQuickReference('Banking / Financial Services', ['KYC', 'AML', 'CASA', 'NPA', 'AUM', 'NAV', 'NIM', 'CRR', 'SLR', 'IPO', 'PE', 'VC', 'ROE', 'ROCE', 'P&L']),
  RoleQuickReference('PSU / Government', ['PSU', 'CPSE', 'MCA', 'ROC', 'SEBI', 'RBI', 'IRDAI', 'GST', 'TDS', 'GeM', 'MSME', 'CSR', 'RFP', 'RFQ', 'LOA', 'BOQ']),
];
