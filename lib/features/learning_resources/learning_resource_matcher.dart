import '../../core/models/learning_resource.dart';
import 'learning_resources_data.dart';

/// Matches free-text Gap Roadmap items to catalogue entries by counting how
/// many of a resource's [LearningResource.tags] appear (case-insensitive,
/// substring) in [searchText] — deterministic, no LLM call, and never
/// surfaces a resource with zero actual tag overlap.
List<LearningResource> matchResourcesForGap(String searchText, {int limit = 3}) {
  final haystack = searchText.toLowerCase();

  final scored = <(LearningResource, int)>[];
  for (final resource in kLearningResources) {
    final score = resource.tags.where((tag) => haystack.contains(tag.toLowerCase())).length;
    if (score > 0) scored.add((resource, score));
  }

  scored.sort((a, b) => b.$2.compareTo(a.$2));
  return [for (final (resource, _) in scored.take(limit)) resource];
}
