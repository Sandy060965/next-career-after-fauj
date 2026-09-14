import '../../core/models/guide_section.dart';

/// The Business Etiquette & Professional Conduct guide's sections, in
/// source order. Sections 1-17 and 19-20 are transcribed from
/// `Next_Career_After_Fauj_Business_Etiquette_Professional_Conduct_Guide.docx`;
/// section 18 is the source's phrasing-playbook table. Sections 21-22
/// ("Statutory Boundaries & Workplace Conduct" and "Body Language & Vocal
/// Presence") are new, written to close gaps identified against an
/// external critique of the source document, in the same
/// Situation/Encounter/Response/Avoid voice as the rest of the guide.
const List<GuideSection> kBusinessEtiquetteSections = [
  GuideSection(
    title: 'Addressing People',
    scenarios: [
      GuideScenario(
        heading: 'The First-Name Introduction',
        situation: 'A colleague says, "Hi Rahul, good to meet you."',
        whatYouMayEncounter: 'You are accustomed to formal, rank-based forms of address.',
        recommendedResponse: 'Respond with your name and continue naturally. Do not insist on '
            'rank-based address unless organisational protocol requires it.',
        avoid: 'Correcting the person or appearing offended.',
      ),
      GuideScenario(
        heading: 'Senior Executive Introduction',
        situation: 'You meet a senior leader for the first time.',
        whatYouMayEncounter: 'It is unclear how the organisation expects you to address them.',
        recommendedResponse: 'Use the form of address used by others in that organisation; when '
            'uncertain, "Mr./Ms." plus surname is safe until they indicate otherwise.',
        avoid: 'Using military rank unless invited.',
      ),
      GuideScenario(
        heading: 'Client Interaction',
        situation: 'A client is senior in age or position.',
        whatYouMayEncounter: 'The conversation becomes friendly and informal.',
        recommendedResponse: 'Use the client\'s preferred form of address and maintain professional '
            'formality until a more informal style is clearly established.',
        avoid: 'Becoming over-familiar because the conversation becomes friendly.',
      ),
    ],
  ),
  GuideSection(
    title: 'Introductions & Small Talk',
    scenarios: [
      GuideScenario(
        heading: 'Self-Introduction',
        situation: 'You join a new team.',
        whatYouMayEncounter: 'Colleagues expect a brief, informal round of introductions.',
        recommendedResponse: 'Give a short introduction: current role, relevant experience and '
            'what you will focus on.',
        avoid: 'Giving a 10-minute service-history briefing.',
      ),
      GuideScenario(
        heading: 'Informal Conversation',
        situation: 'Colleagues are chatting before a meeting.',
        whatYouMayEncounter: 'The talk ranges across work, hobbies, travel and current events.',
        recommendedResponse: 'Participate naturally — work, hobbies, travel, current events, food '
            'and shared interests are common topics.',
        avoid: 'Turning every conversation into rank, posting or service comparisons.',
      ),
    ],
  ),
  GuideSection(
    title: 'Email Etiquette',
    scenarios: [
      GuideScenario(
        heading: 'Email to Senior Management',
        situation: 'You need a decision from the Business Head.',
        whatYouMayEncounter: 'There is a temptation to build up the full background first.',
        recommendedResponse: 'Lead with the issue, recommendation and decision required; provide '
            'supporting detail below.',
        avoid: 'Starting with several paragraphs of background.',
      ),
      GuideScenario(
        heading: 'Follow-Up',
        situation: 'Someone has not responded.',
        whatYouMayEncounter: 'The delay is becoming a problem for your own timeline.',
        recommendedResponse: 'Send a polite follow-up with the specific action and required date; '
            'escalate only when necessary.',
        avoid: 'Repeated "gentle reminders" with no context.',
      ),
      GuideScenario(
        heading: 'CC Usage',
        situation: 'A large number of people are copied.',
        whatYouMayEncounter: 'It is unclear who actually needs to see the thread.',
        recommendedResponse: 'Copy only people who need information, action or visibility.',
        avoid: 'CC-ing senior people to create pressure.',
      ),
      GuideScenario(
        heading: 'Reply All',
        situation: 'A group email does not require everyone to see your response.',
        whatYouMayEncounter: 'Reply All is the default button and easy to hit without thinking.',
        recommendedResponse: 'Reply only to the necessary people.',
        avoid: 'Replying to everyone for minor acknowledgements.',
      ),
    ],
  ),
  GuideSection(
    title: 'Teams / Slack / WhatsApp',
    scenarios: [
      GuideScenario(
        heading: 'Quick Question',
        situation: 'You need a simple clarification.',
        whatYouMayEncounter: 'The organisation has an approved messaging platform for this.',
        recommendedResponse: 'Use the organisation\'s approved messaging platform; keep it short '
            'and specific.',
        avoid: 'Sending fragmented one-word messages over several minutes.',
      ),
      GuideScenario(
        heading: 'After-Hours Message',
        situation: 'You think of a non-urgent question at 10:30 PM.',
        whatYouMayEncounter: 'Sending it now would be the natural instinct from service life.',
        recommendedResponse: 'Send it only if the norm allows and no immediate response is '
            'expected; schedule-send where available.',
        avoid: 'Creating an implied expectation of an immediate reply.',
      ),
      GuideScenario(
        heading: 'Emoji / Casual Tone',
        situation: 'Your team regularly uses informal messaging.',
        whatYouMayEncounter: 'The relaxed tone can make it tempting to relax everywhere.',
        recommendedResponse: 'Follow the team\'s tone while remaining professional.',
        avoid: 'Using humour or emojis in sensitive discussions.',
      ),
    ],
  ),
  GuideSection(
    title: 'Meetings',
    scenarios: [
      GuideScenario(
        heading: 'Joining Late',
        situation: 'You are delayed by another meeting.',
        whatYouMayEncounter: 'You feel the need to explain the delay to the room.',
        recommendedResponse: 'Join as soon as possible, mute on entry if appropriate and avoid a '
            'long public explanation.',
        avoid: 'Entering late and interrupting with an extended apology.',
      ),
      GuideScenario(
        heading: 'Speaking in a Meeting',
        situation: 'You have a point to add.',
        whatYouMayEncounter: 'Several people have already spoken at length.',
        recommendedResponse: 'Be concise: point → evidence → implication → recommendation.',
        avoid: 'Repeating what someone has already said.',
      ),
      GuideScenario(
        heading: 'Disagreement',
        situation: 'You disagree with a proposal.',
        whatYouMayEncounter: 'The disagreement needs to be raised in front of the group.',
        recommendedResponse: 'Challenge the idea, not the person. Example: "What evidence '
            'supports this assumption?"',
        avoid: '"That won\'t work" without a reason.',
      ),
      GuideScenario(
        heading: 'Action Items',
        situation: 'A meeting assigns you an action.',
        whatYouMayEncounter: 'The owner, deliverable or deadline is left slightly ambiguous.',
        recommendedResponse: 'Clarify owner, deliverable and deadline before leaving if there is '
            'any ambiguity.',
        avoid: 'Assuming "we will do it" means someone else owns it.',
      ),
    ],
  ),
  GuideSection(
    title: 'Virtual Meeting Etiquette',
    scenarios: [
      GuideScenario(
        heading: 'Camera / Background',
        situation: 'You join a video meeting from home.',
        whatYouMayEncounter: 'Your background, lighting and audio are all visible to the room.',
        recommendedResponse: 'Use camera when expected, maintain a professional background and '
            'check lighting/audio.',
        avoid: 'Joining from a distracting or inappropriate setting.',
      ),
      GuideScenario(
        heading: 'Microphone',
        situation: 'You are not speaking.',
        whatYouMayEncounter: 'Background noise can carry into the meeting unnoticed.',
        recommendedResponse: 'Stay muted when appropriate and monitor for accidental background '
            'noise.',
        avoid: 'Talking while muted or leaving an open mic.',
      ),
      GuideScenario(
        heading: 'Screen Sharing',
        situation: 'You are about to share your screen.',
        whatYouMayEncounter: 'Other tabs, windows or notifications may be visible once you share.',
        recommendedResponse: 'Close unrelated tabs/windows and verify what will be visible.',
        avoid: 'Exposing personal or confidential information.',
      ),
    ],
  ),
  GuideSection(
    title: 'Presentations',
    scenarios: [
      GuideScenario(
        heading: 'Executive Presentation',
        situation: 'You have 10 minutes with the leadership team.',
        whatYouMayEncounter: 'There is a lot of context you feel they need first.',
        recommendedResponse: 'Start with the conclusion and decision required, then evidence and '
            'detail.',
        avoid: 'Spending 8 minutes on history.',
      ),
      GuideScenario(
        heading: 'Questions',
        situation: 'A senior executive challenges your recommendation.',
        whatYouMayEncounter: 'You do not have the answer to the specific point raised.',
        recommendedResponse: 'Answer directly; if you do not know, say so and commit to finding '
            'out.',
        avoid: 'Deflecting or becoming defensive.',
      ),
    ],
  ),
  GuideSection(
    title: 'Workplace Behaviour',
    scenarios: [
      GuideScenario(
        heading: 'Open Office',
        situation: 'You are used to dedicated workspaces.',
        whatYouMayEncounter: 'Calls and conversations are easily overheard in an open layout.',
        recommendedResponse: 'Keep calls and conversations at a considerate volume; use meeting '
            'rooms when a discussion needs privacy.',
        avoid: 'Assuming your voice level is acceptable because it was normal in another '
            'environment.',
      ),
      GuideScenario(
        heading: 'Shared Workspace',
        situation: 'You leave your desk for a meeting.',
        whatYouMayEncounter: 'Documents and an unlocked screen are left behind at the desk.',
        recommendedResponse: 'Keep documents/screens secure and leave the workspace reasonably '
            'orderly.',
        avoid: 'Leaving sensitive papers visible.',
      ),
      GuideScenario(
        heading: 'Pantry / Common Area',
        situation: 'You meet colleagues informally.',
        whatYouMayEncounter: 'The relaxed setting makes conversation flow more freely.',
        recommendedResponse: 'Use it to build relationships, but respect personal space and '
            'professional boundaries.',
        avoid: 'Discussing confidential business issues in public areas.',
      ),
    ],
  ),
  GuideSection(
    title: 'Business Meals & Dining',
    scenarios: [
      GuideScenario(
        heading: 'Client Meal',
        situation: 'A client invites you to lunch.',
        whatYouMayEncounter: 'The conversation may drift toward business disagreements.',
        recommendedResponse: 'Observe the host, keep conversation balanced and remain mindful '
            'that it is a professional setting.',
        avoid: 'Turning the meal into a debate or discussing sensitive internal matters.',
      ),
      GuideScenario(
        heading: 'Alcohol',
        situation: 'Others order alcohol at a client dinner.',
        whatYouMayEncounter: 'There can be a perceived expectation to join in.',
        recommendedResponse: 'Follow your own judgement and company policy; never feel obliged '
            'to drink.',
        avoid: 'Assuming alcohol is part of professional networking.',
      ),
      GuideScenario(
        heading: 'Bill',
        situation: 'A business meal is ending.',
        whatYouMayEncounter: 'It is unclear who is expected to pay.',
        recommendedResponse: 'Follow the company\'s travel/expense policy and the host\'s lead.',
        avoid: 'Arguing over the bill in front of the client.',
      ),
    ],
  ),
  GuideSection(
    title: 'Networking & LinkedIn',
    scenarios: [
      GuideScenario(
        heading: 'Conference Introduction',
        situation: 'You meet someone useful but unfamiliar.',
        whatYouMayEncounter: 'The conversation is brief and the setting is casual.',
        recommendedResponse: 'Introduce yourself in one or two lines, ask about their work and '
            'follow up later with a short message.',
        avoid: 'Immediately asking for a job or favour.',
      ),
      GuideScenario(
        heading: 'LinkedIn Connection',
        situation: 'You want to connect after a meeting.',
        whatYouMayEncounter: 'LinkedIn\'s default request carries no context.',
        recommendedResponse: 'Mention where you met and why you would like to stay connected.',
        avoid: 'Sending a blank connection request to everyone you meet.',
      ),
    ],
  ),
  GuideSection(
    title: 'Client & Vendor Etiquette',
    scenarios: [
      GuideScenario(
        heading: 'Vendor Meeting',
        situation: 'A supplier is presenting an option.',
        whatYouMayEncounter: 'There is pressure to give a view on the spot.',
        recommendedResponse: 'Evaluate objectively; do not promise a decision on the spot unless '
            'you have the authority.',
        avoid: 'Making commitments outside your approval authority.',
      ),
      GuideScenario(
        heading: 'Client Complaint',
        situation: 'A client is unhappy.',
        whatYouMayEncounter: 'The instinct is to establish whose fault it was.',
        recommendedResponse: 'Listen, clarify the issue, acknowledge the impact and explain the '
            'next step.',
        avoid: 'Arguing about who was at fault.',
      ),
    ],
  ),
  GuideSection(
    title: 'Professional Boundaries',
    scenarios: [
      GuideScenario(
        heading: 'Personal Questions',
        situation: 'A colleague asks about age, family, salary or other private matters.',
        whatYouMayEncounter: 'The question is asked casually, without any ill intent.',
        recommendedResponse: 'Share only what you are comfortable sharing and redirect politely '
            'if necessary.',
        avoid: 'Assuming familiarity means everything is appropriate to discuss.',
      ),
      GuideScenario(
        heading: 'Humour',
        situation: 'A team uses banter.',
        whatYouMayEncounter: 'The tone invites you to join in without a clear sense of the line.',
        recommendedResponse: 'Keep humour inclusive and avoid jokes about protected '
            'characteristics, politics, religion, sexuality or personal circumstances.',
        avoid: 'Assuming service-style humour will be understood the same way everywhere.',
      ),
      GuideScenario(
        heading: 'Physical Contact',
        situation: 'A colleague uses a handshake or a more informal greeting.',
        whatYouMayEncounter: 'Greeting styles vary noticeably across colleagues.',
        recommendedResponse: 'Follow the local professional norm and respect personal boundaries.',
        avoid: 'Assuming everyone has the same comfort level.',
      ),
    ],
  ),
  GuideSection(
    title: 'Diversity & Inclusion',
    scenarios: [
      GuideScenario(
        heading: 'Different Work Styles',
        situation: 'A colleague communicates differently from you.',
        whatYouMayEncounter: 'The difference in style can read, at first, as a difference in '
            'competence.',
        recommendedResponse: 'Focus on outcomes, clarity and respect; adapt your communication '
            'without stereotyping.',
        avoid: 'Making assumptions about competence based on age, gender, region or background.',
      ),
      GuideScenario(
        heading: 'Language',
        situation: 'Colleagues are more comfortable in a different language.',
        whatYouMayEncounter: 'A group conversation naturally slips into that language.',
        recommendedResponse: 'Use the common professional language agreed by the team and ensure '
            'no colleague is unintentionally excluded.',
        avoid: 'Using a private language repeatedly in a group discussion.',
      ),
    ],
  ),
  GuideSection(
    title: 'Confidentiality & Social Media',
    scenarios: [
      GuideScenario(
        heading: 'Office Photograph',
        situation: 'You want to post a photograph taken at work.',
        whatYouMayEncounter: 'The photo looks harmless at a glance.',
        recommendedResponse: 'Follow company/social-media policy and ensure no confidential '
            'screens, documents, client data or restricted areas are visible.',
        avoid: 'Posting first and checking policy later.',
      ),
      GuideScenario(
        heading: 'Internal Information',
        situation: 'A friend asks about a confidential project.',
        whatYouMayEncounter: 'The question is framed as harmless curiosity.',
        recommendedResponse: 'Decline to share; professional trust includes discretion outside '
            'the office.',
        avoid: '"Off-the-record" disclosure.',
      ),
    ],
  ),
  GuideSection(
    title: 'Business Travel',
    scenarios: [
      GuideScenario(
        heading: 'Travelling With Colleagues',
        situation: 'You are travelling for a client meeting.',
        whatYouMayEncounter: 'The trip includes informal, social stretches of time.',
        recommendedResponse: 'Be punctual, professional and considerate; remember travel time is '
            'still workplace time.',
        avoid: 'Treating the trip as entirely social.',
      ),
    ],
  ),
  GuideSection(
    title: 'Gifts, Hospitality & Conflicts',
    scenarios: [
      GuideScenario(
        heading: 'Client Gift',
        situation: 'A client wants to give an expensive gift.',
        whatYouMayEncounter: 'Declining the gift may feel awkward in the moment.',
        recommendedResponse: 'Check company policy and declare/decline where required.',
        avoid: 'Accepting because "everyone does it."',
      ),
      GuideScenario(
        heading: 'Potential Conflict',
        situation: 'A vendor is recommended by a personal acquaintance.',
        whatYouMayEncounter: 'The connection feels minor and unrelated to the decision.',
        recommendedResponse: 'Disclose the relationship and follow procurement policy.',
        avoid: 'Hiding the relationship because it may appear minor.',
      ),
    ],
  ),
  GuideSection(
    title: 'First 30 Days Etiquette Checklist',
    scenarios: [
      GuideScenario(
        heading: 'Observation',
        situation: 'You do not know the local norm.',
        whatYouMayEncounter: 'Your old workplace had a clear norm for this situation.',
        recommendedResponse: 'Watch how experienced colleagues behave before adopting your own '
            'style.',
        avoid: 'Assuming your old workplace\'s norm applies.',
      ),
      GuideScenario(
        heading: 'Questions',
        situation: 'A process is unfamiliar.',
        whatYouMayEncounter: 'Asking feels like it might expose a gap in your knowledge.',
        recommendedResponse: 'Ask early and respectfully; it is better to clarify than to make '
            'an avoidable assumption.',
        avoid: 'Pretending to understand everything.',
      ),
      GuideScenario(
        heading: 'Feedback',
        situation: 'Someone suggests a change to your style.',
        whatYouMayEncounter: 'The feedback can land as a personal criticism at first.',
        recommendedResponse: 'Thank them, test whether the feedback is useful and adapt where '
            'appropriate.',
        avoid: 'Treating all feedback as criticism.',
      ),
    ],
  ),
  GuideSection(
    title: 'Practical Phrases That Work Well',
    translations: [
      GuideTranslation(from: 'Give me a brief.', to: 'Could you give me the two-minute version?'),
      GuideTranslation(from: 'What is the problem?', to: 'What is driving the issue?'),
      GuideTranslation(
        from: 'Do this.',
        to: 'Could you take this forward and confirm the timing?',
      ),
      GuideTranslation(from: 'I disagree.', to: 'I see it differently because…'),
      GuideTranslation(from: 'This is wrong.', to: 'Can we revisit this assumption?'),
      GuideTranslation(
        from: 'Why didn\'t you tell me?',
        to: 'What prevented this from being escalated earlier?',
      ),
      GuideTranslation(
        from: 'I don\'t know.',
        to: 'I don\'t have that information yet; I\'ll confirm and revert by…',
      ),
    ],
  ),
  GuideSection(
    title: 'The Professional Conduct Test',
    paragraphs: [
      'Before sending an email, making a comment, sharing information or reacting in a '
          'meeting, ask:',
    ],
    checklistItems: [
      'Would I be comfortable if this message were forwarded to my manager?',
      'Is this respectful and appropriate for the audience?',
      'Am I discussing information I am authorised to discuss?',
      'Am I challenging the idea or the person?',
      'Is this the right channel for the issue?',
      'Does my message make the required action or decision clear?',
    ],
  ),
  GuideSection(
    title: 'Final Reminder to the Transitioning Officer',
    paragraphs: [
      'You do not need to imitate corporate behaviour. You need to understand it. Your '
          'discipline, integrity, ability to work under pressure, ownership, planning and '
          'leadership remain valuable. The adjustment is mostly about language, context, '
          'informality, stakeholder management and the way authority is exercised.',
      'The aim of business etiquette is not to make you less direct or less decisive. It is '
          'to help your professionalism be interpreted in the new environment the way you '
          'intend it to be interpreted.',
    ],
    closingNote: 'Same Values. New Horizons.',
  ),
  GuideSection(
    title: 'Statutory Boundaries & Workplace Conduct',
    paragraphs: [
      'Some workplace conduct is not a matter of local norm or personal judgement — it is '
          'governed by law, and organisations are required to act on it. Knowing where these '
          'lines sit protects you, your colleagues and your organisation.',
    ],
    scenarios: [
      GuideScenario(
        heading: 'Witnessing or Experiencing Harassment (POSH)',
        situation: 'You witness or experience behaviour that may amount to workplace '
            'harassment.',
        whatYouMayEncounter: 'The behaviour may be framed by others as "just banter" or "how '
            'this team always is."',
        recommendedResponse: 'Every organisation with 10 or more employees is legally required '
            'to have an Internal Committee under the POSH Act. Report through that channel or '
            'to HR; do not rely on an informal word to the person involved to resolve it.',
        avoid: 'Staying silent because you are new, or handling it yourself outside the formal '
            'process.',
      ),
      GuideScenario(
        heading: 'Raising a Concern About Wrongdoing',
        situation: 'You become aware of conduct that may be unethical, unsafe or unlawful.',
        whatYouMayEncounter: 'Raising it may feel like it risks your standing as the newest '
            'person on the team.',
        recommendedResponse: 'Use the organisation\'s whistleblower or ethics-helpline channel; '
            'most listed and many private companies have one, and genuine reports made through '
            'it are protected from retaliation.',
        avoid: 'Ignoring it to avoid being seen as difficult in your first months.',
      ),
      GuideScenario(
        heading: 'Price-Sensitive Information',
        situation: 'Your role gives you access to unpublished financial results, an unannounced '
            'deal, or other information that could move the company\'s share price.',
        whatYouMayEncounter: 'A family member or friend asks what you make of the company\'s '
            'prospects.',
        recommendedResponse: 'Treat this as Unpublished Price Sensitive Information under '
            'insider-trading regulations: do not trade on it, and do not share it, even with '
            'family, until it is public.',
        avoid: 'Treating "I only mentioned it, I didn\'t trade" as a defence — sharing it is '
            'itself the violation.',
      ),
      GuideScenario(
        heading: 'A Personal Relationship Intersects With a Work Decision',
        situation: 'You are asked to evaluate, hire or approve a vendor, candidate or proposal '
            'connected to a friend, relative or former colleague.',
        whatYouMayEncounter: 'The connection feels irrelevant because you intend to be fully '
            'objective.',
        recommendedResponse: 'Declare the relationship to your manager or the designated '
            'conflict-of-interest process before proceeding, and let the organisation decide '
            'whether you should stay involved.',
        avoid: 'Deciding on your own that the connection is too minor to mention.',
      ),
    ],
    closingNote: 'These are not areas for personal judgement about what is "reasonable" — use '
        'the formal channel every time, even when you are confident you could resolve it '
        'informally.',
  ),
  GuideSection(
    title: 'Body Language & Vocal Presence',
    paragraphs: [
      'Command presence — a straight posture, a carrying voice, a directive tone — is trained '
          'into you for a setting where clarity under pressure can be a matter of safety. In '
          'an open office or on a video call, the same signals can read very differently: not '
          'as authority, but as intensity that puts people on edge.',
    ],
    scenarios: [
      GuideScenario(
        heading: 'Your Default Volume Carries Across the Room',
        situation: 'You are on a call at your desk in an open office, speaking at what feels '
            'like a completely normal volume to you.',
        whatYouMayEncounter: 'Colleagues nearby go quiet, or someone gently asks you to take '
            'the call in a booth.',
        recommendedResponse: 'Default to a noticeably lower volume than feels natural for the '
            'first few months, and move to a meeting room or booth for anything longer than a '
            'quick exchange.',
        avoid: 'Assuming your volume is fine because no one has said anything directly to you.',
      ),
      GuideScenario(
        heading: 'A Direct Tone Reads as an Order',
        situation: 'You give a colleague a short, clipped instruction the way you would to a '
            'subordinate on a task.',
        whatYouMayEncounter: 'The colleague responds stiffly, or a peer later mentions you '
            '"came in a bit strong."',
        recommendedResponse: 'Soften direction into a request with a stated reason: "Could you '
            'take this — it needs to go out by 3 PM" lands as collaborative where "Do this by '
            '3 PM" can land as an order.',
        avoid: 'Dismissing the feedback as people being "too sensitive."',
      ),
      GuideScenario(
        heading: 'On Video, Stillness Reads as Disengagement',
        situation: 'You sit upright, still and expressionless on a video call the way you would '
            'in a formal briefing.',
        whatYouMayEncounter: 'A colleague later asks if you were unhappy with something '
            'discussed in the meeting.',
        recommendedResponse: 'On camera, visible small reactions — a nod, a brief smile, leaning '
            'in — carry the engagement that a formal, still posture does not communicate '
            'through a screen.',
        avoid: 'Assuming your attention is obvious just because you are present and listening.',
      ),
    ],
    closingNote: 'None of this asks you to be less direct in substance — only to deliver it at '
        'a volume and tone the room can absorb as collaboration rather than command.',
  ),
];
