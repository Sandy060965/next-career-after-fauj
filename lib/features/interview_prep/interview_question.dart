enum InterviewCategory { aboutYou, leadership, conflict, whyThisRole, transition }

extension InterviewCategoryLabel on InterviewCategory {
  String get label => switch (this) {
        InterviewCategory.aboutYou => 'About You & Career Narrative',
        InterviewCategory.leadership => 'Leadership & Team Management',
        InterviewCategory.conflict => 'Handling Conflict & Setbacks',
        InterviewCategory.whyThisRole => 'Why This Role',
        InterviewCategory.transition => 'Transition-Specific',
      };

  /// Broad guidance for answering questions in this category — built on the
  /// STAR method (Situation, Task, Action, Result) for behavioural
  /// questions, with an explicit steer on translating military experience
  /// into civilian terms where relevant.
  String get guidance => switch (this) {
        InterviewCategory.aboutYou =>
          'Keep it to 2-3 minutes: a brief career arc, then land on why you\'re '
              'suited to this kind of role next. Translate rank and unit scale into '
              'civilian terms — "commanded a battalion of 900" reads better as "led an '
              'organisation of 900 people."',
        InterviewCategory.leadership =>
          'Use STAR — Situation, Task, Action, Result. Pick a specific example, not a '
              'general description of your style. Quantify the team size and outcome, '
              'and describe your actions in civilian management language (coaching, '
              'delegation, performance management) rather than command terminology.',
        InterviewCategory.conflict =>
          'Use STAR here too, but be honest about the setback or disagreement before '
              'explaining the resolution — interviewers are testing self-awareness as '
              'much as the outcome. Avoid framing every story as a clean win.',
        InterviewCategory.whyThisRole =>
          'Ground every answer in something specific from the JD or the organisation, '
              'not generic enthusiasm. If asked about compensation, give a realistic '
              'range based on your research rather than deferring entirely.',
        InterviewCategory.transition =>
          'These questions test whether you\'ve genuinely thought about the shift, not '
              'just whether you want a job. Be specific about what you\'ve already done '
              'to adapt (courses, networking, mentors) rather than promising you\'ll '
              'figure it out. Always translate rank, unit, and command-structure '
              'references into civilian equivalents.',
      };
}

class InterviewQuestion {
  const InterviewQuestion({
    required this.id,
    required this.category,
    required this.question,
  });

  final String id;
  final InterviewCategory category;
  final String question;
}

const List<InterviewQuestion> kInterviewQuestions = [
  // About You & Career Narrative
  InterviewQuestion(id: 'about-1', category: InterviewCategory.aboutYou, question: 'Tell me about yourself.'),
  InterviewQuestion(id: 'about-2', category: InterviewCategory.aboutYou, question: 'Walk me through your career so far.'),
  InterviewQuestion(id: 'about-3', category: InterviewCategory.aboutYou, question: 'What are your greatest strengths?'),
  InterviewQuestion(id: 'about-4', category: InterviewCategory.aboutYou, question: 'What do you consider your biggest weakness?'),
  InterviewQuestion(id: 'about-5', category: InterviewCategory.aboutYou, question: 'What are you looking for in your next role?'),
  InterviewQuestion(id: 'about-6', category: InterviewCategory.aboutYou, question: 'Where do you see yourself in five years?'),
  InterviewQuestion(id: 'about-7', category: InterviewCategory.aboutYou, question: 'What motivates you at work?'),
  InterviewQuestion(id: 'about-8', category: InterviewCategory.aboutYou, question: 'How would your colleagues describe you?'),
  InterviewQuestion(id: 'about-9', category: InterviewCategory.aboutYou, question: 'What achievement are you most proud of?'),
  InterviewQuestion(id: 'about-10', category: InterviewCategory.aboutYou, question: 'How do you keep your skills current?'),

  // Leadership & Team Management
  InterviewQuestion(id: 'leadership-1', category: InterviewCategory.leadership, question: 'Describe a time you led a team through a difficult situation.'),
  InterviewQuestion(id: 'leadership-2', category: InterviewCategory.leadership, question: 'Tell me about a time you had to motivate an underperforming team member.'),
  InterviewQuestion(id: 'leadership-3', category: InterviewCategory.leadership, question: 'How do you delegate responsibility?'),
  InterviewQuestion(id: 'leadership-4', category: InterviewCategory.leadership, question: 'How would you describe your leadership style?'),
  InterviewQuestion(id: 'leadership-5', category: InterviewCategory.leadership, question: 'Tell me about a time you had to make an unpopular decision.'),
  InterviewQuestion(id: 'leadership-6', category: InterviewCategory.leadership, question: 'How do you build trust with a new team?'),
  InterviewQuestion(id: 'leadership-7', category: InterviewCategory.leadership, question: 'Describe a time you developed or mentored someone.'),
  InterviewQuestion(id: 'leadership-8', category: InterviewCategory.leadership, question: 'How do you handle team members who disagree with your decisions?'),
  InterviewQuestion(id: 'leadership-9', category: InterviewCategory.leadership, question: 'Tell me about a time you had to lead without formal authority.'),
  InterviewQuestion(id: 'leadership-10', category: InterviewCategory.leadership, question: 'How do you measure whether your team is succeeding?'),

  // Handling Conflict & Setbacks
  InterviewQuestion(id: 'conflict-1', category: InterviewCategory.conflict, question: 'Describe a conflict you had with a colleague and how you resolved it.'),
  InterviewQuestion(id: 'conflict-2', category: InterviewCategory.conflict, question: 'Tell me about a time you failed and what you learned from it.'),
  InterviewQuestion(id: 'conflict-3', category: InterviewCategory.conflict, question: 'How do you handle criticism?'),
  InterviewQuestion(id: 'conflict-4', category: InterviewCategory.conflict, question: 'Describe a time you had to deliver bad news.'),
  InterviewQuestion(id: 'conflict-5', category: InterviewCategory.conflict, question: 'Tell me about a high-pressure situation and how you handled it.'),
  InterviewQuestion(id: 'conflict-6', category: InterviewCategory.conflict, question: 'How do you prioritise when everything seems urgent?'),
  InterviewQuestion(id: 'conflict-7', category: InterviewCategory.conflict, question: 'Describe a time you disagreed with a superior\'s decision.'),
  InterviewQuestion(id: 'conflict-8', category: InterviewCategory.conflict, question: 'Tell me about a mistake you made and how you fixed it.'),
  InterviewQuestion(id: 'conflict-9', category: InterviewCategory.conflict, question: 'How do you handle ambiguity or unclear instructions?'),
  InterviewQuestion(id: 'conflict-10', category: InterviewCategory.conflict, question: 'Describe a time a project didn\'t go as planned.'),

  // Why This Role
  InterviewQuestion(id: 'role-1', category: InterviewCategory.whyThisRole, question: 'Why do you want to work here?'),
  InterviewQuestion(id: 'role-2', category: InterviewCategory.whyThisRole, question: 'Why this role specifically?'),
  InterviewQuestion(id: 'role-3', category: InterviewCategory.whyThisRole, question: 'What do you know about our company or industry?'),
  InterviewQuestion(id: 'role-4', category: InterviewCategory.whyThisRole, question: 'What can you bring to this role that other candidates can\'t?'),
  InterviewQuestion(id: 'role-5', category: InterviewCategory.whyThisRole, question: 'What are your salary expectations?'),
  InterviewQuestion(id: 'role-6', category: InterviewCategory.whyThisRole, question: 'Are you interviewing elsewhere?'),
  InterviewQuestion(id: 'role-7', category: InterviewCategory.whyThisRole, question: 'How soon would you be able to join?'),
  InterviewQuestion(id: 'role-8', category: InterviewCategory.whyThisRole, question: 'What questions do you have for us?'),

  // Transition-Specific
  InterviewQuestion(id: 'transition-1', category: InterviewCategory.transition, question: 'How do you think your military background will translate to a corporate environment?'),
  InterviewQuestion(id: 'transition-2', category: InterviewCategory.transition, question: 'Civilian workplaces are often less structured than the military — how will you adapt?'),
  InterviewQuestion(id: 'transition-3', category: InterviewCategory.transition, question: 'How do you plan to build a professional network outside the armed forces?'),
  InterviewQuestion(id: 'transition-4', category: InterviewCategory.transition, question: 'What has been the hardest part of your transition so far?'),
  InterviewQuestion(id: 'transition-5', category: InterviewCategory.transition, question: 'How would you explain your role and responsibilities to someone outside the military?'),
  InterviewQuestion(id: 'transition-6', category: InterviewCategory.transition, question: 'Do you think you\'ll miss the structure and hierarchy of the military?'),
  InterviewQuestion(id: 'transition-7', category: InterviewCategory.transition, question: 'How comfortable are you working in a flatter organisational hierarchy?'),
  InterviewQuestion(id: 'transition-8', category: InterviewCategory.transition, question: 'What civilian skills do you feel you still need to develop?'),
  InterviewQuestion(id: 'transition-9', category: InterviewCategory.transition, question: 'How do you feel about reporting to a manager younger or less experienced than you?'),
  InterviewQuestion(id: 'transition-10', category: InterviewCategory.transition, question: 'What non-military experience do you have that\'s relevant to this role?'),
];
