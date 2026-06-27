# TODO — mesh-3peer

**Scenario**: `NAT_SCENARIO=mesh-3peer`
**CI fit**: ✅ three jobs (or 2 local + 1 runner); compounds NAT pairings
**Status**: [ ] not started

## Goal
Three peers each maintaining a live exchange with the other two (full mesh).
Asserts all three pairwise connections work with no cross-talk.

## Core path
- `OrcErmes` multi-connection handling (`ErmesConnectionsHandler` pool).
- Per-peer message routing.

## Actions wiring
- Three jobs (`peer-a`/`peer-b`/`peer-c`) using `alice_main.dart` /
  `bob_main.dart` / `charlie_main.dart`, or mix: 2 peers local + 1 on a runner.
- All three share STUN + relays and each other's pubkeys;
  `NAT_SCENARIO=mesh-3peer`.

## Asserts (strict)
- All three connections established (A-B, B-C, A-C).
- Messages for one pair never surface on another (no cross-talk).
- Zero loss on each pair.

## Metric line
`mesh-3peer connections=3/3 crossTalk=0 messagesLost=<x>/<total>`

## Runner caveats
- A full mesh means runner↔runner punches too (Azure↔Azure) plus local↔Azure —
  the hardest NAT combination here. Expect this to need TURN sooner than the
  2-peer scenarios.
- Distinct identities per peer; watch the `concurrency` group.
