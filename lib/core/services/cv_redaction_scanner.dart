/// A lightweight, client-side flag-and-confirm scan over a .docx CV's
/// extracted text — regex + a curated dictionary, never a silent auto-
/// redaction. Onboarding already warns officers not to include ACR/service-
/// record content; this is a safety net for what slips through anyway.
///
/// Deliberately doesn't cover PDFs — PDFs are sent to Claude as raw bytes,
/// never extracted client-side, so there's no local text to scan.
enum RedactionCategory { serviceNumber, email, phone, aadhaar, pan, militaryUnit }

extension RedactionCategoryLabel on RedactionCategory {
  String get label => switch (this) {
        RedactionCategory.serviceNumber => 'Service number',
        RedactionCategory.email => 'Email address',
        RedactionCategory.phone => 'Phone number',
        RedactionCategory.aadhaar => 'Aadhaar-like number',
        RedactionCategory.pan => 'PAN-like number',
        RedactionCategory.militaryUnit => 'Unit / formation term',
      };
}

/// One unique flagged string, deduplicated across all its occurrences —
/// [count] and [context] describe the first match so the officer can judge
/// it without seeing every repeat.
class RedactionMatch {
  const RedactionMatch({
    required this.category,
    required this.text,
    required this.count,
    required this.context,
  });

  final RedactionCategory category;
  final String text;
  final int count;
  final String context;
}

// Real, well-known Indian Army unit/formation terminology — never invented.
// Kept to terms that rarely appear in ordinary civilian CV prose, so the
// review list stays short and worth reading rather than noisy.
const _militaryUnitTerms = [
  'Battalion',
  'Bn',
  'Regiment',
  'Squadron',
  'Sqn',
  'Coy',
  'Bde',
  'Brigade',
  'Rashtriya Rifles',
  'Para SF',
  'Siachen',
  'Field Regiment',
  'Infantry Battalion',
  'Armoured Regiment',
  'Artillery Regiment',
  'Mountain Division',
  'Strike Corps',
  'Formation Headquarters',
  'Unit Headquarters',
];

final _patterns = <RedactionCategory, RegExp>{
  // Officer/JCO service number formats, e.g. "IC-12345", "SS 67890".
  RedactionCategory.serviceNumber: RegExp(r'\b(?:IC|SS|EC|JC|NC)[\s-]?\d{4,8}\b', caseSensitive: false),
  // Each dot-segment of the domain must be followed by a word character, so
  // a sentence-ending period right after the address isn't swallowed in.
  RedactionCategory.email: RegExp(r'[\w.+-]+@[\w-]+(?:\.[\w-]+)+'),
  RedactionCategory.phone: RegExp(r'(?:\+?91[\s-]?)?[6-9]\d{9}\b'),
  RedactionCategory.aadhaar: RegExp(r'\b\d{4}\s?\d{4}\s?\d{4}\b'),
  RedactionCategory.pan: RegExp(r'\b[A-Z]{5}\d{4}[A-Z]\b'),
};

String _contextAround(String text, int start, int end) {
  const radius = 20;
  final from = (start - radius).clamp(0, text.length);
  final to = (end + radius).clamp(0, text.length);
  return text.substring(from, to).replaceAll('\n', ' ').trim();
}

List<RedactionMatch> scanForRedactions(String text) {
  final byKey = <String, ({RedactionCategory category, String text, int count, String context})>{};

  void record(RedactionCategory category, RegExpMatch match) {
    final matched = match.group(0)!;
    // Dedup case-insensitively (e.g. "Battalion" and "battalion" are the
    // same flagged term) — display keeps whichever casing was seen first.
    final key = '${category.name}::${matched.toLowerCase()}';
    final existing = byKey[key];
    if (existing == null) {
      byKey[key] = (
        category: category,
        text: matched,
        count: 1,
        context: _contextAround(text, match.start, match.end),
      );
    } else {
      byKey[key] = (
        category: existing.category,
        text: existing.text,
        count: existing.count + 1,
        context: existing.context,
      );
    }
  }

  for (final entry in _patterns.entries) {
    for (final match in entry.value.allMatches(text)) {
      record(entry.key, match);
    }
  }
  for (final term in _militaryUnitTerms) {
    final pattern = RegExp(r'\b' + RegExp.escape(term) + r'\b', caseSensitive: false);
    for (final match in pattern.allMatches(text)) {
      record(RedactionCategory.militaryUnit, match);
    }
  }

  return byKey.values
      .map((e) => RedactionMatch(category: e.category, text: e.text, count: e.count, context: e.context))
      .toList();
}

/// Replaces every occurrence of each string in [textsToRedact] with a
/// placeholder — applied only to strings the officer explicitly confirmed.
String applyRedactions(String text, Set<String> textsToRedact) {
  var result = text;
  for (final t in textsToRedact) {
    // Case-insensitive to match scanForRedactions' case-insensitive
    // dedup/count — a checked "Battalion" (3 occurrences) must redact all
    // 3 even if some appeared in different casing.
    result = result.replaceAll(RegExp(RegExp.escape(t), caseSensitive: false), '[REDACTED]');
  }
  return result;
}
