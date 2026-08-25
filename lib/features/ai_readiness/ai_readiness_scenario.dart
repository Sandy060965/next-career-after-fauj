/// Four-tier AI readiness structure, replacing the earlier pure self-rating
/// design: Knowledge and Application test what the officer actually knows
/// and does; Judgment and Governance test whether they'd catch a wrong or
/// risky AI output rather than trusting it blindly. Governance is anchored
/// to the NIST AI Risk Management Framework (a real, public framework —
/// Govern/Map/Measure/Manage), not an invented standard.
enum AiReadinessTier { knowledge, application, judgment, governance }

extension AiReadinessTierLabel on AiReadinessTier {
  String get label => switch (this) {
        AiReadinessTier.knowledge => 'Knowledge',
        AiReadinessTier.application => 'Application',
        AiReadinessTier.judgment => 'Judgment',
        AiReadinessTier.governance => 'Governance',
      };

  String get description => switch (this) {
        AiReadinessTier.knowledge => 'Understanding core AI/LLM concepts and terminology.',
        AiReadinessTier.application => 'Using AI tools effectively for real work tasks.',
        AiReadinessTier.judgment =>
          'Critically evaluating AI output rather than trusting it by default.',
        AiReadinessTier.governance =>
            'Security, privacy, and responsible-AI practice — anchored to the NIST AI Risk '
            'Management Framework.',
      };
}

/// A scenario-based multiple-choice question, scored deterministically
/// against [correctIndex] — never graded by the LLM. [explanation] is shown
/// after answering regardless of whether the officer got it right.
class ScenarioQuestion {
  const ScenarioQuestion({
    required this.id,
    required this.tier,
    required this.prompt,
    required this.options,
    required this.correctIndex,
    required this.explanation,
  });

  final String id;
  final AiReadinessTier tier;
  final String prompt;
  final List<String> options;
  final int correctIndex;
  final String explanation;
}

const List<ScenarioQuestion> kAiReadinessQuestions = [
  // --- Knowledge ---
  ScenarioQuestion(
    id: 'k-hallucination',
    tier: AiReadinessTier.knowledge,
    prompt: "What is an AI 'hallucination'?",
    options: [
      "A hardware malfunction in the AI provider's servers",
      'When an AI model generates confident-sounding output that is factually incorrect or fabricated',
      'A visual glitch in an AI image generator',
      'When two AI models disagree with each other',
    ],
    correctIndex: 1,
    explanation:
        'Hallucination means the model states something false or invented with the same '
        'confidence as a true fact — a core limitation to design around, not an edge case.',
  ),
  ScenarioQuestion(
    id: 'k-llm',
    tier: AiReadinessTier.knowledge,
    prompt: "What best describes a 'large language model' (LLM) like the ones behind "
        'ChatGPT or Claude?',
    options: [
      'A search engine that only retrieves existing web pages',
      'A rule-based system programmed with explicit if-then logic',
      'A statistical model trained on large amounts of text to predict and generate language',
      'A database of pre-written answers to common questions',
    ],
    correctIndex: 2,
    explanation:
        "LLMs don't look answers up — they generate text by predicting likely continuations, "
        'learned from patterns in their training data.',
  ),
  ScenarioQuestion(
    id: 'k-agent',
    tier: AiReadinessTier.knowledge,
    prompt: "What is an 'AI agent', as distinct from a basic chatbot?",
    options: [
      'A chatbot with a friendlier tone',
      'A system that can autonomously take multi-step actions toward a goal — searching, '
          'using tools, executing tasks — not just answer one question',
      'A human customer-service representative',
      'An AI model that only works offline',
    ],
    correctIndex: 1,
    explanation:
        'Agents chain reasoning with real actions across multiple steps, which is what makes '
        'them more capable — and riskier if unsupervised — than a single-turn chatbot reply.',
  ),

  // --- Application ---
  ScenarioQuestion(
    id: 'a-contracts',
    tier: AiReadinessTier.application,
    prompt: 'You need to summarize 50 vendor contracts by Friday. What is the most '
        'effective way to use AI here?',
    options: [
      "Manually read and summarize each one — AI can't be trusted with legal documents",
      'Feed the contracts to an AI tool in batches with a consistent prompt format, then '
          'spot-check outputs against a sample of the originals',
      'Ask the AI to guess what typical vendor contracts usually contain, without reading '
          'the actual documents',
      'Have the AI rewrite all 50 contracts from scratch',
    ],
    correctIndex: 1,
    explanation:
        'A consistent prompt plus spot-checking gets you speed without blind trust — the '
        'sample check is what catches a systematic misread before it reaches your report.',
  ),
  ScenarioQuestion(
    id: 'a-memo',
    tier: AiReadinessTier.application,
    prompt: "You're drafting a strategy memo and want AI help. What gets the best result?",
    options: [
      'Type one vague sentence like "write a strategy memo" and use whatever comes out',
      'Give it your actual data, context, audience, and constraints, then iterate with '
          'follow-up prompts',
      'Ask it to write the memo without giving it any of your specific business context',
      'Avoid AI entirely for anything strategic',
    ],
    correctIndex: 1,
    explanation:
        'Output quality tracks input quality — real context plus iteration consistently '
        'beats a single vague prompt.',
  ),
  ScenarioQuestion(
    id: 'a-autocomplete',
    tier: AiReadinessTier.application,
    prompt: 'An AI tool offers to auto-complete your sentences while drafting a client '
        'email. When is this most useful?',
    options: [
      'Always accept every suggestion without reading it, to save time',
      'Never use it, since it might sound robotic',
      'Use it to speed up routine phrasing, but review and edit before sending — especially '
          'for anything sensitive or client-specific',
      'Only use it for emails to your own team, never external clients',
    ],
    correctIndex: 2,
    explanation:
        'Speed is the benefit; review before sending is the safeguard — dropping either one '
        'defeats the point.',
  ),

  // --- Judgment ---
  ScenarioQuestion(
    id: 'j-falseflag',
    tier: AiReadinessTier.judgment,
    prompt: 'An AI tool flags a vendor invoice as a duplicate-payment risk, but your own '
        "quick check shows it's a legitimate recurring charge. What's the right next step?",
    options: [
      "Trust the AI's flag automatically and block the payment, since AI is usually right",
      'Ignore all future flags from this tool, since it was wrong once',
      'Verify against the source data, override the flag with a documented reason, and note '
          'the false positive',
      'Escalate to IT to shut the AI tool down entirely',
    ],
    correctIndex: 2,
    explanation:
        'One false positive means "verify and document," not "always trust" or "never '
        'trust" — the goal is calibrated confidence, not either extreme.',
  ),
  ScenarioQuestion(
    id: 'j-numbers',
    tier: AiReadinessTier.judgment,
    prompt: 'An AI assistant gives a confident, detailed answer with specific numbers to a '
        'factual question. What should you do before using those numbers in a report?',
    options: [
      "Use them as-is — a confident tone means it's accurate",
      'Verify against a primary source before relying on them, especially for anything '
          "you'll be accountable for",
      'Ask a different AI tool the same question and use whichever answer sounds more '
          'confident',
      'Discard the answer entirely and never use AI for anything factual again',
    ],
    correctIndex: 1,
    explanation:
        'Confidence of tone carries no information about accuracy — verification against a '
        'real source is the only thing that does.',
  ),
  ScenarioQuestion(
    id: 'j-bias',
    tier: AiReadinessTier.judgment,
    prompt: 'An AI resume-screening tool consistently ranks candidates from a particular '
        'background lower, even when qualifications are comparable. What does this most '
        'likely indicate?',
    options: [
      'The tool is working correctly and those candidates are genuinely weaker',
      'The tool may have learned a biased pattern from its training data and needs review '
          'before being trusted for decisions',
      "This is normal and doesn't need investigation",
      'AI tools cannot have bias, only humans can',
    ],
    correctIndex: 1,
    explanation:
        'A consistent, unexplained skew is exactly the signature of a biased training '
        'pattern — it warrants review before the tool is trusted for real decisions.',
  ),

  // --- Governance (NIST AI RMF-anchored) ---
  ScenarioQuestion(
    id: 'g-nist-functions',
    tier: AiReadinessTier.governance,
    prompt: 'The NIST AI Risk Management Framework organizes AI risk management into four '
        'core functions. Which of these is one of them?',
    options: ['Govern', 'Monetize', 'Advertise', 'Franchise'],
    correctIndex: 0,
    explanation:
        "NIST AI RMF's four functions are Govern, Map, Measure, and Manage — Govern means "
        'establishing the culture and structure for managing AI risk across an organization.',
  ),
  ScenarioQuestion(
    id: 'g-data',
    tier: AiReadinessTier.governance,
    prompt: 'Before using an AI tool on sensitive company or client data, what is the most '
        'important governance question to ask first?',
    options: [
      'Does it have a nice user interface?',
      'Where does the data go, who can access it, and does this comply with the '
          "organization's data-handling policy?",
      'Is it free to use?',
      'Does it produce long answers?',
    ],
    correctIndex: 1,
    explanation:
        'Data handling is the actual risk surface — interface quality and cost are '
        'irrelevant to whether sensitive data is being exposed.',
  ),
  ScenarioQuestion(
    id: 'g-deployment',
    tier: AiReadinessTier.governance,
    prompt: 'Your organization is rolling out an AI tool for a business process. Per a '
        'risk-management mindset like NIST AI RMF, what should happen before wide '
        'deployment?',
    options: [
      'Deploy to everyone immediately — issues can be fixed after the fact',
      'Map out where the AI could fail or cause harm, measure that risk, and put '
          'safeguards in place before scaling up',
      'Skip evaluation, since the vendor already tested it',
      'Only test it on the least experienced staff, to see what happens',
    ],
    correctIndex: 1,
    explanation:
        'Map-then-Measure-then-Manage before scaling is the core NIST AI RMF sequence — '
        'skipping it means finding failure modes in production instead of before rollout.',
  ),
];
