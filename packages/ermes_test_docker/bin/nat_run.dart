import 'dart:io';

/// One-shot launcher for the GitHub Actions NAT test.
///
/// Pushes the current commit to the `nat-test` branch (which triggers
/// `.github/workflows/nat-test.yml`), waits for the freshly created run,
/// streams its progress live, downloads both peer logs and prints a
/// PASS/FAIL summary. Its own exit code mirrors the run result.
///
/// Usage: dart run packages/ermes_test_docker/bin/nat_run.dart [remote]
///   remote  git remote to push to (default: auto-detected, prefers `origin`)
///
/// Requires the GitHub CLI (`gh`) authenticated with `workflow` scope.
const _workflow = 'nat-test.yml';
const _branch = 'nat-test';

Future<void> main(List<String> args) async {
  final remote = args.isNotEmpty ? args.first : await _detectRemote();
  stdout.writeln('==> remote: $remote');

  final before = await _latestRunId();
  final pushed = await _push(remote);

  final runId =
      pushed ? await _awaitNewRun(before) : await _useExistingRun(before);
  stdout.writeln('==> run id: $runId');

  final ok = await _watch(runId);
  final dir = await _download(runId);
  _printLogs(dir);

  stdout.writeln(ok ? '\n==> NAT TEST PASSED' : '\n==> NAT TEST FAILED');
  exit(ok ? 0 : 1);
}

Future<String> _detectRemote() async {
  final r = await Process.run('git', ['remote']);
  final remotes = r.stdout
      .toString()
      .split('\n')
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty)
      .toList();
  if (remotes.isEmpty) {
    stderr.writeln('No git remote configured.');
    exit(1);
  }
  return remotes.contains('origin') ? 'origin' : remotes.first;
}

/// Pushes HEAD to the trigger branch. Returns `true` when the ref actually
/// moved (a new workflow run will be created), `false` when the remote was
/// already up to date (no `push` event fires, so no new run).
Future<bool> _push(String remote) async {
  stdout.writeln('==> git push $remote HEAD:$_branch');
  final r = await Process.run('git', ['push', remote, 'HEAD:$_branch']);
  final out = '${r.stdout}${r.stderr}';
  stdout.write(out);
  if (r.exitCode != 0) {
    stderr.writeln('git push failed (exit ${r.exitCode}).');
    exit(r.exitCode);
  }
  return !out.contains('up-to-date');
}

/// Branch already at HEAD: no new run was triggered, so attach to the most
/// recent existing run instead of waiting forever for a fresh one.
Future<int> _useExistingRun(int? latest) async {
  if (latest == null) {
    stderr
      ..writeln('Branch "$_branch" already up to date but no run exists.')
      ..writeln('Re-run the last one: gh run rerun <id>  (or push a commit).');
    exit(1);
  }
  stdout.writeln('==> branch up to date; attaching to existing run $latest');
  return latest;
}

Future<int?> _latestRunId() async {
  final r = await Process.run('gh', [
    'run', 'list', '--workflow=$_workflow', '--branch=$_branch',
    '--limit=1', '--json', 'databaseId', '-q', '.[0].databaseId // empty',
  ], runInShell: true);
  if (r.exitCode != 0) {
    return null;
  }
  final out = r.stdout.toString().trim();
  return out.isEmpty ? null : int.tryParse(out);
}

Future<int> _awaitNewRun(int? before) async {
  stdout.write('==> waiting for the run to register');
  for (var i = 0; i < 30; i++) {
    final id = await _latestRunId();
    if (id != null && id != before) {
      stdout.writeln(' done.');
      return id;
    }
    stdout.write('.');
    await Future<void>.delayed(const Duration(seconds: 4));
  }
  stdout.writeln();
  stderr
    ..writeln('Timed out waiting for a new run on "$_branch".')
    ..writeln('Check: gh run list --workflow=$_workflow --branch=$_branch');
  exit(1);
}

Future<bool> _watch(int runId) async {
  stdout.writeln('==> watching run $runId (live)...');
  await _stream('gh', ['run', 'watch', '$runId', '--exit-status'], shell: true);
  // `gh run watch` exit status is unreliable when attaching to an already
  // running job, so derive PASS/FAIL from the authoritative run conclusion.
  return _succeeded(runId);
}

Future<bool> _succeeded(int runId) async {
  final r = await Process.run('gh',
      ['run', 'view', '$runId', '--json', 'conclusion', '-q', '.conclusion'],
      runInShell: true);
  return r.stdout.toString().trim() == 'success';
}

Future<String> _download(int runId) async {
  final dir = 'nat-test-logs/$runId';
  stdout.writeln('==> downloading artifacts to $dir');
  await _stream('gh', ['run', 'download', '$runId', '--dir', dir], shell: true);
  return dir;
}

void _printLogs(String dir) {
  final d = Directory(dir);
  if (!d.existsSync()) {
    return;
  }
  for (final f in d.listSync(recursive: true).whereType<File>()) {
    if (!f.path.endsWith('.log')) {
      continue;
    }
    stdout
      ..writeln('\n===== ${f.path} =====')
      ..writeln(f.readAsStringSync());
  }
}

Future<int> _stream(String cmd, List<String> args, {bool shell = false}) async {
  final p = await Process.start(cmd, args,
      mode: ProcessStartMode.inheritStdio, runInShell: shell);
  return p.exitCode;
}
