# ermes_test_docker

Docker-based integration tests for OrcErmes peer-to-peer communication. Alice and Bob are separate Docker containers that use OrcErmes to exchange messages via a signaling server with a coturn STUN server.

## Project Structure

```
packages/ermes_test_docker/
├── bin/
│   ├── alice_main.dart       # Alice peer executable
│   └── bob_main.dart         # Bob peer executable
├── lib/src/
│   ├── docker_test_runner.dart  # Test framework (run, pass/fail, duration)
│   ├── test_result.dart         # TestResult + SuiteResult data models
│   ├── message_envelope.dart    # JSON-typed message protocol (DockerMsgType)
│   ├── ermes_setup.dart         # OrcErmes factory configured from env vars
│   ├── test_scenarios.dart      # Test scenarios (Alice + Bob interactions)
│   └── result_writer.dart       # JSON output writer
└── docker/
    ├── Dockerfile.alice      # Alice container (Dart → native binary)
    └── Dockerfile.bob        # Bob container (Dart → native binary)
```

## Architecture

### Docker Network

```
ermes-alice-bob-network (bridge)
├── coturn           :3478/udp  (STUN server for NAT traversal)
├── alice            (OrcErmes peer)
└── bob              (OrcErmes peer)

Shared volume: test-output → /output/ (JSON results)
```

### Message Protocol

All OrcErmes messages are wrapped in a JSON envelope with a type field:

```json
{"type": "testData", "test": "simple_send", "seq": 0, "payload": "<base64>"}
{"type": "ack", "test": "simple_send"}
{"type": "endOfTests"}
```

## Running the Tests

### Full Docker Compose Run

```bash
# Build and run all containers
docker compose -f docker-compose-alice-bob.yml up --build

# Follow logs in separate terminal
docker compose -f docker-compose-alice-bob.yml logs -f alice bob

# After completion, read results from the named volume
docker run --rm -v ermes_test_docker_test-output:/data alpine cat /data/alice_result.json | jq .

# Verify exit codes (0 = all tests passed)
docker inspect ermes-ab-alice --format='{{.State.ExitCode}}'
docker inspect ermes-ab-bob   --format='{{.State.ExitCode}}'

# Clean up
docker compose -f docker-compose-alice-bob.yml down -v
```

### Output Format

Both containers write JSON to `/output/{alice,bob}_result.json`:

```json
{
  "peer": "alice",
  "timestamp": "2026-04-24T10:32:15.123Z",
  "all_passed": true,
  "passed": 2,
  "total": 2,
  "tests": [
    {"name": "sanity_check", "passed": true, "duration_ms": 3421},
    {"name": "simple_send", "passed": true, "duration_ms": 87}
  ]
}
```

## Configuration

### Environment Variables (set in docker-compose-alice-bob.yml)

- `STUN_HOST` → STUN server hostname (default: `coturn`)
- `STUN_PORT` → STUN server port (default: `3478`)
- `SHSP_PORT` → Local SHSP socket port (default: `0` = auto-assign)

## Dependencies

- `ermes_core` – OrcErmes + factories
- `ermes_signaling` – ErmesSignalingServer + handler
- `ermes_cipher`, `ermes_storage`, `ermes_id_handler`, `ermes_message_control` – core feature packages
- `stun_shsp` – STUN/SHSP transport

## Design Notes

### Why coturn?

Docker bridge networks use internal IPs (172.x.x.x). A public STUN server would return the host's external IP, breaking UDP connectivity between containers. coturn on the same network returns the correct Docker bridge IP.

### No Mocks

Per the ErmesDart project guidelines, all tests use real implementations — no mocks, no stubs. Alice and Bob are real OrcErmes instances.

### Message Routing

Alice coordinates test scenarios by sending typed messages. Bob listens and responds. The `onMessage` callback routes messages to test handlers based on the `testName` field.

### Async Test Framework

`DockerTestRunner` replaces `dart test`. Each test is a `Future<void>`, timed, and pass/fail status is recorded. Results are JSON-serialized at the end.

## Extending the Tests

To add a new test scenario:

1. Define a new `DockerMsgType` enum value in `message_envelope.dart` (if needed)
2. Add a scenario method to `AliceTestScenarios` (sends test message)
3. Add a corresponding handler to `BobTestScenarios` (receives, verifies, sends ACK)
4. Call the scenario from `AliceTestScenarios.runAll()`
5. Run the full compose stack to test

## Notes

- Both peers start simultaneously after the signaling server is ready
- Alice drives the test sequence and sends `END_OF_TESTS` when complete
- Bob waits for `END_OF_TESTS` before finalizing
- Exit codes: 0 = all tests passed, 1 = any test failed
