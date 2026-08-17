// Fixed reference competencies — the LLM may only select from this list when
// identifying gaps, never invent a skill name.
// Mirrors lib/features/ai_readiness/ai_competency.dart — keep both in sync.
export const AI_COMPETENCIES = [
  { id: 'fundamentals', name: 'AI & Generative AI Fundamentals', priority: 'must', dimension: 'awareness' },
  { id: 'llms', name: 'LLMs & AI Models', priority: 'must', dimension: 'awareness' },
  { id: 'prompting', name: 'Prompt Engineering', priority: 'must', dimension: 'productivity' },
  {
    id: 'assistants',
    name: 'Using ChatGPT / Gemini / Claude / Copilot effectively',
    priority: 'must',
    dimension: 'productivity',
  },
  { id: 'research', name: 'AI-powered Research', priority: 'must', dimension: 'decisionSupport' },
  { id: 'productivity', name: 'AI Productivity & Office Automation', priority: 'must', dimension: 'productivity' },
  { id: 'data-analysis', name: 'AI-assisted Data Analysis', priority: 'must', dimension: 'decisionSupport' },
  {
    id: 'communication',
    name: 'AI-assisted Presentations & Communication',
    priority: 'must',
    dimension: 'productivity',
  },
  { id: 'agents', name: 'AI Agents & Workflow Automation', priority: 'should', dimension: 'productivity' },
  { id: 'cybersecurity', name: 'AI + Cybersecurity / Deepfakes', priority: 'should', dimension: 'governance' },
  { id: 'responsible-ai', name: 'Responsible AI / Governance', priority: 'should', dimension: 'governance' },
  { id: 'strategy', name: 'AI Strategy & Transformation', priority: 'should', dimension: 'leadership' },
  {
    id: 'business-functions',
    name: 'AI for Specific Business Functions',
    priority: 'should',
    dimension: 'decisionSupport',
  },
  { id: 'defence-ai', name: 'AI in Defence & National Security', priority: 'good', dimension: 'awareness' },
  { id: 'ai-business-building', name: 'Building AI-enabled Businesses', priority: 'good', dimension: 'leadership' },
];
