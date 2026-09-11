import 'package:flutter_test/flutter_test.dart';
import 'package:next_career_after_fauj/features/learning_resources/learning_resource_matcher.dart';
import 'package:next_career_after_fauj/features/learning_resources/learning_resources_data.dart';

void main() {
  group('matchResourcesForGap', () {
    test('finds a resource by an exact tag hit', () {
      final matches = matchResourcesForGap('PMP certification');
      expect(matches.map((r) => r.id), contains('pmi-pmp'));
    });

    test('is case-insensitive', () {
      final lower = matchResourcesForGap('power bi dashboards');
      final upper = matchResourcesForGap('POWER BI DASHBOARDS');
      expect(upper.map((r) => r.id).toSet(), lower.map((r) => r.id).toSet());
      expect(lower, isNotEmpty);
    });

    test('returns an empty list when nothing matches', () {
      expect(matchResourcesForGap('completely unrelated gibberish xyz123'), isEmpty);
    });

    test('ranks a resource with more tag hits above one with fewer', () {
      final matches = matchResourcesForGap('generative ai prompting chatgpt', limit: 20);
      expect(matches, isNotEmpty);

      int scoreOf(String id) {
        final resource = kLearningResources.firstWhere((r) => r.id == id);
        return resource.tags
            .where((t) => 'generative ai prompting chatgpt'.contains(t.toLowerCase()))
            .length;
      }

      for (var i = 0; i < matches.length - 1; i++) {
        expect(scoreOf(matches[i].id), greaterThanOrEqualTo(scoreOf(matches[i + 1].id)));
      }
    });

    test('respects the limit parameter', () {
      final matches = matchResourcesForGap('ai generative learning course free', limit: 2);
      expect(matches.length, lessThanOrEqualTo(2));
    });
  });
}
