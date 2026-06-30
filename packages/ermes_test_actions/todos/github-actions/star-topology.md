# TODO — star-topology

**Scenario**: `NAT_SCENARIO=star-topology`
**CI fit**: ✅ one job per spoke; hub local or on a runner
**Status**: [ ] not started

## Goal
One hub peer with N spoke peers, mirroring the in-process star-topology test
(`multi_peer_integration_test.dart`) over real NAT.

## Core path
- Hub holding N simultaneous connections (`ErmesConnectionsHandler`).
- `getConnections()` settling to N.

## Actions wiring
- Hub local (drives); each spoke a separate runner job using a matrix:
  `strategy.matrix.spoke: [0, 1, 2, ...]` → N parallel `peer-b`-style jobs, each
  with its own throwaway identity. Or hub on a runner too (all-CI).
- Reuse `alice_main.dart` (hub) / `bob_main.dart`/`charlie_main.dart` (spokes);
  `NAT_SCENARIO=star-topology`.
- Each spoke must agree on the hub pubkey; the hub must know all spoke pubkeys.

## Asserts (strict)
- Hub's `getConnections()` settles to exactly N.
- Each spoke exchange completes with zero loss.
- No spoke starves another (all make progress).

## Metric line
`star-topology spokes=<N> connected=<N> messagesLost=<x>/<total>`

## Runner caveats
- Each spoke is behind its own Azure NAT → N independent local↔Azure punches;
  validate `encrypted` first.
- Identities must be distinct per spoke to avoid relay collisions (mind the
  `concurrency` group in the workflow).
