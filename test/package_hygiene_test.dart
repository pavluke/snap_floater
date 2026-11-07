import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Static checks over the repository files (docs, pubspec, changelog,
/// example). `flutter test` runs with the package root as cwd.
String read(String path) => File(path).readAsStringSync();

void main() {
  final readme = read('README.md');
  final pubspec = read('pubspec.yaml');
  final changelog = read('CHANGELOG.md');

  group('README <-> code', () {
    test(
      '[#13] SnapFloaterScope.builder example uses the real parameter name',
      () {
        expect(
          readme,
          isNot(contains('buttonBuilder')),
          reason:
              'the factory parameter is `builder`, so the README example '
              'and API table do not compile',
        );
      },
    );

    test('[#13] every named argument in README builder examples exists', () {
      final scopeSrc = read('lib/src/view/widgets/snap_floater_scope.dart');
      final factory = RegExp(
        r'factory SnapFloaterScope\.builder\(\{(.*?)\}\)',
        dotAll: true,
      ).firstMatch(scopeSrc)!.group(1)!;
      final real = RegExp(
        r'\b(\w+),',
      ).allMatches(factory).map((m) => m.group(1)!).toSet();

      final usage = RegExp(
        r'SnapFloaterScope\.builder\(\s*(?:\n\s*)?(\w+):',
      ).allMatches(readme).map((m) => m.group(1)!);

      for (final arg in usage) {
        expect(real, contains(arg), reason: 'README uses `$arg:`');
      }
    });

    test('[misc] README install snippet matches the pubspec version', () {
      final pub = RegExp(
        r'^version:\s*(\d+)\.(\d+)\.',
        multiLine: true,
      ).firstMatch(pubspec)!;
      final doc = RegExp(
        r'snap_floater:\s*\^(\d+)\.(\d+)\.',
      ).firstMatch(readme)!;
      expect(
        '${doc.group(1)}.${doc.group(2)}',
        '${pub.group(1)}.${pub.group(2)}',
        reason: 'caret on 0.x pins the minor version',
      );
    });

    test('README documents every SnapFloaterSettings field', () {
      for (final field in [
        'snapAlignments',
        'isEnabled',
        'showPreview',
        'storage',
        'dragMode',
      ]) {
        expect(readme, contains('`$field`'));
      }
    });
  });

  group('pubspec', () {
    test('[misc] homepage and repository are not duplicates', () {
      final home = RegExp(
        r'^homepage:\s*(\S+)',
        multiLine: true,
      ).firstMatch(pubspec)?.group(1);
      final repo = RegExp(
        r'^repository:\s*(\S+)',
        multiLine: true,
      ).firstMatch(pubspec)?.group(1);
      expect(home == null || home != repo, isTrue);
    });

    test('[misc] declares a minimum Flutter version', () {
      final env = RegExp(
        r'environment:\s*\n((?:[ \t]+.*\n?)+)',
      ).firstMatch(pubspec)!.group(1)!;
      expect(
        env,
        contains('flutter:'),
        reason: 'example/ uses Row(spacing:) (Flutter 3.27+)',
      );
    });

    test('[misc] SDK lower bound supports dot-shorthands used in the docs', () {
      final usesShorthand = Directory('lib')
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'))
          .any(
            (f) => f
                .readAsLinesSync()
                .where((l) => l.trimLeft().startsWith('///'))
                .any(
                  (l) =>
                      RegExp(r'///\s+\.(bottom|top|center)\w*,?$').hasMatch(l),
                ),
          );
      final sdk = RegExp(r'sdk:\s*"?>=(\d+)\.(\d+)').firstMatch(pubspec)!;
      final min = int.parse(sdk.group(1)!) * 100 + int.parse(sdk.group(2)!);
      if (usesShorthand) {
        expect(
          min,
          greaterThanOrEqualTo(310),
          reason: 'dot-shorthands need Dart 3.10',
        );
      }
    });
  });

  group('CHANGELOG', () {
    test('[misc] uses a single list marker', () {
      final markers = RegExp(
        r'^([*-])\s',
        multiLine: true,
      ).allMatches(changelog).map((m) => m.group(1)!).toSet();
      expect(markers, hasLength(1), reason: 'found $markers');
    });

    test('[misc] top entry matches the pubspec version', () {
      final pub = RegExp(
        r'^version:\s*(\S+)',
        multiLine: true,
      ).firstMatch(pubspec)!.group(1);
      final top = RegExp(
        r'^##\s*(\S+)',
        multiLine: true,
      ).firstMatch(changelog)!.group(1);
      expect(top, pub);
    });
  });

  group('file naming', () {
    test('[misc] snap_floater_state.dart is spelled correctly', () {
      expect(
        File('lib/src/models/shap_floater_state.dart').existsSync(),
        isFalse,
        reason: '"shap" is a typo of "snap"',
      );
      expect(
        File('lib/src/models/snap_floater_state.dart').existsSync(),
        isTrue,
      );
    });
  });

  group('example app', () {
    final home = read('example/lib/home_screen.dart');
    final app = read('example/lib/app.dart');

    test('[misc] home_screen has no dead removeListener after early return', () {
      expect(
        RegExp(
          r'if \(_controller != null\) return;\s*_controller\?\.removeListener',
        ).hasMatch(home),
        isFalse,
      );
    });

    test('[misc] wrapper widget has a descriptive name', () {
      expect(app, isNot(contains('class NewWidget')));
    });

    test('[misc] no redundant `child ?? const HomeScreen()` fallback', () {
      expect(app, isNot(contains('child ?? const HomeScreen()')));
    });
  });
}
