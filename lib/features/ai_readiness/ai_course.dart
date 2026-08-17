enum CourseCost { free, paid, freeWithPaidCertOrTier }

extension CourseCostLabel on CourseCost {
  String get label => switch (this) {
        CourseCost.free => 'Free',
        CourseCost.paid => 'Paid',
        CourseCost.freeWithPaidCertOrTier => 'Free (paid tier available)',
      };
}

/// A course/workshop verified live (not recited from memory) before being
/// added here. The LLM may only recommend courses from this fixed list —
/// never invent a course, provider, URL, or duration.
class AiCourse {
  const AiCourse({
    required this.id,
    required this.name,
    required this.provider,
    required this.url,
    required this.duration,
    required this.cost,
    required this.description,
  });

  final String id;
  final String name;
  final String provider;
  final String url;
  final String duration;
  final CourseCost cost;
  final String description;
}

const List<AiCourse> kAiCourses = [
  AiCourse(
    id: 'google-ai-essentials',
    name: 'AI Essentials',
    provider: 'Google',
    url: 'https://grow.google/ai-essentials/',
    duration: 'Under 5 hours, 5 modules',
    cost: CourseCost.free,
    description:
        'Fundamentals of generative AI plus hands-on productivity use — drafting, research, '
        'responsible use. Free certificate on completion.',
  ),
  AiCourse(
    id: 'microsoft-intro-genai-agents',
    name: 'Introduction to Generative AI and Agents',
    provider: 'Microsoft Learn',
    url: 'https://learn.microsoft.com/en-us/training/modules/fundamentals-generative-ai/',
    duration: '7 units, beginner',
    cost: CourseCost.free,
    description:
        'Core concepts of generative AI, LLMs, prompts, and AI agents, with a module assessment.',
  ),
  AiCourse(
    id: 'deeplearningai-prompting',
    name: 'AI Prompting for Everyone',
    provider: 'DeepLearning.AI',
    url: 'https://www.deeplearning.ai/courses/ai-prompting-for-everyone/',
    duration: '7h4m, 21 video lessons',
    cost: CourseCost.freeWithPaidCertOrTier,
    description:
        'Taught by Andrew Ng — finding information, using AI as a thought partner, and working '
        'with multimedia. Free to watch; certificate requires a paid PRO membership.',
  ),
  AiCourse(
    id: 'outskill-genai-mastermind',
    name: 'Gen-AI Mastermind (weekend workshop)',
    provider: 'Outskill',
    url: 'https://www.outskill.com/',
    duration: '2-day live cohort, 5 sessions',
    cost: CourseCost.free,
    description:
        'Live weekend workshop: generative AI fundamentals, building custom GPTs/agents, '
        'no-code AI products, and AI-generated visual content. Dated cohort, not self-paced.',
  ),
  AiCourse(
    id: 'outskill-accelerator-fellowship',
    name: 'AI Accelerator / AI Fellowship',
    provider: 'Outskill',
    url: 'https://www.outskill.com/',
    duration: '40-60+ hrs (Accelerator) or 6 months (Fellowship)',
    cost: CourseCost.paid,
    description:
        'Deeper paid programs beyond the free Mastermind — self-paced Accelerator or a 6-month '
        'hybrid Fellowship. Pricing is not publicly listed; shown only via their enrollment flow.',
  ),
  AiCourse(
    id: 'soar-skill-india',
    name: 'SOAR (Skilling for AI Readiness)',
    provider: 'Ministry of Skill Development & Entrepreneurship, Govt of India',
    url: 'https://www.skillindiadigital.gov.in/',
    duration: 'Self-paced, 50 NSQF-aligned micro-credential courses',
    cost: CourseCost.free,
    description:
        'National AI-readiness initiative delivered via the Skill India Digital Hub. Covers AI '
        'awareness through sector-specific applications, developed with industry partners '
        'including Microsoft and NASSCOM.',
  ),
];
