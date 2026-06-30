# ermes_test_actions

GitHub Actions orchestration for the NAT traversal tests. The peers run on
GitHub runners (or local↔runner); this package is the thin layer that drives
the workflow and reports the result. The peer binaries themselves live in
[`ermes_test_shared`](../ermes_test_shared).

## Contents

- `bin/nat_run.dart` — one-shot launcher: push the trigger branch, watch the
  run live, download both peer logs, print PASS/FAIL (mirrors the run result in
  its exit code). Requires the GitHub CLI (`gh`) with `workflow` scope.
- `lib/src/nat_run_report.dart` — console reporting helpers (run URL, job
  status, artifact download, log display).
- `CLAUDE.md` — requirements for each GitHub Actions test (workflow YAML + the
  `run-test-github-<name>.sh` script; Linux **and** Windows compatible).
- `todos/github-actions/` — the CI-adapted scenario specs and status tracker.

The workflows (`.github/workflows/nat-*.yml`) and the `run-test-github-*.sh`
driver scripts (under the repo-root `scripts/`) dispatch the same
`NAT_SCENARIO` values that the PC-to-PC tests use. Drive everything via the
workspace melos scripts (`nat:run`, `test:github:*`).
