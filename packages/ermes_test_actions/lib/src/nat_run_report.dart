// Step-by-step console reporting for the GitHub Actions NAT-test driver.
//
// Every phase of `nat_run` is announced with a numbered banner so the live
// console makes the whole flow auditable, and the per-peer logs are always
// surfaced — falling back to the run's full job log when artifact download
// is unavailable (e.g. a `gh` auth 401). stdout is the only transport.
// ignore_for_file: avoid_print

import 'dart:io';

/// Total number of phases `nat_run` reports, used in the step banners.
const int natRunTotalSteps = 6;

/// Prints a numbered phase banner, with an optional one-line detail.
void step(int n, String title, [String? detail]) {
  stdout.writeln('\n==> [$n/$natRunTotalSteps] $title');
  if (detail != null) {
    stdout.writeln('    $detail');
  }
}

/// Prints an indented sub-point under the current step.
void note(String message) => stdout.writeln('    - $message');

/// Runs `gh` and returns its trimmed stdout, or '' when the call fails.
Future<String> _gh(List<String> args) async {
  final r = await Process.run('gh', args, runInShell: true);
  return r.exitCode == 0 ? r.stdout.toString().trim() : '';
}

/// Prints the run's web URL so the user can open it and watch live.
Future<void> printRunUrl(int runId) async {
  final url = await _gh(
    ['run', 'view', '$runId', '--json', 'url', '-q', '.url'],
  );
  note(url.isEmpty ? 'run URL unavailable' : 'open live: $url');
}

/// Prints the run's overall status/conclusion and one line per job.
Future<void> printJobStatus(int runId) async {
  final summary = await _gh([
    'run', 'view', '$runId', '--json', 'status,conclusion',
    '-q', r'"run: status=\(.status) conclusion=\(.conclusion // "pending")"',
  ]);
  note(summary.isEmpty ? 'run status unavailable' : summary);
  final jobs = await _gh([
    'run', 'view', '$runId', '--json', 'jobs',
    '-q', r'.jobs[] | "job \(.name): \(.status)/\(.conclusion // "pending")"',
  ]);
  for (final line in jobs.split('\n').where((l) => l.trim().isNotEmpty)) {
    note(line);
  }
}

/// Downloads the run's artifacts into [dir], retrying once. Returns true when
/// at least one `.log` file landed.
Future<bool> downloadArtifacts(int runId, String dir) async {
  for (var attempt = 1; attempt <= 2; attempt++) {
    note('attempt $attempt: gh run download $runId --dir $dir');
    final p = await Process.start(
      'gh', ['run', 'download', '$runId', '--dir', dir],
      mode: ProcessStartMode.inheritStdio, runInShell: true,
    );
    await p.exitCode;
    if (_hasLogs(dir)) {
      return true;
    }
    if (attempt == 1) {
      note('no logs downloaded yet; retrying in 3s...');
      await Future<void>.delayed(const Duration(seconds: 3));
    }
  }
  return _hasLogs(dir);
}

/// Prints every downloaded `.log` file; when none are present (artifact
/// download denied or empty), falls back to the run's full job log so the
/// per-peer output is never lost.
Future<void> showLogs(String dir, int runId) async {
  final logs = _logFiles(dir);
  if (logs.isEmpty) {
    note('no artifact logs found; falling back to full run log...');
    final p = await Process.start(
      'gh', ['run', 'view', '$runId', '--log'],
      mode: ProcessStartMode.inheritStdio, runInShell: true,
    );
    await p.exitCode;
    return;
  }
  for (final f in logs) {
    stdout
      ..writeln('\n===== ${f.path} =====')
      ..writeln(f.readAsStringSync());
  }
}

List<File> _logFiles(String dir) {
  final d = Directory(dir);
  if (!d.existsSync()) {
    return <File>[];
  }
  return d
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.log'))
      .toList();
}

bool _hasLogs(String dir) => _logFiles(dir).isNotEmpty;
