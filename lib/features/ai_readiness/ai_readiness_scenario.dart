import 'dart:math';

/// Six practical AI-workplace competencies, replacing the earlier four-tier
/// structure. Chosen to mirror how AI actually shows up in a corporate role:
/// knowing the concepts, picking the right tool, getting useful output from
/// it, using it on real data/decisions, wiring it into a workflow, and
/// knowing when to distrust it.
///
/// MAINTENANCE: review this file at least once a quarter (every 3 months),
/// and no less than every 6 months — AI tooling and workplace practice move
/// fast enough that a question can go stale within a year. On each review:
/// re-read every question for continued accuracy, and add fresh questions
/// rather than only removing old ones, so the bank keeps growing. Every
/// question here is deliberately capability-based rather than naming a
/// specific product (ChatGPT, Claude, Gemini, ...), since a product's
/// specific capabilities change far faster than the underlying skill of
/// choosing the right tool for a task — this keeps the bank durable. If a
/// future revision adds product-specific questions, keep them in a clearly
/// separate, more frequently reviewed pool rather than mixing them in here.
/// Last reviewed: 5 September 2026.
enum AiReadinessTopic {
  fundamentals,
  toolSelection,
  prompting,
  researchAndDecisions,
  workflowsAndAgents,
  governance,
}

extension AiReadinessTopicLabel on AiReadinessTopic {
  String get label => switch (this) {
        AiReadinessTopic.fundamentals => 'AI Fundamentals & Concepts',
        AiReadinessTopic.toolSelection => 'AI Tools, Models & Tool Selection',
        AiReadinessTopic.prompting => 'Prompting & AI-Assisted Productivity',
        AiReadinessTopic.researchAndDecisions => 'AI for Research, Data & Decision-Making',
        AiReadinessTopic.workflowsAndAgents => 'AI Workflows, Automation & Agents',
        AiReadinessTopic.governance => 'AI Governance, Security & Critical Evaluation',
      };

  String get description => switch (this) {
        AiReadinessTopic.fundamentals =>
          'Understanding core AI/LLM concepts and terminology.',
        AiReadinessTopic.toolSelection =>
          'Matching AI capabilities to a task, rather than reaching for whatever is familiar.',
        AiReadinessTopic.prompting =>
          'Getting consistent, useful output from AI on real work tasks.',
        AiReadinessTopic.researchAndDecisions =>
          'Using AI on real data and research without being misled by it.',
        AiReadinessTopic.workflowsAndAgents =>
          'Designing AI into a repeatable process, with the right checks in place.',
        AiReadinessTopic.governance =>
          'Security, privacy, bias, and critically evaluating AI output rather than trusting '
              'it by default — anchored to the NIST AI Risk Management Framework.',
      };
}

enum QuestionType { multipleChoice, fillInBlank }

/// A single question, either multiple-choice (scored against [correctIndex])
/// or fill-in-the-blank (scored against [acceptedAnswers], case-insensitive
/// and whitespace-trimmed). Always scored deterministically — never graded
/// by the LLM. [explanation] is shown after the officer submits the full
/// assessment, regardless of whether they got it right, so a wrong answer
/// comes with the reasoning for the correct one.
class ScenarioQuestion {
  const ScenarioQuestion({
    required this.id,
    required this.topic,
    required this.type,
    required this.prompt,
    this.options = const [],
    this.correctIndex,
    this.acceptedAnswers = const [],
    required this.explanation,
  });

  final String id;
  final AiReadinessTopic topic;
  final QuestionType type;
  final String prompt;

  /// Populated only when [type] is [QuestionType.multipleChoice].
  final List<String> options;
  final int? correctIndex;

  /// Populated only when [type] is [QuestionType.fillInBlank] — every
  /// acceptable spelling/form of the answer, matched case-insensitively
  /// after trimming whitespace.
  final List<String> acceptedAnswers;

  final String explanation;

  bool isCorrect(dynamic answer) {
    if (type == QuestionType.multipleChoice) {
      return answer is int && answer == correctIndex;
    }
    if (answer is! String) return false;
    final normalized = answer.trim().toLowerCase();
    if (normalized.isEmpty) return false;
    return acceptedAnswers.any((a) => a.trim().toLowerCase() == normalized);
  }

  /// The correct option text (MCQ) or the primary accepted spelling
  /// (fill-in-blank) — for display on the post-assessment review screen.
  String get correctAnswerDisplay =>
      type == QuestionType.multipleChoice ? options[correctIndex!] : acceptedAnswers.first;
}

const _fundamentals = [
  ScenarioQuestion(
    id: 'fund-hallucination',
    topic: AiReadinessTopic.fundamentals,
    type: QuestionType.multipleChoice,
    prompt: "What is an AI 'hallucination'?",
    options: [
      "A hardware malfunction in the AI provider's servers",
      'When an AI model generates confident-sounding output that is factually incorrect or '
          'fabricated',
      'A visual glitch in an AI image generator',
      'When two AI models disagree with each other',
    ],
    correctIndex: 1,
    explanation:
        'Hallucination means the model states something false or invented with the same '
        'confidence as a true fact — a core limitation to design around, not an edge case.',
  ),
  ScenarioQuestion(
    id: 'fund-llm',
    topic: AiReadinessTopic.fundamentals,
    type: QuestionType.multipleChoice,
    prompt: "What best describes a 'large language model' (LLM)?",
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
    id: 'fund-agent',
    topic: AiReadinessTopic.fundamentals,
    type: QuestionType.multipleChoice,
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
  ScenarioQuestion(
    id: 'fund-context-window',
    topic: AiReadinessTopic.fundamentals,
    type: QuestionType.multipleChoice,
    prompt: 'Which characteristic most directly determines how much text an LLM can consider '
        'at once in a single interaction?',
    options: [
      'Number of parameters',
      'Training frequency',
      "The model's context window",
      'Output temperature',
    ],
    correctIndex: 2,
    explanation:
        "The context window is the amount of text (measured in tokens) a model can hold in "
        "view at once — parameter count is about the model's overall capacity, not this limit.",
  ),
  ScenarioQuestion(
    id: 'fund-rag',
    topic: AiReadinessTopic.fundamentals,
    type: QuestionType.multipleChoice,
    prompt: 'What does Retrieval-Augmented Generation (RAG) mean?',
    options: [
      'Compressing documents before training',
      "Increasing the model's parameter count",
      'Retraining the model from scratch on new data',
      'Retrieving relevant external information and supplying it to the model when generating '
          'a response',
    ],
    correctIndex: 3,
    explanation:
        'RAG lets a model answer using current or private information it was never trained '
        'on, without the cost and delay of retraining it.',
  ),
  ScenarioQuestion(
    id: 'fund-embeddings',
    topic: AiReadinessTopic.fundamentals,
    type: QuestionType.multipleChoice,
    prompt: 'What is the main purpose of embeddings in an AI system?',
    options: [
      'To represent information numerically so semantic relationships between pieces of '
          'content can be identified',
      'To generate images',
      "To increase the model's temperature",
      'To eliminate hallucinations entirely',
    ],
    correctIndex: 0,
    explanation:
        'Embeddings turn text (or other content) into numbers positioned so that similar '
        'meanings end up close together — the basis for semantic search and RAG.',
  ),
  ScenarioQuestion(
    id: 'fund-tokenisation',
    topic: AiReadinessTopic.fundamentals,
    type: QuestionType.multipleChoice,
    prompt: "What is 'tokenisation' in the context of how an LLM processes text?",
    options: [
      'Converting text into the smaller units (tokens) the model actually processes',
      'Encrypting a document for storage',
      'Searching a database for exact matches',
      'Fine-tuning a model on new examples',
    ],
    correctIndex: 0,
    explanation:
        'Models never read raw text directly — everything is first broken into tokens '
        '(roughly word-pieces), which is also why context windows are measured in tokens.',
  ),
  ScenarioQuestion(
    id: 'fund-knowledge-cutoff',
    topic: AiReadinessTopic.fundamentals,
    type: QuestionType.multipleChoice,
    prompt: "What does an AI model's 'knowledge cutoff' refer to?",
    options: [
      'The maximum number of simultaneous users',
      'The date the model stops functioning',
      "The date its software licence expires",
      "The point after which its training data may not include newer developments",
    ],
    correctIndex: 3,
    explanation:
        "A model can't know about anything that happened after its training data was "
        'collected — which is exactly the gap RAG or web-connected tools are built to close.',
  ),
  ScenarioQuestion(
    id: 'fund-fib-context',
    topic: AiReadinessTopic.fundamentals,
    type: QuestionType.fillInBlank,
    prompt: 'The maximum amount of text an AI model can consider in a single interaction is '
        'commonly called its ______ window.',
    acceptedAnswers: ['context'],
    explanation: "This is the model's context window — everything outside it simply isn't "
        'visible to the model when it generates a response.',
  ),
  ScenarioQuestion(
    id: 'fund-fib-hallucination',
    topic: AiReadinessTopic.fundamentals,
    type: QuestionType.fillInBlank,
    prompt: 'A confident but fabricated or factually unsupported AI-generated statement is '
        'called a ______.',
    acceptedAnswers: ['hallucination'],
    explanation: 'The term for this specific failure mode — plausible-sounding, unsupported '
        'output — is hallucination.',
  ),
  ScenarioQuestion(
    id: 'fund-fib-finetuning',
    topic: AiReadinessTopic.fundamentals,
    type: QuestionType.fillInBlank,
    prompt: 'Training an existing AI model further on a narrower, task-specific dataset to '
        'adapt its behaviour is called ______.',
    acceptedAnswers: ['fine-tuning', 'finetuning', 'fine tuning'],
    explanation: 'Fine-tuning adapts an already-trained model rather than building one from '
        'scratch — distinct from RAG, which changes what the model sees, not what it is.',
  ),
];

const _toolSelection = [
  ScenarioQuestion(
    id: 'tool-current-research',
    topic: AiReadinessTopic.toolSelection,
    type: QuestionType.multipleChoice,
    prompt: 'You need to research a fast-changing industry and want the AI\'s answers '
        'grounded in the most current information possible. Which approach is most '
        'appropriate?',
    options: [
      'Rely purely on the model\'s built-in training knowledge',
      'Pair the model with retrieval against current, authoritative sources',
      'Increase the temperature setting',
      'Ask the model to guess based on older patterns',
    ],
    correctIndex: 1,
    explanation:
        "A model's training data has a cutoff — for anything current, it needs to retrieve "
        'live sources rather than rely on memory alone.',
  ),
  ScenarioQuestion(
    id: 'tool-long-document',
    topic: AiReadinessTopic.toolSelection,
    type: QuestionType.multipleChoice,
    prompt: "Your team needs to repeatedly query a 500-page internal policy manual that's "
        'updated occasionally. Which capability matters most?',
    options: [
      'Long-context or retrieval-based document handling',
      'Voice synthesis',
      'Image generation',
      'Maximum creativity/temperature',
    ],
    correctIndex: 0,
    explanation:
        'A document this large needs either a large enough context window to hold it, or '
        'retrieval that pulls the relevant sections — not a general-purpose creative setting.',
  ),
  ScenarioQuestion(
    id: 'tool-multimodal',
    topic: AiReadinessTopic.toolSelection,
    type: QuestionType.multipleChoice,
    prompt: 'You need an AI tool to analyse scanned inspection reports that mix photographs, '
        'handwritten notes, and typed tables. Which capability is essential?',
    options: [
      'Multimodal (text + image) understanding',
      'Plain text-only processing',
      'Highest possible token-generation speed',
      'Voice-only interaction',
    ],
    correctIndex: 0,
    explanation:
        'A text-only tool simply cannot see the photographs or handwriting — multimodal '
        'capability is a hard requirement here, not a nice-to-have.',
  ),
  ScenarioQuestion(
    id: 'tool-confidential-data',
    topic: AiReadinessTopic.toolSelection,
    type: QuestionType.multipleChoice,
    prompt: 'Before uploading confidential client data to any AI tool, what should you check '
        'first?',
    options: [
      'Whether it has an attractive interface',
      'Whether it is free',
      "The tool's data handling, retention, and your organisation's policy on external AI use",
      'How quickly it responds',
    ],
    correctIndex: 2,
    explanation:
        'Data handling is the actual risk surface here — cost and interface quality are '
        'irrelevant to whether confidential information is being exposed.',
  ),
  ScenarioQuestion(
    id: 'tool-large-context-claim',
    topic: AiReadinessTopic.toolSelection,
    type: QuestionType.multipleChoice,
    prompt: 'A vendor advertises that their AI model has a very large context window. What '
        'does this tell you on its own?',
    options: [
      'It is automatically more accurate',
      'It has real-time internet access',
      'It cannot hallucinate',
      'It can potentially take in more information per interaction, but that alone does not '
          'guarantee quality',
    ],
    correctIndex: 3,
    explanation:
        'A bigger context window is a capacity claim, not a quality guarantee — accuracy, '
        'grounding, and hallucination risk are separate questions entirely.',
  ),
  ScenarioQuestion(
    id: 'tool-evaluation-method',
    topic: AiReadinessTopic.toolSelection,
    type: QuestionType.multipleChoice,
    prompt: 'What is the most reliable way to choose between two AI tools for a specific '
        'business task?',
    options: [
      'Always choose the newest release',
      'Test both against representative examples of your actual task and compare results',
      'Pick whichever is more heavily advertised',
      'Choose based on name recognition alone',
    ],
    correctIndex: 1,
    explanation:
        'Benchmarks and marketing describe general performance — only testing against your '
        'own real task tells you which tool actually works for it.',
  ),
  ScenarioQuestion(
    id: 'tool-hr-policy-assistant',
    topic: AiReadinessTopic.toolSelection,
    type: QuestionType.multipleChoice,
    prompt: 'A company wants an AI assistant to answer employee questions using HR policies '
        'that change frequently. Which design is most appropriate?',
    options: [
      'Fine-tune a model every time a policy changes',
      'Use a static, unchangeable script',
      'An LLM combined with retrieval from the current, approved policy documents',
      "Maximise the model's temperature setting",
    ],
    correctIndex: 2,
    explanation:
        'Fine-tuning on every update is slow and expensive; retrieval lets the assistant stay '
        'current the moment the source documents change.',
  ),
  ScenarioQuestion(
    id: 'tool-selection-criteria',
    topic: AiReadinessTopic.toolSelection,
    type: QuestionType.multipleChoice,
    prompt: 'Which factor should NOT be the primary basis for selecting an AI model for '
        'serious business use?',
    options: [
      'Its performance on tasks representative of your actual use case',
      'Data-privacy and security fit for your organisation',
      'Integration with your existing systems',
      'How popular or trending it appears on social media',
    ],
    correctIndex: 3,
    explanation:
        'Popularity says nothing about fitness for your specific task, data-handling needs, '
        'or integration requirements — the three factors that actually matter.',
  ),
  ScenarioQuestion(
    id: 'tool-fib-multimodal',
    topic: AiReadinessTopic.toolSelection,
    type: QuestionType.fillInBlank,
    prompt: 'An AI system that can process and combine information from multiple formats — '
        'text, images, audio — is described as ______.',
    acceptedAnswers: ['multimodal'],
    explanation: 'Multimodal systems handle more than one type of input, which matters '
        'whenever a task mixes text with images, audio, or other formats.',
  ),
  ScenarioQuestion(
    id: 'tool-fib-apis',
    topic: AiReadinessTopic.toolSelection,
    type: QuestionType.fillInBlank,
    prompt: 'Software interfaces that let an AI system communicate with other applications '
        'and exchange data automatically are called ______.',
    acceptedAnswers: ['apis', 'api'],
    explanation: 'APIs are what let an AI tool actually plug into your other business '
        'systems, rather than being a standalone chat window.',
  ),
  ScenarioQuestion(
    id: 'tool-fib-rag',
    topic: AiReadinessTopic.toolSelection,
    type: QuestionType.fillInBlank,
    prompt: 'Retrieving relevant information from an external source and supplying it to a '
        'model before it answers is called Retrieval-______ Generation.',
    acceptedAnswers: ['augmented'],
    explanation: 'Retrieval-Augmented Generation (RAG) is the standard term for this '
        'pattern — grounding a model\'s answer in retrieved, current source material.',
  ),
];

const _prompting = [
  ScenarioQuestion(
    id: 'prompt-contracts',
    topic: AiReadinessTopic.prompting,
    type: QuestionType.multipleChoice,
    prompt: 'You need to summarize 50 vendor contracts by Friday. What is the most effective '
        'way to use AI here?',
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
    id: 'prompt-memo',
    topic: AiReadinessTopic.prompting,
    type: QuestionType.multipleChoice,
    prompt: "You're drafting a strategy memo and want AI's help. What gets the best result?",
    options: [
      'Give it your actual data, context, audience, and constraints, then iterate with '
          'follow-up prompts',
      'Type one vague sentence like "write a strategy memo" and use whatever comes out',
      'Ask it to write the memo without giving it any of your specific business context',
      'Avoid AI entirely for anything strategic',
    ],
    correctIndex: 0,
    explanation:
        'Output quality tracks input quality — real context plus iteration consistently '
        'beats a single vague prompt.',
  ),
  ScenarioQuestion(
    id: 'prompt-autocomplete',
    topic: AiReadinessTopic.prompting,
    type: QuestionType.multipleChoice,
    prompt: 'An AI tool offers to auto-complete your sentences while drafting a client '
        'email. When is this most useful?',
    options: [
      'Always accept every suggestion without reading it, to save time',
      'Never use it, since it might sound robotic',
      'Only use it for emails to your own team, never external clients',
      'Use it to speed up routine phrasing, but review and edit before sending — especially '
          'for anything sensitive or client-specific',
    ],
    correctIndex: 3,
    explanation:
        'Speed is the benefit; review before sending is the safeguard — dropping either one '
        'defeats the point.',
  ),
  ScenarioQuestion(
    id: 'prompt-classification',
    topic: AiReadinessTopic.prompting,
    type: QuestionType.multipleChoice,
    prompt: 'You want AI to classify 200 documents into 5 predefined categories '
        'consistently. What most improves consistency?',
    options: [
      'Ask it to classify them "appropriately"',
      'Increase temperature substantially',
      'Define the categories clearly and give a few worked examples of each',
      'Give no examples, to avoid biasing it',
    ],
    correctIndex: 2,
    explanation:
        'Clear definitions plus examples anchor the model to a consistent standard — vague '
        'instructions leave it to interpret the boundary case by case.',
  ),
  ScenarioQuestion(
    id: 'prompt-generic-draft',
    topic: AiReadinessTopic.prompting,
    type: QuestionType.multipleChoice,
    prompt: "Your first AI draft is too generic. What's the most effective next step?",
    options: [
      'Assume AI cannot do the task and give up',
      'Increase temperature to add randomness',
      'Delete all source material and start blank',
      'Add specific context, constraints, and examples, then iterate',
    ],
    correctIndex: 3,
    explanation:
        'A generic first draft almost always means the prompt lacked specifics — adding real '
        'context and iterating fixes it far more reliably than randomness.',
  ),
  ScenarioQuestion(
    id: 'prompt-few-shot',
    topic: AiReadinessTopic.prompting,
    type: QuestionType.multipleChoice,
    prompt: "Which is the clearest example of 'few-shot prompting'?",
    options: [
      'Asking a question with zero context',
      'Providing 2-3 examples of the input/output pattern you want before asking the real '
          'question',
      'Fine-tuning the underlying model',
      'Searching the web for the answer first',
    ],
    correctIndex: 1,
    explanation:
        "Few-shot prompting shows the model the pattern you want via examples, within the "
        'prompt itself — no retraining involved.',
  ),
  ScenarioQuestion(
    id: 'prompt-rubric',
    topic: AiReadinessTopic.prompting,
    type: QuestionType.multipleChoice,
    prompt: 'You want AI-generated interview evaluations to be comparable across 50 '
        'candidates. What should you provide?',
    options: [
      'A defined scoring rubric and criteria applied the same way to every candidate',
      "Just each candidate's name",
      'Encouragement to be "as creative as possible"',
      'No structure, so it can judge freely',
    ],
    correctIndex: 0,
    explanation:
        'Comparability requires the same yardstick every time — a defined rubric is what '
        'makes 50 separate evaluations actually comparable to each other.',
  ),
  ScenarioQuestion(
    id: 'prompt-audience',
    topic: AiReadinessTopic.prompting,
    type: QuestionType.multipleChoice,
    prompt: 'Why does specifying the intended audience matter when prompting AI for a '
        'report?',
    options: [
      'It only matters for image generation',
      'It has no real effect on output quality',
      'It changes the appropriate depth, tone, and level of technical detail',
      'It guarantees factual accuracy',
    ],
    correctIndex: 2,
    explanation:
        'The same content needs a different depth and tone for a board summary versus a '
        'technical team — audience is one of the highest-leverage things to specify.',
  ),
  ScenarioQuestion(
    id: 'prompt-fib-fewshot',
    topic: AiReadinessTopic.prompting,
    type: QuestionType.fillInBlank,
    prompt: 'Providing an AI model with 2-3 examples of the exact input/output pattern you '
        'want before your real question is called ______-shot prompting.',
    acceptedAnswers: ['few'],
    explanation: 'This is few-shot prompting — as opposed to "zero-shot" (no examples at '
        'all).',
  ),
  ScenarioQuestion(
    id: 'prompt-fib-prompt',
    topic: AiReadinessTopic.prompting,
    type: QuestionType.fillInBlank,
    prompt: 'The overall set of instructions, context, and constraints you give an AI model '
        'to guide its response is called a ______.',
    acceptedAnswers: ['prompt'],
    explanation: "The prompt is the single biggest lever you control over an AI's output "
        'quality.',
  ),
  ScenarioQuestion(
    id: 'prompt-fib-iterative',
    topic: AiReadinessTopic.prompting,
    type: QuestionType.fillInBlank,
    prompt: "Refining an AI's output through several rounds of follow-up instructions "
        'rather than accepting the first draft is known as ______ prompting.',
    acceptedAnswers: ['iterative'],
    explanation: 'Treating the first response as a draft to refine, not a final answer, is '
        'what iterative prompting means in practice.',
  ),
];

const _researchAndDecisions = [
  ScenarioQuestion(
    id: 'research-verify-numbers',
    topic: AiReadinessTopic.researchAndDecisions,
    type: QuestionType.multipleChoice,
    prompt: 'An AI assistant gives a confident, detailed answer with specific numbers to a '
        'factual question. What should you do before using those numbers in a report?',
    options: [
      "Use them as-is — a confident tone means it's accurate",
      'Ask a different AI tool the same question and use whichever answer sounds more '
          'confident',
      'Discard the answer entirely and never use AI for anything factual again',
      'Verify against a primary source before relying on them, especially for anything '
          "you'll be accountable for",
    ],
    correctIndex: 3,
    explanation:
        'Confidence of tone carries no information about accuracy — verification against a '
        'real source is the only thing that does.',
  ),
  ScenarioQuestion(
    id: 'research-hiring-bias',
    topic: AiReadinessTopic.researchAndDecisions,
    type: QuestionType.multipleChoice,
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
  ScenarioQuestion(
    id: 'research-conflicting-figures',
    topic: AiReadinessTopic.researchAndDecisions,
    type: QuestionType.multipleChoice,
    prompt: 'AI reports a 35% fall in quarterly sales, but your own dashboard shows 22%. '
        "What's the right first step?",
    options: [
      'Average the two figures and move on',
      'Automatically trust the AI since it processed more data',
      'Investigate the underlying definitions, source data, and calculation period behind '
          'each figure',
      'Automatically trust the dashboard without checking',
    ],
    correctIndex: 2,
    explanation:
        'A discrepancy this large almost always traces back to different definitions, time '
        'windows, or source data — averaging or picking a side by default hides the real bug.',
  ),
  ScenarioQuestion(
    id: 'research-correlation',
    topic: AiReadinessTopic.researchAndDecisions,
    type: QuestionType.multipleChoice,
    prompt: 'AI shows that ice-cream sales and drowning incidents rise together and suggests '
        'a strong link between them. What is the most important thing to check?',
    options: [
      'Whether a third factor (like hot weather) could explain both, rather than one '
          'causing the other',
      "Whether the AI's grammar is correct",
      'Whether the chart colours are appealing',
      'Whether more decimal places would help',
    ],
    correctIndex: 0,
    explanation:
        "A confident AI narrative about correlation doesn't make it causation — checking for "
        'a shared underlying cause is the standard first move.',
  ),
  ScenarioQuestion(
    id: 'research-evidence-base',
    topic: AiReadinessTopic.researchAndDecisions,
    type: QuestionType.multipleChoice,
    prompt: "You're researching a fast-changing industry for a board paper. Which "
        'combination gives the strongest evidence base?',
    options: [
      'Ask one AI model for its opinion and use it directly',
      'Gather current, authoritative sources, have AI help synthesise them, then verify the '
          'key claims yourself',
      'Use only the first search result you find',
      "Ask AI to estimate any information you couldn't find",
    ],
    correctIndex: 1,
    explanation:
        'AI is genuinely useful for synthesis — the discipline is gathering real sources '
        'first and verifying the load-bearing claims before they go in a board paper.',
  ),
  ScenarioQuestion(
    id: 'research-data-quality',
    topic: AiReadinessTopic.researchAndDecisions,
    type: QuestionType.multipleChoice,
    prompt: 'Which data problem is most likely to silently distort an AI-generated '
        'analysis?',
    options: [
      'A large monitor',
      'A long, detailed prompt',
      'An attractively formatted dashboard',
      'Missing or inconsistent data that was never cleaned before analysis',
    ],
    correctIndex: 3,
    explanation:
        "AI analysis is only as good as the data behind it — dirty or incomplete data "
        'produces a confident-looking but wrong answer just as easily as a careful one.',
  ),
  ScenarioQuestion(
    id: 'research-confirmation-bias',
    topic: AiReadinessTopic.researchAndDecisions,
    type: QuestionType.multipleChoice,
    prompt: "What is 'confirmation bias' in the context of AI-assisted research?",
    options: [
      'Asking AI only for evidence that supports a conclusion you have already decided on',
      'Asking AI for counterarguments to your own view',
      'Cross-checking primary sources',
      'Comparing two competing explanations fairly',
    ],
    correctIndex: 0,
    explanation:
        'AI will readily produce supporting evidence for almost any premise if that\'s all '
        "you ask for — the bias is in the asking, not the tool.",
  ),
  ScenarioQuestion(
    id: 'research-reproducibility',
    topic: AiReadinessTopic.researchAndDecisions,
    type: QuestionType.multipleChoice,
    prompt: 'Why is it important to be able to reproduce an AI-assisted quantitative '
        'analysis?',
    options: [
      'It makes the AI sound more confident',
      'It removes the need for any data at all',
      'It allows the result to be checked and any inconsistency investigated',
      'It automatically guarantees the conclusion is correct',
    ],
    correctIndex: 2,
    explanation:
        'Reproducibility is what makes a result checkable — without it, an error has no way '
        'of being caught before it reaches a decision.',
  ),
  ScenarioQuestion(
    id: 'research-fib-correlation',
    topic: AiReadinessTopic.researchAndDecisions,
    type: QuestionType.fillInBlank,
    prompt: 'When two things rise and fall together but one has not necessarily caused the '
        'other, this relationship is called ______.',
    acceptedAnswers: ['correlation'],
    explanation: 'Correlation describes the pattern; causation is a separate claim that '
        'needs its own evidence.',
  ),
  ScenarioQuestion(
    id: 'research-fib-verification',
    topic: AiReadinessTopic.researchAndDecisions,
    type: QuestionType.fillInBlank,
    prompt: 'Checking an AI-generated claim against reliable, independent evidence before '
        'relying on it is called ______.',
    acceptedAnswers: ['verification'],
    explanation: 'Verification is the step that separates "AI said so" from "this is '
        'actually true."',
  ),
  ScenarioQuestion(
    id: 'research-fib-confirmation',
    topic: AiReadinessTopic.researchAndDecisions,
    type: QuestionType.fillInBlank,
    prompt: 'Asking AI only for evidence that supports a conclusion you have already reached '
        'is an example of ______ bias.',
    acceptedAnswers: ['confirmation'],
    explanation: 'Confirmation bias shapes the question, so the tool never gets a fair '
        'chance to disagree with you.',
  ),
];

const _workflowsAndAgents = [
  ScenarioQuestion(
    id: 'workflow-automation-candidate',
    topic: AiReadinessTopic.workflowsAndAgents,
    type: QuestionType.multipleChoice,
    prompt: 'Which task is generally the strongest candidate for AI-driven automation?',
    options: [
      'A repetitive, high-volume process with clearly defined inputs and outputs',
      'A one-off strategic decision with unclear objectives',
      'A sensitive disciplinary decision',
      'A task with no defined process at all',
    ],
    correctIndex: 0,
    explanation:
        'Automation needs a defined, repeatable pattern to work against — exactly what '
        'high-volume, well-defined processes have and one-off judgement calls don\'t.',
  ),
  ScenarioQuestion(
    id: 'workflow-agent-vs-chatbot',
    topic: AiReadinessTopic.workflowsAndAgents,
    type: QuestionType.multipleChoice,
    prompt: 'What distinguishes an AI agent from a simple chatbot in a business workflow?',
    options: [
      'The agent always gives factually perfect answers',
      'An agent can plan and execute multiple steps, potentially using tools, toward a goal',
      'The agent is simply a bigger language model',
      'A chatbot can never make mistakes',
    ],
    correctIndex: 1,
    explanation:
        'The defining feature of an agent is taking multi-step action toward a goal, not '
        'just answering — which is also what raises the stakes if it goes unsupervised.',
  ),
  ScenarioQuestion(
    id: 'workflow-crm-permissions',
    topic: AiReadinessTopic.workflowsAndAgents,
    type: QuestionType.multipleChoice,
    prompt: 'Before letting an AI agent automatically update records in your CRM, what '
        'should be established first?',
    options: [
      'Maximum, unrestricted access to every system',
      'No approval mechanism at all',
      'The highest possible creativity setting',
      'Clear permissions, validation rules, and logging, with appropriate human checks',
    ],
    correctIndex: 3,
    explanation:
        'An agent acting on real business systems needs the same controls you\'d put around '
        "any automated process that can change real records.",
  ),
  ScenarioQuestion(
    id: 'workflow-map-first',
    topic: AiReadinessTopic.workflowsAndAgents,
    type: QuestionType.multipleChoice,
    prompt: "You want to automate a monthly reporting process. What's the right first step?",
    options: [
      'Immediately buy the most advanced AI agent available',
      'Map the existing process to identify its inputs, decisions, and repetitive steps',
      'Remove all human involvement from the start',
      'Ask AI to redesign the entire business function',
    ],
    correctIndex: 1,
    explanation:
        'You can\'t automate what you haven\'t mapped — understanding the current process is '
        'what tells you which steps are actually repetitive versus which need judgement.',
  ),
  ScenarioQuestion(
    id: 'workflow-human-in-loop',
    topic: AiReadinessTopic.workflowsAndAgents,
    type: QuestionType.multipleChoice,
    prompt: "What is the purpose of a 'human-in-the-loop' design in an AI workflow?",
    options: [
      'To prevent AI from ever being used',
      "To increase the model's temperature",
      'To eliminate automation entirely',
      'To retain human review or approval at appropriate points in the process',
    ],
    correctIndex: 3,
    explanation:
        "Human-in-the-loop isn't the opposite of automation — it's automation with a "
        'deliberate checkpoint at the points that matter most.',
  ),
  ScenarioQuestion(
    id: 'workflow-exceptions',
    topic: AiReadinessTopic.workflowsAndAgents,
    type: QuestionType.multipleChoice,
    prompt: 'Why are exception-handling rules important when automating a business process '
        'with AI?',
    options: [
      'They make the AI more creative',
      'They eliminate the need for any testing',
      'Real-world inputs regularly fall outside the "normal" pattern the automation expects',
      'AI cannot process typical, expected cases',
    ],
    correctIndex: 2,
    explanation:
        'Every real process eventually meets an unusual case — without a defined path for '
        'exceptions, the automation either breaks or, worse, silently does the wrong thing.',
  ),
  ScenarioQuestion(
    id: 'workflow-least-privilege',
    topic: AiReadinessTopic.workflowsAndAgents,
    type: QuestionType.multipleChoice,
    prompt: 'An automated AI workflow is granted access to your finance, HR, and CRM '
        'systems. What principle should govern how much access it actually gets?',
    options: [
      'Grant only the minimum access necessary for its specific, approved task',
      'Give it full access to everything, for convenience',
      'No authentication should be required',
      'Access should never be logged',
    ],
    correctIndex: 0,
    explanation:
        "Least privilege limits the damage if something goes wrong — an agent that only "
        'needs read access to one system should never hold write access to three.',
  ),
  ScenarioQuestion(
    id: 'workflow-pilot',
    topic: AiReadinessTopic.workflowsAndAgents,
    type: QuestionType.multipleChoice,
    prompt: 'Why should a new AI-driven workflow be piloted on a small scale before being '
        'rolled out to the whole organisation?',
    options: [
      'To avoid measuring any results',
      'To skip governance requirements',
      'To test real performance, risk, and user acceptance under controlled conditions '
          'before scaling',
      'Piloting has no practical benefit',
    ],
    correctIndex: 2,
    explanation:
        'A pilot surfaces failure modes and user friction while the blast radius is still '
        'small — exactly what you want before every user in the organisation depends on it.',
  ),
  ScenarioQuestion(
    id: 'workflow-fib-agent',
    topic: AiReadinessTopic.workflowsAndAgents,
    type: QuestionType.fillInBlank,
    prompt: 'An AI system capable of planning and executing multiple steps toward a goal, '
        'potentially using external tools, is commonly called an AI ______.',
    acceptedAnswers: ['agent'],
    explanation: 'This is the standard term — agent — for a system that takes multi-step '
        'action, not just answers a single question.',
  ),
  ScenarioQuestion(
    id: 'workflow-fib-humanintheloop',
    topic: AiReadinessTopic.workflowsAndAgents,
    type: QuestionType.fillInBlank,
    prompt: 'The practice of keeping a person reviewing or approving an AI system\'s actions '
        'at key points is called human-in-the-______.',
    acceptedAnswers: ['loop'],
    explanation: 'Human-in-the-loop is the standard term for this design pattern.',
  ),
  ScenarioQuestion(
    id: 'workflow-fib-privilege',
    topic: AiReadinessTopic.workflowsAndAgents,
    type: QuestionType.fillInBlank,
    prompt: 'The security principle of giving a system only the minimum access it needs for '
        'its specific task is known as least ______.',
    acceptedAnswers: ['privilege'],
    explanation: 'Least privilege is a core security principle, not unique to AI, but '
        'especially important once an AI agent can take real actions.',
  ),
];

const _governance = [
  ScenarioQuestion(
    id: 'gov-nist-functions',
    topic: AiReadinessTopic.governance,
    type: QuestionType.multipleChoice,
    prompt: 'The NIST AI Risk Management Framework organizes AI risk management into four '
        'core functions. Which of these is one of them?',
    options: ['Govern', 'Monetize', 'Advertise', 'Franchise'],
    correctIndex: 0,
    explanation:
        "NIST AI RMF's four functions are Govern, Map, Measure, and Manage — Govern means "
        'establishing the culture and structure for managing AI risk across an organization.',
  ),
  ScenarioQuestion(
    id: 'gov-data-question',
    topic: AiReadinessTopic.governance,
    type: QuestionType.multipleChoice,
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
    id: 'gov-deployment',
    topic: AiReadinessTopic.governance,
    type: QuestionType.multipleChoice,
    prompt: 'Your organization is rolling out an AI tool for a business process. Per a '
        'risk-management mindset like NIST AI RMF, what should happen before wide '
        'deployment?',
    options: [
      'Deploy to everyone immediately — issues can be fixed after the fact',
      'Skip evaluation, since the vendor already tested it',
      'Map out where the AI could fail or cause harm, measure that risk, and put '
          'safeguards in place before scaling up',
      'Only test it on the least experienced staff, to see what happens',
    ],
    correctIndex: 2,
    explanation:
        'Map-then-Measure-then-Manage before scaling is the core NIST AI RMF sequence — '
        'skipping it means finding failure modes in production instead of before rollout.',
  ),
  ScenarioQuestion(
    id: 'gov-false-flag',
    topic: AiReadinessTopic.governance,
    type: QuestionType.multipleChoice,
    prompt: 'An AI tool flags a vendor invoice as a duplicate-payment risk, but your own '
        "quick check shows it's a legitimate recurring charge. What's the right next step?",
    options: [
      "Trust the AI's flag automatically and block the payment, since AI is usually right",
      'Ignore all future flags from this tool, since it was wrong once',
      'Escalate to IT to shut the AI tool down entirely',
      'Verify against the source data, override the flag with a documented reason, and note '
          'the false positive',
    ],
    correctIndex: 3,
    explanation:
        'One false positive means "verify and document," not "always trust" or "never '
        'trust" — the goal is calibrated confidence, not either extreme.',
  ),
  ScenarioQuestion(
    id: 'gov-prompt-injection',
    topic: AiReadinessTopic.governance,
    type: QuestionType.multipleChoice,
    prompt: "What is 'prompt injection'?",
    options: [
      'Malicious or manipulative instructions hidden inside content an AI system processes, '
          'intended to alter its behaviour',
      'Asking AI to summarise a long report',
      "Increasing a model's context window",
      'Changing the interface language',
    ],
    correctIndex: 0,
    explanation:
        'Prompt injection is a real security concern any time an AI system reads content '
        'from an untrusted source — email, a web page, a document someone else uploaded.',
  ),
  ScenarioQuestion(
    id: 'gov-deletion-myth',
    topic: AiReadinessTopic.governance,
    type: QuestionType.multipleChoice,
    prompt: 'Why can confidential information remain a concern even after you delete it '
        'from an AI chat interface?',
    options: [
      'Deleted text automatically becomes public',
      'AI systems cannot process confidential information at all',
      'The underlying service may have logged, processed, or retained it according to its '
          'own architecture and policy',
      'Deletion always guarantees permanent, immediate erasure',
    ],
    correctIndex: 2,
    explanation:
        "What happens on-screen and what happens server-side are different things — this is "
        'exactly why the earlier data-handling question matters before you type anything in.',
  ),
  ScenarioQuestion(
    id: 'gov-recruitment-bias',
    topic: AiReadinessTopic.governance,
    type: QuestionType.multipleChoice,
    prompt: 'An AI-based recruitment tool scores candidates from one demographic group lower '
        'on average, even when qualifications look comparable. What should this prompt?',
    options: [
      'Accepting the scores as objective since AI has no personal opinions',
      'Investigating possible bias in the training data, features, and decision process '
          'before trusting it for real decisions',
      'Assuming the tool must be correct because it processed more data than a human could',
      'Ignoring it, since the difference is likely coincidental',
    ],
    correctIndex: 1,
    explanation:
        "AI systems inherit patterns from their training data — a consistent, unexplained "
        'skew is a real signal to investigate, not evidence of objectivity.',
  ),
  ScenarioQuestion(
    id: 'gov-explainability',
    topic: AiReadinessTopic.governance,
    type: QuestionType.multipleChoice,
    prompt: "What does 'explainability' mean in the context of an AI-assisted decision?",
    options: [
      'The ability to make the AI generate longer answers',
      "The ability to increase the model's creativity setting",
      'The ability to remove all uncertainty from a decision',
      'The ability to understand and articulate the key factors behind an AI output or '
          'recommendation',
    ],
    correctIndex: 3,
    explanation:
        "Explainability is what lets you defend a decision that AI contributed to — without "
        "it, you can't tell a stakeholder why the recommendation came out the way it did.",
  ),
  ScenarioQuestion(
    id: 'gov-fib-injection',
    topic: AiReadinessTopic.governance,
    type: QuestionType.fillInBlank,
    prompt: 'Malicious or manipulative instructions hidden inside content that an AI system '
        'processes, intended to alter its behaviour, is called prompt ______.',
    acceptedAnswers: ['injection'],
    explanation: 'Prompt injection is the standard term for this attack pattern.',
  ),
  ScenarioQuestion(
    id: 'gov-fib-pii',
    topic: AiReadinessTopic.governance,
    type: QuestionType.fillInBlank,
    prompt: 'Information that can be used to identify a specific individual is commonly '
        'referred to as personally identifiable ______.',
    acceptedAnswers: ['information'],
    explanation: 'PII — personally identifiable information — is the term used in most data '
        'protection and privacy policy.',
  ),
  ScenarioQuestion(
    id: 'gov-fib-bias',
    topic: AiReadinessTopic.governance,
    type: QuestionType.fillInBlank,
    prompt: 'Unfair, systematic differences in AI outcomes linked to a particular group can '
        'indicate algorithmic ______.',
    acceptedAnswers: ['bias'],
    explanation: 'Algorithmic bias is what a consistent, unexplained skew across a '
        'demographic group is a real signal of.',
  ),
];

/// The full bank, organised by topic — every attempt samples from this
/// rather than showing every question every time. See the file-level doc
/// comment for the review cadence and why product-specific facts are kept
/// out of this bank entirely.
const Map<AiReadinessTopic, List<ScenarioQuestion>> kAiReadinessQuestionBank = {
  AiReadinessTopic.fundamentals: _fundamentals,
  AiReadinessTopic.toolSelection: _toolSelection,
  AiReadinessTopic.prompting: _prompting,
  AiReadinessTopic.researchAndDecisions: _researchAndDecisions,
  AiReadinessTopic.workflowsAndAgents: _workflowsAndAgents,
  AiReadinessTopic.governance: _governance,
};

/// Draws one assessment attempt: 4 multiple-choice + 1 fill-in-blank per
/// topic (30 questions total), randomly sampled from that topic's pool so
/// repeat attempts don't show the same 30 questions every time. Grouped by
/// topic in the returned list, matching how the quiz screen displays them.
List<ScenarioQuestion> sampleAiReadinessQuestions({Random? random}) {
  final rng = random ?? Random();
  final sampled = <ScenarioQuestion>[];
  for (final topic in AiReadinessTopic.values) {
    final pool = kAiReadinessQuestionBank[topic] ?? const [];
    final mcqs = pool.where((q) => q.type == QuestionType.multipleChoice).toList()..shuffle(rng);
    final fibs = pool.where((q) => q.type == QuestionType.fillInBlank).toList()..shuffle(rng);
    sampled.addAll(mcqs.take(4));
    sampled.addAll(fibs.take(1));
  }
  return sampled;
}
