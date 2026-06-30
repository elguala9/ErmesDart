# TODO — mesh-3peer

**Scenario**: `NAT_SCENARIO=mesh-3peer`
**Status**: [ ] not started

## Goal
Three peers on three machines, each pair maintaining a live exchange (full
mesh). Asserts all three pairwise connections work and there is no cross-talk
between conversations.

## Core path
- `OrcErmes` multi-connection handling (`ErmesConnectionsHandler` pool).
- Per-peer message routing.

## Setup
Three PCs (or 2 PCs + CI). Build on `alice_main.dart` / `bob_main.dart` /
`charlie_main.dart`.

## Steps
1. All three rendezvous pairwise (A-B, B-C, A-C).
2. Each pair runs an independent heartbeat with distinct payloads.

## Asserts (strict)
- All three connections established.
- Messages for one pair never surface on another (no cross-talk).
- Zero loss on each pair.

## Metric line
`mesh-3peer connections=3/3 crossTalk=0 messagesLost=<x>/<total>`
