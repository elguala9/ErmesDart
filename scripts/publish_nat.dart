// Publish the NAT-test Docker image via GitHub Actions.
//
// Runs the same on Windows and Linux:  dart run scripts/publish_nat.dart
//
// It force-pushes your CURRENT commit to the dedicated `publish-nat-image`
// branch. That push triggers .github/workflows/docker-publish-nat.yml, which
// builds the image and pushes it to Docker Hub using the repo secrets
// DOCKERHUB_USERNAME and DOCKERHUB_TOKEN (set once on GitHub).
//
// Your working tree and current branch are NOT touched: no checkout, no
// commit, no stash — only a push of what you have already committed.
import 'dart:io';

const branch = 'publish-nat-image';

Future<int> run(String exe, List<String> args) async {
  stdout.writeln('\$ $exe ${args.join(' ')}');
  final process = await Process.start(
    exe,
    args,
    mode: ProcessStartMode.inheritStdio,
    runInShell: true,
  );
  return process.exitCode;
}

Future<void> main() async {
  final code = await run('git', ['push', 'origin', 'HEAD:$branch', '--force']);
  if (code != 0) {
    stderr.writeln('\ngit push failed (exit $code).');
    exit(code);
  }
  stdout
    ..writeln('\nPushed to "$branch" — the publish workflow is now running.')
    ..writeln('Watch it:  gh run watch        (or the Actions tab on GitHub)');
}
