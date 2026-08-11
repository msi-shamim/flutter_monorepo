import 'dart:io';

import 'package:test/test.dart';

/// End-to-end verification that the tool produces a project that runs.
///
/// The unit suite asserts on template strings, which cannot catch a generated
/// project that fails version solving, does not compile, or throws on startup
/// — every one of which has shipped before. This generates a real monorepo per
/// state management choice and drives it through the same commands a developer
/// would: resolve, analyze, format, and run the tests, including the boot test
/// that pumps the app.
///
/// Deliberately named without the `_test.dart` suffix so `dart test` does not
/// pick it up: each case invokes flutter create and the network and takes
/// minutes. Run it explicitly:
///
///     dart test test/integration/generate_and_boot.dart
void main() {
  final cliPath = Directory.current.absolute.path;

  for (final state in ['getx', 'riverpod', 'bloc', 'cubit']) {
    test(
      '$state: generates a project that analyzes, formats and boots',
      () async {
        final workDir = Directory.systemTemp.createTempSync(
          'fm_integration_$state',
        );
        addTearDown(() {
          try {
            workDir.deleteSync(recursive: true);
          } on FileSystemException {
            // Generated projects leave storage files open on Windows.
          }
        });

        final name = '${state}_probe';
        final generate = await Process.run(
          'dart',
          [
            'run',
            '$cliPath/bin/flutter_monorepo.dart',
            name,
            '--state',
            state,
            '--no-git',
          ],
          workingDirectory: workDir.path,
          runInShell: true,
        );

        // The generator exits non-zero when any step fails, so this alone covers
        // dependency resolution, gen-l10n, formatting and analysis.
        expect(
          generate.exitCode,
          0,
          reason: 'generation failed:\n${generate.stdout}\n${generate.stderr}',
        );

        final projectDir = '${workDir.path}/$name';
        expect(File('$projectDir/pubspec.yaml').existsSync(), isTrue);
        expect(File('$projectDir/.flutter_monorepo.yaml').existsSync(), isTrue);
        expect(File('$projectDir/ARCHITECTURE.md').existsSync(), isTrue);

        // The boot test lives here and pumps the real app.
        final appTests = await Process.run(
          'flutter',
          ['test', '${name}_app/test'],
          workingDirectory: projectDir,
          runInShell: true,
        );
        expect(
          appTests.exitCode,
          0,
          reason: 'app tests failed:\n${appTests.stdout}\n${appTests.stderr}',
        );

        // Shared packages, which the generated CI also runs.
        final coreTests = await Process.run(
          'dart',
          ['test', 'packages/core/test'],
          workingDirectory: projectDir,
          runInShell: true,
        );
        expect(
          coreTests.exitCode,
          0,
          reason:
              'core tests failed:\n${coreTests.stdout}\n${coreTests.stderr}',
        );

        // Every path the generated guidance points at must exist in the tree it
        // describes. Four separate defects shipped because a skill referenced a
        // directory that was never created, or one missing its lib/ segment.
        final guidance = Directory('$projectDir/.claude/skills')
            .listSync(recursive: true)
            .whereType<File>()
            .where((f) => f.path.endsWith('SKILL.md'))
            .map((f) => f.readAsStringSync())
            .join('\n');
        expect(guidance, isNotEmpty, reason: 'no skills were generated');

        // Not a raw string: the project name has to interpolate, or app-package
        // paths are never checked.
        final referenced = RegExp('(?:packages|${name}_app)/[\\w./<>-]+')
            .allMatches(guidance)
            .map((m) => m.group(0)!)
            // Placeholders like <screen_name> stand for files the developer
            // creates; only concrete paths can be checked.
            .where((p) => !p.contains('<'))
            .map((p) => p.endsWith('/') ? p.substring(0, p.length - 1) : p)
            .toSet();

        final missing = referenced
            .where((p) => !File('$projectDir/$p').existsSync())
            .where((p) => !Directory('$projectDir/$p').existsSync())
            .toList();
        expect(
          missing,
          isEmpty,
          reason: 'skills reference paths that do not exist: $missing',
        );

        // doctor must consider its own output healthy.
        final doctor = await Process.run(
          'dart',
          ['run', '$cliPath/bin/flutter_monorepo.dart', 'doctor'],
          workingDirectory: projectDir,
          runInShell: true,
        );
        expect(
          doctor.exitCode,
          0,
          reason: 'doctor reported problems:\n${doctor.stdout}',
        );
      },
      timeout: const Timeout(Duration(minutes: 15)),
    );
  }
}
