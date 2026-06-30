# ermes_test_shared

Shared core for the cross-network integration tests (NAT traversal, encrypted
exchange, reconnection, and more). Holds the actual test logic and the two peer
entry points; the surrounding packages only add a *context* in which to run
them.

## Contents

- `bin/nat_peer_a.dart`, `bin/nat_peer_b.dart` — the initiator/responder peer
  binaries. The scenario is selected at runtime via the `NAT_SCENARIO`
  environment variable (default: one-shot burst).
- `lib/src/` — rendezvous, heartbeat engines, ECDH/AES cipher exchange,
  reconnection breaks, the wire protocol (`MessageEnvelope`) and the OrcErmes
  bring-up (`DockerErmesConfig` / `createDockerOrcErmes`).

## Who depends on this

- `ermes_test_pc` — runs these binaries on two real machines (Docker/native).
- `ermes_test_actions` — runs the same binaries on GitHub runners.
- `ermes_test_docker` — reuses `MessageEnvelope` + the OrcErmes bring-up for the
  Alice/Bob/Charlie mesh test.

Nothing here depends on those packages: the dependency direction is always
toward this shared base.

## Running a peer locally

See the melos `nat:local:a` / `nat:local:b` scripts at the workspace root, or
`packages/ermes_test_pc/NAT_TEST.md` for the full protocol and required
environment variables.
