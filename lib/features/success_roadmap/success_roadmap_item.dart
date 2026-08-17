import '../ai_readiness/ai_readiness.dart' show RoadmapPhase;

export '../ai_readiness/ai_readiness.dart' show RoadmapPhase, RoadmapPhaseLabel;

/// A single action for succeeding after joining a new organisation.
/// Curated, universal professional-development guidance — not generated,
/// not personalised to any real company, so there's nothing to fabricate.
class SuccessRoadmapItem {
  const SuccessRoadmapItem({required this.phase, required this.title, required this.description});

  final RoadmapPhase phase;
  final String title;
  final String description;
}

const List<SuccessRoadmapItem> kNinetyDaySuccessPlan = [
  // First 30 days
  SuccessRoadmapItem(
    phase: RoadmapPhase.day30,
    title: 'Map your key stakeholders',
    description:
        'Identify who you need to work with, who influences decisions, and who you report to '
        'and who reports to you — not just on the org chart, but in practice.',
  ),
  SuccessRoadmapItem(
    phase: RoadmapPhase.day30,
    title: 'Understand how success is measured',
    description:
        'Learn the specific KPIs/OKRs your role and team are judged on. Ask directly — don\'t '
        'assume they match what mattered in your last role.',
  ),
  SuccessRoadmapItem(
    phase: RoadmapPhase.day30,
    title: 'Learn the unwritten rules',
    description:
        'Every organisation has an informal culture alongside the formal one — how decisions '
        'really get made, communication norms, meeting etiquette. Observe before you act.',
  ),
  SuccessRoadmapItem(
    phase: RoadmapPhase.day30,
    title: 'Resist the urge to change things immediately',
    description:
        'Command instincts push toward fast, decisive action. In a new organisation, spend the '
        'first month building credibility and understanding before proposing changes.',
  ),

  // Days 31-60
  SuccessRoadmapItem(
    phase: RoadmapPhase.day60,
    title: 'Identify one or two quick wins',
    description:
        'Find a small, visible problem you can genuinely fix well, ideally one your manager '
        'already cares about. Early credibility compounds.',
  ),
  SuccessRoadmapItem(
    phase: RoadmapPhase.day60,
    title: 'Build relationships beyond your immediate team',
    description:
        'Deliberately meet people in adjacent functions. Influence in a corporate structure '
        'often runs sideways, not just up and down the chain.',
  ),
  SuccessRoadmapItem(
    phase: RoadmapPhase.day60,
    title: 'Translate command habits into civilian workplace norms',
    description:
        'Directive instructions that worked in uniform can land as abrupt in a corporate '
        'setting. Practice framing requests collaboratively and explaining the "why."',
  ),
  SuccessRoadmapItem(
    phase: RoadmapPhase.day60,
    title: 'Seek structured feedback from your manager',
    description:
        'Don\'t wait for a formal review cycle. Ask directly what\'s working and what isn\'t — '
        'it signals self-awareness and gives you time to adjust.',
  ),

  // Days 61-90
  SuccessRoadmapItem(
    phase: RoadmapPhase.day90,
    title: 'Deliver one visible, measurable result',
    description:
        'By day 90, have something concrete to point to that ties back to the KPIs you '
        'identified in week one.',
  ),
  SuccessRoadmapItem(
    phase: RoadmapPhase.day90,
    title: 'Establish your leadership identity',
    description:
        'Decide deliberately how you want to be known in this organisation — as a builder, a '
        'fixer, a strategist — rather than letting early impressions form by accident.',
  ),
  SuccessRoadmapItem(
    phase: RoadmapPhase.day90,
    title: 'Propose one forward-looking initiative',
    description:
        'Having earned credibility through your first quarter, put forward one idea for '
        'improvement — framed as a proposal to discuss, not a directive.',
  ),
  SuccessRoadmapItem(
    phase: RoadmapPhase.day90,
    title: 'Set your next six-month goals with your manager',
    description:
        'Use the 90-day mark to align explicitly on what success looks like going forward, '
        'rather than assuming it carries over unchanged from your onboarding period.',
  ),
];
