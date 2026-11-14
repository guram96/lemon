// Runs every quality gate across the workspace: codegen, format, analyze, tests.
//
//   dart tool/check.dart          # everything
//   dart tool/check.dart --fix    # apply formatting instead of failing on it

import 'dart:io';

/// Workspace packages and whether they need the Flutter test runner.
const _packages = {
  'packages/rs_core': false,
  'packages/rs_api_client': false,
  'packages/rs_theme': true,
  'packages/rs_ui': true,
  'packages/rs_ui_steam': true,
  'packages/rs_ui_crossblade': true,
  'apps/server': false,
  'apps/client': true,
};

/// Packages that use build_runner.
const _codegen = ['packages/rs_core'];

Future<void> main(List<String> args) async {
  final fix = args.contains('--fix');
  final failures = <String>[];

  Future<void> step(
    String name,
    String exe,
    List<String> argv, {
    String dir = '.',
  }) async {
    stdout.writeln('\n▶ $name');
    final p = await Process.start(
      exe,
      argv,
      workingDirectory: dir,
      runInShell: true,
      mode: ProcessStartMode.inheritStdio,
    );
    if (await p.exitCode != 0) failures.add(name);
  }

  await step('pub get', 'flutter', ['pub', 'get']);
  for (final dir in _codegen) {
    await step('codegen $dir', 'dart', [
      'run',
      'build_runner',
      'build',
      '--delete-conflicting-outputs',
    ], dir: dir);
  }
  await step('format', 'dart', [
    'format',
    if (!fix) '--set-exit-if-changed',
    'apps',
    'packages',
    'tool',
  ]);
  await step('analyze', 'flutter', ['analyze']);
  for (final MapEntry(key: dir, value: isFlutter) in _packages.entries) {
    await step('test $dir', isFlutter ? 'flutter' : 'dart', ['test'], dir: dir);
  }

  stdout.writeln(
    failures.isEmpty
        ? '\n✅ All checks passed.'
        : '\n❌ Failed: ${failures.join(', ')}',
  );
  exit(failures.isEmpty ? 0 : 1);
}
