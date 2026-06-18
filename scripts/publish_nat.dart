// Publish the NAT-test Docker image via GitHub Actions.
//
// Runs the same on Windows and Linux:  melos run publish:quay
//                                 (or:  dart run scripts/publish_nat.dart)
//
// It force-pushes your CURRENT commit to the dedicated `publish-nat-image`
// branch. That push triggers .github/workflows/docker-publish-nat.yml, which
// builds the image and pushes it to Quay.io using the repo secrets
// QUAY_USERNAME and QUAY_TOKEN (set once on GitHub).
//
// Your working tree and current branch are NOT touched: no checkout, no
// commit, no stash — only a push of what you have already committed.
//
// The git remote is auto-detected (the upstream of the current branch, else
// the only remote, else `origin`). Override it with an argument or env var:
//   dart run scripts/publish_nat.dart GitHub
//   ERMES_REMOTE=GitHub dart run scripts/publish_nat.dart
import 'dart:io';

const branch = 'publish-nat-image';

Future<int> run(String exe, List<String> args) async {
  stdout.writeln('\$ $exe ${args.join(' ')}');
  final process = await Process.start(exe, args, runInShell: true);
  // git writes its normal push status (e.g. "<old>..<new> HEAD -> branch") to
  // stderr even on success. Route both streams to stdout so wrappers like melos
  // don't mislabel that successful output as an error. The exit code below
  // still reflects a real failure.
  process.stdout.listen(stdout.add);
  process.stderr.listen(stdout.add);
  return process.exitCode;
}

Future<String> capture(String exe, List<String> args) async {
  final result = await Process.run(exe, args, runInShell: true);
  if (result.exitCode != 0) {
    return '';
  }
  return (result.stdout as String).trim();
}

// Pick the remote to push to: explicit arg/env wins; otherwise the upstream of
// the current branch, then `origin` if it exists, then the only remote.
Future<String> resolveRemote(List<String> argv) async {
  final override = argv.isNotEmpty
      ? argv.first
      : Platform.environment['ERMES_REMOTE'];
  if (override != null && override.isNotEmpty) {
    return override;
  }

  final upstream = await capture('git', [
    'rev-parse',
    '--abbrev-ref',
    '--symbolic-full-name',
    '@{u}',
  ]);
  if (upstream.contains('/')) {
    return upstream.split('/').first;
  }

  final remotes = (await capture('git', ['remote']))
      .split('\n')
      .map((r) => r.trim())
      .where((r) => r.isNotEmpty)
      .toList();
  if (remotes.contains('origin')) {
    return 'origin';
  }
  if (remotes.length == 1) {
    return remotes.first;
  }
  if (remotes.isEmpty) {
    stderr.writeln('No git remote configured. Add one and retry.');
    exit(1);
  }
  stderr.writeln(
    'Multiple remotes found (${remotes.join(', ')}) and no upstream set.\n'
    'Pass the remote explicitly:  dart run scripts/publish_nat.dart <remote>',
  );
  exit(1);
}

Future<void> main(List<String> argv) async {
  final remote = await resolveRemote(argv);
  stdout.writeln('Using remote "$remote".');
  final code = await run('git', ['push', remote, 'HEAD:$branch', '--force']);
  if (code != 0) {
    stderr.writeln('\ngit push failed (exit $code).');
    exit(code);
  }
  stdout
    ..writeln('\nPushed to "$branch" — the publish workflow is now running.')
    ..writeln('Watch it:  gh run watch        (or the Actions tab on GitHub)');
}
