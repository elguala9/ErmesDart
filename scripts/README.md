# Testing Scripts

This directory contains automated test scripts for running the ErmesDart test suite with **automatic Ganache startup**.

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

The automated scripts (`run_tests.sh` and `run_tests.bat`) automatically:

1. **Check Ganache Availability**: Detects if Ganache is already running
2. **Auto-Start Ganache**: If Docker is available, automatically starts Ganache via docker-compose
3. **Health Checks**: Waits up to 30 seconds for Ganache to be ready
4. **Run Full Test Suite**: Executes all 549 tests (531 unit tests + 18 Ganache tests)
5. **Smart Fallback**: If Docker is unavailable, tests continue with graceful skips
6. **Auto-Cleanup**: Stops Ganache after tests complete

## Test Results

### When Ganache is Available (Docker running)
- **531 tests passing** ✅
- **18 tests passing** (ErmesSignalingServer integration tests) ✅
- **Total: 549 tests passing** ✅

### When Ganache is Unavailable (Docker not running)
- **531 tests passing** ✅
- **18 tests skipped** (ErmesSignalingServer - gracefully skip)
- **Total: 531 passing + 18 skipped** ✅ (No failures)

## Requirements

### Recommended (For Complete Test Suite)
- Docker and Docker Compose installed
- Port 9545 available (for Ganache)

### Minimum (For Unit Tests Only)
- Dart SDK
- No Docker needed (18 Ganache tests will skip gracefully)

## How It Works

The test runner (`tool/test_runner.dart`) automatically:

```
1. Checks if Ganache is running at http://localhost:9545
   ├─ If YES → Run all 549 tests ✅
   └─ If NO  → Try to start with docker-compose
      ├─ Docker available? → Start Ganache + run all 549 tests ✅
      └─ Docker unavailable? → Run 531 unit tests, skip 18 Ganache tests ✅
```

## Troubleshooting

### "Ganache not available" message
This is normal if Docker isn't installed. The 531 unit tests will still run fine.

### Docker Daemon Not Running
Start Docker Desktop or your Docker daemon, then re-run the script. The test runner will automatically detect it and start Ganache.

### Port 9545 Already in Use
Stop any existing Ganache instance:
```bash
docker-compose -f docker-compose-evm.yml down
```

Then re-run tests - the test runner will start a fresh Ganache.

### Manual Ganache Control
If you want to manage Ganache manually:

```bash
# Start Ganache manually
docker-compose -f docker-compose-evm.yml up -d

# Run tests (will use existing Ganache)
dart test packages/ermes_test/test/

# Stop Ganache manually
docker-compose -f docker-compose-evm.yml down
```
