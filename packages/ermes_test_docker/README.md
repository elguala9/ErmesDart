# ermes_test_docker

Docker-based integration tests for OrcErmes peer-to-peer communication. Alice and Bob are separate Docker containers that use OrcErmes to exchange messages via a private Ganache blockchain with a coturn STUN server.

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
├── ganache          :8545  (EVM, account 0 + 1 pre-funded)
├── deployer         (one-shot, deploys SignalingContract)
├── coturn           :3478/udp  (STUN server for NAT traversal)
├── alice            (OrcErmes peer, account 0)
└── bob              (OrcErmes peer, account 1)

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

- `RPC_URL` → Ganache RPC endpoint (default: `http://ganache:8545`)
- `CONTRACT_ADDRESS` → Deployed SignalingContract address (default: `0x5FbDB2315678afecb367f032d93F642f64180aa3`)
- `ACCOUNT_ID` → Ethereum address of this peer
- `PRIVATE_KEY_HEX` → Private key for signing (Hardhat mnemonic-derived)
- `STUN_HOST` → STUN server hostname (default: `coturn`)
- `STUN_PORT` → STUN server port (default: `3478`)
- `SHSP_PORT` → Local SHSP socket port (default: `0` = auto-assign)

### Default Accounts (Hardhat Mnemonic)

```
Mnemonic: test test test test test test test test test test test junk

Alice (account 0):
  Address: 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
  PrivKey: 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80

Bob (account 1):
  Address: 0x70997970C51812dc3A010C7d01b50e0d17dc79C8
  PrivKey: 0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d
```

Contract deploys at: `0x5FbDB2315678afecb367f032d93F642f64180aa3`

## Dependencies

- `ermes_core` – OrcErmes + factories
- `ermes_signaling` – ErmesSignalingServer + handler
- `ermes_cipher`, `ermes_storage`, `ermes_id_handler`, `ermes_message_control` – core feature packages
- `stun_shsp` – STUN/SHSP transport
- `signaling_contract_sdk`, `web3dart`, `wallet` – Ethereum blockchain integration

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

- Both peers start simultaneously after Ganache and the deployer are ready
- The `deployer` service exits immediately after deploy; both peers respect `service_completed_successfully`
- Alice drives the test sequence and sends `END_OF_TESTS` when complete
- Bob waits for `END_OF_TESTS` before finalizing
- Exit codes: 0 = all tests passed, 1 = any test failed
