# Testing Scripts

This directory contains automated test scripts for running the ErmesDart test suite.

## Quick Start

### Linux/Mac
```bash
./scripts/run_tests.sh
```

### Windows
Run the shell script from Git Bash or WSL, or use the cross-platform commands below.

### Cross-platform (any OS)
```bash
melos run test
# or
dart test packages/ermes_test/test/
```

## What These Scripts Do

- `run_tests.sh` — runs the full Dart test suite (or use `melos run test`).
- `run-nat-test-pc.sh` — drives the two-machine real NAT-traversal test (see
  `packages/ermes_test_pc/NAT_TEST.md`).

## Requirements

- Dart SDK
- Docker + bash (for `run-nat-test-pc.sh`)
