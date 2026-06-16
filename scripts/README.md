# Testing Scripts

This directory contains automated test scripts for running the ErmesDart test suite.

## Quick Start

### Linux/Mac
```bash
./scripts/run_tests.sh
```

### Windows
```bash
scripts\run_tests.bat
```

### Direct Dart Test
```bash
dart test packages/ermes_test/test/
```

## What These Scripts Do

- `run_tests.sh` — runs the full Dart test suite (or use `melos run test`).
- `run-nat-test.sh` — drives the two-machine real NAT-traversal test (see
  `packages/ermes_test_docker/NAT_TEST.md`).

## Requirements

- Dart SDK
- Docker + bash (for `run-nat-test.sh`)
