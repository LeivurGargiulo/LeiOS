import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// User-facing text must live in `lib/l10n/app_en.arb`, not in widget code. This is a plain
/// grep over the UI folders: it flags a string literal containing letters passed to `Text(...)`,
/// to a user-visible named argument (`labelText:`, `tooltip:`, `title:` ...) or as a ternary branch
/// inside those. Interpolations (`$x`, `${...}`) are ignored.
const _dirs = ['lib/features', 'lib/core/widgets'];

const _args = 'labelText|hintText|helperText|errorText|tooltip|semanticLabel|semanticsLabel|label|title|body|message|confirmLabel|content';
const _str = r"'((?:\$\{[^}]*\}|[^'\\]|\\.)*)'";

final _patterns = <RegExp>[
  RegExp('\\b(?:Text|SelectableText|SectionHeader)\\(\\s*(?:const\\s+)?$_str'),
  RegExp('\\b(?:$_args)\\s*:\\s*(?:const\\s+)?(?:Text\\(\\s*)?$_str'),
  // Ternary branches: Text(c ? 'A' : 'B'), label: c ? 'A' : 'B'
  RegExp('\\b(?:Text\\(|(?:$_args)\\s*:)[^;]*?\\?\\s*$_str\\s*:\\s*$_str'),
];

final _interpolation = RegExp(r'\$\{[^}]*\}|\$\w+');

/// Literals that are intentionally not translated: `file:literal`.
const _allowlist = <String>{};

void main() {
  test('no inline user-facing English literals in lib/features or lib/core/widgets', () {
    final offenders = <String>[];
    for (final dir in _dirs) {
      for (final f in Directory(dir).listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart'))) {
        final path = f.path.replaceAll('\\', '/');
        final lines = f.readAsLinesSync();
        for (var i = 0; i < lines.length; i++) {
          final line = lines[i];
          final t = line.trimLeft();
          if (t.startsWith('//') || t.startsWith('import ') || t.startsWith('export ')) continue;
          for (final p in _patterns) {
            for (final m in p.allMatches(line)) {
              for (var g = 1; g <= m.groupCount; g++) {
                final lit = m.group(g) ?? '';
                if (!RegExp('[A-Za-z]').hasMatch(lit.replaceAll(_interpolation, ''))) continue;
                if (_allowlist.contains('$path:$lit')) continue;
                offenders.add('$path:${i + 1}: \'$lit\'');
              }
            }
          }
        }
      }
    }
    expect(offenders.toSet().toList(), isEmpty, reason: 'Move these into lib/l10n/app_en.arb and use L10n.of(context):\n${offenders.join('\n')}');
  });
}
