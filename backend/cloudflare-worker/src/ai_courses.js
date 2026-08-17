// Verified live (not recited from memory) before being added here.
// Mirrors lib/features/ai_readiness/ai_course.dart — keep both in sync.
export const AI_COURSES = [
  {
    id: 'google-ai-essentials',
    name: 'AI Essentials',
    provider: 'Google',
    url: 'https://grow.google/ai-essentials/',
    duration: 'Under 5 hours, 5 modules',
    cost: 'free',
    description:
      'Fundamentals of generative AI plus hands-on productivity use — drafting, research, responsible use. Free certificate on completion.',
  },
  {
    id: 'microsoft-intro-genai-agents',
    name: 'Introduction to Generative AI and Agents',
    provider: 'Microsoft Learn',
    url: 'https://learn.microsoft.com/en-us/training/modules/fundamentals-generative-ai/',
    duration: '7 units, beginner',
    cost: 'free',
    description: 'Core concepts of generative AI, LLMs, prompts, and AI agents, with a module assessment.',
  },
  {
    id: 'deeplearningai-prompting',
    name: 'AI Prompting for Everyone',
    provider: 'DeepLearning.AI',
    url: 'https://www.deeplearning.ai/courses/ai-prompting-for-everyone/',
    duration: '7h4m, 21 video lessons',
    cost: 'free_with_paid_cert_or_tier',
    description:
      'Taught by Andrew Ng — finding information, using AI as a thought partner, and working with multimedia. Free to watch; certificate requires a paid PRO membership.',
  },
  {
    id: 'outskill-genai-mastermind',
    name: 'Gen-AI Mastermind (weekend workshop)',
    provider: 'Outskill',
    url: 'https://www.outskill.com/',
    duration: 'Live cohort workshop — see website for current dates',
    cost: 'free',
    description:
      'Live weekend workshop: generative AI fundamentals, building custom GPTs/agents, no-code AI products, and AI-generated visual content. Runs as dated cohorts, not self-paced — check the website for the next available date.',
  },
  {
    id: 'soar-skill-india',
    name: 'SOAR (Skilling for AI Readiness)',
    provider: 'Ministry of Skill Development & Entrepreneurship, Govt of India',
    url: 'https://www.skillindiadigital.gov.in/',
    duration: 'Self-paced, 50 NSQF-aligned micro-credential courses',
    cost: 'free',
    description:
      'National AI-readiness initiative delivered via the Skill India Digital Hub. Covers AI awareness through sector-specific applications, developed with industry partners including Microsoft and NASSCOM.',
  },
];
