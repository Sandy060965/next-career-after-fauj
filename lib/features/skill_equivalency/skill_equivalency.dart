/// A military course, institution, or appointment mapped to its civilian
/// corporate equivalent. Fixed, curated content — every entry is either a
/// well-known, real defence training institution, or a role/responsibility
/// description rather than a guessed specialist course title, so nothing
/// here is invented.
class SkillEquivalency {
  const SkillEquivalency({
    required this.militaryTerm,
    required this.civilianEquivalent,
    required this.description,
    this.verified = true,
  });

  final String militaryTerm;
  final String civilianEquivalent;
  final String description;

  /// True for every entry corroborated by an official (.nic.in/.gov.in) or
  /// multiple independent sources during research. False flags an entry
  /// that's still a real, named course/institution but rests on a single,
  /// non-official source — shown to the officer as a caution, not hidden.
  final bool verified;
}

const List<SkillEquivalency> kSkillEquivalencies = [
  SkillEquivalency(
    militaryTerm: 'Defence Services Staff College (DSSC), Wellington',
    civilianEquivalent: 'Strategic Management & Cross-Functional Leadership',
    description:
        'The tri-service Staff Course is broadly comparable to an executive strategy '
        'programme — planning, joint operations, and cross-functional coordination at '
        'a scale similar to senior management roles.',
  ),
  SkillEquivalency(
    militaryTerm: 'National Defence College (NDC), New Delhi',
    civilianEquivalent: 'National/Corporate Strategy & Board-Level Advisory',
    description:
        'A senior-most strategic studies programme, comparable to the kind of '
        'national and organisational strategy work expected at board-advisory level.',
  ),
  SkillEquivalency(
    militaryTerm: 'Higher Command Course',
    civilianEquivalent: 'Advanced Executive Leadership (General Manager / VP level)',
    description:
        'Prepares officers to lead large, complex organisations — the closest civilian '
        'equivalent is executive leadership development for GM/VP-level general management.',
  ),
  SkillEquivalency(
    militaryTerm: 'Higher Defence Management Course, College of Defence Management (CDM)',
    civilianEquivalent: 'Organisational Strategy & Resource Management',
    description:
        'Covers management theory, resource optimisation, and organisational '
        'behaviour — directly transferable to corporate strategy and operations roles.',
  ),
  SkillEquivalency(
    militaryTerm: 'Command of a unit (Battalion / Regiment / Squadron / Ship)',
    civilianEquivalent: 'General Management / P&L & Operations Leadership',
    description:
        'End-to-end accountability for people, resources, discipline, and outcomes at '
        'unit scale maps directly to running a business unit or large operating team.',
  ),
  SkillEquivalency(
    militaryTerm: 'Instructional or Directing Staff appointment at a training establishment',
    civilianEquivalent: 'Learning & Development / Corporate Training Leadership',
    description:
        'Designing and delivering structured training programmes to adult learners is '
        'the core of a civilian L&D or corporate training role.',
  ),
  SkillEquivalency(
    militaryTerm: 'Logistics, Supply, or Maintenance appointment (EME / AOC / ASC / '
        'Naval Logistics / IAF Maintenance)',
    civilianEquivalent: 'Supply Chain & Operations Management',
    description:
        'Managing inventory, procurement, fleet/equipment readiness, and distribution '
        'under operational constraints is directly comparable to civilian supply chain '
        'and operations roles.',
  ),
  SkillEquivalency(
    militaryTerm: 'Corps of Engineers project or works appointment',
    civilianEquivalent: 'Infrastructure & Project Management',
    description:
        'Planning and executing construction, infrastructure, or works projects to '
        'deadline and budget maps to civilian project and infrastructure management.',
  ),
  SkillEquivalency(
    militaryTerm: 'Signals, Communications, or IT appointment',
    civilianEquivalent: 'IT Infrastructure & Telecom Systems Management',
    description:
        'Running communications networks and systems under operational demands is '
        'directly relevant to civilian IT infrastructure and telecom operations roles.',
  ),
  SkillEquivalency(
    militaryTerm: 'Adjutant or Administration appointment',
    civilianEquivalent: 'HR & Administration Management',
    description:
        'Personnel administration, discipline, welfare, and unit records management is '
        'close to civilian HR operations and administration leadership.',
  ),
  SkillEquivalency(
    militaryTerm: 'Intelligence or Security appointment',
    civilianEquivalent: 'Corporate Security, Risk & Investigations',
    description:
        'Threat assessment, information verification, and security planning transfer '
        'directly to corporate security, risk, and investigations roles.',
  ),
  SkillEquivalency(
    militaryTerm: 'Aide-de-Camp or Personal Staff Officer to senior leadership',
    civilianEquivalent: 'Chief of Staff / Executive Assistant to a CXO',
    description:
        'Coordinating a senior leader\'s priorities, communications, and schedule '
        'across a large organisation is close to a Chief of Staff or senior EA role.',
  ),

  // --- Army: arm-specific specialist courses ---------------------------
  SkillEquivalency(
    militaryTerm: "Young Officers' Course (Infantry), Infantry School, Mhow",
    civilianEquivalent: 'Frontline Team Leadership & Operational Readiness',
    description:
        'First institutional leadership and tactical training for a newly commissioned '
        'officer — comparable to a structured graduate leadership programme for a '
        'first-line manager.',
  ),
  SkillEquivalency(
    militaryTerm: "Young Officers' Course (Armoured Corps), Armoured Corps Centre & School, "
        'Ahmednagar',
    civilianEquivalent: 'Technical Equipment Operations Leadership',
    description:
        'A six-month course in armoured vehicle systems and small-team tactical command — '
        'maps to leading a technical operations team responsible for complex machinery.',
  ),
  SkillEquivalency(
    militaryTerm: 'Long Gunnery Staff Course, School of Artillery, Deolali',
    civilianEquivalent: 'Advanced Technical Specialisation & Instructor Certification',
    description:
        'A 48-week advanced technical-tactical course producing gunnery instructors and '
        'staff officers — comparable to a specialist engineering certification combined '
        'with train-the-trainer credentialing.',
  ),
  SkillEquivalency(
    militaryTerm: 'Advance Air Defence Course, Army Air Defence College, Gopalpur',
    civilianEquivalent: 'Advanced Systems Operations & Threat Detection',
    description:
        'A 13-week advanced course on radar, gun, and missile air-defence systems — maps '
        'to advanced technical operations and real-time threat/anomaly detection roles.',
    verified: false,
  ),
  SkillEquivalency(
    militaryTerm: 'Young Officer Course (Combat Engineers), College of Military Engineering, '
        'Pune',
    civilianEquivalent: 'Infrastructure & Field Engineering Leadership',
    description:
        'Platoon-commander readiness training for combat engineers — early-career '
        'infrastructure and field-engineering leadership, comparable to a project '
        'engineer leading site teams.',
  ),
  SkillEquivalency(
    militaryTerm: 'Regimental Signaller Officers Course, Military College of Telecommunication '
        'Engineering (MCTE), Mhow',
    civilianEquivalent: 'Communications & IT Systems Leadership',
    description:
        'Communications and IT officer training at the Corps of Signals\' technical college '
        '— maps to leading a communications/IT infrastructure team.',
    verified: false,
  ),
  SkillEquivalency(
    militaryTerm: 'Officers Transport Management / Advance Supply Chain Management & Food '
        'Technology Course, ASC Centre & College, Bengaluru',
    civilianEquivalent: 'Supply Chain, Fleet & Logistics Management',
    description:
        'Transport, supply-chain, and food-technology management training for Army '
        'Service Corps officers — directly comparable to civilian supply chain and fleet '
        'management roles.',
  ),
  SkillEquivalency(
    militaryTerm: 'Military College of Materials Management, Jabalpur (Army Ordnance Corps)',
    civilianEquivalent: 'Materials & Inventory Management',
    description:
        'Ordnance and materials-management training — quartermaster and higher munition '
        'courses map to civilian inventory, procurement, and materials management roles.',
  ),
  SkillEquivalency(
    militaryTerm: 'Intelligence Staff Course, Military Intelligence Training School and Depot '
        '(MINTSD), Pune',
    civilianEquivalent: 'Business Intelligence & Risk Analysis',
    description:
        'Intelligence staff duties at formation-headquarters level, comparable in rigour '
        'to a staff college course — maps to corporate business intelligence, competitive '
        'analysis, and enterprise risk roles.',
  ),
  SkillEquivalency(
    militaryTerm: 'Officers Provost Course, Corps of Military Police (CMP) Centre & School, '
        'Bengaluru',
    civilianEquivalent: 'Corporate Security & Compliance Management',
    description:
        'Military policing duties and investigation training — maps to corporate '
        'security, compliance, and internal investigations leadership.',
  ),
  SkillEquivalency(
    militaryTerm: 'Army Education Corps Training College & Centre (AECTCC), Pachmarhi',
    civilianEquivalent: 'Learning & Development / Training Design',
    description:
        'Designing and delivering structured education programmes across the Army — maps '
        'directly to civilian L&D, instructional design, and corporate training roles.',
  ),
  SkillEquivalency(
    militaryTerm: 'Remount & Veterinary Corps (RVC) Centre & College, Meerut',
    civilianEquivalent: 'Specialist Technical/Veterinary Operations Management',
    description:
        'Military veterinary practice and animal-management training — maps to '
        'specialist operations management in veterinary, agritech, or livestock sectors.',
    verified: false,
  ),

  // --- Army: specialised warfare schools --------------------------------
  SkillEquivalency(
    militaryTerm: 'High Altitude Warfare School (HAWS), Gulmarg',
    civilianEquivalent: 'Extreme-Environment Operations & Resilience Leadership',
    description:
        'High-altitude combat, mountaineering, and avalanche-rescue training — maps to '
        'leading teams safely through extreme-environment or high-risk field operations.',
  ),
  SkillEquivalency(
    militaryTerm: 'Unconventional Warfare Course, Counter Insurgency and Jungle Warfare '
        'School (CIJWS), Vairengte',
    civilianEquivalent: 'Adaptive Threat Response & Red-Teaming',
    description:
        'Guerrilla-warfare and asymmetric-threat response training — comparable to red-'
        'team/adversarial-thinking roles in corporate security and risk.',
  ),
  SkillEquivalency(
    militaryTerm: 'Low Intensity Conflict Operations (LICO) Course, Counter Insurgency and '
        'Jungle Warfare School (CIJWS), Vairengte',
    civilianEquivalent: 'Crisis & Complex-Environment Operations Management',
    description:
        'Counter-insurgency and low-intensity-conflict operations training — maps to '
        'managing operations in volatile, high-stakes, or unpredictable environments.',
  ),
  SkillEquivalency(
    militaryTerm: 'Basic Parachute Course, Paratroopers Training School (PTS), Agra',
    civilianEquivalent: 'High-Risk Operations Readiness',
    description:
        'Static-line parachute qualification — a recognised marker of trained readiness '
        'for high-risk operational roles.',
  ),
  SkillEquivalency(
    militaryTerm: 'Special Forces Training School (SFTS), Bakloh',
    civilianEquivalent: 'Elite Small-Team Leadership & Mission Planning',
    description:
        'Small-squad operations, demolitions, and mission-critical training for special '
        'forces — maps to high-performance, high-accountability team leadership roles.',
  ),

  // --- Navy ---------------------------------------------------------------
  SkillEquivalency(
    militaryTerm: 'Naval Higher Command Course (NHCC), Naval War College, Goa',
    civilianEquivalent: 'Strategic Maritime/Enterprise Leadership',
    description:
        'Strategic and operational leadership for senior naval officers, awarding an '
        'MPhil via the University of Mumbai — comparable to senior executive leadership '
        'development.',
  ),
  SkillEquivalency(
    militaryTerm: 'Marine Engineering Specialisation Course (MESC), INS Shivaji, Lonavala',
    civilianEquivalent: 'Marine/Mechanical Engineering Management',
    description:
        'Marine engineering specialisation for Navy engineer-branch officers — maps to '
        'engineering management roles in maritime, shipping, or heavy-machinery sectors.',
  ),
  SkillEquivalency(
    militaryTerm: 'Electrical Specialisation Course, INS Valsura, Jamnagar',
    civilianEquivalent: 'Electrical/Electronics Systems Management',
    description:
        'Electrical and electronics engineering specialisation for Navy officers — maps '
        'directly to civilian electrical/electronics systems management roles.',
  ),
  SkillEquivalency(
    militaryTerm: 'Gunnery Instructor (GI) Course, INS Dronacharya, Kochi',
    civilianEquivalent: 'Technical Instruction & Systems Training Leadership',
    description:
        'Gunnery, missile-systems, and instructor training for the Navy\'s executive '
        'branch — maps to technical training leadership roles.',
  ),
  SkillEquivalency(
    militaryTerm: 'Naval aviation ab-initio training, INS Garuda, Kochi',
    civilianEquivalent: 'Aviation Operations Management',
    description:
        'Pilot, observer, and aviation-technical officer training — maps to civilian '
        'aviation operations and flight-safety management roles.',
    verified: false,
  ),
  SkillEquivalency(
    militaryTerm: 'Basic Submarine Course / Commanding Officers\' Qualifying Course (COQC), '
        'INS Satavahana, Visakhapatnam',
    civilianEquivalent: 'High-Stakes Systems Command & Safety Leadership',
    description:
        'Ab-initio submarine training through command-level qualification in a confined, '
        'zero-margin-for-error environment — maps to safety-critical operations command.',
  ),

  // --- Air Force ------------------------------------------------------
  SkillEquivalency(
    militaryTerm: 'Air Force Academy training (Flying / Ground Duty), Dundigal, Hyderabad',
    civilianEquivalent: 'Aviation/Technical Leadership Development',
    description:
        'Ab-initio officer and flying/technical training — the foundational leadership '
        'and technical development programme for IAF officers.',
  ),
  SkillEquivalency(
    militaryTerm: 'Higher Air Command Course (HACC), College of Air Warfare, Secunderabad',
    civilianEquivalent: 'Joint/Cross-Functional Strategic Leadership',
    description:
        'Joint warfare and air-power employment training for tri-service attendees — '
        'maps to senior cross-functional strategy and leadership roles.',
  ),
  SkillEquivalency(
    militaryTerm: 'Aeronautical Engineering Course, Air Force Technical College, Bengaluru',
    civilianEquivalent: 'Aerospace/Aeronautical Engineering Management',
    description:
        'Aeronautical, electronics, and propulsion engineering training awarding an '
        'M.Tech — maps directly to aerospace engineering management roles.',
  ),
  SkillEquivalency(
    militaryTerm: 'Experimental Flight Test Course, ASTE / IAF Test Pilots School, Bengaluru',
    civilianEquivalent: 'Product Test Engineering & Certification Leadership',
    description:
        'One of only eight globally recognised test-pilot schools — flight-test '
        'engineering and certification training that maps to senior product test/'
        'certification engineering roles.',
  ),
  SkillEquivalency(
    militaryTerm: 'Basic/Advanced Professional Knowledge Course (Officers), Air Force '
        'Administrative College, Coimbatore',
    civilianEquivalent: 'Business Administration & Operations Management',
    description:
        'Administrative and staff training for in-service IAF officers — maps to '
        'civilian business administration and operations management roles.',
  ),
  SkillEquivalency(
    militaryTerm: 'Qualified Flying Instructor (QFI) training, Flying Instructors School '
        '(FIS), Tambaram',
    civilianEquivalent: 'Train-the-Trainer / Instructional Leadership',
    description:
        'Trains instructor pilots across the IAF, Army, Navy, and Coast Guard — a direct '
        'match for train-the-trainer and instructional-design leadership roles.',
  ),
  SkillEquivalency(
    militaryTerm: 'Helicopter pilot/instructor training, Helicopter Training School (HTS), '
        'Hakimpet',
    civilianEquivalent: 'Specialist Aviation Operations & Safety Training',
    description:
        'Asia\'s largest helicopter training school — basic, advanced, and instructor-'
        'level flying and search-and-rescue training, mapping to specialist aviation '
        'operations and safety-training leadership.',
  ),
];
