import '../../core/models/guide_section.dart';

/// Reviewed source material: Next_Career_After_Fauj_Corporate_Culture_
/// Work_Environment_Guide.docx (sections 1-18, transcribed verbatim into
/// structured data below) plus two sections authored for this app closing
/// gaps identified against an external review (see this session's plan) —
/// "The Support Ecosystem You're Used To Won't Travel With You" and
/// "Individual Contributor Before Manager", written in the same voice and
/// Situation/Response/Avoid format as the reviewed sections around them.
const List<GuideSection> kCorporateCultureSections = [
  GuideSection(
    title: 'The First Mental Shift',
    referenceTable: GuideReferenceTable(
      columnHeaders: ['Military environment', 'Typical corporate environment', 'What to adapt'],
      rows: [
        [
          'Rank and appointment are visible sources of authority',
          'Role, expertise and organisational position are the visible sources of authority',
          'Use competence, clarity and influence rather than rank',
        ],
        ['Formal hierarchy', 'Often flatter or matrix-based', 'Build relationships across functions'],
        ['Orders and execution', 'Discussion, alignment, ownership and negotiation', 'Persuade and align'],
        ['Mission completion', 'Business outcomes, KPIs and value creation', 'Show measurable impact'],
        [
          'Strong institutional identity',
          'Professional and organisational identity',
          'Build a new professional brand',
        ],
        [
          'Long service and continuity',
          'Greater movement between roles/companies',
          'Think in terms of skills and market value',
        ],
      ],
    ),
    closingNote: 'You are not starting your professional life again. You are entering a different operating '
        'system. Retain the strengths that made you successful in uniform; adapt the behaviours that the new '
        'environment interprets differently.',
  ),
  GuideSection(
    title: 'Your Rank Usually Does Not Travel With You',
    paragraphs: [
      'In many corporate organisations, your military rank will be respected as part of your background, '
          'but it will not determine how colleagues address you or how decisions are made.',
    ],
    scenarios: [
      GuideScenario(
        heading: 'When a Younger Colleague Calls You by Your First Name',
        situation: 'A 28-year-old colleague says, "Hi Sandeep, can we look at this together?" You are '
            'accustomed to formal forms of address.',
        recommendedResponse: 'Treat the first-name usage as a workplace norm unless the organisation clearly '
            'signals otherwise. Focus on the content and relationship, not the form of address.',
        avoid: 'Correcting the colleague or interpreting the interaction as disrespect on the basis of '
            'first-name usage alone.',
      ),
      GuideScenario(
        heading: 'When a Junior in Age Is Senior in the Corporate Structure',
        situation: 'Your reporting manager is considerably younger than you and has fewer years of total '
            'work experience.',
        recommendedResponse: 'Respect the organisational role while bringing your experience constructively. '
            'Your value comes from judgement, capability and results, not age or former rank.',
        avoid: 'Comparing service seniority or using age as a basis for authority.',
      ),
    ],
  ),
  GuideSection(
    title: 'Hierarchy, Matrix Structures & Dotted Lines',
    paragraphs: [
      'You may find that the person whose cooperation you need does not report to you. A project may '
          'involve several functions, each with a different manager, budget and priority.',
    ],
    checklistItems: [
      'Learn the formal reporting structure quickly.',
      'Map key stakeholders: decision-maker, influencers, subject-matter experts and people who execute '
          'the decision.',
      'Use influence and negotiation where you previously used command authority.',
      'Confirm decision rights before assuming ownership.',
      'Build relationships before you need them.',
    ],
  ),
  GuideSection(
    title: 'From Command to Influence',
    translations: [
      GuideTranslation(
        from: 'Get this done by 1700 hrs.',
        to: 'We need this completed by 5 PM. What do you need from me to make that happen?',
      ),
      GuideTranslation(
        from: 'This is the correct approach.',
        to: 'My recommendation is X because of A and B. What concerns do you see?',
      ),
      GuideTranslation(
        from: 'Why was this not done?',
        to: 'What prevented completion, and what is the recovery plan?',
      ),
      GuideTranslation(
        from: 'I need this immediately.',
        to: 'This is the priority for today. Please confirm timing and dependencies.',
      ),
      GuideTranslation(from: 'I have already told you.', to: 'Let\'s make sure there is no ambiguity about the requirement.'),
    ],
  ),
  GuideSection(
    title: 'Decision-Making in the Corporate World',
    paragraphs: ['Expect more emphasis on:'],
    checklistItems: [
      'Decision rights and approval levels',
      'Business cases and financial implications',
      'Stakeholder alignment',
      'Risk / reward trade-offs',
      'Data and evidence',
      'Record of decisions and actions',
    ],
    closingNote: 'A good corporate leader may spend more time creating alignment before a decision than an '
        'officer is accustomed to spending before issuing an instruction. That is often a feature of the '
        'environment, not indecision.',
  ),
  GuideSection(
    title: 'Meetings: Briefing vs Discussion vs Decision',
    referenceTable: GuideReferenceTable(
      columnHeaders: ['Meeting type', 'Your role', 'Common mistake'],
      rows: [
        [
          'Information / briefing',
          'Be concise and highlight what matters',
          'Giving the full background when the audience needs the decision',
        ],
        [
          'Problem-solving',
          'Contribute analysis, ask questions, build options',
          'Treating the meeting as a one-way brief',
        ],
        [
          'Decision',
          'Present recommendation, evidence, risks and decision required',
          'Giving a long presentation without making the ask explicit',
        ],
        [
          'Project review',
          'Report status, variance, risks, dependencies and actions',
          'Reporting activity without business impact',
        ],
      ],
    ),
    scenarios: [
      GuideScenario(
        heading: 'A Junior Challenges Your View in a Meeting',
        situation: 'A younger employee disagrees publicly with one of your recommendations.',
        recommendedResponse: 'Acknowledge the challenge, test the evidence and separate the idea from the '
            'person. Example: "Good point. Walk me through the data behind that view."',
        avoid: 'Using your former rank, age or service experience to shut down the discussion.',
      ),
    ],
  ),
  GuideSection(
    title: 'Communication Norms',
    referenceTable: GuideReferenceTable(
      columnHeaders: ['Channel', 'Typical use', 'Practical rule'],
      rows: [
        ['Email', 'Formal record, decisions, external communication', 'Keep it concise; make the action/decision clear'],
        [
          'Teams / Slack',
          'Fast coordination, questions, working-level updates',
          'Do not write a paragraph when one sentence will do',
        ],
        ['Phone', 'Urgent or nuanced matters', 'Use when text would create unnecessary delay or ambiguity'],
        ['Video meeting', 'Discussion, review, decision', 'Join prepared; check mic/camera'],
        ['Presentation', 'Executive communication', 'Lead with the conclusion, not the chronology'],
      ],
    ),
  ),
  GuideSection(
    title: 'Corporate Time, Calendar & Priorities',
    paragraphs: [
      'A corporate calendar can contain multiple competing priorities. Being busy is not necessarily '
          'evidence of performance.',
    ],
    checklistItems: [
      'Clarify the expected outcome and deadline.',
      'Identify what is genuinely urgent versus merely visible.',
      'Ask which priority should take precedence when requests conflict.',
      'Protect time for focused work; not every request deserves an immediate response.',
      'Learn your organisation\'s response-time norms rather than assuming military urgency applies everywhere.',
    ],
  ),
  GuideSection(
    title: 'Performance Culture: Activity vs Outcome',
    paragraphs: [
      'Corporate performance is usually discussed in terms of outcomes: revenue, cost, productivity, '
          'service level, customer experience, quality, risk, delivery and other KPIs.',
    ],
    referenceTable: GuideReferenceTable(
      columnHeaders: ['Activity statement', 'Stronger outcome statement'],
      rows: [
        [
          '"Conducted 12 inspections."',
          '"Conducted a risk-based inspection programme that reduced repeat non-compliance by 18%."',
        ],
        [
          '"Managed a team of 120."',
          '"Led 120 personnel across three locations and improved service-level adherence to 96%."',
        ],
        [
          '"Prepared weekly reports."',
          '"Built weekly KPI reporting that improved management visibility and shortened issue-escalation time."',
        ],
      ],
    ),
  ),
  GuideSection(
    title: 'Feedback & Performance Conversations',
    checklistItems: [
      'Expect regular 1:1s rather than only formal annual reviews.',
      'Feedback may be direct, peer-to-peer or upward.',
      'Do not treat feedback from a junior colleague as a challenge to authority.',
      'Ask for specific examples and agree the behaviour or outcome to improve.',
      'Learn to give feedback about behaviour and impact rather than character.',
    ],
  ),
  GuideSection(
    title: 'Working With Younger / Gen Z Colleagues',
    paragraphs: [
      'You may notice different expectations about communication, hierarchy, feedback, flexibility and '
          'work-life boundaries. Avoid treating these differences as a decline in professionalism.',
    ],
    checklistItems: [
      'Use clarity rather than formality to establish expectations.',
      'Explain the \'why\' behind important tasks where appropriate.',
      'Give timely feedback rather than assuming people know where they stand.',
      'Do not confuse informality with lack of accountability.',
      'Judge performance by agreed outcomes and professional behaviour.',
    ],
  ),
  GuideSection(
    title: 'Office Politics & Informal Influence',
    paragraphs: [
      'Every sizeable organisation has formal and informal networks. The objective is not to "play '
          'politics"; it is to understand how stakeholders think, what they are accountable for and how '
          'decisions move.',
    ],
    checklistItems: [
      'Know who gains or loses from a proposal.',
      'Understand competing priorities before escalating.',
      'Build relationships across functions, not only upward.',
      'Avoid bypassing stakeholders unnecessarily.',
      'Protect your integrity; influence should never require misrepresentation.',
    ],
  ),
  GuideSection(
    title: 'Ownership, Escalation & Accountability',
    scenarios: [
      GuideScenario(
        heading: 'Your Team Is Late',
        situation: 'A deliverable is late and you have several people working on it.',
        recommendedResponse: 'Own the outcome: state the current position, cause, recovery plan, new timing '
            'and decision/support required.',
        avoid: '"My team is handling it" without providing status, risk or recovery.',
      ),
      GuideScenario(
        heading: 'You Disagree With the Decision',
        situation: 'Leadership chooses an option you believe is weaker.',
        recommendedResponse: 'State your concern professionally with evidence, document the risk if '
            'appropriate, then support the agreed decision unless it creates an ethical/legal issue.',
        avoid: 'Repeatedly reopening the decision because your preferred option was not selected.',
      ),
    ],
  ),
  GuideSection(
    title: 'Office Norms You May Find Different',
    checklistItems: [
      'Open-plan offices, hot-desking or shared workspaces may be normal.',
      'People may move between companies more frequently than you did during service.',
      'People may discuss compensation, careers and mobility differently from military norms.',
      'Work may be hybrid, with colleagues in different cities/time zones.',
      'Informal conversations at coffee/pantry areas can influence relationships and collaboration.',
      'A meeting invitation may be optional, informational or decision-oriented—read the agenda and context.',
    ],
  ),
  GuideSection(
    title: 'Dress & Professional Presentation',
    paragraphs: [
      'Corporate dress varies by industry and organisation. Do not assume the most formal option is always '
          'the most professional.',
    ],
    checklistItems: [
      'Observe the organisation before settling into a personal style.',
      'Match client meetings and senior-management settings appropriately.',
      'When uncertain in the first month, slightly more formal is safer than too casual.',
      'Personal grooming, punctuality and preparedness often signal professionalism more strongly than '
          'expensive clothing.',
    ],
  ),
  GuideSection(
    title: 'Confidentiality & Information Handling',
    paragraphs: [
      'Military habits around information security remain valuable—but corporate policies may define '
          'different classification and sharing rules.',
    ],
    checklistItems: [
      'Do not forward company documents to personal email without authorisation.',
      'Do not discuss sensitive matters in public areas or social media.',
      'Understand who is authorised to receive client, employee and company information.',
      'Use approved AI tools for company information.',
    ],
  ),
  GuideSection(
    title: 'The Support Ecosystem You\'re Used To Won\'t Travel With You',
    paragraphs: [
      'In service, a great deal of administrative and logistical support happened around you — often '
          'without you having to ask. In most corporate roles, especially in your first assignment, that '
          'support does not exist in the same form. This is one of the most immediate and personal '
          'adjustments of the transition, and it has nothing to do with your seniority or capability.',
    ],
    scenarios: [
      GuideScenario(
        heading: 'Booking Your Own Travel and Managing Your Own Calendar',
        situation: 'You need to travel for a client meeting next week and there is no one to arrange '
            'tickets, accommodation or transport on your behalf.',
        recommendedResponse: 'Learn the organisation\'s travel-booking tool and expense system in your first '
            'week, even if you never expect to need them urgently. Treat this as a basic professional skill, '
            'not a loss of status.',
        avoid: 'Waiting for someone to offer to help, or treating routine administrative tasks as beneath '
            'the role.',
      ),
      GuideScenario(
        heading: 'Building Your Own Presentation',
        situation: 'You are asked to present a proposal to leadership next week, and there is no dedicated '
            'staff to prepare the slides.',
        recommendedResponse: 'Build basic competence in your organisation\'s standard tools (PowerPoint, '
            'Excel, whatever the team actually uses) early, and budget real time for producing your own '
            'materials.',
        avoid: 'Assuming this work will be delegated, or under-estimating how long it takes until you have '
            'done it yourself a few times.',
      ),
    ],
    closingNote: 'This is not a comment on your seniority — even CXOs in most corporate organisations book '
        'their own travel and build their own decks. It reflects a genuinely different operating model, not '
        'a demotion.',
  ),
  GuideSection(
    title: 'Individual Contributor Before Manager',
    paragraphs: [
      'In service, appointment and seniority generally came with a defined span of command. In many '
          'corporate roles — including senior ones — you may be expected to execute personally for a period '
          'before, or even instead of, leading a team. This can feel unfamiliar if you are used to '
          'orchestrating through subordinates.',
    ],
    scenarios: [
      GuideScenario(
        heading: 'No Team to Delegate To Yet',
        situation: 'You join a role with a senior-sounding title, but discover you are expected to build '
            'your own tracker, write your own analysis and follow up on action items yourself.',
        recommendedResponse: 'Treat hands-on execution as a way to understand the work deeply before you '
            'lead others through it — this is often exactly how the organisation expects a new senior hire '
            'to earn credibility.',
        avoid: 'Interpreting the absence of a team as a sign you have been under-levelled, or pushing early '
            'for headcount before you have demonstrated impact.',
      ),
      GuideScenario(
        heading: 'Balancing "Doing" and "Leading"',
        situation: 'You do eventually get a small team, but are still expected to personally own certain '
            'deliverables rather than only directing others.',
        recommendedResponse: 'Expect the balance between individual contribution and management to shift '
            'gradually, not overnight, even in senior roles — ask your manager directly what proportion of '
            'your time should be hands-on versus managerial.',
        avoid: 'Assuming that having any direct reports means you should no longer do detailed work yourself.',
      ),
    ],
    closingNote: 'Being willing to do the work yourself, especially early on, is one of the fastest ways a '
        'former officer earns trust in a corporate team — it is rarely read as a step down.',
  ),
  GuideSection(
    title: 'First 90 Days — Cultural Adaptation Plan',
    referenceTable: GuideReferenceTable(
      columnHeaders: ['Period', 'Primary objective', 'What to do'],
      rows: [
        ['Days 1–30', 'Observe & understand', 'Learn the organisation, stakeholders, language, KPIs and unwritten norms'],
        ['Days 31–60', 'Contribute & build trust', 'Deliver visible early wins; build cross-functional relationships'],
        [
          'Days 61–90',
          'Influence & improve',
          'Propose improvements after understanding the current process and business context',
        ],
      ],
    ),
    paragraphs: ['Five rules for the first 90 days:'],
    checklistItems: [
      'Observe before judging.',
      'Understand before changing.',
      'Build relationships before needing influence.',
      'Ask questions without apologising for your lack of corporate familiarity.',
      'Retain your values and leadership strengths while adapting your operating style.',
    ],
  ),
  GuideSection(
    title: 'Quick Cultural-Shock Checklist',
    checklistItems: [
      'Someone may call you by your first name.',
      'A much younger colleague may know more about a particular subject than you do.',
      'A junior may disagree openly with you.',
      'Your former rank may not be used.',
      'You may have to persuade someone you do not command.',
      'A decision may require several approvals.',
      'A colleague may leave the organisation after one or two years.',
      'A presentation may need a business recommendation rather than a detailed chronology.',
      'Success may be judged by measurable outcomes, not effort alone.',
    ],
    closingNote: 'Your military experience remains valuable—but you must translate it into the '
        'organisation\'s language.',
  ),
];
