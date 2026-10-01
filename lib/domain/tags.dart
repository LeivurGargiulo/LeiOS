List<String> splitTags(String raw) =>
    raw.split(',').map((t) => t.trim()).where((t) => t.isNotEmpty).toList();

/// Trim, drop empties, de-duplicate case-insensitively (first spelling wins), join with ", ".
String normalizeTags(String raw) {
  final seen = <String>{};
  final out = <String>[];
  for (final t in splitTags(raw)) {
    if (seen.add(t.toLowerCase())) out.add(t);
  }
  return out.join(', ');
}

/// Empty [filter] matches everything; otherwise any tag containing [filter] (case-insensitive).
bool matchesTagFilter(String tags, String filter) {
  final f = filter.trim().toLowerCase();
  if (f.isEmpty) return true;
  return splitTags(tags).any((t) => t.toLowerCase().contains(f));
}

bool matchesSearch({required String title, required String content, required String query}) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return true;
  return title.toLowerCase().contains(q) || content.toLowerCase().contains(q);
}

/// Top [limit] tags across [tagStrings] (ordered newest-first by the caller).
/// Counts by lowercase key, keeps the first spelling seen, stable sort by count desc.
List<({String label, int count})> topTags(Iterable<String> tagStrings, {int limit = 5}) {
  final labels = <String, String>{};
  final counts = <String, int>{};
  final order = <String>[];
  for (final s in tagStrings) {
    for (final t in splitTags(s)) {
      final k = t.toLowerCase();
      if (!counts.containsKey(k)) {
        labels[k] = t;
        order.add(k);
      }
      counts[k] = (counts[k] ?? 0) + 1;
    }
  }
  final indexed = [for (var i = 0; i < order.length; i++) (i, order[i])];
  indexed.sort((a, b) {
    final c = counts[b.$2]!.compareTo(counts[a.$2]!);
    return c != 0 ? c : a.$1.compareTo(b.$1);
  });
  return [for (final e in indexed.take(limit)) (label: labels[e.$2]!, count: counts[e.$2]!)];
}

/// Strips common Markdown syntax for list previews.
String stripMarkdown(String md) {
  var s = md;
  s = s.replaceAll(RegExp(r'```[\s\S]*?```'), ' ');
  s = s.replaceAllMapped(RegExp(r'!?\[([^\]]*)\]\([^)]*\)'), (m) => m[1]!);
  s = s.replaceAll(RegExp(r'^\s{0,3}#{1,6}\s*', multiLine: true), '');
  s = s.replaceAll(RegExp(r'^\s*(>|[-*+]|\d+\.)\s+', multiLine: true), '');
  s = s.replaceAll(RegExp(r'[*_~`]+'), '');
  return s.replaceAll(RegExp(r'\s+'), ' ').trim();
}
