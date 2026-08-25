import 'package:flutter_test/flutter_test.dart';
import 'package:next_career_after_fauj/core/services/cv_redaction_scanner.dart';

void main() {
  group('scanForRedactions', () {
    test('flags a service number', () {
      final matches = scanForRedactions('Contact: IC-45678, previously served with distinction.');
      expect(matches.any((m) => m.category == RedactionCategory.serviceNumber && m.text == 'IC-45678'),
          isTrue);
    });

    test('flags an email address', () {
      final matches = scanForRedactions('Reach me at officer.name@example.com for details.');
      expect(
        matches.any((m) => m.category == RedactionCategory.email && m.text == 'officer.name@example.com'),
        isTrue,
      );
    });

    test('flags a 10-digit Indian mobile number', () {
      final matches = scanForRedactions('Mobile: 9876543210');
      expect(matches.any((m) => m.category == RedactionCategory.phone && m.text == '9876543210'), isTrue);
    });

    test('flags an Aadhaar-shaped 12-digit number', () {
      final matches = scanForRedactions('ID: 1234 5678 9012');
      expect(matches.any((m) => m.category == RedactionCategory.aadhaar), isTrue);
    });

    test('flags a PAN-shaped code', () {
      final matches = scanForRedactions('PAN: ABCDE1234F on file.');
      expect(matches.any((m) => m.category == RedactionCategory.pan && m.text == 'ABCDE1234F'), isTrue);
    });

    test('flags military unit terms case-insensitively', () {
      final matches = scanForRedactions('Commanded an infantry battalion in a mountain division.');
      expect(matches.any((m) => m.category == RedactionCategory.militaryUnit && m.text == 'battalion'),
          isTrue);
      expect(
        matches.any((m) => m.category == RedactionCategory.militaryUnit && m.text == 'mountain division'),
        isTrue,
      );
    });

    test('deduplicates repeated occurrences into one match with a count', () {
      final matches = scanForRedactions('Battalion strength. The battalion moved. Battalion HQ.');
      final battalionMatches =
          matches.where((m) => m.category == RedactionCategory.militaryUnit && m.text.toLowerCase() == 'battalion');
      expect(battalionMatches, hasLength(1));
      expect(battalionMatches.single.count, 3);
    });

    test('does not flag ordinary civilian CV prose', () {
      final matches = scanForRedactions(
        'Led the Operations division of a manufacturing company, managing a team of 40.',
      );
      // "division" and "company" alone are not in the curated dictionary.
      expect(matches, isEmpty);
    });

    test('returns no matches for clean text', () {
      expect(scanForRedactions('Experienced operations leader with a strong record.'), isEmpty);
    });
  });

  group('applyRedactions', () {
    test('replaces every occurrence of a checked string', () {
      const text = 'Battalion strength was high. The Battalion moved out.';
      final result = applyRedactions(text, {'Battalion'});
      expect(result, 'REDACTED strength was high. The REDACTED moved out.'.replaceAll('REDACTED', '[REDACTED]'));
    });

    test('leaves unchecked strings untouched', () {
      const text = 'Contact officer.name@example.com or call 9876543210.';
      final result = applyRedactions(text, {'officer.name@example.com'});
      expect(result, contains('[REDACTED]'));
      expect(result, contains('9876543210'));
    });

    test('is a no-op when nothing is checked', () {
      const text = 'Some CV text with IC-12345 in it.';
      expect(applyRedactions(text, {}), text);
    });
  });
}
