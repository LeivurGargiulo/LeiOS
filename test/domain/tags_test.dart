import 'package:flutter_test/flutter_test.dart';
import 'package:leios/domain/tags.dart';

void main() {
  test('normalizeTags dedupes case-insensitively keeping first spelling', () {
    expect(normalizeTags(' Work, work ,, Home,HOME , gym'), 'Work, Home, gym');
    expect(normalizeTags(''), '');
    expect(normalizeTags(' , ,'), '');
  });

  test('matchesTagFilter is a case-insensitive substring over any tag', () {
    expect(matchesTagFilter('Work, Home', ''), isTrue);
    expect(matchesTagFilter('Work, Home', 'ho'), isTrue);
    expect(matchesTagFilter('Work, Home', 'WORK'), isTrue);
    expect(matchesTagFilter('Work, Home', 'gym'), isFalse);
    expect(matchesTagFilter('', 'x'), isFalse);
  });

  test('matchesSearch checks title and content', () {
    expect(matchesSearch(title: 'Groceries', content: 'milk', query: ''), isTrue);
    expect(matchesSearch(title: 'Groceries', content: 'milk', query: 'GROC'), isTrue);
    expect(matchesSearch(title: 'Groceries', content: 'milk', query: 'Milk'), isTrue);
    expect(matchesSearch(title: 'Groceries', content: 'milk', query: 'eggs'), isFalse);
  });

  test('topTags counts by lowercase, first spelling, ties keep first-occurrence order', () {
    // newest first
    final r = topTags(['Calm, Work', 'work, tired', 'Tired, Sleep, Gym, Run, Read, Cook']);
    expect(r[0], (label: 'Work', count: 2));
    expect(r[1], (label: 'tired', count: 2)); // tie with Work, first seen later
    expect(r[2], (label: 'Calm', count: 1));
  });

  test('topTags tie-breaking is stable and limited to 5', () {
    final r = topTags(['a, b, c', 'd, e, f']);
    expect([for (final t in r) t.label], ['a', 'b', 'c', 'd', 'e']);
  });

  test('stripMarkdown removes syntax', () {
    expect(stripMarkdown('# Title\n\n**bold** and [link](http://x.y)\n- item'), 'Title bold and link item');
  });
}
